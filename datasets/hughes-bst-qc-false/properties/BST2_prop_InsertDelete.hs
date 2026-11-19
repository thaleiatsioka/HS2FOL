-- prop_InsertDelete, tested against BST2.hs (bug 2: insert duplicates an existing key instead of updating it).
--
-- From John Hughes, "How to Specify It!" (TFP 2019), adapted for hs2fol as
-- described in benchmarks/hughes-bst/README.md. QuickCheck falsifies it:
--
--   *** Failed! Falsified (after 42 tests and 34 shrinks):
--   (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc Zero)))))))))),Zero)
--   Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc Zero))))))))))
--   [(Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc Zero)))))))))),Zero)]
--   [(Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc Zero)))))))))),Zero)] /= [(Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc Zero)))))))))),Zero),(Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc Zero)))))))))),Zero)]
--
-- Theorem provers (hs2fol + witness2input): solved by vampire (3.1 s).
--
-- Run:  runghc BST2_prop_InsertDelete.hs      (or: hs2fol BST2_prop_InsertDelete.hs)
module Main (main) where

import Test.QuickCheck
import Nat
import BST2

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

prop_InsertDelete :: (Key,Val) -> Key -> [(Key, Val)] -> Property
prop_InsertDelete (k,v) k' kvs =
  insert k v (delete k' t)
  =~=
  if k==k' then insert k v t else delete k' (insert k v t)
  where t = tree kvs

main :: IO ()
main = quickCheck (withMaxSuccess 10000 prop_InsertDelete)
