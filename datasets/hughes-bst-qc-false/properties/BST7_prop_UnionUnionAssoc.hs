-- prop_UnionUnionAssoc, tested against BST7.hs (bug 7: union assumes that if the root of t is smaller than the root of t', all of t is).
--
-- From John Hughes, "How to Specify It!" (TFP 2019), adapted for hs2fol as
-- described in benchmarks/hughes-bst/README.md. QuickCheck falsifies it:
--
--   *** Failed! Falsified (after 6 tests and 17 shrinks):
--   [(Suc Zero,Zero)]
--   [(Zero,Zero)]
--   [(Suc Zero,Suc Zero)]
--   Branch Leaf Zero Zero (Branch (Branch Leaf (Suc Zero) Zero Leaf) (Suc Zero) (Suc Zero) Leaf) /= Branch Leaf Zero Zero (Branch (Branch Leaf (Suc Zero) (Suc Zero) Leaf) (Suc Zero) Zero Leaf)
--
-- Theorem provers (hs2fol + witness2input): not solved by any prover (10 s, then 60 s).
--
-- Run:  runghc BST7_prop_UnionUnionAssoc.hs      (or: hs2fol BST7_prop_UnionUnionAssoc.hs)
module Main (main) where

import Test.QuickCheck
import Nat
import BST7

type Key = Nat
type Val = Nat
type Tree = BST Key Val

-- the generator of the paper
tree :: [(Key, Val)] -> Tree
tree kvs = foldr (uncurry insert) nil kvs

-- Control.Applicative's <|> at type Maybe
infixl 3 <|>
(<|>) :: Maybe a -> Maybe a -> Maybe a
Nothing <|> m = m
Just x <|> _ = Just x

(=~=) :: (Eq k, Eq v, Show k, Show v) => BST k v -> BST k v -> Property
t1 =~= t2 =
  toList t1 === toList t2

insertComplete :: Tree -> Property
insertComplete t =
  t === foldl (flip $ uncurry insert) nil (insertions t)

deleteKey :: Key -> [(Key, Val)] -> [(Key, Val)]
deleteKey k = filter ((/=k) . fst)

-- Data.List.insert
insertL :: Ord a => a -> [a] -> [a]
insertL x [] = [x]
insertL x (y:ys) = if x <= y then x : y : ys else y : insertL x ys

-- Data.List.sort (as insertion sort)
sortL :: Ord a => [a] -> [a]
sortL [] = []
sortL (x:xs) = insertL x (sortL xs)

-- Data.List.unionBy ((==) `on` fst)
unionByKey :: [(Key, Val)] -> [(Key, Val)] -> [(Key, Val)]
unionByKey xs ys = xs ++ [ p | p <- nubKey ys, fst p `notElem` map fst xs ]

nubKey :: [(Key, Val)] -> [(Key, Val)]
nubKey [] = []
nubKey (p:ps) = p : nubKey (filter (\q -> fst q /= fst p) ps)

prop_UnionUnionAssoc :: [(Key, Val)] -> [(Key, Val)] -> [(Key, Val)] -> Property
prop_UnionUnionAssoc kvs1 kvs2 kvs3 =
  union (union t1 t2) t3
  ===
  union t1 (union t2 t3)
  where t1 = tree kvs1
        t2 = tree kvs2
        t3 = tree kvs3

main :: IO ()
main = quickCheck (withMaxSuccess 10000 prop_UnionUnionAssoc)
