-- GENERATED from template/STLC.template.hs by ../generate.py; do not edit.
-- Variant: mutant subst_var_all.
-- Simply-typed lambda calculus from Etna (Shi et al., ICFP 2023), workload
-- Haskell/STLC: Impl.hs and Spec.hs ported to the Haskell subset that hs2fol
-- accepts. Upstream: https://github.com/jwshii/etna (see ../README.md).
--
-- The mutants are written as in Etna: {-! -} marks the correct code,
-- {-!! name -} {-! code -} the code of mutant `name`. generate.py writes one
-- file per mutant (STLC_<mutant>.hs) and STLC_base.hs with the correct code.
--
-- Changes from Etna, all semantics-preserving (see ../README.md):
--  * de Bruijn indices are integers built from Peano numbers (Z.hs) instead
--    of Int: n + d is zadd n d, literals 0, 1, -1 are zero, one, minusOne.
--  * length and !! are lengthN and nth on Nat; the fuel of multistep is a Nat
--    (literal pattern 0 becomes Zero, fuel - 1 a Suc pattern).
--  * The Maybe monad is written with case, Just and fmapM instead of do,
--    <$> and return (hs2fol has no constructor classes); the failing pattern
--    bind `TFun t11 t12 <- getTyp ctx e1` becomes a case with a Nothing branch.
--  * Etna's `pre --> post` (discard when pre is false) is QuickCheck's ==>.
module STLC_subst_var_all where

import Test.QuickCheck
import Data.Maybe (fromMaybe)
import Nat
import Z

data Typ
  = TBool
  | TFun Typ Typ
  deriving (Eq, Ord, Show)

data Expr
  = Var Z
  | Bool Bool
  | Abs Typ Expr
  | App Expr Expr
  deriving (Eq, Ord, Show)

type Ctx = [Typ]

fmapM :: (a -> b) -> Maybe a -> Maybe b
fmapM _ Nothing = Nothing
fmapM f (Just a) = Just (f a)

isJust :: Maybe a -> Bool
isJust (Just _) = True
isJust Nothing = False

fromJust :: Maybe a -> a
fromJust (Just a) = a

------------------------------------------------------------------------
-- Impl.hs

typeCheck :: Ctx -> Expr -> Typ -> Bool
typeCheck ctx e t =
  case getTyp ctx e of
    Just t' -> t == t'
    Nothing -> False

getTyp :: Ctx -> Expr -> Maybe Typ
getTyp ctx (Var n)
  | n >= zero && n < Pos (lengthN ctx) = Just (nth ctx (toNat n))
  | otherwise = Nothing
getTyp _ (Bool _) = Just TBool
getTyp ctx (Abs t e) =
  case getTyp (t : ctx) e of
    Just t' -> Just (TFun t t')
    Nothing -> Nothing
getTyp ctx (App e1 e2) =
  case getTyp ctx e1 of
    Just (TFun t11 t12) ->
      case getTyp ctx e2 of
        Just t2 -> if t11 == t2 then Just t12 else Nothing
        Nothing -> Nothing
    Just TBool -> Nothing
    Nothing -> Nothing

shift :: Z -> Expr -> Expr
shift d = go zero
  where
    go c (Var n)
      | n < c = Var n
      | otherwise = Var (zadd n d)
    go _ (Bool b) = Bool b
    go c (Abs t e) =
      Abs t (go (zadd c one) e)
    go c (App e1 e2) = App (go c e1) (go c e2)

-- [n -> s]e
subst :: Z -> Expr -> Expr -> Expr
subst n s (Var m)
  = s
subst _ _ (Bool b) = Bool b
subst n s (Abs t e) =
  Abs t (subst (zadd n one) (shift one s) e)
subst n s (App e1 e2) = App (subst n s e1) (subst n s e2)

-- [0 -> s]e
substTop :: Expr -> Expr -> Expr
substTop s e =
  shift minusOne (subst zero (shift one s) e)

pstep :: Expr -> Maybe Expr
pstep (Abs t e) = fmapM (Abs t) (pstep e)
pstep (App (Abs _ e1) e2) =
  let e1' = fromMaybe e1 (pstep e1)
      e2' = fromMaybe e2 (pstep e2)
   in Just (substTop e2' e1')
pstep (App e1 e2) =
  case (pstep e1, pstep e2) of
    (Nothing, Nothing) -> Nothing
    (me1, me2) ->
      let e1' = fromMaybe e1 me1
          e2' = fromMaybe e2 me2
       in Just (App e1' e2')
pstep _ = Nothing

multistep :: Nat -> (Expr -> Maybe Expr) -> Expr -> Maybe Expr
multistep Zero _ _ = Nothing
multistep (Suc fuel) step e =
  case step e of
    Nothing -> Just e
    Just e' -> multistep fuel step e'

------------------------------------------------------------------------
-- Spec.hs

prop_SinglePreserve :: Expr -> Property
prop_SinglePreserve e =
  isJust mt ==> mtypeCheck (pstep e) (fromJust mt)
  where
    mt = getTyp [] e

prop_MultiPreserve :: Expr -> Property
prop_MultiPreserve e =
  isJust mt ==> mtypeCheck (multistep fuel40 pstep e) (fromJust mt)
  where
    mt = getTyp [] e

mtypeCheck :: Maybe Expr -> Typ -> Bool
mtypeCheck (Just e) t = typeCheck [] e t
mtypeCheck Nothing _ = True

-- the literal 40
fuel40 :: Nat
fuel40 = Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Suc (Zero))))))))))))))))))))))))))))))))))))))))

------------------------------------------------------------------------
-- QuickCheck generators (Etna's Strategy/Correct.hs); hs2fol skips these.

instance Arbitrary Typ where
  arbitrary = sized go
    where
      go 0 = return TBool
      go n =
        oneof
          [ go 0,
            TFun <$> go (n `div` 2) <*> go (n `div` 2)
          ]

instance Arbitrary Expr where
  arbitrary = do
    t <- (arbitrary :: Gen Typ)
    genExactExpr [] t

genExactExpr :: Ctx -> Typ -> Gen Expr
genExactExpr ctx0 t0 = sized $ \n0 -> go n0 ctx0 t0
  where
    go :: Int -> Ctx -> Typ -> Gen Expr
    go 0 ctx t = oneof $ genOne ctx t : genVar ctx t
    go n ctx t =
      oneof
        ( [genOne ctx t]
            ++ [genAbs ctx t1 t2 | TFun t1 t2 <- [t]]
            ++ [genApp ctx t]
            ++ genVar ctx t
        )
      where
        genAbs ctx' t1 t2 = Abs t1 <$> go (n - 1) (t1 : ctx') t2

        genApp ctx' t' = do
          t'' <- arbitrary
          e1 <- go (n `div` 2) ctx' (TFun t'' t')
          e2 <- go (n `div` 2) ctx' t''
          return (App e1 e2)

    genOne _ TBool = Bool <$> arbitrary
    genOne ctx (TFun t1 t2) = Abs t1 <$> genOne (t1 : ctx) t2

    genVar :: Ctx -> Typ -> [Gen Expr]
    genVar ctx t = [Var . fromIntZ <$> elements vars | not (null vars)]
      where
        vars = filter (\i -> ctx !! i == t) (indices (length ctx))

-- [0 .. n - 1]
indices :: Int -> [Int]
indices n = if n <= 0 then [] else indices (n - 1) ++ [n - 1]
