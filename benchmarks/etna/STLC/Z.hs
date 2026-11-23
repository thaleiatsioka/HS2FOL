-- GENERATED: copy of ../Z.hs made by ../generate.py; do not edit.
module Z where

import Test.QuickCheck
import Nat

-- Integers built from Nat: Pos n is n, Neg n is -(n+1). Every integer has
-- exactly one representation, so the derived Eq is integer equality.
-- Used instead of Int, which hs2fol keeps abstract.
data Z = Pos Nat | Neg Nat
  deriving (Eq, Show)

instance Ord Z where
  compare (Pos a) (Pos b) = compare a b
  compare (Neg a) (Neg b) = compare b a
  compare (Neg _) (Pos _) = LT
  compare (Pos _) (Neg _) = GT

-- a - b on naturals, as an integer
subN :: Nat -> Nat -> Z
subN a Zero = Pos a
subN Zero (Suc b) = Neg b
subN (Suc a) (Suc b) = subN a b

-- integer addition
zadd :: Z -> Z -> Z
zadd (Pos a) (Pos b) = Pos (addN a b)
zadd (Neg a) (Neg b) = Neg (Suc (addN a b))
zadd (Pos a) (Neg b) = subN a (Suc b)
zadd (Neg a) (Pos b) = subN b (Suc a)

zero :: Z
zero = Pos Zero

one :: Z
one = Pos (Suc Zero)

minusOne :: Z
minusOne = Neg Zero

-- the natural number of a non-negative integer (n >= 0 is checked first)
toNat :: Z -> Nat
toNat (Pos n) = n

fromIntZ :: Int -> Z
fromIntZ n = if n >= 0 then Pos (fromInt n) else Neg (fromInt (negate n - 1))

toIntZ :: Z -> Int
toIntZ (Pos n) = toInt n
toIntZ (Neg n) = negate (toInt n) - 1

instance Arbitrary Z where
  arbitrary = fmap fromIntZ arbitrary
