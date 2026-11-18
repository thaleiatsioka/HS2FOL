-- | Hindley-Milner type inference. Annotates every occurrence of a global
-- identifier with its type and computes, for every top-level binding, which
-- of its quantified type variables decide the resolution of overloading
-- ("relevant" variables).
module TypeCheck (typecheck, TcResult (..)) where

import Control.Monad
import Control.Monad.Except
import Control.Monad.State
import Data.Graph (flattenSCC, stronglyConnComp)
import qualified Data.Map as M
import Data.Maybe (fromMaybe, isNothing)
import qualified Data.Set as S
import Syntax

data TcResult = TcResult
  { tcSchemes :: M.Map String Scheme -- ^ bindings (and methods)
  , tcBodies :: M.Map String CExpr -- ^ annotated bodies
  , tcRel :: M.Map String [String] -- ^ relevant type variables
  }

data TcState = TcState { tsSubst :: M.Map String Type, tsCount :: !Int }

type TC a = StateT TcState (Either String) a

data TcEnv = TcEnv
  { teGlobals :: M.Map String Scheme
  , teCons :: M.Map Ident Scheme
  , teLocals :: M.Map Name Scheme
  , teOverloaded :: String -> Bool
  }

isMeta :: String -> Bool
isMeta ('?' : _) = True
isMeta _ = False

newMeta :: TC Type
newMeta = do
  s <- get
  put s { tsCount = tsCount s + 1 }
  return (TVar ('?' : show (tsCount s)))

newRigid :: TC String
newRigid = do
  s <- get
  put s { tsCount = tsCount s + 1 }
  return ('t' : show (tsCount s) ++ "'")

applyS :: M.Map String Type -> Type -> Type
applyS s t@(TVar v) = case M.lookup v s of
  Just t' -> applyS s t'
  Nothing -> t
applyS s (TCon c ts) = TCon c (map (applyS s) ts)

zonk :: Type -> TC Type
zonk t = do
  s <- gets tsSubst
  return (applyS s t)

unify :: Type -> Type -> TC ()
unify a b = do
  a' <- zonk a
  b' <- zonk b
  case (a', b') of
    (TVar x, TVar y) | x == y -> return ()
    (TVar x, t) | isMeta x -> bindMeta x t
    (t, TVar x) | isMeta x -> bindMeta x t
    (TCon c ts, TCon d us)
      | c == d && length ts == length us -> zipWithM_ unify ts us
    _ -> throwError ("type mismatch: " ++ prettyType a' ++ " vs. " ++ prettyType b')

bindMeta :: String -> Type -> TC ()
bindMeta x t
  | x `elem` ftv t = throwError ("infinite type " ++ prettyType t)
  | otherwise = modify (\s -> s { tsSubst = M.insert x t (tsSubst s) })

instantiate :: Scheme -> TC Type
instantiate (Forall vs t) = do
  ms <- mapM (const newMeta) vs
  return (substType (M.fromList (zip vs ms)) t)

addLocals :: [(Name, Scheme)] -> TcEnv -> TcEnv
addLocals xs env = env { teLocals = M.union (M.fromList xs) (teLocals env) }

infer :: TcEnv -> CExpr -> TC (CExpr, Type)
infer env expr = case expr of
  CVar n _
    | isGlobal n -> case M.lookup (nameBase n) (teGlobals env) of
        Just sc -> do
          t <- instantiate sc
          return (CVar n (Just t), t)
        Nothing -> throwError ("unknown identifier " ++ nameBase n)
    | otherwise -> case M.lookup n (teLocals env) of
        Just sc -> do
          t <- instantiate sc
          return (CVar n Nothing, t)
        Nothing -> throwError ("internal: unbound variable " ++ nameBase n)
  CCon c -> case M.lookup c (teCons env) of
    Just sc -> do
      t <- instantiate sc
      return (expr, t)
    Nothing -> throwError ("unknown constructor " ++ c)
  CLit _ -> return (expr, tInt)
  CApp f a -> do
    (f', tf) <- infer env f
    (a', ta) <- infer env a
    r <- newMeta
    unify tf (tFun ta r)
    return (CApp f' a', r)
  CLam x b -> do
    t <- newMeta
    (b', tb) <- infer (addLocals [(x, Forall [] t)] env) b
    return (CLam x b', tFun t tb)
  CLet bs b -> do
    (groups, env') <- inferLet env bs
    (b', tb) <- infer env' b
    return (foldr CLet b' groups, tb)
  CCase s alts -> do
    (s', ts) <- infer env s
    r <- newMeta
    alts' <- forM alts $ \(CAlt c xs rhs) -> do
      sc <- maybe (throwError ("unknown constructor " ++ c)) return (M.lookup c (teCons env))
      ct <- instantiate sc
      (fields, res) <- maybe (throwError ("wrong number of fields for " ++ c)) return (splitArgs (length xs) ct)
      unify ts res
      (rhs', tr) <- infer (addLocals (zip xs (map (Forall []) fields)) env) rhs
      unify r tr
      return (CAlt c xs rhs')
    return (CCase s' alts', r)
  CFail -> do
    t <- newMeta
    return (CFail, t)
  CFallthrough -> do
    t <- newMeta
    return (CFail, t)
  CTyped e t -> do
    (e', te) <- infer env e
    t' <- instantiate (Forall (ftv t) t)
    unify te t'
    return (e', te)

inferLet :: TcEnv -> [(Name, CExpr)] -> TC ([[(Name, CExpr)]], TcEnv)
inferLet env0 bs = foldM step ([], env0) sccs
  where
    names = S.fromList (map fst bs)
    sccs = stronglyConnComp [ (b, fst b, S.toList (S.intersection names (freeVars (snd b)))) | b <- bs ]
    step (acc, env) scc = do
      let grp = flattenSCC scc
      ms <- mapM (const newMeta) grp
      let envM = addLocals [ (n, Forall [] m) | ((n, _), m) <- zip grp ms ] env
      rs <- forM (zip grp ms) $ \((n, e), m) -> do
        (e', te) <- infer envM e
        unify m te
        return (n, e')
      let canGen = not (any (mentionsOverloaded env . snd) rs)
      scs <- if canGen then mapM (generalizeLocal env) ms else return (map (Forall []) ms)
      return (acc ++ [rs], addLocals (zip (map fst grp) scs) env)
    mentionsOverloaded env e = any (teOverloaded env . fst) (globalOccs e)

generalizeLocal :: TcEnv -> Type -> TC Scheme
generalizeLocal env t = do
  t' <- zonk t
  envTys <- mapM (zonk . schemeType) (M.elems (teLocals env))
  let envVars = S.fromList (concatMap ftv envTys)
      gvs = [ v | v <- ftv t', isMeta v, not (S.member v envVars) ]
  rs <- mapM (const newRigid) gvs
  forM_ (zip gvs rs) $ \(v, r) -> bindMeta v (TVar r)
  t'' <- zonk t'
  return (Forall rs t'')

zonkExpr :: M.Map String Type -> CExpr -> CExpr
zonkExpr s e = case e of
  CVar n (Just t) -> CVar n (Just (applyS s t))
  CApp f a -> CApp (zonkExpr s f) (zonkExpr s a)
  CLam x b -> CLam x (zonkExpr s b)
  CLet bs b -> CLet [ (n, zonkExpr s r) | (n, r) <- bs ] (zonkExpr s b)
  CCase sc alts -> CCase (zonkExpr s sc) [ CAlt c xs (zonkExpr s r) | CAlt c xs r <- alts ]
  _ -> e

--------------------------------------------------------------------------------
-- Top level

typecheck :: Program -> Either String TcResult
typecheck prog = evalStateT run (TcState M.empty 0)
  where
    binds = [ b | b <- progBinds prog, Just _ <- [bindBody b] ]
    sigSchemes = M.fromList [ (bindKey b, s) | b <- progBinds prog, Just s <- [bindSig b] ]
    methodSchemes = M.map methodScheme (progMethods prog)
    conSchemes = M.map conScheme (progCons prog)
    keys = S.fromList (map bindKey binds)
    sccs = stronglyConnComp
      [ (b, bindKey b, [ k | (k, _) <- globalOccs body, S.member k keys ])
      | b <- binds, let body = fromMaybe CFail (bindBody b) ]

    run = do
      (schemes, bodies, rel) <-
        foldM tcGroup (M.union methodSchemes sigSchemes, M.empty, M.empty) (map flattenSCC sccs)
      return (TcResult schemes bodies rel)

    tcGroup (schemes, bodies, rel) grp = do
      let noSig = [ b | b <- grp, isNothing (bindSig b) ]
      ms <- mapM (const newMeta) noSig
      let monoS = M.fromList [ (bindKey b, Forall [] m) | (b, m) <- zip noSig ms ]
          grpKeys = S.fromList (map bindKey grp)
          isOver k = M.member k (progMethods prog) || not (null (M.findWithDefault [] k rel)) || S.member k grpKeys
          env = TcEnv (M.union monoS schemes) conSchemes M.empty isOver
      typed <- forM grp $ \b -> do
        let body = fromMaybe CFail (bindBody b)
            ctx :: TC x -> TC x
            ctx m = catchError m (\e -> throwError ("in " ++ bindHask b ++ ": " ++ e))
        (body', t) <- ctx (infer env body)
        ctx $ case bindSig b of
          Just (Forall _ st) -> unify t st
          Nothing -> unify t (schemeType (monoS M.! bindKey b))
        return (b, body')
      newSchemes <- forM noSig $ \b -> do
        t <- zonk (schemeType (monoS M.! bindKey b))
        let gvs = [ v | v <- ftv t, isMeta v ]
        rs <- mapM (const newRigid) gvs
        forM_ (zip gvs rs) $ \(v, r) -> bindMeta v (TVar r)
        t' <- zonk t
        return (bindKey b, Forall rs t')
      s <- gets tsSubst
      let schemes' = M.union (M.fromList newSchemes) schemes
          zbodies = M.fromList [ (bindKey b, zonkExpr s body') | (b, body') <- typed ]
          rel' = computeRel prog schemes' rel (map bindKey grp) zbodies
      return (schemes', M.union zbodies bodies, rel')

-- | Relevant type variables of the bindings of one group (fixpoint).
computeRel :: Program -> M.Map String Scheme -> M.Map String [String] -> [String] -> M.Map String CExpr -> M.Map String [String]
computeRel prog schemes rel0 grp bodies = fixp (M.union (M.fromList [ (k, []) | k <- grp ]) rel0)
  where
    fixp rel =
      let rel' = M.union (M.fromList [ (k, relOf rel k) | k <- grp ]) rel
      in if all (\k -> M.lookup k rel' == M.lookup k rel) grp then rel else fixp rel'
    relOf rel k =
      let vs = case M.lookup k schemes of
            Just (Forall qs _) -> qs
            Nothing -> []
          found = S.fromList (concatMap (occRel rel) [ (g, t) | (g, Just t) <- globalOccs (M.findWithDefault CFail k bodies) ])
      in [ v | v <- vs, S.member v found ]
    occRel rel (g, t) = case M.lookup g (progMethods prog) of
      Just mi -> case matchType (schemeType (methodScheme mi)) t of
        Just s -> maybe [] ftv (M.lookup (methodVar mi) s)
        Nothing -> []
      Nothing -> case M.findWithDefault [] g rel of
        [] -> []
        rs -> case M.lookup g schemes >>= \sc -> matchType (schemeType sc) t of
          Just s -> concat [ maybe [] ftv (M.lookup r s) | r <- rs ]
          Nothing -> []
