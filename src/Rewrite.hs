-- | Evaluation of ground (or partly ground) terms with the generated
-- equations. The left-hand sides never overlap, so rewriting is
-- deterministic; every equation holds in Haskell, so a term and its normal
-- form denote the same value. Used to turn a prover's witness, which may
-- mention auxiliary functions, into constructor terms.
module Rewrite (normalise) where

import qualified Data.Map as M
import FOL

-- | Rewrite innermost-first, with a bound on the number of steps. Returns
-- the term reached (a normal form unless the fuel ran out).
normalise :: Int -> [Equation] -> Term -> Term
normalise fuel eqs t0 = fst (go fuel t0)
  where
    byHead = M.fromListWith (flip (++)) [ (h, [e]) | e@(Equation _ (TF h _) _) <- eqs ]
    go :: Int -> Term -> (Term, Int)
    go n t | n <= 0 = (t, n)
    go n t@(TV _) = (t, n)
    go n (TF s args) =
      let (args', n') = goList n args
          t' = TF s args'
      in case firstMatch t' of
           Just r -> go (n' - 1) r
           Nothing -> (t', n')
    goList n [] = ([], n)
    goList n (a : as) =
      let (a', n1) = go n a
          (as', n2) = goList n1 as
      in (a' : as', n2)
    firstMatch t@(TF h _) =
      case [ substTerms s (eqRhs e) | e <- M.findWithDefault [] h byHead, Just s <- [match (eqLhs e) t M.empty] ] of
        (r : _) -> Just r
        [] -> Nothing
    firstMatch _ = Nothing
    match (TV v) t s = case M.lookup v s of
      Nothing -> Just (M.insert v t s)
      Just t' -> if t' == t then Just s else Nothing
    match (TF f ps) (TF g ts) s
      | f == g && length ps == length ts = matchList ps ts s
    match _ _ _ = Nothing
    matchList [] [] s = Just s
    matchList (p : ps) (t : ts) s = match p t s >>= matchList ps ts
    matchList _ _ _ = Nothing
