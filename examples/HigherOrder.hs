module HigherOrder where

import Nat

-- Properties with function arguments: the prover has to construct a
-- function (from fn_const, fn_id and fn_case_T) as part of the answer.

-- false: f = const Zero
prop_fnSuc :: (Nat -> Nat) -> Nat -> Bool
prop_fnSuc f n = f (Suc n) == Suc (f n)

-- false: map and filter do not commute in general
prop_mapFilter :: (Nat -> Nat) -> (Nat -> Bool) -> [Nat] -> Bool
prop_mapFilter f p xs = map f (filter p xs) == filter p (map f xs)

-- true
prop_mapCompose :: (Nat -> Nat) -> (Nat -> Nat) -> [Nat] -> Bool
prop_mapCompose f g xs = map (f . g) xs == map f (map g xs)

-- false: twice f is not f
prop_twice :: (Nat -> Nat) -> Nat -> Property
prop_twice f n = f (f n) === f n
