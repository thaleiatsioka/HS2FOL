module Nat where

-- Peano numbers. Some properties are true, some are false; the prover
-- should find counterexamples for the false ones only.

data Nat = Zero | Suc Nat
  deriving (Eq, Ord, Show)

plus :: Nat -> Nat -> Nat
plus Zero m = m
plus (Suc n) m = Suc (plus n m)

double :: Nat -> Nat
double Zero = Zero
double (Suc n) = Suc (Suc (double n))

half :: Nat -> Nat
half Zero = Zero
half (Suc Zero) = Zero
half (Suc (Suc n)) = Suc (half n)

leq :: Nat -> Nat -> Bool
leq Zero _ = True
leq (Suc _) Zero = False
leq (Suc n) (Suc m) = leq n m

isEven :: Nat -> Bool
isEven n = case n of
  Zero -> True
  Suc m -> not (isEven m)

-- true
prop_plusZero :: Nat -> Bool
prop_plusZero n = plus n Zero == n

-- false: n = Suc _
prop_plusIdem :: Nat -> Bool
prop_plusIdem n = plus n n == n

-- true
prop_halfDouble :: Nat -> Bool
prop_halfDouble n = half (double n) == n

-- false: n = Suc Zero
prop_doubleHalf :: Nat -> Property
prop_doubleHalf n = double (half n) === n

-- false: needs n /= m with leq n m
prop_leqAntisym :: Nat -> Nat -> Property
prop_leqAntisym n m = leq n m ==> n == m

-- true
prop_doubleEven :: Nat -> Bool
prop_doubleEven n = isEven (double n)

-- false: guards and if
prop_maxLeft :: Nat -> Nat -> Bool
prop_maxLeft n m
  | n <= m = max n m == m
  | otherwise = max n m == m
