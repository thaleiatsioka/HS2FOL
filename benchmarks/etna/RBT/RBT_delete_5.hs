-- GENERATED from template/RBT.template.hs by ../generate.py; do not edit.
-- Variant: mutant delete_5.
-- Red-black trees from Etna (Shi et al., ICFP 2023), workload Haskell/RBT:
-- Impl.hs and Spec.hs ported to the Haskell subset that hs2fol accepts.
-- Upstream: https://github.com/jwshii/etna (see ../README.md for the commit).
--
-- The mutants are written as in Etna: {-! -} marks the correct code,
-- {-!! name -} {-! code -} the code of mutant `name`. generate.py writes one
-- file per mutant (RBT_<mutant>.hs) and RBT_base.hs with the correct code.
--
-- Changes from Etna, all semantics-preserving (see ../README.md):
--  * Keys are Nat instead of Int (only compared, so any counterexample over
--    Int has an order-isomorphic one over Nat); black heights are Nat.
--  * The Either monad is written with bindE/fmapE/Right instead of do,
--    <$>, =<< and return (hs2fol has no constructor classes).
--  * Properties take curried arguments instead of a tuple, and Etna's
--    `pre --> post` (discard when pre is false) is QuickCheck's `pre ==> post`.
--  * Mutant no_balance_insert_2 calls `insert` (which returns an Either)
--    inside a tree, which does not type-check; it calls `ins` here.
module RBT_delete_5 where

import Test.QuickCheck
import Nat

data Color = R | B
  deriving (Eq, Ord, Show)

data Tree k v
  = E
  | T Color (Tree k v) k v (Tree k v)
  deriving (Eq, Ord, Show)

data Error = IE -- invariant error
  deriving (Eq, Ord, Show)

-- The Either monad, monomorphically.
bindE :: Either e a -> (a -> Either e b) -> Either e b
bindE (Left e) _ = Left e
bindE (Right a) f = f a

fmapE :: (a -> b) -> Either e a -> Either e b
fmapE _ (Left e) = Left e
fmapE f (Right a) = Right (f a)

fromRight :: b -> Either a b -> b
fromRight _ (Right b) = b
fromRight d (Left _) = d

------------------------------------------------------------------------
-- Impl.hs

insert :: Ord k => k -> v -> Tree k v -> Either Error (Tree k v)
insert x vx s = Right (blacken (ins x vx s))
  where
    ins x vx E =
      T R E x vx E
    ins x vx (T rb a y vy b)
      | x < y = balance rb (ins x vx a) y vy b
      | x > y = balance rb a y vy (ins x vx b)
      | otherwise = T rb a y vx b

delete :: Ord k => k -> Tree k v -> Either Error (Tree k v)
delete x t =
  fmapE blacken (del t)
  where
    del E = Right E
    del (T _ a y vy b)
      | x > y = delLeft a y vy b
      | x < y = delRight a y vy b
      | otherwise = join a b

    delLeft a@(T B _ _ _ _) y vy b = bindE (del a) (\a' -> balLeft a' y vy b)
    delLeft a y vy b = bindE (del a) (\a' -> Right (T R a' y vy b))

    delRight a y vy b@(T B _ _ _ _) = bindE (del b) (balRight a y vy)
    delRight a y vy b = fmapE (T R a y vy) (del b)

balLeft :: Tree k v -> k -> v -> Tree k v -> Either Error (Tree k v)
balLeft (T R a x vx b) y vy c = Right (T R (T B a x vx b) y vy c)
balLeft bl x vx (T B a y vy b) = Right (balance B bl x vx (T R a y vy b))
balLeft bl x vx (T R (T B a y vy b) z vz c) =
  bindE (redden c) (\c' -> Right (T R (T B bl x vx a) y vy (balance B b z vz c')))
balLeft _ _ _ _ = Left IE

balRight :: Tree k v -> k -> v -> Tree k v -> Either Error (Tree k v)
balRight a x vx (T R b y vy c) = Right (T R a x vx (T B b y vy c))
balRight (T B a x vx b) y vy bl = Right (balance B (T R a x vx b) y vy bl)
balRight (T R a x vx (T B b y vy c)) z vz bl =
  bindE (redden a) (\a' -> Right (T R (balance B a' x vx b) y vy (T B c z vz bl)))
balRight _ _ _ _ = Left IE

join :: Tree k v -> Tree k v -> Either Error (Tree k v)
join E a = Right a
join a E = Right a
join (T R a x vx b) (T R c y vy d) =
  bindE (join b c) (\t' ->
    case t' of
      T R b' z vz c' ->
        Right (T R (T R a x vx b') z vz (T R c' y vy d))
      bc -> Right (T R a x vx (T R bc y vy d)))
join (T B a x vx b) (T B c y vy d) =
  bindE (join b c) (\t' ->
    case t' of
      T R b' z vz c' ->
        Right (T R (T B a x vx b') z vz (T B c' y vy d))
      bc -> balLeft a x vx (T B bc y vy d))
join a (T R b x vx c) = bindE (join a b) (\t' -> Right (T R t' x vx c))
join (T R a x vx b) c = fmapE (T R a x vx) (join b c)

blacken :: Tree k v -> Tree k v
blacken E = E
blacken (T _ a x vx b) = T B a x vx b

redden :: Tree k v -> Either Error (Tree k v)
redden (T B a x vx b) = Right (T R a x vx b)
redden _ = Left IE

balance :: Color -> Tree k v -> k -> v -> Tree k v -> Tree k v
balance B (T R (T R a x vx b) y vy c) z vz d = T R (T B a x vx b) y vy (T B c z vz d)
balance B (T R a x vx (T R b y vy c)) z vz d = T R (T B a x vx b) y vy (T B c z vz d)
balance B a x vx (T R (T R b y vy c) z vz d) = T R (T B a x vx b) y vy (T B c z vz d)
balance B a x vx (T R b y vy (T R c z vz d)) = T R (T B a x vx b) y vy (T B c z vz d)
balance rb a x vx b = T rb a x vx b

------------------------------------------------------------------------
-- Spec.hs

isRBT :: Ord k => Tree k v -> Bool
isRBT t = isBST t && consistentBlackHeight t && noRedRed t && blackRoot t

isBST :: Ord k => Tree k v -> Bool
isBST E = True
isBST (T _ a x _ b) =
  every (< x) a && every (> x) b && isBST a && isBST b
  where
    every p E = True
    every p (T _ a x _ b) = p x && every p a && every p b

-- "No red node has a red parent."
noRedRed :: Tree k v -> Bool
noRedRed E = True
noRedRed (T B a _ _ b) = noRedRed a && noRedRed b
noRedRed (T R a _ _ b) = blackRoot a && blackRoot b && noRedRed a && noRedRed b
  where
    blackRoot (T R _ _ _ _) = False
    blackRoot _ = True

-- "Every path from the root to an empty node contains the same number of black nodes."
consistentBlackHeight :: Tree k v -> Bool
consistentBlackHeight = fst . go
  where
    go E = (True, Suc Zero)
    go (T rb a x _ b) =
      (aBool && bBool && aHeight == bHeight, addN aHeight (isBlack rb))
      where
        (aBool, aHeight) = go a
        (bBool, bHeight) = go b

        isBlack R = Zero
        isBlack B = Suc Zero

blackRoot :: Tree k v -> Bool
blackRoot E = True
blackRoot (T B _ _ _ _) = True
blackRoot _ = False

toList :: Tree k v -> [(k, v)]
toList E = []
toList (T _ l k v r) =
  toList l ++ [(k, v)] ++ toList r

find :: Ord k => k -> Tree k v -> Maybe v
find _ E = Nothing
find x (T _ l y vy r)
  | x < y = find x l
  | x > y = find x r
  | otherwise = Just vy

newtype Key = Key Nat
  deriving (Eq, Ord, Show)

newtype Val = Val Bool
  deriving (Eq, Ord, Show)

type RBT = Tree Key Val

-- Validity properties.

prop_InsertValid :: RBT -> Key -> Val -> Property
prop_InsertValid t k v =
  isRBT t ==> fromRight False (fmapE isRBT (insert k v t))

prop_DeleteValid :: RBT -> Key -> Property
prop_DeleteValid t k =
  isRBT t ==> fromRight False (fmapE isRBT (delete k t))

-- Postcondition properties.

prop_InsertPost :: RBT -> Key -> Key -> Val -> Property
prop_InsertPost t k k' v =
  isRBT t
    ==> fmapE (find k') (insert k v t)
    == Right (if k == k' then Just v else find k' t)

prop_DeletePost :: RBT -> Key -> Key -> Property
prop_DeletePost t k k' =
  isRBT t
    ==> fmapE (find k') (delete k t)
    == Right (if k == k' then Nothing else find k' t)

-- Model-based properties.

prop_InsertModel :: RBT -> Key -> Val -> Property
prop_InsertModel t k v =
  isRBT t
    ==> fmapE toList (insert k v t)
    == Right (insertL (k, v) (deleteKey k (toList t)))

prop_DeleteModel :: RBT -> Key -> Property
prop_DeleteModel t k =
  isRBT t
    ==> fmapE toList (delete k t)
    == Right (deleteKey k (toList t))

deleteKey :: Ord k => k -> [(k, v)] -> [(k, v)]
deleteKey k = filter ((/= k) . fst)

-- Data.List.insert
insertL :: Ord a => a -> [a] -> [a]
insertL x [] = [x]
insertL x (y : ys) = if x <= y then x : y : ys else y : insertL x ys

-- Metamorphic properties.

prop_InsertInsert :: RBT -> Key -> Key -> Val -> Val -> Property
prop_InsertInsert t k k' v v' =
  isRBT t
    ==> bindE (insert k' v' t) (insert k v)
    =~= (if k == k' then insert k v t else bindE (insert k v t) (insert k' v'))

prop_InsertDelete :: RBT -> Key -> Key -> Val -> Property
prop_InsertDelete t k k' v =
  isRBT t
    ==> bindE (delete k' t) (insert k v)
    =~= (if k == k' then insert k v t else bindE (insert k v t) (delete k'))

prop_DeleteInsert :: RBT -> Key -> Key -> Val -> Property
prop_DeleteInsert t k k' v' =
  isRBT t
    ==> bindE (insert k' v' t) (delete k)
    =~= (if k == k' then delete k t else bindE (delete k t) (insert k' v'))

prop_DeleteDelete :: RBT -> Key -> Key -> Property
prop_DeleteDelete t k k' =
  isRBT t
    ==> bindE (delete k' t) (delete k)
    =~= bindE (delete k t) (delete k')

(=~=) :: Either Error (Tree Key Val) -> Either Error (Tree Key Val) -> Bool
(Right t1) =~= (Right t2) = toList t1 == toList t2
_ =~= _ = False

------------------------------------------------------------------------
-- QuickCheck generators (Etna's Strategy/Correct.hs); hs2fol skips these.

instance Arbitrary Key where
  arbitrary = fmap Key arbitrary

instance Arbitrary Val where
  arbitrary = fmap Val arbitrary

-- Trees built by inserting random keys with the correct insert.
instance (Ord k, Arbitrary k, Arbitrary v) => Arbitrary (Tree k v) where
  arbitrary = fmap genTree arbitrary

genTree :: Ord k => [(k, v)] -> Tree k v
genTree = foldr (\(k, v) t -> genInsert k v t) E

genInsert :: Ord k => k -> v -> Tree k v -> Tree k v
genInsert k vk s = genBlacken (ins k vk s)
  where
    ins x vx E = T R E x vx E
    ins x vx (T rb a y vy b)
      | x < y = genBalance rb (ins x vx a) y vy b
      | x > y = genBalance rb a y vy (ins x vx b)
      | otherwise = T rb a y vx b

genBlacken :: Tree k v -> Tree k v
genBlacken E = E
genBlacken (T _ a k v b) = T B a k v b

genBalance :: Color -> Tree k v -> k -> v -> Tree k v -> Tree k v
genBalance B (T R (T R a x vx b) y vy c) z vz d = T R (T B a x vx b) y vy (T B c z vz d)
genBalance B (T R a x vx (T R b y vy c)) z vz d = T R (T B a x vx b) y vy (T B c z vz d)
genBalance B a x vx (T R (T R b y vy c) z vz d) = T R (T B a x vx b) y vy (T B c z vz d)
genBalance B a x vx (T R b y vy (T R c z vz d)) = T R (T B a x vx b) y vy (T B c z vz d)
genBalance rb a x vx b = T rb a x vx b
