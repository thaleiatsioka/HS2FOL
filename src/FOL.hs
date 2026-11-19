-- | First-order terms and equations, slicing and TPTP printing.
module FOL
  ( Callee (..)
  , Sym (..)
  , Term (..)
  , Equation (..)
  , calleeSym
  , appChain
  , termVars
  , termSyms
  , substTerm
  , substTerms
  , sliceEquations
  , reachableSyms
  , NameMap
  , assignNames
  , showTerm
  , varNames
  , formatEquations
  ) where

import Data.List (intercalate, nub, sortOn)
import qualified Data.Map as M
import qualified Data.Set as S
import Names (sanitize, varBase)
import Syntax (Name (..))

data Callee = ToFun String | ToCon String
  deriving (Eq, Ord, Show)

data Sym
  = SFun String -- ^ function (global key)
  | SCon String -- ^ constructor (Haskell name)
  | SClo Callee Int -- ^ closure: callee applied to n arguments
  | SLit Integer
  | SApp
  | SFnConst
  | SFnId
  | SFnCase String -- ^ case builder for a data type
  deriving (Eq, Ord, Show)

data Term = TV Name | TF Sym [Term]
  deriving (Eq, Show)

data Equation = Equation
  { eqOwner :: Sym -- ^ the symbol this equation defines
  , eqLhs :: Term
  , eqRhs :: Term
  } deriving (Show)

calleeSym :: Callee -> Sym
calleeSym (ToFun k) = SFun k
calleeSym (ToCon c) = SCon c

appChain :: Term -> [Term] -> Term
appChain = foldl (\f a -> TF SApp [f, a])

termVars :: Term -> [Name]
termVars (TV v) = [v]
termVars (TF _ ts) = concatMap termVars ts

termSyms :: Term -> [Sym]
termSyms (TV _) = []
termSyms (TF s ts) = s : concatMap termSyms ts

substTerm :: Name -> Term -> Term -> Term
substTerm v t (TV w)
  | v == w = t
  | otherwise = TV w
substTerm v t (TF s ts) = TF s (map (substTerm v t) ts)

substTerms :: M.Map Name Term -> Term -> Term
substTerms m (TV w) = M.findWithDefault (TV w) w m
substTerms m (TF s ts) = TF s (map (substTerms m) ts)

-- | The equations reachable from the given root symbols.
sliceEquations :: [Equation] -> [Sym] -> [Equation]
sliceEquations eqs roots = filter (\e -> S.member (eqOwner e) reached) eqs
  where
    reached = reachableSyms eqs roots

-- | The symbols reachable from the roots through defining equations.
reachableSyms :: [Equation] -> [Sym] -> S.Set Sym
reachableSyms eqs roots = reached
  where
    byOwner = M.fromListWith (flip (++)) [ (eqOwner e, [e]) | e <- eqs ]
    reached = go S.empty roots
    go seen [] = seen
    go seen (s : ss)
      | S.member s seen = go seen ss
      | otherwise =
          let es = M.findWithDefault [] s byOwner
              new = concat [ termSyms (eqLhs e) ++ termSyms (eqRhs e) | e <- es ]
          in go (S.insert s seen) (new ++ ss)

type NameMap = M.Map Sym String

-- | Allocate unique FOL names. Entries are (symbol, priority, desired name);
-- lower priority values are served first.
assignNames :: Ord k => [(k, Int, String)] -> M.Map k String
assignNames entries = snd (foldl step (S.empty, M.empty) (sortOn (\(s, p, _) -> (p, s)) (nubSyms entries)))
  where
    nubSyms es = M.elems (M.fromList [ (s, e) | e@(s, _, _) <- es ])
    step (used, m) (s, _, base) =
      let b = sanitize base
          cand = head [ c | c <- b : [ b ++ "_" ++ show i | i <- [1 :: Int ..] ], not (S.member c used) ]
      in (S.insert cand used, M.insert s cand m)

showTerm :: NameMap -> M.Map Name String -> Term -> String
showTerm _ vm (TV v) = M.findWithDefault "V_unknown" v vm
showTerm nm vm (TF s ts) =
  let f = M.findWithDefault ("unknown_" ++ sanitize (show s)) s nm
  in if null ts then f else f ++ "(" ++ intercalate ", " (map (showTerm nm vm) ts) ++ ")"

-- | TPTP variable names for the given variables (unique, readable).
varNames :: [Name] -> M.Map Name String
varNames vs = snd (foldl step (S.empty, M.empty) (nub vs))
  where
    step (used, m) v =
      let b = varBase (nameBase v)
          cand = head [ c | c <- b : [ b ++ show i | i <- [1 :: Int ..] ], not (S.member c used) ]
      in (S.insert cand used, M.insert v cand m)

-- | Print equations as TPTP axioms. The function gives the label base and
-- an optional comment for an owner symbol.
formatEquations :: NameMap -> (Sym -> (String, Maybe String)) -> [Equation] -> ([String], S.Set String)
formatEquations nm info eqs = go S.empty Nothing eqs
  where
    go used _ [] = ([], used)
    go used prevOwner (e : rest) =
      let (base, comment) = info (eqOwner e)
          label = head [ c | i <- [1 :: Int ..], let c = base ++ "_" ++ show i, not (S.member c used) ]
          vs = nub (termVars (eqLhs e) ++ termVars (eqRhs e))
          vm = varNames vs
          quant = if null vs then "" else "![" ++ intercalate ", " (map (vm M.!) vs) ++ "]: "
          line = "fof(" ++ label ++ ", axiom, " ++ quant ++ showTerm nm vm (eqLhs e) ++ " = " ++ showTerm nm vm (eqRhs e) ++ ")."
          header = case comment of
            Just c | prevOwner /= Just (eqOwner e) -> ["", "% " ++ c]
            _ -> []
          (ls, used') = go (S.insert label used) (Just (eqOwner e)) rest
      in (header ++ [line] ++ ls, used')
