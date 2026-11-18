-- | Tokeniser and layout algorithm.
module Lexer
  ( Tok (..)
  , Token (..)
  , tokenize
  , showTok
  ) where

import Data.Char
import Data.List (intercalate, isPrefixOf)

data Tok
  = TVarId String
  | TConId String -- ^ possibly qualified (A.B.C)
  | TVarSym String
  | TConSym String
  | TInteger Integer
  | TString String
  | TChar Char
  | TSpecial String -- ^ ( ) [ ] , ; ` { }
  | TReserved String
  | TResOp String
  deriving (Eq, Show)

-- | Virtual tokens inserted by the layout algorithm may have line 0.
data Token = Token { tokLine :: !Int, tokCol :: !Int, tokTok :: Tok }
  deriving (Show)

showTok :: Tok -> String
showTok t = case t of
  TVarId s -> s
  TConId s -> s
  TVarSym s -> s
  TConSym s -> s
  TInteger n -> show n
  TString s -> show s
  TChar c -> show c
  TSpecial s -> s
  TReserved s -> s
  TResOp s -> s

reservedIds :: [String]
reservedIds =
  [ "case", "class", "data", "default", "deriving", "do", "else", "foreign", "if"
  , "import", "in", "infix", "infixl", "infixr", "instance", "let", "module"
  , "newtype", "of", "then", "type", "where", "_" ]

reservedOps :: [String]
reservedOps = ["..", ":", "::", "=", "\\", "|", "<-", "->", "@", "~", "=>"]

isSymChar :: Char -> Bool
isSymChar c = c `elem` "!#$%&*+./<=>?@\\^|-~:"

isIdChar :: Char -> Bool
isIdChar c = isAlphaNum c || c == '_' || c == '\''

tokenize :: String -> Either String [Token]
tokenize src = layout <$> lexer src

posStr :: Int -> Int -> String
posStr l c = "line " ++ show l ++ ", column " ++ show c ++ ": "

symTok :: String -> Tok
symTok w
  | w `elem` reservedOps = TResOp w
  | take 1 w == ":" = TConSym w
  | otherwise = TVarSym w

idTok :: String -> Tok
idTok w = if w `elem` reservedIds then TReserved w else TVarId w

lexer :: String -> Either String [Token]
lexer = go 1 1
  where
    go :: Int -> Int -> String -> Either String [Token]
    go _ _ [] = Right []
    go l c s@(ch : rest)
      | ch == '\n' = go (l + 1) 1 rest
      | ch == '\t' = go l (((c - 1) `div` 8 + 1) * 8 + 1) rest
      | isSpace ch = go l (c + 1) rest
      | "--" `isPrefixOf` s && lineComment s = go l c (dropWhile (/= '\n') s)
      | "{-" `isPrefixOf` s = block l (c + 2) (1 :: Int) (drop 2 s)
      | isLower ch || ch == '_' =
          let (w, r) = span isIdChar s in emit l c (idTok w) (length w) r
      | isUpper ch = qualified l c s
      | isDigit ch =
          let (d, r) = span isDigit s in emit l c (TInteger (read d)) (length d) r
      | ch == '"' = str l c (c + 1) rest ""
      | ch == '\'' = charLit l c rest
      | ch `elem` "()[],;`{}" = emit l c (TSpecial [ch]) 1 rest
      | isSymChar ch =
          let (w, r) = span isSymChar s in emit l c (symTok w) (length w) r
      | otherwise = Left (posStr l c ++ "unexpected character " ++ show ch)

    emit l c t n r = fmap (Token l c t :) (go l (c + n) r)

    lineComment s = case dropWhile (== '-') s of
      (x : _) -> not (isSymChar x)
      [] -> True

    block l c n s
      | n == 0 = go l c s
      | otherwise = case s of
          [] -> Left "unterminated block comment"
          ('-' : '}' : r) -> block l (c + 2) (n - 1) r
          ('{' : '-' : r) -> block l (c + 2) (n + 1) r
          ('\n' : r) -> block (l + 1) 1 n r
          (_ : r) -> block l (c + 1) n r

    -- A.B.C, A.B.f (qualified variable: qualifier dropped), A.B.+ (operator)
    qualified l c s =
      let (segs, r) = conSegs s
          full = intercalate "." segs
          len = length full
      in case r of
           ('.' : x : _)
             | isLower x || x == '_' ->
                 let (w, r') = span isIdChar (drop 1 r)
                 in emit l c (idTok w) (len + 1 + length w) r'
             | isSymChar x ->
                 let (w, r') = span isSymChar (drop 1 r)
                 in emit l c (symTok w) (len + 1 + length w) r'
           _ -> emit l c (TConId full) len r

    conSegs s =
      let (w, r) = span isIdChar s
      in case r of
           ('.' : x : _) | isUpper x -> let (ws, r') = conSegs (drop 1 r) in (w : ws, r')
           _ -> ([w], r)

    str l c0 c r acc = case r of
      [] -> Left (posStr l c0 ++ "unterminated string literal")
      ('"' : r') -> fmap (Token l c0 (TString (reverse acc)) :) (go l (c + 1) r')
      ('\\' : x : r') -> str l c0 (c + 2) r' (escape x : acc)
      ('\n' : _) -> Left (posStr l c0 ++ "unterminated string literal")
      (x : r') -> str l c0 (c + 1) r' (x : acc)

    charLit l c r = case r of
      ('\\' : x : '\'' : r') -> emit l c (TChar (escape x)) 4 r'
      (x : '\'' : r') -> emit l c (TChar x) 3 r'
      _ -> Left (posStr l c ++ "bad character literal")

    escape 'n' = '\n'
    escape 't' = '\t'
    escape x = x

--------------------------------------------------------------------------------
-- Layout (Haskell 2010 report, section 10.3, with an approximation of the
-- parse-error(t) rule: implicit blocks are also closed by `in`, by closing
-- brackets and commas inside brackets, by then/else and by of).

data LItem = LTok Token | LOpen Int Bool | LIndent Int

annotate :: [Token] -> [LItem]
annotate [] = [LOpen 0 False]
annotate ts@(t0 : _) = start ++ go (if hasModule then 0 else tokLine t0) ts
  where
    hasModule = tokTok t0 `elem` [TReserved "module", TSpecial "{"]
    start = if hasModule then [] else [LOpen (tokCol t0) False]
    go _ [] = []
    go prev (t : rest) =
      [ LIndent (tokCol t) | tokLine t > prev ]
        ++ [LTok t]
        ++ opener t rest
        ++ go (tokLine t) rest
    opener t rest
      | tokTok t `elem` map TReserved ["let", "where", "of", "do"] = case rest of
          (n : _)
            | tokTok n == TSpecial "{" -> []
            | otherwise -> [LOpen (tokCol n) (tokTok t == TReserved "let")]
          [] -> [LOpen 0 False]
      | otherwise = []

data Ctx = Implicit Int Bool | Explicit | Marker String

layout :: [Token] -> [Token]
layout ts = run (annotate ts) []
  where
    run :: [LItem] -> [Ctx] -> [Token]
    run [] ctx = [ vt (0, 0) "}" | Implicit _ _ <- ctx ]
    run (LOpen n isLet : LIndent _ : rest) ctx = run (LOpen n isLet : rest) ctx
    run (LOpen n isLet : rest) ctx
      | n > enclosing ctx = vt p "{" : run rest (Implicit n isLet : ctx)
      | otherwise = vt p "{" : vt p "}" : run (LIndent n : rest) ctx
      where
        p = nextPos rest
    run (LIndent n : rest) ctx = case ctx of
      (Implicit m _ : ctx')
        | n == m -> vt p ";" : run rest ctx
        | n < m -> vt p "}" : run (LIndent n : rest) ctx'
      _ -> run rest ctx
      where
        p = nextPos rest
    run (LTok t : rest) ctx = case tokTok t of
      TSpecial "{" -> t : run rest (Explicit : ctx)
      TSpecial "}" -> case ctx of
        (Explicit : ctx') -> t : run rest ctx'
        _ -> t : run rest ctx
      TSpecial s | s == "(" || s == "[" -> t : run rest (Marker s : ctx)
      TSpecial s | s == ")" || s == "]" ->
        let (cs, ctx') = popTo ["(", "["] ctx in cs ++ t : run rest (dropMarker ctx')
      TSpecial "," | markerBelow ["(", "["] ctx ->
        let (cs, ctx') = popTo ["(", "["] ctx in cs ++ t : run rest ctx'
      TReserved "if" -> t : run rest (Marker "if" : ctx)
      TReserved "then" -> let (cs, ctx') = popTo ["if"] ctx in cs ++ t : run rest ctx'
      TReserved "else" -> let (cs, ctx') = popTo ["if"] ctx in cs ++ t : run rest (dropMarker ctx')
      TReserved "case" -> t : run rest (Marker "case" : ctx)
      TReserved "of" -> let (cs, ctx') = popTo ["case"] ctx in cs ++ t : run rest (dropMarker ctx')
      TReserved "in" -> case ctx of
        (Implicit _ True : ctx') -> vt (tokLine t, tokCol t) "}" : t : run rest ctx'
        _ -> t : run rest ctx
      _ -> t : run rest ctx

    vt (l, c) s = Token l c (TSpecial s)

    enclosing (Implicit m _ : _) = m
    enclosing (Marker _ : c) = enclosing c
    enclosing _ = 0

    -- close implicit blocks down to the nearest marker in ms (if there is one)
    popTo ms ctx
      | markerBelow ms ctx = closeImplicit ctx
      | otherwise = ([], ctx)
    closeImplicit (Implicit _ _ : c) = let (cs, r) = closeImplicit c in (vt (0, 0) "}" : cs, r)
    closeImplicit c = ([], c)

    markerBelow ms (Implicit _ _ : c) = markerBelow ms c
    markerBelow ms (Marker m : _) = m `elem` ms
    markerBelow _ _ = False

    dropMarker (Marker _ : c) = c
    dropMarker c = c

    nextPos (LTok t : _) = (tokLine t, tokCol t)
    nextPos (_ : r) = nextPos r
    nextPos [] = (0, 0)
