module Main where

import Test.QuickCheck
import Nat

-- A QuickCheck file with a few bugs. hs2fol skips the generator below
-- (it uses things outside the supported subset) and translates the rest.

instance Arbitrary Nat where
  arbitrary = sized gen
    where
      gen 0 = return Zero
      gen n = oneof [return Zero, Suc <$> gen (n - 1)]

len :: [a] -> Nat
len [] = Zero
len (_ : xs) = Suc (len xs)

ordered :: [Nat] -> Bool
ordered (x : y : ys) = x <= y && ordered (y : ys)
ordered _ = True

-- buggy: drops y
insertBad :: Nat -> [Nat] -> [Nat]
insertBad x [] = [x]
insertBad x (y : ys)
  | x <= y = x : ys
  | otherwise = y : insertBad x ys

isortBad :: [Nat] -> [Nat]
isortBad = foldr insertBad []

rev :: [a] -> [a]
rev xs = go xs []
  where
    go [] acc = acc
    go (y : ys) acc = go ys (y : acc)

pairs :: [Nat] -> [(Nat, Nat)]
pairs xs = [ (x, y) | x <- xs, y <- xs, x < y ]

-- true
prop_sortedOrdered :: [Nat] -> Bool
prop_sortedOrdered xs = ordered (isortBad xs)

-- false: two elements, first smaller
prop_sortLength :: [Nat] -> Bool
prop_sortLength xs = len (isortBad xs) == len xs

-- true
prop_revRev :: [Nat] -> Bool
prop_revRev xs = rev (rev xs) == xs

-- false: needs two different elements
prop_revId :: [Nat] -> Bool
prop_revId xs = rev xs == xs

-- false: reverse (xs ++ ys) is reverse ys ++ reverse xs
prop_revApp :: [Nat] -> [Nat] -> Property
prop_revApp xs ys = reverse (xs ++ ys) === reverse xs ++ reverse ys

-- true (uses a lambda)
prop_mapId :: [Nat] -> Bool
prop_mapId xs = map (\x -> plus x Zero) xs == xs

-- true (uses a section)
prop_appendNil :: [Nat] -> Bool
prop_appendNil xs = (xs ++) [] == xs

-- false: elem x xs does not imply x is the head
prop_elemHead :: Nat -> [Nat] -> Property
prop_elemHead x xs = elem x xs ==> head xs == x

-- false: pairs xs is not always empty
prop_pairsEmpty :: [Nat] -> Bool
prop_pairsEmpty xs = null (pairs xs)
