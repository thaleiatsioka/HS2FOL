-- | The whole translation pipeline, properties, function builders, naming
-- and rendering of TPTP problems.
module Translate
  ( Translation (..)
  , PropSpec (..)
  , translateProgram
  , renderProblem
  , funDisplay
  ) where

import Data.List (isPrefixOf, sortOn)
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

data PropSpec = PropSpec
  { psName :: Ident
  , psKey :: String
  , psArity :: Int
  , psType :: Type
  , psBuilders :: [Sym]
  }

data Translation = Translation
  { trEqns :: [Equation]
  , trNames :: NameMap
  , trProps :: [PropSpec]
  , trFuns :: M.Map String FunInfo
  , trCons :: M.Map Ident ConInfo
  , trWarnings :: [String]
  }

translateProgram :: [Decl] -> [Decl] -> Either String Translation
translateProgram pre usr = do
  (prog, warns) <- desugarProgram pre usr
  tc <- typecheck prog
  sbs <- specialise prog tc
  let undefKey = if any ((== "Prelude.undefined") . bindKey) (progBinds prog) then "Prelude.undefined" else "undefined"
  (funs, eqs) <- liftProgram (progFresh prog) prog undefKey sbs
  let candidates = [ b | b <- progBinds prog, bindKind b == BUser, "prop" `isPrefixOf` bindHask b, isJust (bindBody b) ]
      checked = map (checkProp tc funs) candidates
      props = [ p | Right p <- checked ]
      propWarnings = [ w | Left w <- checked ]
      datas = progDatas prog
      withBuilders = [ p { psBuilders = propBuilders datas (argTypes p) } | p <- props ]
      builderTypes = S.toList (S.fromList [ t | p <- withBuilders, SFnCase t <- psBuilders p ])
      allEqs = eqs ++ (if any (not . null . psBuilders) withBuilders then builderEqns datas builderTypes else [])
      syms = concatMap (\e -> termSyms (eqLhs e) ++ termSyms (eqRhs e)) allEqs
          ++ [ SFun (psKey p) | p <- withBuilders ] ++ concatMap psBuilders withBuilders
          ++ [SCon "False", SCon "True"]
      names = assignNames [ let (pr, b) = symBase funs s in (s, pr, b) | s <- syms ]
  return Translation
    { trEqns = allEqs
    , trNames = names
    , trProps = withBuilders
    , trFuns = funs
    , trCons = progCons prog
    , trWarnings = warns ++ propWarnings
    }
  where
    argTypes p = take (psArity p) (fst (funArgs (psType p)))

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
renderProblem src tr p = unlines (header ++ body ++ ["", conj])
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
