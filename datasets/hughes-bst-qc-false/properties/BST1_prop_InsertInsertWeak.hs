-- prop_InsertInsertWeak, tested against BST1.hs (bug 1: insert discards the existing tree).
--
-- From John Hughes, "How to Specify It!" (TFP 2019), adapted for hs2fol as
-- described in benchmarks/hughes-bst/README.md. QuickCheck falsifies it:
--
--   *** Failed! Falsified (after 1 test and 1 shrink):
--   (Zero,Zero)
--   (Suc Zero,Zero)
--   []
--   [(Zero,Zero)] /= [(Suc Zero,Zero)]
--
-- Theorem provers (hs2fol + witness2input): solved by eprover (0.0 s), twee (0.1 s), vampire (0.0 s).
--
-- Run:  runghc BST1_prop_InsertInsertWeak.hs      (or: hs2fol BST1_prop_InsertInsertWeak.hs)
module Main (main) where

import Test.QuickCheck
import Nat
import BST1

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

prop_InsertInsertWeak :: (Key,Val) -> (Key,Val) -> [(Key, Val)] -> Property
prop_InsertInsertWeak (k,v) (k',v') kvs =
  k /= k' ==>
    insert k v (insert k' v' t)
    =~=
    insert k' v' (insert k v t)
  where t = tree kvs

main :: IO ()
main = quickCheck (withMaxSuccess 10000 prop_InsertInsertWeak)
