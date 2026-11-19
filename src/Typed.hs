-- | Typed first-order logic (TPTP TFF0): sort inference for the generated
-- equations, typed function builders, and TFF printing.
--
-- After full monomorphisation every program function has a monomorphic
-- type. Constructors, closures of constructors, @app@ and @undefined@ are
-- still polymorphic in the untyped equations; here every occurrence gets
-- the instance it is used at, and each (symbol, instance) pair becomes its
-- own TFF symbol (e.g. @cons_nat@, @app_nat_bool@). Auxiliary functions
-- created by lambda lifting get their (monomorphic) sorts by inference.
module Typed
  ( TTerm (..)
  , TEq (..)
  , TKey
  , typeEquations
  , typedBuilders
  , sortName
  , symSignature
  , ttermSyms
  , ttermVars
  ) where

import Control.Monad
import Control.Monad.Except
import Control.Monad.State
import Data.Char (toLower)
import qualified Data.Map as M
import qualified Data.Set as S
import FOL
import Lift (FunInfo (..))
import Names (sanitize)
import Syntax

-- | A term whose symbol occurrences carry their instance and whose
-- variables carry their sort.
data TTerm = TTV Name Type | TTF Sym [Type] [TTerm]
  deriving (Eq, Show)

data TEq = TEq { teOwner :: Sym, teLhs :: TTerm, teRhs :: TTerm }
  deriving (Show)

-- | A TFF symbol: an untyped symbol at an instance.
type TKey = (Sym, [Type])

ttermSyms :: TTerm -> [TKey]
ttermSyms (TTV _ _) = []
ttermSyms (TTF s inst ts) = (s, inst) : concatMap ttermSyms ts

ttermVars :: TTerm -> [(Name, Type)]
ttermVars (TTV v t) = [(v, t)]
ttermVars (TTF _ _ ts) = concatMap ttermVars ts

-- | Name of a sort: nat, list_nat, fun_nat_bool, bst_nat_nat, ...
sortName :: Type -> String
sortName t = sanitize (go t)
  where
    go (TVar v) = "a_" ++ v
    go (TCon c ts) = base c ++ concatMap (("_" ++) . go) ts
    base c
      | c == "[]" = "list"
      | c == "()" = "unit"
      | c == "->" = "fun"
      | c == "(,)" = "pair"
      | isTupleCon c = "tuple" ++ show (length c - 1)
      | otherwise = map toLower (sanitize c)

--------------------------------------------------------------------------------
-- Signatures

data Env = Env
  { envTypes :: M.Map String Type -- ^ monomorphic types of program functions
  , envFuns :: M.Map String FunInfo
  , envCons :: M.Map Ident ConInfo
  }

data TS = TS
  { tsCount :: !Int
  , tsSubst :: M.Map String Type
  , tsAux :: M.Map String ([Type], Type) -- ^ inferred signatures of lifted functions
  , tsVars :: M.Map Name Type
  }

type TM a = StateT TS (Either String) a

fresh :: TM Type
fresh = do
  s <- get
  put s { tsCount = tsCount s + 1 }
  return (TVar ('?' : show (tsCount s)))

isMeta :: String -> Bool
isMeta ('?' : _) = True
isMeta _ = False

zonk :: M.Map String Type -> Type -> Type
zonk s t@(TVar v) = maybe t (zonk s) (M.lookup v s)
zonk s (TCon c ts) = TCon c (map (zonk s) ts)

unify :: Type -> Type -> TM ()
unify a b = do
  s <- gets tsSubst
  case (zonk s a, zonk s b) of
    (TVar x, TVar y) | x == y -> return ()
    (TVar x, t) | isMeta x -> bind x t
    (t, TVar x) | isMeta x -> bind x t
    (TCon c ts, TCon d us)
      | c == d && length ts == length us -> zipWithM_ unify ts us
    (a', b') -> throwError ("sort mismatch: " ++ prettyType a' ++ " vs. " ++ prettyType b')
  where
    bind x t
      | x `elem` ftv t = throwError ("infinite sort " ++ prettyType t)
      | otherwise = modify (\st -> st { tsSubst = M.insert x t (tsSubst st) })

instantiate :: [String] -> Type -> TM ([Type], Type)
instantiate vs t = do
  ms <- mapM (const fresh) vs
  return (ms, substType (M.fromList (zip vs ms)) t)

-- | Instance, argument sorts and result sort of a symbol occurrence.
sigOf :: Env -> Sym -> TM ([Type], [Type], Type)
sigOf env s = case s of
  SFun k -> do
    ar <- maybe (throwError ("unknown function " ++ k)) (return . fiArity) (M.lookup k (envFuns env))
    case M.lookup k (envTypes env) of
      Just t -> do
        let vs = ftv t
        (inst, t') <- if null vs then return ([], t) else instantiate vs t
        (args, res) <- maybe (throwError ("arity mismatch for " ++ k)) return (splitArgs ar t')
        return (inst, args, res)
      Nothing -> do
        aux <- gets tsAux
        case M.lookup k aux of
          Just (args, res) -> return ([], args, res)
          Nothing -> do
            args <- replicateM ar fresh
            res <- fresh
            modify (\st -> st { tsAux = M.insert k (args, res) (tsAux st) })
            return ([], args, res)
  SCon c -> case M.lookup c (envCons env) of
    Just ci -> do
      let Forall vs t = conScheme ci
      (inst, t') <- instantiate vs t
      (args, res) <- maybe (throwError ("arity mismatch for " ++ c)) return (splitArgs (conArity ci) t')
      return (inst, args, res)
    Nothing -> throwError ("unknown constructor " ++ c)
  SClo callee j -> do
    (inst, args, res) <- sigOf env (calleeSym callee)
    return (inst, take j args, foldr tFun res (drop j args))
  SLit _ -> return ([], [], tInt)
  SApp -> do
    a <- fresh
    b <- fresh
    return ([a, b], [tFun a b, a], b)
  _ -> throwError "internal: builders are typed separately"

inferTerm :: Env -> Term -> TM (TTerm, Type)
inferTerm env t = case t of
  TV v -> do
    vars <- gets tsVars
    ty <- case M.lookup v vars of
      Just ty -> return ty
      Nothing -> do
        m <- fresh
        modify (\st -> st { tsVars = M.insert v m (tsVars st) })
        return m
    return (TTV v ty, ty)
  TF s args -> do
    (inst, argSorts, res) <- sigOf env s
    when (length argSorts /= length args) $
      throwError ("wrong number of arguments for " ++ show s)
    targs <- forM (zip args argSorts) $ \(a, expected) -> do
      (ta, ty) <- inferTerm env a
      unify ty expected
      return ta
    return (TTF s inst targs, res)

-- | Infer sorts for all equations together (lifted functions are shared
-- between equations). Remaining unknown sorts default to unit.
typeEquations :: M.Map String Type -> M.Map String FunInfo -> M.Map Ident ConInfo -> [Equation] -> Either String ([TEq], M.Map String ([Type], Type))
typeEquations types funs cons eqs = evalStateT run (TS 0 M.empty M.empty M.empty)
  where
    env = Env types funs cons
    run = do
      teqs <- forM eqs $ \e -> do
        modify (\st -> st { tsVars = M.empty })
        r <- (do
               (l, lt) <- inferTerm env (eqLhs e)
               (rr, rt) <- inferTerm env (eqRhs e)
               unify lt rt
               return (TEq (eqOwner e) l rr))
             `catchError` (\err -> throwError ("cannot assign sorts in an equation for " ++ show (eqOwner e) ++ ": " ++ err))
        return r
      s <- gets tsSubst
      aux <- gets tsAux
      return (map (finish s) teqs, M.map (\(as, r) -> (map (dflt . zonk s) as, dflt (zonk s r))) aux)
    finish s (TEq o l r) = TEq o (fin s l) (fin s r)
    fin s (TTV v t) = TTV v (dflt (zonk s t))
    fin s (TTF sym inst ts) = TTF sym (map (dflt . zonk s) inst) (map (fin s) ts)
    dflt (TVar _) = TCon "()" []
    dflt (TCon c ts) = TCon c (map dflt ts)

--------------------------------------------------------------------------------
-- Builders

-- | Typed builder equations for the function-typed arguments of a property:
-- fn_const and fn_id for every needed function sort, and fn_case for every
-- function sort whose domain is a data type.
typedBuilders :: M.Map Ident DataInfo -> [Type] -> [TEq]
typedBuilders datas argTypes = go S.empty [ (a, b) | TCon "->" [a, b] <- argTypes ]
  where
    go _ [] = []
    go seen ((a, b) : rest)
      | S.member (a, b) seen = go seen rest
      | otherwise =
          let (eqs, more) = builder a b
          in eqs ++ go (S.insert (a, b) seen) (more ++ rest)
    x a = TTV (Name "X" (-1)) a
    builder a b =
      let constEq = TEq SFnConst (TTF SApp [a, b] [TTF SFnConst [a, b] [TTV (Name "Y" (-1)) b], x a]) (TTV (Name "Y" (-1)) b)
          idEq = [ TEq SFnId (TTF SApp [a, a] [TTF SFnId [a] [], x a]) (x a) | a == b ]
          caseEqs = case a of
            TCon tc ts | Just d <- M.lookup tc datas, length (dataVars d) == length ts ->
              let sub = M.fromList (zip (dataVars d) ts)
                  ctors = [ (c, map (substType sub) fs) | (c, fs) <- dataCons d ]
                  rSorts = [ foldr tFun b fs | (_, fs) <- ctors ]
                  rs = [ TTV (Name ("R" ++ show i) (-1)) r | (i, r) <- zip [1 :: Int ..] rSorts ]
                  eqFor (c, fs) r =
                    let zs = [ TTV (Name ("Z" ++ show i) (-1)) f | (i, f) <- zip [1 :: Int ..] fs ]
                        body = applyAll r (foldr tFun b fs) zs
                    in TEq (SFnCase tc) (TTF SApp [a, b] [TTF (SFnCase tc) (ts ++ [b]) rs, TTF (SCon c) ts zs]) body
                  newSorts = concat [ curried fs b | (_, fs) <- ctors ]
              in (zipWith eqFor ctors rs, newSorts)
            _ -> ([], [])
          resultSorts = case b of
            TCon "->" [c, d] -> [(c, d)]
            _ -> []
      in (constEq : idEq ++ fst caseEqs, snd caseEqs ++ resultSorts)
    -- apply a term of sort f1 -> ... -> fn -> b to arguments
    applyAll t _ [] = t
    applyAll t (TCon "->" [p, q]) (z : zs) = applyAll (TTF SApp [p, q] [t, z]) q zs
    applyAll t _ _ = t
    curried [] _ = []
    curried (f : fs) b = (f, foldr tFun b fs) : curried fs b

--------------------------------------------------------------------------------
-- Declarations

-- | Argument and result sorts of a TFF symbol.
symSignature :: M.Map String Type -> M.Map String FunInfo -> M.Map Ident ConInfo -> M.Map Ident DataInfo -> M.Map String ([Type], Type) -> TKey -> Maybe ([Type], Type)
symSignature types funs cons datas auxSigs (s, inst) = case s of
  SFun k -> do
    fi <- M.lookup k funs
    case M.lookup k types of
      Just t -> splitArgs (fiArity fi) (substType (M.fromList (zip (ftv t) inst)) t)
      Nothing -> M.lookup k auxSigs
  SCon c -> do
    ci <- M.lookup c cons
    let Forall vs t = conScheme ci
    splitArgs (conArity ci) (substType (M.fromList (zip vs inst)) t)
  SClo callee j -> do
    (args, res) <- symSignature types funs cons datas auxSigs (calleeSym callee, inst)
    return (take j args, foldr tFun res (drop j args))
  SLit _ -> Just ([], tInt)
  SApp -> case inst of
    [a, b] -> Just ([tFun a b, a], b)
    _ -> Nothing
  SFnConst -> case inst of
    [a, b] -> Just ([b], tFun a b)
    _ -> Nothing
  SFnId -> case inst of
    [a] -> Just ([], tFun a a)
    _ -> Nothing
  SFnCase tc -> do
    d <- M.lookup tc datas
    let n = length (dataVars d)
        ts = take n inst
        b = last inst
        sub = M.fromList (zip (dataVars d) ts)
    return ([ foldr tFun b (map (substType sub) fs) | (_, fs) <- dataCons d ], tFun (TCon tc ts) b)
