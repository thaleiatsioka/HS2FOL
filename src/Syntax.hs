-- | Types, surface syntax, core language and program tables shared by all
-- phases of hs2fol.
module Syntax
  ( Ident
    -- * Types
  , Type (..), Scheme (..), schemeType, tFun, tBool, tInt, tList
  , funArgs, splitArgs, typeArity, tupleCon, isTupleCon, ftv, substType
  , matchType, prettyType
    -- * Surface syntax
  , Op (..), Assoc (..), Pat (..), Expr (..), Alt (..), Stmt (..), Rhs (..)
  , Guarded (..), ConDecl (..), Decl (..), opExpr, resolveOps
    -- * Core
  , Name (..), globalName, isGlobal, CExpr (..), CAlt (..), gvar, lvar
  , cApps, collectApps, collectLams, freeVars, globalOccs, substE
    -- * Program tables
  , DataInfo (..), ConInfo (..), MethodInfo (..), InstInfo (..)
  , BindKind (..), Binding (..), Program (..)
  ) where

import Control.Monad (foldM)
import Data.List (intercalate, nub)
import qualified Data.Map as M
import qualified Data.Set as S

type Ident = String

--------------------------------------------------------------------------------
-- Types

-- | Type variables whose name starts with @?@ are unification variables;
-- all others are rigid. Function types are @TCon "->" [a, b]@, lists
-- @TCon "[]" [a]@, tuples @TCon "(,)" [a, b]@ and unit @TCon "()" []@.
data Type = TVar String | TCon String [Type]
  deriving (Eq, Ord, Show)

data Scheme = Forall [String] Type
  deriving (Eq, Show)

schemeType :: Scheme -> Type
schemeType (Forall _ t) = t

tFun :: Type -> Type -> Type
tFun a b = TCon "->" [a, b]

tBool, tInt :: Type
tBool = TCon "Bool" []
tInt = TCon "Int" []

tList :: Type -> Type
tList a = TCon "[]" [a]

funArgs :: Type -> ([Type], Type)
funArgs (TCon "->" [a, b]) = let (as, r) = funArgs b in (a : as, r)
funArgs t = ([], t)

splitArgs :: Int -> Type -> Maybe ([Type], Type)
splitArgs 0 t = Just ([], t)
splitArgs n (TCon "->" [a, b]) = do
  (as, r) <- splitArgs (n - 1) b
  return (a : as, r)
splitArgs _ _ = Nothing

typeArity :: Type -> Int
typeArity = length . fst . funArgs

tupleCon :: Int -> String
tupleCon n = "(" ++ replicate (n - 1) ',' ++ ")"

isTupleCon :: String -> Bool
isTupleCon ('(' : ',' : _) = True
isTupleCon _ = False

ftv :: Type -> [String]
ftv = nub . go
  where
    go (TVar v) = [v]
    go (TCon _ ts) = concatMap go ts

substType :: M.Map String Type -> Type -> Type
substType s t@(TVar v) = M.findWithDefault t v s
substType s (TCon c ts) = TCon c (map (substType s) ts)

-- | One-way matching: find a substitution for the variables of the pattern
-- (first argument) that makes it equal to the target.
matchType :: Type -> Type -> Maybe (M.Map String Type)
matchType p0 t0 = go p0 t0 M.empty
  where
    go (TVar v) t s = case M.lookup v s of
      Nothing -> Just (M.insert v t s)
      Just t' -> if t' == t then Just s else Nothing
    go (TCon c ps) (TCon d ts) s
      | c == d && length ps == length ts = foldM (\s' (a, b) -> go a b s') s (zip ps ts)
    go _ _ _ = Nothing

prettyType :: Type -> String
prettyType = go (0 :: Int)
  where
    go _ (TVar v) = v
    go p (TCon "->" [a, b]) = paren (p > 0) (go 1 a ++ " -> " ++ go 0 b)
    go _ (TCon "[]" [a]) = "[" ++ go 0 a ++ "]"
    go _ (TCon c ts) | isTupleCon c = "(" ++ intercalate ", " (map (go 0) ts) ++ ")"
    go _ (TCon c []) = c
    go p (TCon c ts) = paren (p > 1) (unwords (c : map (go 2) ts))
    paren b s = if b then "(" ++ s ++ ")" else s

--------------------------------------------------------------------------------
-- Surface syntax

data Op = Op { opName :: Ident, opIsCon :: Bool }
  deriving (Eq, Show)

data Assoc = InfixL | InfixR | InfixN
  deriving (Eq, Show)

data Pat
  = PVar Ident
  | PWild
  | PCon Ident [Pat]
  | PLit Integer
  | PAs Ident Pat
  | PTuple [Pat]
  | PList [Pat]
  | POps Pat [(Op, Pat)]
  deriving (Show)

data Expr
  = EVar Ident
  | ECon Ident
  | ELit Integer
  | EStr String
  | EApp Expr Expr
  | ELam [Pat] Expr
  | ELet [Decl] Expr
  | EIf Expr Expr Expr
  | ECase Expr [Alt]
  | ETuple [Expr]
  | EList [Expr]
  | EListComp Expr [Stmt]
  | EOps Expr [(Op, Expr)]
  | ENeg Expr
  | ELeftSection Expr Op
  | ERightSection Op Expr
  | ETyped Expr Type
  deriving (Show)

data Alt = Alt Pat Rhs
  deriving (Show)

data Stmt = SGen Pat Expr | SGuard Expr | SLet [Decl]
  deriving (Show)

data Rhs = Rhs Guarded [Decl]
  deriving (Show)

data Guarded = Unguarded Expr | Guarded [(Expr, Expr)]
  deriving (Show)

-- | Constructor name, field types, record field names.
data ConDecl = ConDecl Ident [Type] [Maybe Ident]
  deriving (Show)

data Decl
  = DData Ident [Ident] [ConDecl] [Ident]
  | DSyn Ident [Ident] Type
  | DSig [Ident] Type
  | DEqn Ident [Pat] Rhs
  | DPatBind Pat Rhs
  | DClass Ident Ident [Decl]
  | DInst Ident Type [Decl]
  | DFixity Assoc Int [Ident]
  | DImport Ident
  deriving (Show)

opExpr :: Op -> Expr
opExpr (Op n True) = ECon n
opExpr (Op n False) = EVar n

-- | Resolve a flat operator expression @e0 op1 e1 op2 e2 ...@ using the
-- fixity table (default: infixl 9).
resolveOps :: M.Map Ident (Assoc, Int) -> (Op -> a -> a -> a) -> a -> [(Op, a)] -> Either String a
resolveOps fixities mk e0 rest0 = go [e0] [] rest0
  where
    fixity o = M.findWithDefault (InfixL, 9) (opName o) fixities
    go es ops [] = finish es ops
    go es ops ((o, e) : more) = case ops of
      (o' : ops') ->
        let (a1, p1) = fixity o'
            (a2, p2) = fixity o
        in if p1 > p2 || (p1 == p2 && a1 == InfixL && a2 == InfixL)
             then case es of
               (r : l : es') -> go (mk o' l r : es') ops' ((o, e) : more)
               _ -> Left "malformed operator expression"
             else if p1 == p2 && not (a1 == InfixR && a2 == InfixR)
               then Left ("cannot mix operators " ++ opName o' ++ " and " ++ opName o ++ " (fixity)")
               else go (e : es) (o : ops) more
      [] -> go (e : es) [o] more
    finish [e] [] = Right e
    finish (r : l : es) (o : ops) = finish (mk o l r : es) ops
    finish _ _ = Left "malformed operator expression"

--------------------------------------------------------------------------------
-- Core language

-- | Global names have id 0 and their base is the global key; local names
-- have a unique positive id.
data Name = Name { nameBase :: String, nameId :: !Int }
  deriving (Eq, Ord, Show)

globalName :: String -> Name
globalName s = Name s 0

isGlobal :: Name -> Bool
isGlobal n = nameId n == 0

data CExpr
  = CVar Name (Maybe Type) -- ^ type annotation at this occurrence (globals)
  | CCon Ident
  | CLit Integer
  | CApp CExpr CExpr
  | CLam Name CExpr
  | CLet [(Name, CExpr)] CExpr -- ^ recursive
  | CCase CExpr [CAlt]
  | CFail -- ^ pattern-match failure (no clause)
  | CFallthrough -- ^ guard fall-through (only during desugaring)
  | CTyped CExpr Type
  deriving (Eq, Show)

data CAlt = CAlt Ident [Name] CExpr
  deriving (Eq, Show)

gvar :: String -> CExpr
gvar k = CVar (globalName k) Nothing

lvar :: Name -> CExpr
lvar n = CVar n Nothing

cApps :: CExpr -> [CExpr] -> CExpr
cApps = foldl CApp

collectApps :: CExpr -> (CExpr, [CExpr])
collectApps = go []
  where
    go acc (CApp f a) = go (a : acc) f
    go acc e = (e, acc)

collectLams :: CExpr -> ([Name], CExpr)
collectLams (CLam x b) = let (xs, e) = collectLams b in (x : xs, e)
collectLams e = ([], e)

-- | Free local variables.
freeVars :: CExpr -> S.Set Name
freeVars e = case e of
  CVar n _ | isGlobal n -> S.empty
           | otherwise -> S.singleton n
  CApp f a -> S.union (freeVars f) (freeVars a)
  CLam x b -> S.delete x (freeVars b)
  CLet bs b -> S.difference (S.unions (freeVars b : map (freeVars . snd) bs)) (S.fromList (map fst bs))
  CCase s alts -> S.unions (freeVars s : [ S.difference (freeVars r) (S.fromList xs) | CAlt _ xs r <- alts ])
  CTyped x _ -> freeVars x
  _ -> S.empty

-- | Occurrences of global names with their annotations.
globalOccs :: CExpr -> [(String, Maybe Type)]
globalOccs e = case e of
  CVar n t | isGlobal n -> [(nameBase n, t)]
  CApp f a -> globalOccs f ++ globalOccs a
  CLam _ b -> globalOccs b
  CLet bs b -> concatMap (globalOccs . snd) bs ++ globalOccs b
  CCase s alts -> globalOccs s ++ concat [ globalOccs r | CAlt _ _ r <- alts ]
  CTyped x _ -> globalOccs x
  _ -> []

-- | Substitution of local variables. Binder names are unique, so no capture
-- can happen.
substE :: M.Map Name CExpr -> CExpr -> CExpr
substE s e
  | M.null s = e
  | otherwise = case e of
      CVar n _ | not (isGlobal n), Just r <- M.lookup n s -> r
      CApp f a -> CApp (substE s f) (substE s a)
      CLam x b -> CLam x (substE (M.delete x s) b)
      CLet bs b ->
        let s' = foldr M.delete s (map fst bs)
        in CLet [ (n, substE s' r) | (n, r) <- bs ] (substE s' b)
      CCase sc alts -> CCase (substE s sc) [ CAlt c xs (substE (foldr M.delete s xs) r) | CAlt c xs r <- alts ]
      CTyped x t -> CTyped (substE s x) t
      _ -> e

--------------------------------------------------------------------------------
-- Program tables

data DataInfo = DataInfo
  { dataName :: Ident
  , dataVars :: [Ident]
  , dataCons :: [(Ident, [Type])]
  } deriving (Show)

data ConInfo = ConInfo
  { conData :: Ident
  , conIndex :: Int
  , conArity :: Int
  , conScheme :: Scheme
  } deriving (Show)

data MethodInfo = MethodInfo
  { methodClass :: Ident
  , methodName :: Ident
  , methodVar :: Ident
  , methodScheme :: Scheme -- ^ quantifies the class variable first
  } deriving (Show)

data InstInfo = InstInfo
  { instHead :: Type
  , instMethods :: M.Map String (Maybe String) -- ^ method key -> binding key (Nothing: abstract)
  } deriving (Show)

data BindKind = BUser | BPrelude | BInstance
  deriving (Eq, Show)

data Binding = Binding
  { bindKey :: String
  , bindHask :: Ident
  , bindSig :: Maybe Scheme
  , bindBody :: Maybe CExpr -- ^ Nothing: abstract primitive
  , bindKind :: BindKind
  } deriving (Show)

data Program = Program
  { progDatas :: M.Map Ident DataInfo
  , progCons :: M.Map Ident ConInfo
  , progMethods :: M.Map String MethodInfo -- ^ keyed by method key
  , progInstances :: M.Map (Ident, Ident) InstInfo -- ^ (class, type constructor)
  , progBinds :: [Binding]
  , progFresh :: Int
  }
