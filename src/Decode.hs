-- | Read a prover's answer (TPTP terms) and print it as Haskell.
module Decode
  ( decodeAnswer
  , extractWitnesses
  , decodeArgs
  , VarMode (..)
  , PT (..)
  , normaliseWitness
  ) where

import Data.Char (isAlphaNum, isDigit, isLower, isSpace, isUpper, toLower)
import Data.List (intercalate, isInfixOf, isPrefixOf, tails)
import qualified Data.Map as M
import FOL
import Lift (FunInfo (..), FunKind (..))
import Names
import Rewrite (normalise)
import Syntax
import Text.Parsec
import Text.Parsec.String (Parser)
import Translate

data PT = PV String | PF String [PT]

-- | How to print variables of an answer: as named holes (_X), or as
-- 'undefined' (any value works, so this is a valid concrete input).
data VarMode = VarsAsHoles | VarsAsUndefined
  deriving (Eq)

-- | Find the witnesses (argument tuples) in prover output:
--
-- * Vampire and E: a line @SZS answers Tuple [[t1,...,tn],...|_]@;
-- * Twee: the block after a line containing "goal is true when", with
--   lines @Xi = t@ (variables of the conjecture are X1..Xn);
-- * otherwise the whole input is read as comma-separated TPTP terms.
extractWitnesses :: Int -> String -> Either String [[PT]]
extractWitnesses arity input =
  case [ l | l <- lines input, "SZS answers Tuple" `isInfixOf` l ] of
    (l : _) -> parseAnswers (afterTuple l)
    [] -> case break isGoalTrue (lines input) of
      (before, _ : rest) -> do
        let block = takeWhile (not . all isSpace) (dropWhile (all isSpace) rest)
        binds <- mapM parseBinding block
        -- Twee renames the conjecture's variables; their order is given by
        -- the restated goal "Goal 1 (name): prop(X, Y) = false."
        let names = case [ vs | l <- reverse before, Just vs <- [goalVars l] ] of
              (vs : _) | length vs == arity -> vs
              _ -> [ "X" ++ show i | i <- [1 .. arity] ]
        return [[ maybe (PV v) id (lookup v binds) | v <- names ]]
      (_, []) | arity == 0 -> Right [[]]
              | otherwise -> fmap (: []) (parseTerms input)
  where
    afterTuple l = case [ rest | rest <- tails l, take 5 rest == "Tuple" ] of
      (r : _) -> drop 5 r
      [] -> l
    isGoalTrue l = "goal is true when" `isInfixOf` map toLower l
    goalVars l
      | "Goal " `isPrefixOf` dropWhile isSpace l =
          case [ drop 3 r | r <- tails l, take 3 r == "): " ] of
            (t : _) -> case parse (spaces *> term) "twee goal" t of
              Right (PF _ args) | all isVar args -> Just [ v | PV v <- args ]
              _ -> Nothing
            [] -> Nothing
      | otherwise = Nothing
    isVar (PV _) = True
    isVar _ = False
    parseBinding l = either (Left . show) Right (parse binding "twee answer" l)
    binding = do
      spaces
      v <- many1 (satisfy (\c -> isAlphaNum c || c == '_'))
      spaces
      _ <- char '='
      spaces
      t <- term
      return (v, t)

-- | Evaluate each witness term with the program's equations, so that it no
-- longer mentions auxiliary functions (normal forms are usually constructor
-- terms). Terms with symbols that are not in the translation are kept.
normaliseWitness :: Translation -> [PT] -> [PT]
normaliseWitness tr = map norm
  where
    inverse = M.fromList [ (v, k) | (k, v) <- M.toList (trNames tr) ]
    norm pt = maybe pt (fromTerm . normalise 100000 (trEqns tr)) (toTerm pt)
    toTerm (PV v) = Just (TV (Name v (-2)))
    toTerm (PF n args) = do
      s <- M.lookup n inverse
      TF s <$> mapM toTerm args
    fromTerm (TV v) = PV (nameBase v)
    fromTerm (TF s args) = PF (M.findWithDefault "unknown" s (trNames tr)) (map fromTerm args)

-- | Decode one witness into Haskell expressions (one per argument, each
-- parenthesised if needed).
decodeArgs :: VarMode -> Translation -> [PT] -> Either String [String]
decodeArgs mode tr ts = map atomS <$> mapM (decodeTerm mode tr 0) ts

-- | Decode the prover output for a property. Returns lines to print.
decodeAnswer :: Translation -> Maybe PropSpec -> String -> Either String [String]
decodeAnswer tr mprop input = do
  tuples <- extractWitnesses (maybe 0 psArity mprop) input
  case tuples of
    [] -> Left "no answer found"
    _ -> mapM decodeTuple tuples
  where
    decodeTuple ts = do
      args <- unwords <$> decodeArgs VarsAsHoles tr ts
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
    -- Vampire writes tuples with free variables as  ∀X0,X1.[t1,...,tn]
    tuple = do
      optional (do _ <- (char '\8704' <|> char '!') <* spaces
                   _ <- many1 (satisfy (\c -> isAlphaNum c || c == '_')) `sepBy1` symbol ","
                   symbol ".")
      between (symbol "[") (symbol "]") (term `sepBy` symbol ",")

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

decodeTerm :: VarMode -> Translation -> Int -> PT -> Either String HS
decodeTerm mode tr depth t = case t of
  PV v
    | mode == VarsAsUndefined -> Right (HS "undefined" True)
    | otherwise -> Right (HS ("_" ++ v) True)
  PF n args -> case M.lookup n inverse of
    Nothing
      | all isDigit n -> Right (HS n True)
      | otherwise -> Left ("unknown symbol " ++ n ++ " in answer")
    Just s -> do
      as <- mapM (decodeTerm mode tr (depth + 1)) args
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
          case mapM (decodeTerm mode tr (depth + 1)) rest of
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
