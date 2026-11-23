module Nat where

import Test.QuickCheck

-- Peano numbers instead of Int: hs2fol keeps Int abstract (no axioms), so
-- arithmetic and comparisons on Int could never be evaluated by a prover.
data Nat = Zero | Suc Nat
  deriving (Eq, Ord, Show)

addN :: Nat -> Nat -> Nat
addN Zero m = m
addN (Suc n) m = Suc (addN n m)

-- length of a list as a Nat
lengthN :: [a] -> Nat
lengthN [] = Zero
lengthN (_ : xs) = Suc (lengthN xs)

-- xs !! n
nth :: [a] -> Nat -> a
nth (x : _) Zero = x
nth (_ : xs) (Suc n) = nth xs n

fromInt :: Int -> Nat
fromInt n = if n <= 0 then Zero else Suc (fromInt (n - 1))

toInt :: Nat -> Int
toInt Zero = 0
toInt (Suc n) = 1 + toInt n

instance Arbitrary Nat where
  arbitrary = sized (\n -> fmap fromInt (choose (0, n)))
  shrink Zero = []
  shrink (Suc n) = [n]
