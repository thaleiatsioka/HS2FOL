-- | Read a prover's answer (TPTP terms) and print it as Haskell.
module Decode (decodeAnswer) where

import Data.Char (isAlphaNum, isDigit, isLower, isUpper)
import Data.List (intercalate, isInfixOf, tails)
import qualified Data.Map as M
import FOL
import Lift (FunInfo (..), FunKind (..))
import Names
import Syntax
import Text.Parsec
import Text.Parsec.String (Parser)
import Translate

data PT = PV String | PF String [PT]

-- | Decode the prover output for a property. Returns lines to print.
decodeAnswer :: Translation -> Maybe PropSpec -> String -> Either String [String]
decodeAnswer tr mprop input = do
  tuples <- case [ l | l <- lines input, "SZS answers Tuple" `isInfixOf` l ] of
    (l : _) -> parseAnswers (afterTuple l)
    [] -> fmap (: []) (parseTerms input)
  case tuples of
    [] -> Left "no answer found"
    _ -> mapM decodeTuple tuples
  where
    afterTuple l = case [ rest | rest <- tails l, take 5 rest == "Tuple" ] of
      (r : _) -> drop 5 r
      [] -> l
    decodeTuple ts = do
      hs <- mapM (decodeTerm tr 0) ts
      let args = unwords (map atomS hs)
      return $ case mprop of
        Just p -> psName p ++ (if null args then "" else " " ++ args) ++ "   -- evaluates to False"
        Nothing -> args

parseAnswers :: String -> Either String [[PT]]
parseAnswers s = either (Left . show) Right (parse answers "answer" s)
  where
    answers = do
      spaces
      _ <- char '['
      ts <- tuple `sepBy` symbol ","
      return ts
    tuple = between (symbol "[") (symbol "]") (term `sepBy` symbol ",")

parseTerms :: String -> Either String [PT]
parseTerms s = either (Left . show) Right (parse (spaces *> (term `sepBy` symbol ",") <* eof) "answer" s)

symbol :: String -> Parser String
symbol x = string x <* spaces

term :: Parser PT
term = do
  n <- name
  if isUpper (head n) || head n == '_'
    then return (PV n)
    else do
      args <- option [] (between (symbol "(") (symbol ")") (term `sepBy` symbol ","))
      return (PF n args)
  where
    name = (many1 (satisfy (\c -> isAlphaNum c || c == '_')) <* spaces) <?> "name"

--------------------------------------------------------------------------------

-- | A Haskell expression and whether it is atomic.
data HS = HS String Bool

atomS :: HS -> String
atomS (HS s True) = s
atomS (HS s False) = "(" ++ s ++ ")"

applyHS :: String -> [HS] -> HS
applyHS f [] = HS f True
applyHS f as = HS (unwords (f : map atomS as)) False

decodeTerm :: Translation -> Int -> PT -> Either String HS
decodeTerm tr depth t = case t of
  PV v -> Right (HS ("_" ++ v) True)
  PF n args -> case M.lookup n inverse of
    Nothing
      | all isDigit n -> Right (HS n True)
      | otherwise -> Left ("unknown symbol " ++ n ++ " in answer")
    Just s -> do
      as <- mapM (decodeTerm tr (depth + 1)) args
      sym s as args
  where
    inverse = M.fromList [ (v, k) | (k, v) <- M.toList (trNames tr) ]
    funs = trFuns tr
    sym s as args = case s of
      SCon c -> Right (con c as args)
      SFun k -> Right (applyHS (funDisplay funs k) as)
      SClo (ToCon c) _ -> Right (applyHS (conDisplay c) as)
      SClo (ToFun k) j -> case M.lookup k funs of
        Just (FunInfo _ _ _ (KLambda nfv fvs e)) | j >= nfv ->
          let sub = M.fromList (zip fvs (map atomS (take nfv as)))
              lam = HS (ppCore funs sub e) False
          in Right (if j == nfv then lam else applyHS (atomS lam) (drop nfv as))
        _ -> Right (applyHS (funDisplay funs k) as)
      SLit n -> Right (HS (show n) True)
      SApp -> case as of
        [f, x] -> Right (HS (atomS f ++ " " ++ atomS x) False)
        _ -> Left "malformed app"
      SFnConst -> case as of
        [y] -> Right (HS ("\\_ -> " ++ atomS y) False)
        _ -> Left "malformed fn_const"
      SFnId -> Right (HS "\\x -> x" False)
      SFnCase tc -> Right (fnCase tc as)
    fnCase tc as =
      let x = "x" ++ show depth
          conList = [ (c, conArity ci) | (c, ci) <- M.toList (trCons tr), conData ci == tc ]
          ordered = map snd (M.toList (M.fromList [ (conIndex (trCons tr M.! c), (c, a)) | (c, a) <- conList ]))
          alt ((c, a), r) =
            let vs = [ "y" ++ show depth ++ "_" ++ show i | i <- [1 .. a] ]
                lhs = unwords (conDisplay c : vs)
                rhs = if null vs then atomS r else unwords (atomS r : vs)
            in lhs ++ " -> " ++ rhs
      in HS ("\\" ++ x ++ " -> case " ++ x ++ " of { " ++ intercalate "; " (map alt (zip ordered as)) ++ " }") False
    con c as args
      | c == ":" , [h, tl] <- as, Just rest <- listElems (args !! 1) =
          case mapM (decodeTerm tr (depth + 1)) rest of
            Right rs -> HS ("[" ++ intercalate ", " (map plain (h : rs)) ++ "]") True
            Left _ -> HS (atomS h ++ " : " ++ atomS tl) False
      | c == ":", [h, tl] <- as = HS (atomS h ++ " : " ++ atomS tl) False
      | isTupleCon c && length as == length c - 1 = HS ("(" ++ intercalate ", " (map plain as) ++ ")") True
      | isOperatorName c, [a, b] <- as = HS (atomS a ++ " " ++ c ++ " " ++ atomS b) False
      | otherwise = applyHS (conDisplay c) as
    plain (HS s _) = s
    -- elements of a cons-list term ending in nil
    listElems (PF n xs) = case M.lookup n inverse of
      Just (SCon "[]") | null xs -> Just []
      Just (SCon ":") | [h, tl] <- xs -> (h :) <$> listElems tl
      _ -> Nothing
    listElems _ = Nothing

-- | Pretty-print a core expression as Haskell (used for lambdas in answers).
ppCore :: M.Map String FunInfo -> M.Map Name String -> CExpr -> String
ppCore funs sub = go (0 :: Int)
  where
    go p e = case e of
      CVar n _
        | isGlobal n -> funDisplay funs (nameBase n)
        | otherwise -> M.findWithDefault (local n) n sub
      CCon c -> conDisplay c
      CLit n -> show n
      CApp _ _ ->
        let (h, as) = collectApps e
        in paren (p > 1) (unwords (go 2 h : map (go 2) as))
      CLam _ _ ->
        let (xs, b) = collectLams e
        in paren (p > 0) ("\\" ++ unwords (map local xs) ++ " -> " ++ go 0 b)
      CLet bs b -> paren (p > 0) ("let { " ++ intercalate "; " [ local n ++ " = " ++ go 0 r | (n, r) <- bs ] ++ " } in " ++ go 0 b)
      CCase s alts -> paren (p > 0) ("case " ++ go 0 s ++ " of { "
        ++ intercalate "; " [ unwords (conDisplay c : map local xs) ++ " -> " ++ go 0 r | CAlt c xs r <- alts ] ++ " }")
      CFail -> "undefined"
      CFallthrough -> "undefined"
      CTyped x _ -> go p x
    paren b s = if b then "(" ++ s ++ ")" else s
    local n =
      let b = nameBase n
      in if not (null b) && all (\c -> isAlphaNum c || c == '_' || c == '\'') b && (isLower (head b) || head b == '_')
           then b
           else "v" ++ show (nameId n)
