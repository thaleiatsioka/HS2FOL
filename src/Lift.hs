-- | From monomorphic core bindings to first-order equations: simplification,
-- eta-expansion, lambda lifting, flattening of pattern matching into
-- non-overlapping clauses, and closures for partial application.
module Lift
  ( liftProgram
  , FunInfo (..)
  , FunKind (..)
  , simplifyFix
  ) where

import Control.Monad
import Control.Monad.Except
import Control.Monad.State
import Data.Graph (SCC (..), flattenSCC, stronglyConnComp)
import qualified Data.Map as M
import qualified Data.Set as S
import FOL
import Names (sanitize)
import Specialise
import Syntax

data FunKind
  = KUser
  | KPrelude
  | KSpec
  | KAbstract
  | KLambda Int [Name] CExpr -- ^ number of free variables, free variables, original lambda
  | KLocal
  | KAux

data FunInfo = FunInfo
  { fiArity :: Int
  , fiFol :: String -- ^ desired FOL name
  , fiHask :: String -- ^ Haskell name
  , fiKind :: FunKind
  }

data LState = LState
  { lsCount :: !Int
  , lsLam :: !Int
  , lsAux :: M.Map String Int
  , lsFuns :: M.Map String FunInfo
  , lsPending :: [(String, [Name], CExpr)]
  , lsEqns :: [Equation] -- ^ reversed
  , lsClosures :: S.Set (Callee, Int)
  , lsCons :: M.Map Ident ConInfo
  , lsUndefined :: String
  }

type LM a = StateT LState (Either String) a

-- | Translate all bindings. Returns the function table and the equations.
liftProgram :: Int -> Program -> String -> [SBind] -> Either String (M.Map String FunInfo, [Equation])
liftProgram cnt prog undefKey sbs = evalStateT run st0
  where
    st0 = LState cnt 0 M.empty M.empty [] [] S.empty (progCons prog) undefKey
    run = do
      prepared <- forM sbs $ \sb -> case sbBody sb of
        Nothing -> do
          register (sbKey sb) (FunInfo (sbArity sb) (sbFol sb) (sbHask sb) KAbstract)
          return Nothing
        Just body -> do
          b1 <- freshen M.empty body
          let (ps, inner) = collectLams (simplifyFix b1)
              ar = max (length ps) (sbArity sb)
          extra <- forM [length ps + 1 .. ar] $ \i -> newName ("x" ++ show i)
          inner' <- freshen M.empty (simplifyFix (cApps inner (map lvar extra)))
          register (sbKey sb) (FunInfo ar (sbFol sb) (sbHask sb) (kindOf sb))
          return (Just (sbKey sb, sbFol sb, ps ++ extra, inner'))
      forM_ [ p | Just p <- prepared ] $ \(k, fol, ps, body) -> do
        body' <- liftE (LEnv k fol M.empty) body
        addPending k ps body'
      pend <- gets lsPending
      forM_ (reverse pend) $ \(k, ps, b) -> flattenFun k ps b
      closureRules
      inlineLambdas
      funs <- gets lsFuns
      eqs <- gets lsEqns
      return (funs, reverse eqs)
    kindOf sb = case sbKind sb of
      SKUser -> KUser
      SKPrelude -> KPrelude
      SKSpec -> KSpec

--------------------------------------------------------------------------------
-- State helpers

newName :: String -> LM Name
newName base = do
  s <- get
  put s { lsCount = lsCount s + 1 }
  return (Name base (lsCount s))

register :: String -> FunInfo -> LM ()
register k fi = modify (\s -> s { lsFuns = M.insert k fi (lsFuns s) })

addPending :: String -> [Name] -> CExpr -> LM ()
addPending k ps b = modify (\s -> s { lsPending = (k, ps, b) : lsPending s })

emitEq :: Equation -> LM ()
emitEq e = modify (\s -> s { lsEqns = e : lsEqns s })

lookupFun :: String -> LM FunInfo
lookupFun k = do
  fs <- gets lsFuns
  maybe (throwError ("internal: unknown function " ++ k)) return (M.lookup k fs)

-- | Rename every binder to a fresh name.
freshen :: M.Map Name Name -> CExpr -> LM CExpr
freshen m e = case e of
  CVar n t
    | isGlobal n -> return e
    | otherwise -> return (CVar (M.findWithDefault n n m) t)
  CLam x b -> do
    x' <- newName (nameBase x)
    CLam x' <$> freshen (M.insert x x' m) b
  CLet bs b -> do
    ns' <- mapM (newName . nameBase . fst) bs
    let m' = M.union (M.fromList (zip (map fst bs) ns')) m
    rs <- mapM (freshen m' . snd) bs
    b' <- freshen m' b
    return (CLet (zip ns' rs) b')
  CCase s alts -> do
    s' <- freshen m s
    alts' <- forM alts $ \(CAlt c xs r) -> do
      xs' <- mapM (newName . nameBase) xs
      CAlt c xs' <$> freshen (M.union (M.fromList (zip xs xs')) m) r
    return (CCase s' alts')
  CApp f a -> CApp <$> freshen m f <*> freshen m a
  CTyped x t -> (\x' -> CTyped x' t) <$> freshen m x
  _ -> return e

--------------------------------------------------------------------------------
-- Simplifier: beta reduction (via let), let-substitution of atoms,
-- application pushed into case/let, case of known constructor.

simplifyFix :: CExpr -> CExpr
simplifyFix = go (20 :: Int)
  where
    go 0 e = e
    go n e = let e' = simplify e in if e' == e then e else go (n - 1) e'

simplify :: CExpr -> CExpr
simplify e = case e of
  CApp f a -> simpApp (simplify f) (simplify a)
  CLam x b -> CLam x (simplify b)
  CLet bs b -> simpLet [ (n, simplify r) | (n, r) <- bs ] (simplify b)
  CCase s alts -> simpCase (simplify s) [ CAlt c xs (simplify r) | CAlt c xs r <- alts ]
  CTyped x _ -> simplify x
  _ -> e

simpApp :: CExpr -> CExpr -> CExpr
simpApp f a = case f of
  CLam x b -> simpLet [(x, a)] b
  CLet bs b -> CLet bs (simpApp b a)
  CCase s alts -> CCase s [ CAlt c xs (simpApp r a) | CAlt c xs r <- alts ]
  CFail -> CFail
  _ -> CApp f a

isAtom :: CExpr -> Bool
isAtom e = case e of
  CVar _ _ -> True
  CCon _ -> True
  CLit _ -> True
  _ -> False

simpLet :: [(Name, CExpr)] -> CExpr -> CExpr
simpLet [] b = b
simpLet bs b =
  case break substitutable bs of
    (pre, (x, r) : post) ->
      let s = M.singleton x r
      in simpLet [ (n, substE s r') | (n, r') <- pre ++ post ] (substE s b)
    _ -> CLet bs b
  where
    substitutable (x, r) = isAtom r && not (S.member x (freeVars r))

simpCase :: CExpr -> [CAlt] -> CExpr
simpCase s alts = case collectApps s of
  (CCon c, args) -> case [ (xs, r) | CAlt c' xs r <- alts, c' == c ] of
    ((xs, r) : _) | length xs == length args -> simpLet (zip xs args) r
    _ -> CFail
  _ -> case s of
    CLet bs b -> CLet bs (simpCase b alts)
    CFail -> CFail
    _ -> CCase s alts

--------------------------------------------------------------------------------
-- Lambda lifting

data LEnv = LEnv
  { leParent :: String
  , leParentFol :: String
  , leFuns :: M.Map Name (String, [Name]) -- ^ lifted local function -> (key, free variables)
  }

freeVarsMapped :: LEnv -> CExpr -> S.Set Name
freeVarsMapped env e =
  S.unions [ maybe (S.singleton x) (S.fromList . snd) (M.lookup x (leFuns env)) | x <- S.toList (freeVars e) ]

liftE :: LEnv -> CExpr -> LM CExpr
liftE env e = case e of
  CVar n _
    | not (isGlobal n), Just (k, fvs) <- M.lookup n (leFuns env) -> return (cApps (gvar k) (map lvar fvs))
    | otherwise -> return e
  CApp f a -> CApp <$> liftE env f <*> liftE env a
  CCase s alts -> CCase <$> liftE env s <*> mapM (\(CAlt c xs r) -> CAlt c xs <$> liftE env r) alts
  CTyped x _ -> liftE env x
  CLam _ _ -> liftLambda env e
  CLet bs b -> liftLet env bs b
  _ -> return e

liftLambda :: LEnv -> CExpr -> LM CExpr
liftLambda env e = do
  let (xs, body) = collectLams e
  case etaReduce xs body of
    Just e' -> liftE env e'
    Nothing -> do
      let fvs = S.toList (freeVarsMapped env e)
      n <- gets lsLam
      modify (\s -> s { lsLam = n + 1 })
      let key = "lam#" ++ show (n + 1)
          fol = "lam" ++ show (n + 1)
      register key (FunInfo (length fvs + length xs) fol fol (KLambda (length fvs) fvs e))
      body' <- liftE env body
      addPending key (fvs ++ xs) body'
      return (cApps (gvar key) (map lvar fvs))

-- | \x1..xn -> h a1..am x1..xn  ==>  h a1..am
etaReduce :: [Name] -> CExpr -> Maybe CExpr
etaReduce xs body =
  let (h, args) = collectApps body
      k = length args - length xs
      (pre, post) = splitAt k args
      xset = S.fromList xs
      isVarN (CVar v _) x = v == x
      isVarN _ _ = False
      okHead = case h of
        CVar _ _ -> True
        CCon _ -> True
        _ -> False
  in if k >= 0 && and (zipWith isVarN post xs) && okHead
          && all (\a -> S.null (S.intersection (freeVars a) xset)) (h : pre)
       then Just (cApps h pre)
       else Nothing

liftLet :: LEnv -> [(Name, CExpr)] -> CExpr -> LM CExpr
liftLet env [] body = liftE env body
liftLet env bs body =
  case stronglyConnComp [ (b, fst b, S.toList (S.intersection names (freeVars (snd b)))) | b <- bs ] of
    [] -> liftE env body
    (scc : _) -> do
      let grp = flattenSCC scc
          grpNames = map fst grp
          rest = [ b | b <- bs, fst b `notElem` grpNames ]
      case scc of
        AcyclicSCC (x, r)
          | not (isLam r) && (cheap r || occurrences x rest body <= 1) -> do
              let s = M.singleton x r
              liftLet env [ (n, substE s r') | (n, r') <- rest ] (substE s body)
        _ -> do
          let fvs = S.toList (S.difference (S.unions [ freeVarsMapped env r | (_, r) <- grp ]) (S.fromList grpNames))
              keyOf n = leParent env ++ "/" ++ nameBase n ++ "#" ++ show (nameId n)
              env' = env { leFuns = M.union (M.fromList [ (n, (keyOf n, fvs)) | n <- grpNames ]) (leFuns env) }
          forM_ grp $ \(n, r) -> do
            let (ps, rb) = collectLams r
            register (keyOf n) (FunInfo (length fvs + length ps) (leParentFol env ++ "_" ++ sanitize (nameBase n)) (nameBase n) KLocal)
          forM_ grp $ \(n, r) -> do
            let (ps, rb) = collectLams r
            rb' <- liftE env' rb
            addPending (keyOf n) (fvs ++ ps) rb'
          liftLet env' rest body
  where
    names = S.fromList (map fst bs)
    isLam (CLam _ _) = True
    isLam _ = False

cheap :: CExpr -> Bool
cheap e = case e of
  CVar _ _ -> True
  CCon _ -> True
  CLit _ -> True
  CApp f a -> cheap f && cheap a
  _ -> False

occurrences :: Name -> [(Name, CExpr)] -> CExpr -> Int
occurrences x bs body = sum (map (count . snd) bs) + count body
  where
    count e = case e of
      CVar n _ -> if n == x then 1 else 0
      CApp f a -> count f + count a
      CLam _ b -> count b
      CLet bs' b -> sum (map (count . snd) bs') + count b
      CCase s alts -> count s + sum [ count r | CAlt _ _ r <- alts ]
      CTyped y _ -> count y
      _ -> 0

--------------------------------------------------------------------------------
-- Flattening into equations

flattenFun :: String -> [Name] -> CExpr -> LM ()
flattenFun key params body0 = go (map TV params) M.empty body0
  where
    go :: [Term] -> M.Map Name Term -> CExpr -> LM ()
    go lhs sub e = case e of
      CFail -> return ()
      CCase s alts -> case collectApps s of
        (CCon c, args) ->
          case [ (xs, r) | CAlt c' xs r <- alts, c' == c ] of
            ((xs, r) : _) | length xs == length args -> go lhs sub (substE (M.fromList (zip xs args)) r)
            _ -> return ()
        (CVar v _, []) | not (isGlobal v) -> case M.lookup v sub of
          Just (TV y) -> go lhs sub (CCase (lvar y) alts)
          Just t@(TF (SCon _) _) -> known lhs sub t alts
          Just _ -> liftTop lhs sub s alts
          Nothing
            | v `elem` concatMap termVars lhs ->
                forM_ alts $ \(CAlt c xs r) -> do
                  let t = TF (SCon c) (map TV xs)
                      lhs' = map (substTerm v t) lhs
                      sub' = M.insert v t (M.map (substTerm v t) sub)
                  go lhs' sub' r
            | otherwise -> liftTop lhs sub s alts
        _ -> liftTop lhs sub s alts
      _ -> do
        r <- term key sub e
        emitEq (Equation (SFun key) (TF (SFun key) lhs) r)

    known lhs sub t alts = case t of
      TF (SCon c) args -> case [ (xs, r) | CAlt c' xs r <- alts, c' == c ] of
        ((xs, r) : _) | length xs == length args -> go lhs (M.union (M.fromList (zip xs args)) sub) r
        _ -> return ()
      _ -> return ()

    -- case on something that is not a parameter: auxiliary function
    liftTop lhs sub s alts = do
      u <- newName "s"
      let altFvs = S.toList (S.unions [ S.difference (freeVars r) (S.fromList xs) | CAlt _ xs r <- alts ])
      (k, fol) <- auxKey key
      register k (FunInfo (1 + length altFvs) fol fol KAux)
      flattenFun k (u : altFvs) (CCase (lvar u) alts)
      st <- term key sub s
      emitEq (Equation (SFun key) (TF (SFun key) lhs) (TF (SFun k) (st : map (substVar sub) altFvs)))

substVar :: M.Map Name Term -> Name -> Term
substVar sub v = M.findWithDefault (TV v) v sub

auxKey :: String -> LM (String, String)
auxKey owner = do
  m <- gets lsAux
  let i = M.findWithDefault 0 owner m + 1
  modify (\s -> s { lsAux = M.insert owner i (lsAux s) })
  fi <- lookupFun owner
  let base = case fiKind fi of
        KLambda _ _ _ -> fiFol fi ++ "_body"
        _ -> fiFol fi
  return (owner ++ "/case" ++ show i, base ++ "_case" ++ show i)

-- | Translate an expression without top-level case into a term. Nested
-- case expressions become auxiliary functions.
term :: String -> M.Map Name Term -> CExpr -> LM Term
term owner sub e = do
  let (h, args) = collectApps e
  args' <- mapM (term owner sub) args
  case h of
    CVar n _
      | isGlobal n -> do
          fi <- lookupFun (nameBase n)
          applyCallee (ToFun (nameBase n)) (fiArity fi) args'
      | otherwise -> return (appChain (substVar sub n) args')
    CCon c -> do
      cons <- gets lsCons
      case M.lookup c cons of
        Just ci -> applyCallee (ToCon c) (conArity ci) args'
        Nothing -> throwError ("internal: unknown constructor " ++ c)
    CLit n -> return (appChain (TF (SLit n) []) args')
    CFail -> do
      u <- gets lsUndefined
      return (appChain (TF (SFun u) []) args')
    CCase _ _ -> do
      let fvs = S.toList (freeVars h)
      (k, fol) <- auxKey owner
      register k (FunInfo (length fvs) fol fol KAux)
      flattenFun k fvs h
      return (appChain (TF (SFun k) (map (substVar sub) fvs)) args')
    _ -> throwError "internal: unexpected expression after lambda lifting"

applyCallee :: Callee -> Int -> [Term] -> LM Term
applyCallee c ar args
  | n == ar = return (TF (calleeSym c) args)
  | n < ar = do
      modify (\s -> s { lsClosures = S.insert (c, n) (lsClosures s) })
      return (TF (SClo c n) args)
  | otherwise = return (appChain (TF (calleeSym c) (take ar args)) (drop ar args))
  where
    n = length args

--------------------------------------------------------------------------------
-- Closures

arityOfCallee :: Callee -> LM Int
arityOfCallee (ToFun k) = fiArity <$> lookupFun k
arityOfCallee (ToCon c) = do
  cons <- gets lsCons
  return (maybe 0 conArity (M.lookup c cons))

closureRules :: LM ()
closureRules = do
  cl <- gets lsClosures
  levels <- forM (S.toList cl) $ \(c, n) -> do
    ar <- arityOfCallee c
    return [ (c, j, ar) | j <- [n .. ar - 1] ]
  let alls = S.toList (S.fromList (concat levels))
  forM_ alls $ \(c, j, ar) -> do
    let xs = [ TV (Name ("X" ++ show i) (-1)) | i <- [1 .. j] ]
        y = TV (Name "Y" (-1))
        lhs = TF SApp [TF (SClo c j) xs, y]
        rhs = if j + 1 == ar then TF (calleeSym c) (xs ++ [y]) else TF (SClo c (j + 1)) (xs ++ [y])
    emitEq (Equation (SClo c j) lhs rhs)

-- | A lambda whose body is a single equation with only variables on the
-- left is inlined into its closure's app rule.
inlineLambdas :: LM ()
inlineLambdas = do
  eqs <- gets (reverse . lsEqns)
  funs <- gets lsFuns
  let lamKeys = [ k | (k, FunInfo _ _ _ (KLambda _ _ _)) <- M.toList funs ]
      defsOf = M.fromListWith (flip (++)) [ (k, [e]) | e@(Equation (SFun k) _ _) <- eqs ]
      refsOf k = [ eqOwner e | e <- eqs, eqOwner e /= SFun k, SFun k `elem` termSyms (eqRhs e) ]
      isClosureOf k (SClo (ToFun k') _) = k == k'
      isClosureOf _ _ = False
      inlinable k = case M.findWithDefault [] k defsOf of
        [Equation _ (TF _ args) _] -> distinctVars args && all (isClosureOf k) (refsOf k)
        _ -> False
      inl = M.fromList [ (k, head (defsOf M.! k)) | k <- lamKeys, inlinable k ]
      rewrite e = case eqRhs e of
        TF (SFun k) actuals
          | Just (Equation _ (TF _ formals) body) <- M.lookup k inl, isClosureOf k (eqOwner e) ->
              e { eqRhs = substTerms (M.fromList [ (v, a) | (TV v, a) <- zip formals actuals ]) body }
        _ -> e
      isInlinedDef e = case eqOwner e of
        SFun k -> M.member k inl
        _ -> False
  modify (\s -> s { lsEqns = reverse [ rewrite e | e <- eqs, not (isInlinedDef e) ] })
  where
    distinctVars args =
      let vs = [ v | TV v <- args ]
      in length vs == length args && S.size (S.fromList vs) == length vs
