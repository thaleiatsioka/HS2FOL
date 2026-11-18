-- GENERATED from template/BSTSpec.template.hs by generate.sh; do not edit.
--
-- The properties of John Hughes, "How to Specify It!" (TFP 2019), from
-- BSTSpec.hs in https://github.com/rjmh/how-to-specify-it, tested against
-- BST1 (bug 1: insert discards the existing tree).
--
-- Adaptations for hs2fol (see README.md):
--  * Key and Val are Nat instead of Int/Integer.
--  * A Tree argument t is replaced by a list kvs with t = tree kvs, which is
--    exactly the paper's Arbitrary instance (foldr (uncurry insert) nil), so
--    the provers search the same space of trees that QuickCheck generates.
--  * Data.List functions in the model-based properties are defined locally
--    (hs2fol does not support qualified names), with the same meaning.
--  * Left out: prop_SizeInsert (Int arithmetic), prop_ShrinkValid and the
--    Equivs/congruence properties (they need QuickCheck's shrink/shuffle).
module BSTSpec1 where

import Test.QuickCheck
import Nat
import BST1

type Key = Nat
type Val = Nat
type Tree = BST Key Val

-- the generator of the paper
tree :: [(Key, Val)] -> Tree
tree kvs = foldr (uncurry insert) nil kvs

-- invariant properties

prop_ArbitraryValid :: [(Key, Val)] -> Bool
prop_ArbitraryValid kvs = valid (tree kvs)

prop_NilValid :: Bool
prop_NilValid = valid (nil :: Tree)

prop_InsertValid :: Key -> Val -> [(Key, Val)] -> Bool
prop_InsertValid k v kvs = valid (insert k v (tree kvs))

prop_DeleteValid :: Key -> [(Key, Val)] -> Bool
prop_DeleteValid k kvs = valid (delete k (tree kvs))

prop_UnionValid :: [(Key, Val)] -> [(Key, Val)] -> Bool
prop_UnionValid kvs kvs' = valid (union (tree kvs) (tree kvs'))

-- postcondition properties

prop_InsertPost :: Key -> Val -> [(Key, Val)] -> Key -> Property
prop_InsertPost k v kvs k' =
  find k' (insert k v t)
  ===
  if k==k' then Just v else find k' t
  where t = tree kvs

prop_DeletePost :: Key -> [(Key, Val)] -> Key -> Property
prop_DeletePost k kvs k' =
  find k' (delete k t)
  ===
  if k==k' then Nothing else find k' t
  where t = tree kvs

prop_FindPostPresent :: Key -> Val -> [(Key, Val)] -> Property
prop_FindPostPresent k v kvs =
  find k (insert k v (tree kvs)) === Just v

prop_FindPostAbsent :: Key -> [(Key, Val)] -> Property
prop_FindPostAbsent k kvs =
  find k (delete k (tree kvs)) === Nothing

prop_InsertDeleteComplete :: Key -> [(Key, Val)] -> Property
prop_InsertDeleteComplete k kvs =
  case find k t of
    Nothing -> t === delete k t
    Just v  -> t === insert k v t
  where t = tree kvs

prop_UnionPost :: [(Key, Val)] -> [(Key, Val)] -> Key -> Property
prop_UnionPost kvs kvs' k =
  find k (union t t')
  ===
  (find k t <|> find k t')
  where t = tree kvs
        t' = tree kvs'

-- Control.Applicative's <|> at type Maybe
infixl 3 <|>
(<|>) :: Maybe a -> Maybe a -> Maybe a
Nothing <|> m = m
Just x <|> _ = Just x

-- metamorphic properties

(=~=) :: (Eq k, Eq v, Show k, Show v) => BST k v -> BST k v -> Property
t1 =~= t2 =
  toList t1 === toList t2

prop_InsertInsertWeak :: (Key,Val) -> (Key,Val) -> [(Key, Val)] -> Property
prop_InsertInsertWeak (k,v) (k',v') kvs =
  k /= k' ==>
    insert k v (insert k' v' t)
    =~=
    insert k' v' (insert k v t)
  where t = tree kvs

prop_InsertInsert :: (Key,Val) -> (Key,Val) -> [(Key, Val)] -> Property
prop_InsertInsert (k,v) (k',v') kvs =
  insert k v (insert k' v' t)
  =~=
  if k==k' then insert k v t else insert k' v' (insert k v t)
  where t = tree kvs

prop_InsertDeleteWeak :: (Key,Val) -> Key -> [(Key, Val)] -> Property
prop_InsertDeleteWeak (k,v) k' kvs =
  k /= k' ==>
    insert k v (delete k' t)
    =~=
    delete k' (insert k v t)
  where t = tree kvs

prop_InsertDelete :: (Key,Val) -> Key -> [(Key, Val)] -> Property
prop_InsertDelete (k,v) k' kvs =
  insert k v (delete k' t)
  =~=
  if k==k' then insert k v t else delete k' (insert k v t)
  where t = tree kvs

prop_InsertUnion :: (Key,Val) -> [(Key, Val)] -> [(Key, Val)] -> Property
prop_InsertUnion (k,v) kvs kvs' =
  insert k v (union t t')
  =~=
  union (insert k v t) t'
  where t = tree kvs
        t' = tree kvs'

prop_DeleteNil :: Key -> Property
prop_DeleteNil k =
  delete k nil === (nil :: Tree)

prop_DeleteInsertWeak :: Key -> (Key,Val) -> [(Key, Val)] -> Property
prop_DeleteInsertWeak k (k',v') kvs =
  k /= k' ==>
    delete k (insert k' v' t)
    =~=
    insert k' v' (delete k t)
  where t = tree kvs

prop_DeleteInsert :: Key -> (Key,Val) -> [(Key, Val)] -> Property
prop_DeleteInsert k (k',v') kvs =
  delete k (insert k' v' t)
  =~=
  if k==k' then delete k t else insert k' v' (delete k t)
  where t = tree kvs

prop_DeleteDelete :: Key -> Key -> [(Key, Val)] -> Property
prop_DeleteDelete k k' kvs =
  delete k (delete k' t)
  =~=
  delete k' (delete k t)
  where t = tree kvs

prop_DeleteUnion :: Key -> [(Key, Val)] -> [(Key, Val)] -> Property
prop_DeleteUnion k kvs kvs' =
  delete k (union t t')
  =~=
  union (delete k t) (delete k t')
  where t = tree kvs
        t' = tree kvs'

prop_UnionInsert :: [(Key, Val)] -> [(Key, Val)] -> (Key,Val) -> Property
prop_UnionInsert kvs kvs' (k,v) =
  union (insert k v t) t'
  =~=
  insert k v (union t t')
  where t = tree kvs
        t' = tree kvs'

prop_UnionNil1 :: [(Key, Val)] -> Property
prop_UnionNil1 kvs =
  union nil t === t
  where t = tree kvs

prop_UnionNil2 :: [(Key, Val)] -> Property
prop_UnionNil2 kvs =
  union t nil === t
  where t = tree kvs

prop_UnionDeleteInsert :: [(Key, Val)] -> [(Key, Val)] -> (Key,Val) -> Property
prop_UnionDeleteInsert kvs kvs' (k,v) =
  union (delete k t) (insert k v t')
  =~=
  insert k v (union t t')
  where t = tree kvs
        t' = tree kvs'

prop_UnionDeleteDelete :: [(Key, Val)] -> [(Key, Val)] -> Key -> Property
prop_UnionDeleteDelete kvs kvs' k =
  union (delete k t) (delete k t')
  =~=
  delete k (union t t')
  where t = tree kvs
        t' = tree kvs'

prop_UnionUnionIdem :: [(Key, Val)] -> Property
prop_UnionUnionIdem kvs =
  union t t =~= t
  where t = tree kvs

prop_UnionUnionAssoc :: [(Key, Val)] -> [(Key, Val)] -> [(Key, Val)] -> Property
prop_UnionUnionAssoc kvs1 kvs2 kvs3 =
  union (union t1 t2) t3
  ===
  union t1 (union t2 t3)
  where t1 = tree kvs1
        t2 = tree kvs2
        t3 = tree kvs3

prop_FindNil :: Key -> Property
prop_FindNil k =
  find k (nil :: Tree) === Nothing

prop_FindInsert :: Key -> (Key,Val) -> [(Key, Val)] -> Property
prop_FindInsert k (k',v') kvs =
  find k (insert k' v' t)
  ===
  if k==k' then Just v' else find k t
  where t = tree kvs

prop_FindDelete :: Key -> Key -> [(Key, Val)] -> Property
prop_FindDelete k k' kvs =
  find k (delete k' t)
  ===
  if k==k' then Nothing else find k t
  where t = tree kvs

prop_FindUnion :: Key -> [(Key, Val)] -> [(Key, Val)] -> Property
prop_FindUnion k kvs kvs' =
  find k (union t t')
  ===
  (find k t <|> find k t')
  where t = tree kvs
        t' = tree kvs'

-- completeness of insertion

insertComplete :: Tree -> Property
insertComplete t =
  t === foldl (flip $ uncurry insert) nil (insertions t)

prop_InsertComplete :: [(Key, Val)] -> Property
prop_InsertComplete kvs =
  insertComplete (tree kvs)

prop_InsertCompleteForDelete :: Key -> [(Key, Val)] -> Property
prop_InsertCompleteForDelete k kvs =
  insertComplete (delete k (tree kvs))

prop_InsertCompleteForUnion :: [(Key, Val)] -> [(Key, Val)] -> Property
prop_InsertCompleteForUnion kvs kvs' =
  insertComplete (union (tree kvs) (tree kvs'))

-- model-based properties

prop_NilModel :: Property
prop_NilModel =
  toList (nil :: Tree) === []

prop_InsertModel :: (Key, Val) -> [(Key, Val)] -> Property
prop_InsertModel (k,v) kvs =
  toList (insert k v t) === insertL (k,v) (deleteKey k $ toList t)
  where t = tree kvs

prop_DeleteModel :: Key -> [(Key, Val)] -> Property
prop_DeleteModel k kvs =
  toList (delete k t) === deleteKey k (toList t)
  where t = tree kvs

prop_UnionModel :: [(Key, Val)] -> [(Key, Val)] -> Property
prop_UnionModel kvs kvs' =
  toList (union t t') === sortL (unionByKey (toList t) (toList t'))
  where t = tree kvs
        t' = tree kvs'

prop_FindModel :: Key -> [(Key, Val)] -> Property
prop_FindModel k kvs =
  find k t === lookup k (toList t)
  where t = tree kvs

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
