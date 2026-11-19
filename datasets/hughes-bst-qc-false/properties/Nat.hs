module Nat where

import Test.QuickCheck

-- Keys and values are Peano numbers instead of Int/Integer: hs2fol keeps Int
-- abstract, so with Int keys every key comparison would be an uninterpreted
-- symbol and no counterexample could be found.
data Nat = Zero | Suc Nat
  deriving (Eq, Ord, Show)

fromInt :: Int -> Nat
fromInt n = if n <= 0 then Zero else Suc (fromInt (n - 1))

instance Arbitrary Nat where
  arbitrary = sized (\n -> fmap fromInt (choose (0, n)))
  shrink Zero = []
  shrink (Suc n) = [n]
