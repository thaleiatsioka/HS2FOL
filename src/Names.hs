-- | Naming conventions for FOL symbols and variables.
module Names
  ( funFolBase
  , conFolBase
  , sanitize
  , varBase
  , mangleType
  , mangleTycon
  , isOperatorName
  , haskDisplay
  , conDisplay
  ) where

import Data.Char
import Syntax (Type (..), isTupleCon)

isOperatorName :: String -> Bool
isOperatorName s = not (null s) && all (`elem` "!#$%&*+./<=>?@\\^|-~:") s

opTable :: [(String, String)]
opTable =
  [ ("++", "opAppend"), (".", "opCompose"), ("$", "opApply"), ("&&", "opAnd")
  , ("||", "opOr"), ("==", "eq"), ("/=", "neq"), ("<", "lt"), ("<=", "le")
  , (">", "gt"), (">=", "ge"), ("+", "opPlus"), ("-", "opMinus"), ("*", "opTimes")
  , ("!!", "opIndex"), ("==>", "implies"), ("===", "eq") ]

symCharName :: Char -> String
symCharName c = case c of
  '+' -> "Plus"
  '-' -> "Minus"
  '*' -> "Star"
  '/' -> "Slash"
  '<' -> "Lt"
  '>' -> "Gt"
  '=' -> "Eq"
  '&' -> "Amp"
  '|' -> "Bar"
  '.' -> "Dot"
  '!' -> "Bang"
  '$' -> "Dollar"
  '%' -> "Percent"
  '^' -> "Hat"
  '~' -> "Tilde"
  '@' -> "At"
  '#' -> "Hash"
  '?' -> "Q"
  ':' -> "Colon"
  '\\' -> "Backslash"
  _ -> "X"

-- | Desired FOL name of a function (or class method) with this Haskell name.
funFolBase :: String -> String
funFolBase s = case lookup s opTable of
  Just n -> n
  Nothing
    | isOperatorName s -> "op" ++ concatMap symCharName s
    | otherwise -> sanitize s

-- | Desired FOL name of a constructor.
conFolBase :: String -> String
conFolBase c
  | c == "[]" = "nil"
  | c == ":" = "cons"
  | c == "()" = "unit"
  | c == "(,)" = "pair"
  | isTupleCon c = "tuple" ++ show (length c - 1)
  | isOperatorName c = "op" ++ concatMap symCharName c
  | all (\x -> isUpper x || isDigit x || x == '_') c = sanitize (map toLower c)
  | otherwise = case c of
      (x : xs) -> sanitize (toLower x : xs)
      [] -> "c"

-- | A valid TPTP lower word: [a-z][A-Za-z0-9_]*
sanitize :: String -> String
sanitize s =
  let s' = [ if (isAscii x && isAlphaNum x) || x == '_' then x else '_' | x <- s ]
  in case s' of
       (x : rest)
         | isAsciiLower x -> s'
         | isAsciiUpper x -> toLower x : rest
       _ -> "f" ++ s'

-- | A valid TPTP variable name: [A-Z][A-Za-z0-9_]*
varBase :: String -> String
varBase s =
  case [ if (isAscii x && isAlphaNum x) || x == '_' then x else '_' | x <- s ] of
    (x : rest)
      | isAsciiLower x -> toUpper x : rest
      | isAsciiUpper x -> x : rest
    s' -> "V" ++ s'

mangleTycon :: String -> String
mangleTycon c
  | c == "[]" = "List"
  | c == "()" = "Unit"
  | c == "->" = "Fun"
  | c == "(,)" = "Pair"
  | isTupleCon c = "Tuple" ++ show (length c - 1)
  | otherwise = case sanitize c of
      (x : xs) -> toUpper x : xs
      [] -> "T"

mangleType :: Type -> String
mangleType (TCon c ts) = mangleTycon c ++ concatMap mangleType ts
mangleType (TVar _) = "A"

-- | How to show a function name in Haskell syntax (operators in parentheses).
haskDisplay :: String -> String
haskDisplay s = if isOperatorName s then "(" ++ s ++ ")" else s

conDisplay :: String -> String
conDisplay c
  | c == "[]" || c == "()" || isTupleCon c = c
  | isOperatorName c = "(" ++ c ++ ")"
  | otherwise = c
