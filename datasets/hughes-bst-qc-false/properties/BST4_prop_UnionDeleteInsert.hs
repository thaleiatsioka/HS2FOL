-- prop_UnionDeleteInsert, tested against BST4.hs (bug 4: delete does not rebuild the tree above the deleted key).
--
-- From John Hughes, "How to Specify It!" (TFP 2019), adapted for hs2fol as
-- described in benchmarks/hughes-bst/README.md. QuickCheck falsifies it:
--
--   *** Failed! Falsified (after 2 tests and 2 shrinks):
--   [(Suc Zero,Zero)]
--   []
--   (Zero,Zero)
--   [(Zero,Zero)] /= [(Zero,Zero),(Suc Zero,Zero)]
--
-- Theorem provers (hs2fol + witness2input): solved by vampire (3.8 s).
--
-- Run:  runghc BST4_prop_UnionDeleteInsert.hs      (or: hs2fol BST4_prop_UnionDeleteInsert.hs)
module Main (main) where

import Test.QuickCheck
import Nat
import BST4

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

prop_UnionDeleteInsert :: [(Key, Val)] -> [(Key, Val)] -> (Key,Val) -> Property
prop_UnionDeleteInsert kvs kvs' (k,v) =
  union (delete k t) (insert k v t')
  =~=
  insert k v (union t t')
  where t = tree kvs
        t' = tree kvs'

main :: IO ()
main = quickCheck (withMaxSuccess 10000 prop_UnionDeleteInsert)
