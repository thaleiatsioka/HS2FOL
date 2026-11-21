-- | The whole translation pipeline, properties, function builders, naming
-- and rendering of TPTP problems.
module Translate
  ( Translation (..)
  , PropSpec (..)
  , translateProgram
  , renderProblem
  , funDisplay
  , TypedData (..)
  , PolyData (..)
  , Mode (..)
  ) where

import Data.List (intercalate, isPrefixOf, sortOn)
import qualified Data.Map as M
import Data.Maybe (isJust)
import qualified Data.Set as S
import Desugar
import FOL
import Lift
import Names
import Specialise
import Syntax
import TypeCheck
import Typed

data PropSpec = PropSpec
  { psName :: Ident
  , psKey :: String
  , psArity :: Int
  , psType :: Type
  , psBuilders :: [Sym]
  }

data Translation = Translation
  { trEqns :: [Equation]
  , trNames :: NameMap -- ^ one FOL name per symbol (untyped names, or one typed instance)
  , trInverse :: M.Map String Sym -- ^ every printed name -> its symbol
  , trProps :: [PropSpec]
  , trFuns :: M.Map String FunInfo
  , trCons :: M.Map Ident ConInfo
  , trWarnings :: [String]
  , trTyped :: Maybe TypedData -- ^ present in typed (TFF0) mode
  , trPoly :: Maybe PolyData -- ^ present in polymorphic (TF1) mode
  , trTypeArgs :: M.Map String Int -- ^ printed name -> number of leading type arguments (TF1)
  }

-- | Output format.
data Mode = MUntyped | MTFF0 | MTF1
  deriving (Eq, Show)

-- | Polymorphic (TF1) view of the equations.
data PolyData = PolyData
  { pdEqs :: [TEq] -- ^ program and builder equations; type variables are TVar
  , pdSig :: Sym -> Maybe ([String], [Type], Type)
  , pdNames :: M.Map (Either String Sym) String -- ^ type constructors and symbols
  , pdTyArity :: M.Map String Int -- ^ type constructor -> number of parameters
  }

-- | Typed (TFF) view of the equations.
data TypedData = TypedData
  { tdEqs :: [TEq] -- ^ sorts for the program equations (no builders)
  , tdBuilders :: M.Map String [TEq] -- ^ typed builders per property key
  , tdNames :: M.Map (Either Type TKey) String -- ^ names of sorts and symbols
  , tdSig :: TKey -> Maybe ([Type], Type)
  }

-- | Translate; with @typed@, also infer sorts for TFF output (this needs
-- full monomorphisation).
translateProgram :: Mode -> [Decl] -> [Decl] -> Either String Translation
translateProgram mode pre usr = do
  let typed = mode == MTFF0
  (prog, warns) <- desugarProgram pre usr
  tc <- typecheck prog
  sbs <- specialise typed (mode == MTF1) prog tc
  let undefKey = if any ((== "Prelude.undefined") . bindKey) (progBinds prog) then "Prelude.undefined" else "undefined"
  (funs, eqs) <- liftProgram (progFresh prog) prog undefKey sbs
  let candidates = [ b | b <- progBinds prog, bindKind b == BUser, "prop" `isPrefixOf` bindHask b, isJust (bindBody b) ]
      checked = map (checkProp tc funs) candidates
      sbTypes = M.fromList [ (sbKey sb, sbType sb) | sb <- sbs ]
      props = [ if mode /= MUntyped then p { psType = M.findWithDefault (psType p) (psKey p) sbTypes } else p | Right p <- checked ]
      propWarnings = [ w | Left w <- checked ]
      datas = progDatas prog
      withBuilders = [ p { psBuilders = propBuilders datas (argTypes p) } | p <- props ]
      builderTypes = S.toList (S.fromList [ t | p <- withBuilders, SFnCase t <- psBuilders p ])
      allEqs = eqs ++ (if any (not . null . psBuilders) withBuilders then builderEqns datas builderTypes else [])
      syms = concatMap (\e -> termSyms (eqLhs e) ++ termSyms (eqRhs e)) allEqs
          ++ [ SFun (psKey p) | p <- withBuilders ] ++ concatMap psBuilders withBuilders
          ++ [SCon "False", SCon "True"]
      untypedNames = assignNames [ let (pr, b) = symBase funs s in (s, pr, b) | s <- syms ]
  typedData <- if not typed then return Nothing else do
    (teqs, auxSigs) <- typeEquations sbTypes funs (progCons prog) eqs
    let builders = M.fromList [ (psKey p, typedBuilders datas (argTypes p)) | p <- withBuilders, not (null (psBuilders p)) ]
        allT = teqs ++ concat (M.elems builders)
        keys = S.toList (S.fromList (concat [ ttermSyms l ++ ttermSyms r | TEq _ l r <- allT ]
                 ++ [ (SFun (psKey p), []) | p <- withBuilders ] ++ [(SCon "False", []), (SCon "True", [])]))
        sig k = symSignature sbTypes funs (progCons prog) datas auxSigs k
        sorts = S.toList (S.fromList (concat [ maybe [] (\(as, r) -> r : as) (sig k) | k <- keys ]
                  ++ [ t | TEq _ l r <- allT, (_, t) <- ttermVars l ++ ttermVars r ]))
        tnames = assignNames
          ([ (Left t, -1, sortName t) | t <- sorts ]
           ++ [ let (pr, b) = symBase funs s in (Right (s, inst), pr, b ++ concatMap (("_" ++) . sortName) inst) | (s, inst) <- keys ])
    return (Just (TypedData teqs builders tnames sig))
  polyData <- if mode /= MTF1 then return Nothing else do
    (peqs, auxSigs) <- typeEquationsPoly sbTypes funs (progCons prog) datas allEqs
    let sig = polySig sbTypes funs (progCons prog) datas auxSigs
        symsP = S.toList (S.fromList syms)
        tys = concat [ r : as | Just (_, as, r) <- map sig symsP ]
              ++ [ t | TEq _ l r <- peqs, (_, t) <- ttermVars l ++ ttermVars r ]
              ++ [ t | p <- withBuilders, t <- argTypes p ]
        tycons = M.fromList (concatMap tyconsOf tys)
        pnames = assignNames
          ([ (Left c, -1, tyconName c) | c <- M.keys tycons ]
           ++ [ let (pr, b) = symBase funs sy in (Right sy, pr, b) | sy <- symsP ])
    return (Just (PolyData peqs sig pnames tycons))
  let (names, inverse) = case typedData of
        Nothing
          | Just pd <- polyData ->
              let symNames = [ (sy, n) | (Right sy, n) <- M.toList (pdNames pd) ]
              in (M.fromList symNames, M.fromList [ (n, sy) | (sy, n) <- symNames ])
          | otherwise -> (untypedNames, M.fromList [ (v, k) | (k, v) <- M.toList untypedNames ])
        Just td ->
          let symNames = [ (s, n) | (Right (s, _), n) <- M.toList (tdNames td) ]
          in (M.fromListWith (\_ old -> old) symNames, M.fromList [ (n, s) | (s, n) <- symNames ])
  return Translation
    { trEqns = allEqs
    , trNames = names
    , trInverse = inverse
    , trProps = withBuilders
    , trFuns = funs
    , trCons = progCons prog
    , trWarnings = warns ++ propWarnings
    , trTyped = typedData
    , trPoly = polyData
    , trTypeArgs = case polyData of
        Nothing -> M.empty
        Just pd -> M.fromList [ (n, length vs) | (Right sy, n) <- M.toList (pdNames pd), Just (vs, _, _) <- [pdSig pd sy], not (null vs) ]
    }
  where
    argTypes p = take (psArity p) (fst (funArgs (psType p)))
    tyconsOf (TVar _) = []
    tyconsOf (TCon c ts) = (c, length ts) : concatMap tyconsOf ts

-- | TPTP name of a type constructor: nat, list, fun, pair, ...
tyconName :: Ident -> String
tyconName c = sortName (TCon c [])

checkProp :: TcResult -> M.Map String FunInfo -> Binding -> Either String PropSpec
checkProp tc funs b
  | not (null (M.findWithDefault [] k (tcRel tc))) =
      Left ("skipping property " ++ bindHask b ++ ": it is overloaded; give it a monomorphic type signature")
  | otherwise = case (M.lookup k (tcSchemes tc), M.lookup k funs) of
      (Just (Forall _ t), Just fi) -> case splitArgs (fiArity fi) t of
        Just (_, res) | res == tBool -> Right (PropSpec (bindHask b) k (fiArity fi) t [])
        _ -> Left ("skipping " ++ bindHask b ++ ": its result type is not Bool/Property (" ++ prettyType t ++ ")")
      _ -> Left ("skipping " ++ bindHask b ++ ": no type information")
  where
    k = bindKey b

-- | Builders needed for function-valued arguments.
propBuilders :: M.Map Ident DataInfo -> [Type] -> [Sym]
propBuilders datas args
  | null funTys = []
  | otherwise = [SFnConst, SFnId] ++ map SFnCase (S.toList tcs)
  where
    funTys = [ t | t@(TCon "->" _) <- args ]
    doms = concatMap (fst . funArgs) funTys
    tcs = closure S.empty (concatMap tycons doms)
    tycons (TCon c ts) = [ c | M.member c datas ] ++ concatMap tycons ts
    tycons (TVar _) = []
    closure seen [] = seen
    closure seen (c : cs)
      | S.member c seen = closure seen cs
      | otherwise = case M.lookup c datas of
          Just d -> closure (S.insert c seen) (concatMap tycons (concatMap snd (dataCons d)) ++ cs)
          Nothing -> closure seen cs

builderEqns :: M.Map Ident DataInfo -> [Ident] -> [Equation]
builderEqns datas tcs =
  [ Equation SFnConst (TF SApp [TF SFnConst [y], x]) y
  , Equation SFnId (TF SApp [TF SFnId [], x]) x
  ]
    ++ [ Equation (SFnCase tc) (TF SApp [TF (SFnCase tc) rs, TF (SCon c) zs]) (appChain r zs)
       | tc <- tcs
       , Just d <- [M.lookup tc datas]
       , let rs = [ TV (Name ("R" ++ show i) (-1)) | i <- [1 .. length (dataCons d)] ]
       , ((c, fts), r) <- zip (dataCons d) rs
       , let zs = [ TV (Name ("Z" ++ show i) (-1)) | i <- [1 .. length fts] ] ]
  where
    x = TV (Name "X" (-1))
    y = TV (Name "Y" (-1))

-- | Priority and desired name of a symbol.
symBase :: M.Map String FunInfo -> Sym -> (Int, String)
symBase funs s = case s of
  SApp -> (0, "app")
  SFnConst -> (0, "fn_const")
  SFnId -> (0, "fn_id")
  SFnCase tc -> (0, "fn_case_" ++ mangleTycon tc)
  SCon c -> (1, conFolBase c)
  SFun k -> case M.lookup k funs of
    Just fi -> case fiKind fi of
      KUser -> (2, fiFol fi)
      KLambda _ _ _ -> (5, fiFol fi ++ "_body")
      KLocal -> (5, fiFol fi)
      KAux -> (5, fiFol fi)
      _ -> (3, fiFol fi)
    Nothing -> (6, k)
  SLit n -> (4, "int_" ++ show n)
  SClo (ToCon c) j -> (5, conFolBase c ++ "_" ++ show j)
  SClo (ToFun k) j -> case M.lookup k funs of
    Just (FunInfo _ fol _ (KLambda nfv _ _)) -> (5, if j == nfv then fol else fol ++ "_" ++ show (j - nfv))
    Just fi -> (5, fiFol fi ++ "_" ++ show j)
    Nothing -> (6, k ++ "_" ++ show j)

-- | Haskell rendering of a function name.
funDisplay :: M.Map String FunInfo -> String -> String
funDisplay funs k = case M.lookup k funs of
  Just fi -> case fiKind fi of
    KUser -> haskDisplay (fiHask fi)
    KPrelude -> haskDisplay (fiHask fi)
    KSpec -> haskDisplay (fiHask fi)
    KAbstract -> haskDisplay (fiHask fi)
    _ -> fiFol fi
  Nothing -> k

-- | One TPTP problem for a property.
renderProblem :: FilePath -> Translation -> PropSpec -> String
renderProblem src tr p = case (trTyped tr, trPoly tr) of
  (Just td, _) -> renderTyped src tr td p
  (_, Just pd) -> renderPoly src tr pd p
  _ -> renderUntyped src tr p

-- | One polymorphic (TF1) problem for a property.
renderPoly :: FilePath -> Translation -> PolyData -> PropSpec -> String
renderPoly src tr pd p = unlines (header ++ tyDecls ++ symDecls ++ axioms ++ ["", conj])
  where
    roots = SFun (psKey p) : psBuilders p
    reached = reachableSyms (trEqns tr) roots
    eqs = groupOwners [ e | e <- pdEqs pd, S.member (teOwner e) reached ]
    nm s = M.findWithDefault ("unknown_" ++ sanitize (show s)) (Right s) (pdNames pd)
    tcNm c = M.findWithDefault (tyconName c) (Left c) (pdNames pd)
    syms = S.toList (S.fromList (SFun (psKey p) : SCon "False" : concat [ map fst (ttermSyms l ++ ttermSyms r) | TEq _ l r <- eqs ]))
    sigs = [ (s, sg) | s <- syms, Just sg <- [pdSig pd s] ]
    argSorts = take (psArity p) (fst (funArgs (psType p)))
    usedTycons = S.toList (S.fromList (concat
      ([ concatMap tcs (r : as) | (_, (_, as, r)) <- sigs ]
       ++ [ tcs t | TEq _ l r <- eqs, (_, t) <- ttermVars l ++ ttermVars r ]
       ++ map tcs argSorts)))
    tcs (TVar _) = []
    tcs (TCon c ts) = c : concatMap tcs ts
    header =
      [ "% Generated by hs2fol (polymorphic typed, TF1) from " ++ src
      , "% Property: " ++ psName p ++ " :: " ++ prettyType (psType p)
      , "% A proof of the conjecture is a counterexample; the answer substitution gives the arguments."
      , "% Polymorphic symbols take their type arguments first: cons(nat, X, Xs)."
      , ""
      , "% type constructors" ]
    tyDecls = [ "tff(" ++ tcNm c ++ "_type, type, " ++ tcNm c ++ ": " ++ kind (M.findWithDefault 0 c (pdTyArity pd)) ++ ")." | c <- usedTycons ] ++ ["", "% symbols"]
    kind 0 = "$tType"
    kind 1 = "$tType > $tType"
    kind n = "(" ++ intercalate " * " (replicate n "$tType") ++ ") > $tType"
    symDecls = [ "tff(" ++ nm s ++ "_decl, type, " ++ nm s ++ ": " ++ sigText sg ++ ")." | (s, sg) <- sigs ] ++ [""]
    sigText (vs, as, r) =
      let tvm = M.fromList (zip vs (tyVarNames S.empty (length vs)))
          ty = showTy tvm
          body = case as of
            [] -> ty r
            [a] -> ty a ++ " > " ++ ty r
            _ -> "(" ++ intercalate " * " (map ty as) ++ ") > " ++ ty r
      in if null vs then body else "!>[" ++ intercalate ", " [ tvm M.! v ++ ": $tType" | v <- vs ] ++ "]: " ++ body
    showTy tvm (TVar v) = M.findWithDefault "TUnknown" v tvm
    showTy tvm (TCon c []) = let _ = tvm in tcNm c
    showTy tvm (TCon c ts) = tcNm c ++ "(" ++ intercalate ", " (map (showTy tvm) ts) ++ ")"
    (axioms, labels) = labelled S.empty eqs
    labelled used [] = ([], used)
    labelled used (e : rest) =
      let base = case teLhs e of
            TTF SApp _ (TTF s _ _ : _) -> "app_" ++ nm s
            TTF s _ _ -> nm s
            _ -> "eq"
          label = head [ c | i <- [1 :: Int ..], let c = base ++ "_" ++ show i, not (S.member c used) ]
          vs = nubOrd (ttermVars (teLhs e) ++ ttermVars (teRhs e))
          vm = varNames (map fst vs)
          tvs = nubS (concatMap ftv (concat [ inst | (_, inst) <- ttermSyms (teLhs e) ++ ttermSyms (teRhs e) ] ++ map snd vs))
          tvm = M.fromList (zip tvs (tyVarNames (S.fromList (M.elems vm)) (length tvs)))
          binders = [ n ++ ": $tType" | n <- map (tvm M.!) tvs ] ++ [ vm M.! v ++ ": " ++ showTy tvm t | (v, t) <- vs ]
          quant = if null binders then "" else "![" ++ intercalate ", " binders ++ "]: "
          line = "tff(" ++ label ++ ", axiom, " ++ quant ++ showT tvm vm (teLhs e) ++ " = " ++ showT tvm vm (teRhs e) ++ ")."
          (ls, used') = labelled (S.insert label used) rest
      in (line : ls, used')
    showT _ vm (TTV v _) = M.findWithDefault "V" v vm
    showT tvm vm (TTF s inst ts) =
      let args = map (showTy tvm) inst ++ map (showT tvm vm) ts
      in nm s ++ (if null args then "" else "(" ++ intercalate ", " args ++ ")")
    vars = [ ("X" ++ show i, t) | (i, t) <- zip [1 :: Int ..] argSorts ]
    call = if null vars then nm (SFun (psKey p)) else nm (SFun (psKey p)) ++ "(" ++ intercalate ", " (map fst vars) ++ ")"
    plabel = head [ l | l <- sanitize (psName p) : [ sanitize (psName p) ++ "_conjecture" ++ show i | i <- [1 :: Int ..] ], not (S.member l labels) ]
    conj
      | null vars = "tff(" ++ plabel ++ ", conjecture, " ++ call ++ " = " ++ nm (SCon "False") ++ ")."
      | otherwise = "tff(" ++ plabel ++ ", conjecture, ?[" ++ intercalate ", " [ v ++ ": " ++ showTy M.empty t | (v, t) <- vars ] ++ "]: " ++ call ++ " = " ++ nm (SCon "False") ++ ")."
    nubOrd = go S.empty
      where
        go _ [] = []
        go seen ((v, t) : xs)
          | S.member v seen = go seen xs
          | otherwise = (v, t) : go (S.insert v seen) xs
    nubS = go S.empty
      where
        go _ [] = []
        go seen (x : xs)
          | S.member x seen = go seen xs
          | otherwise = x : go (S.insert x seen) xs
    groupOwners es = concatMap snd (sortOn fst (M.elems (M.fromListWith (\(_, new) (i, old) -> (i, old ++ new)) [ (teOwner e, (i, [e])) | (i, e) <- zip [0 :: Int ..] es ])))

-- | n type variable names (TA, TB, ..., TA1, ...) avoiding the given names.
tyVarNames :: S.Set String -> Int -> [String]
tyVarNames avoid n = take n [ c | c <- cands, not (S.member c avoid) ]
  where
    letters = [ [l] | l <- ['A' .. 'Z'] ]
    cands = [ "T" ++ l | l <- letters ] ++ [ "T" ++ l ++ show i | i <- [1 :: Int ..], l <- letters ]

-- | One typed (TFF) problem for a property.
renderTyped :: FilePath -> Translation -> TypedData -> PropSpec -> String
renderTyped src tr td p = unlines (header ++ sortDecls ++ symDecls ++ axioms ++ ["", conj])
  where
    reached = reachableSyms (trEqns tr) [SFun (psKey p)]
    progEqs = [ e | e <- tdEqs td, S.member (teOwner e) reached ]
    eqs = groupTyped progEqs ++ M.findWithDefault [] (psKey p) (tdBuilders td)
    nm k = M.findWithDefault ("unknown_" ++ sanitize (show k)) (Right k) (tdNames td)
    sortNm t = M.findWithDefault (sortName t) (Left t) (tdNames td)
    propKey = (SFun (psKey p), [])
    falseKey = (SCon "False", [])
    keys = S.toList (S.fromList (propKey : falseKey : concat [ ttermSyms l ++ ttermSyms r | TEq _ l r <- eqs ]))
    sigs = [ (k, s) | k <- keys, Just s <- [tdSig td k] ]
    sorts = S.toList (S.fromList (concat [ r : as | (_, (as, r)) <- sigs ] ++ [ t | TEq _ l r <- eqs, (_, t) <- ttermVars l ++ ttermVars r ]))
    header =
      [ "% Generated by hs2fol (typed, TFF) from " ++ src
      , "% Property: " ++ psName p ++ " :: " ++ prettyType (psType p)
      , "% A proof of the conjecture is a counterexample; the answer substitution gives the arguments."
      , ""
      , "% sorts" ]
    sortDecls = [ "tff(" ++ sortNm t ++ "_type, type, " ++ sortNm t ++ ": $tType)." | t <- sorts ] ++ ["", "% symbols"]
    symDecls = [ "tff(" ++ nm k ++ "_decl, type, " ++ nm k ++ ": " ++ sigText s ++ ")." | (k, s) <- sigs ] ++ [""]
    sigText ([], r) = sortNm r
    sigText ([a], r) = sortNm a ++ " > " ++ sortNm r
    sigText (as, r) = "(" ++ intercalate " * " (map sortNm as) ++ ") > " ++ sortNm r
    (axioms, labels) = labelled S.empty eqs
    labelled used [] = ([], used)
    labelled used (e : rest) =
      let base = case teLhs e of
            TTF SApp _ (TTF s inst _ : _) -> "app_" ++ nm (s, inst)
            TTF s inst _ -> nm (s, inst)
            _ -> "eq"
          label = head [ c | i <- [1 :: Int ..], let c = base ++ "_" ++ show i, not (S.member c used) ]
          vs = nubOrd (ttermVars (teLhs e) ++ ttermVars (teRhs e))
          vm = varNames (map fst vs)
          quant = if null vs then "" else "![" ++ intercalate ", " [ vm M.! v ++ ": " ++ sortNm t | (v, t) <- vs ] ++ "]: "
          line = "tff(" ++ label ++ ", axiom, " ++ quant ++ showT vm (teLhs e) ++ " = " ++ showT vm (teRhs e) ++ ")."
          (ls, used') = labelled (S.insert label used) rest
      in (line : ls, used')
    showT vm (TTV v _) = M.findWithDefault "V" v vm
    showT vm (TTF s inst ts) = nm (s, inst) ++ (if null ts then "" else "(" ++ intercalate ", " (map (showT vm) ts) ++ ")")
    argSorts = take (psArity p) (fst (funArgs (psType p)))
    vars = [ ("X" ++ show i, t) | (i, t) <- zip [1 :: Int ..] argSorts ]
    call = if null vars then nm propKey else nm propKey ++ "(" ++ intercalate ", " (map fst vars) ++ ")"
    plabel = head [ l | l <- sanitize (psName p) : [ sanitize (psName p) ++ "_conjecture" ++ show i | i <- [1 :: Int ..] ], not (S.member l labels) ]
    conj
      | null vars = "tff(" ++ plabel ++ ", conjecture, " ++ call ++ " = " ++ nm falseKey ++ ")."
      | otherwise = "tff(" ++ plabel ++ ", conjecture, ?[" ++ intercalate ", " [ v ++ ": " ++ sortNm t | (v, t) <- vars ] ++ "]: " ++ call ++ " = " ++ nm falseKey ++ ")."
    nubOrd = go S.empty
      where
        go _ [] = []
        go seen ((v, t) : xs)
          | S.member v seen = go seen xs
          | otherwise = (v, t) : go (S.insert v seen) xs
    groupTyped es = concatMap snd (sortOn fst (M.elems (M.fromListWith (\(_, new) (i, old) -> (i, old ++ new)) [ (teOwner e, (i, [e])) | (i, e) <- zip [0 :: Int ..] es ])))

-- | One untyped (FOF) problem for a property.
renderUntyped :: FilePath -> Translation -> PropSpec -> String
renderUntyped src tr p = unlines (header ++ body ++ ["", conj])
  where
    names = trNames tr
    funs = trFuns tr
    roots = SFun (psKey p) : psBuilders p
    eqs = groupByOwner (sliceEquations (trEqns tr) roots)
    header =
      [ "% Generated by hs2fol from " ++ src
      , "% Property: " ++ psName p ++ " :: " ++ prettyType (psType p)
      , "% A proof of the conjecture is a counterexample; the answer substitution gives the arguments."
      ]
    (body, labels) = formatEquations names info eqs
    vars = [ "X" ++ show i | i <- [1 .. psArity p] ]
    pname = M.findWithDefault (sanitize (psName p)) (SFun (psKey p)) names
    false = M.findWithDefault "false" (SCon "False") names
    call = if null vars then pname else pname ++ "(" ++ commaSep vars ++ ")"
    label = head [ l | l <- sanitize (psName p) : [ sanitize (psName p) ++ "_conjecture" ++ suffix i | i <- [0 :: Int ..] ]
                     , not (S.member l labels) ]
    suffix 0 = ""
    suffix i = show i
    conj
      | null vars = "fof(" ++ label ++ ", conjecture, " ++ call ++ " = " ++ false ++ ")."
      | otherwise = "fof(" ++ label ++ ", conjecture, ?[" ++ commaSep vars ++ "]: " ++ call ++ " = " ++ false ++ ")."
    commaSep = foldr1 (\a b -> a ++ ", " ++ b)
    info s =
      let nm = M.findWithDefault "sym" s names
      in case s of
           SFun k -> (nm, Just (describe k nm))
           SClo (ToFun k) j -> ("app_" ++ nm, Just (closureComment k j nm))
           SClo (ToCon c) j -> ("app_" ++ nm, Just (nm ++ ": " ++ conDisplay c ++ " applied to " ++ show j ++ " argument(s)"))
           SFnConst -> ("app_" ++ nm, Just "function builders (for function-valued counterexamples)")
           SFnId -> ("app_" ++ nm, Nothing)
           SFnCase _ -> ("app_" ++ nm, Nothing)
           _ -> (nm, Nothing)
    describe k nm = case M.lookup k funs of
      Just fi -> case fiKind fi of
        KAux -> nm ++ ": auxiliary function for a case/if/guard"
        KLocal -> nm ++ ": local definition " ++ fiHask fi
        KLambda _ _ _ -> nm ++ ": body of a lambda"
        _ -> let d = funDisplay funs k in if d == nm then nm else nm ++ ": " ++ d
      Nothing -> nm
    closureComment k j nm = case M.lookup k funs of
      Just (FunInfo _ _ _ (KLambda nfv _ _)) | j == nfv -> nm ++ ": lambda closure"
      _ -> nm ++ ": " ++ funDisplay funs k ++ " applied to " ++ show j ++ " argument(s)"

-- | Keep equations of the same owner together (in order of first appearance).
groupByOwner :: [Equation] -> [Equation]
groupByOwner eqs = concatMap snd (sortOn fst (M.elems groups))
  where
    groups = M.fromListWith (\(_, new) (i, old) -> (i, old ++ new)) [ (eqOwner e, (i, [e])) | (i, e) <- zip [0 :: Int ..] eqs ]
