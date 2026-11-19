-- prop_DeletePost, tested against BST2.hs (bug 2: insert duplicates an existing key instead of updating it).
--
-- From John Hughes, "How to Specify It!" (TFP 2019), adapted for hs2fol as
-- described in benchmarks/hughes-bst/README.md. QuickCheck falsifies it:
--
--   *** Failed! Falsified (after 7 tests and 9 shrinks):
--   Suc (Suc Zero)
--   [(Suc (Suc Zero),Zero),(Suc (Suc Zero),Zero)]
--   Suc (Suc Zero)
--   Just Zero /= Nothing
--
-- Theorem provers (hs2fol + witness2input): solved by eprover (1.2 s), twee (0.6 s), vampire (0.9 s).
--
-- Run:  runghc BST2_prop_DeletePost.hs      (or: hs2fol BST2_prop_DeletePost.hs)
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

prop_DeletePost :: Key -> [(Key, Val)] -> Key -> Property
prop_DeletePost k kvs k' =
  find k' (delete k t)
  ===
  if k==k' then Nothing else find k' t
  where t = tree kvs

main :: IO ()
main = quickCheck (withMaxSuccess 10000 prop_DeletePost)
