-- | Parser for the supported Haskell subset (Parsec over layout-processed
-- tokens).
module Parser (parseModule) where

import Control.Monad (when)
import Text.Parsec
import Text.Parsec.Pos (newPos)
import Lexer
import Syntax

type P a = Parsec [Token] () a

-- | Parse a module; returns its imports and its other declarations.
parseModule :: FilePath -> String -> Either String ([Ident], [Decl])
parseModule fp src = do
  toks <- either (\e -> Left (fp ++ ": " ++ e)) Right (tokenize src)
  let real = [ t | t <- toks, tokLine t > 0 ]
      setStart = case real of
        (t : _) -> setPosition (newPos fp (tokLine t) (tokCol t))
        [] -> return ()
  case runParser (setStart >> pModule) () fp toks of
    Left err -> Left (show err)
    Right ds -> Right ([ m | DImport m <- ds ], filter (not . isImport) ds)
  where
    isImport (DImport _) = True
    isImport _ = False

--------------------------------------------------------------------------------
-- Token primitives

tokP :: (Tok -> Maybe a) -> P a
tokP f = tokenPrim (showTok . tokTok) next (f . tokTok)
  where
    next pos _ rest = case rest of
      (t : _) | tokLine t > 0 -> setSourceColumn (setSourceLine pos (tokLine t)) (tokCol t)
      _ -> pos

is :: Tok -> P ()
is t = tokP (\t' -> if t' == t then Just () else Nothing)

special :: String -> P ()
special s = is (TSpecial s) <?> show s

reserved :: String -> P ()
reserved s = is (TReserved s) <?> show s

resOp :: String -> P ()
resOp s = is (TResOp s) <?> show s

kw :: String -> P ()
kw s = is (TVarId s) <?> show s

varId :: P Ident
varId = tokP (\t -> case t of TVarId v -> Just v; _ -> Nothing) <?> "variable"

conId :: P Ident
conId = tokP (\t -> case t of TConId c -> Just (unqual c); _ -> Nothing) <?> "constructor"
  where
    unqual c = reverse (takeWhile (/= '.') (reverse c))

modId :: P Ident
modId = tokP (\t -> case t of TConId c -> Just c; _ -> Nothing) <?> "module name"

varSym :: P Ident
varSym = tokP (\t -> case t of TVarSym s -> Just s; _ -> Nothing) <?> "operator"

conSym :: P Ident
conSym = tokP f <?> "constructor operator"
  where
    f (TConSym s) = Just s
    f (TResOp ":") = Just ":"
    f _ = Nothing

integer :: P Integer
integer = tokP (\t -> case t of TInteger n -> Just n; _ -> Nothing) <?> "integer"

stringLit :: P String
stringLit = tokP (\t -> case t of TString s -> Just s; _ -> Nothing) <?> "string"

charLit :: P Char
charLit = tokP (\t -> case t of TChar c -> Just c; _ -> Nothing) <?> "character"

minusTok :: P ()
minusTok = is (TVarSym "-")

anyTok :: P Tok
anyTok = tokP Just

parens :: P a -> P a
parens = between (special "(") (special ")")

braces :: P a -> P a
braces = between (special "{") (special "}")

backticks :: P a -> P a
backticks = between (special "`") (special "`")

comma :: P ()
comma = special ","

-- | A layout block: { item ; item ; ... }
block :: P a -> P [a]
block p = do
  special "{"
  xs <- items
  special "}"
  return xs
  where
    items = do
      skipMany (special ";")
      option [] $ do
        x <- p
        rest <- (special ";" >> items) <|> return []
        return (x : rest)

skipParens :: P ()
skipParens = special "(" >> go (1 :: Int)
  where
    go 0 = return ()
    go n = do
      t <- anyTok
      case t of
        TSpecial "(" -> go (n + 1)
        TSpecial ")" -> go (n - 1)
        _ -> go n

--------------------------------------------------------------------------------
-- Modules and declarations

pModule :: P [Decl]
pModule = do
  optional (reserved "module" >> modId >> optional skipParens >> reserved "where")
  ds <- block topDecl
  eof
  return (concat ds)

topDecl :: P [Decl]
topDecl = choice
  [ pImport
  , pData
  , pTypeSyn
  , pClass
  , pInstance
  , pFixity
  , reserved "deriving" >> fail "standalone deriving is not supported"
  , pValueDecl
  ]

pImport :: P [Decl]
pImport = do
  reserved "import"
  optional (kw "qualified")
  m <- modId
  optional (kw "as" >> modId)
  optional (kw "hiding")
  optional skipParens
  return [DImport m]

pData :: P [Decl]
pData = do
  reserved "data" <|> reserved "newtype"
  optional (try (btype >> resOp "=>"))
  n <- conId
  vs <- many varId
  cs <- option [] (resOp "=" >> pConstr `sepBy1` resOp "|")
  ds <- option [] pDeriving
  return [DData n vs cs ds]

pConstr :: P ConDecl
pConstr = try infixCon <|> prefixCon
  where
    infixCon = do
      a <- strictAType
      op <- conSym <|> backticks conId
      b <- strictAType
      return (ConDecl op [a, b] [Nothing, Nothing])
    prefixCon = do
      c <- conId <|> try (parens conSym)
      recordCon c <|> plainCon c
    recordCon c = do
      fs <- braces (fieldDecl `sepBy` comma)
      let fs' = concat fs
      return (ConDecl c (map snd fs') (map (Just . fst) fs'))
    plainCon c = do
      ts <- many strictAType
      return (ConDecl c ts (map (const Nothing) ts))
    fieldDecl = do
      ns <- varId `sepBy1` comma
      resOp "::"
      optional bang
      t <- pType
      return [ (n, t) | n <- ns ]

strictAType :: P Type
strictAType = optional bang >> atype

bang :: P ()
bang = is (TVarSym "!")

pDeriving :: P [Ident]
pDeriving = do
  reserved "deriving"
  optional (kw "stock" <|> kw "anyclass")
  parens (conId `sepBy` comma) <|> fmap (: []) conId

pTypeSyn :: P [Decl]
pTypeSyn = do
  reserved "type"
  n <- conId
  vs <- many varId
  resOp "="
  t <- pType
  return [DSyn n vs t]

pClass :: P [Decl]
pClass = do
  reserved "class"
  optional (try (btype >> resOp "=>"))
  c <- conId
  v <- varId
  body <- option [] (reserved "where" >> fmap concat (block pLocalDecl))
  return [DClass c v body]

pInstance :: P [Decl]
pInstance = do
  reserved "instance"
  optional (try (btype >> resOp "=>"))
  c <- conId
  t <- atype
  body <- option [] (reserved "where" >> fmap concat (block pLocalDecl))
  return [DInst c t body]

pFixity :: P [Decl]
pFixity = do
  a <- (InfixL <$ reserved "infixl") <|> (InfixR <$ reserved "infixr") <|> (InfixN <$ reserved "infix")
  p <- option 9 (fromInteger <$> integer)
  ops <- fixOp `sepBy1` comma
  return [DFixity a p ops]
  where
    fixOp = varSym <|> conSym <|> backticks (varId <|> conId)

pLocalDecl :: P [Decl]
pLocalDecl = pFixity <|> pValueDecl

pValueDecl :: P [Decl]
pValueDecl = try pSig <|> pEquation

pSig :: P [Decl]
pSig = do
  ns <- sigVar `sepBy1` comma
  resOp "::"
  t <- pSigType
  return [DSig ns t]
  where
    sigVar = varId <|> try (parens (varSym <|> conSym))

--------------------------------------------------------------------------------
-- Types

pSigType :: P Type
pSigType = do
  optional (try (btype >> resOp "=>"))
  pType

pType :: P Type
pType = do
  t <- btype
  option t (resOp "->" >> (tFun t <$> pType))

btype :: P Type
btype = do
  ts <- many1 atype
  case ts of
    [t] -> return t
    (TCon c [] : args) -> return (TCon c args)
    _ -> fail "unsupported type application (type variables cannot be applied)"

atype :: P Type
atype = choice
  [ (\c -> TCon c []) <$> conId
  , TVar <$> varId
  , between (special "[") (special "]") (tList <$> pType)
  , parenType
  ]
  where
    parenType = do
      special "("
      (special ")" >> return (TCon "()" [])) <|> do
        ts <- pType `sepBy1` comma
        special ")"
        return (case ts of
                  [t] -> t
                  _ -> TCon (tupleCon (length ts)) ts)

--------------------------------------------------------------------------------
-- Equations

data LhsItem = LOperand Pat | LOp Op

isOperand :: LhsItem -> Bool
isOperand (LOperand _) = True
isOperand _ = False

pEquation :: P [Decl]
pEquation = do
  items <- many1 lhsItem
  rhs <- pRhs (resOp "=")
  case mkEquation items rhs of
    Left err -> fail err
    Right d -> return [d]
  where
    lhsItem = (LOp <$> lhsOp) <|> (LOperand <$> apat)
    lhsOp = (do s <- varSym; return (Op s False))
      <|> (do s <- conSym; return (Op s True))
      <|> backticks ((\v -> Op v False) <$> varId <|> (\c -> Op c True) <$> conId)

mkEquation :: [LhsItem] -> Rhs -> Either String Decl
mkEquation items rhs =
  case break isVarOp items of
    (l, LOp o : r)
      | not (any isVarOp r) -> do
          lp <- itemsToPat l
          rp <- itemsToPat r
          return (DEqn (opName o) [lp, rp] rhs)
      | otherwise -> Left "cannot parse left-hand side (more than one operator)"
    _ -> case items of
      (LOperand (PVar f) : args) | all isOperand args ->
        return (DEqn f [ p | LOperand p <- args ] rhs)
      _ -> do
        p <- itemsToPat items
        return (DPatBind p rhs)
  where
    isVarOp (LOp (Op _ False)) = True
    isVarOp _ = False

-- | Turn a sequence of atomic patterns and constructor operators into a
-- pattern (constructor application binds tighter than operators).
itemsToPat :: [LhsItem] -> Either String Pat
itemsToPat items = do
  let (g0, rest) = span isOperand items
  p0 <- grp g0
  ps <- go rest
  return (if null ps then p0 else POps p0 ps)
  where
    go [] = Right []
    go (LOp o : more) = do
      let (g, rest') = span isOperand more
      p <- grp g
      ps <- go rest'
      return ((o, p) : ps)
    go _ = Left "malformed pattern"
    grp [LOperand p] = Right p
    grp (LOperand (PCon c []) : args) = Right (PCon c [ p | LOperand p <- args ])
    grp [] = Left "missing pattern"
    grp _ = Left "malformed pattern"

pRhs :: P () -> P Rhs
pRhs sep = do
  g <- (Unguarded <$> (sep >> pExp)) <|> (Guarded <$> many1 guardAlt)
  ws <- option [] (reserved "where" >> fmap concat (block pLocalDecl))
  return (Rhs g ws)
  where
    guardAlt = do
      resOp "|"
      cs <- pExp `sepBy1` comma
      sep
      e <- pExp
      return (foldr1 (\a b -> EApp (EApp (EVar "&&") a) b) cs, e)

--------------------------------------------------------------------------------
-- Expressions

pExp :: P Expr
pExp = do
  e <- pInfixExp
  option e (resOp "::" >> (ETyped e <$> pSigType))

pInfixExp :: P Expr
pInfixExp = do
  (e0, rest, tr) <- infixSeq False
  case tr of
    Nothing -> return (mkOps e0 rest)
    Just _ -> fail "operator section without parentheses"

mkOps :: Expr -> [(Op, Expr)] -> Expr
mkOps e [] = e
mkOps e rest = EOps e rest

-- | [-] e (op e)* [op]   (a trailing operator only if allowed: left sections)
infixSeq :: Bool -> P (Expr, [(Op, Expr)], Maybe Op)
infixSeq allowTrailing = do
  neg <- optionMaybe minusTok
  e0 <- exp10
  go (maybe e0 (const (ENeg e0)) neg) []
  where
    go e0 acc = option (e0, reverse acc, Nothing) $ do
      o <- qop
      (do neg <- optionMaybe minusTok
          e <- exp10
          go e0 ((o, maybe e (const (ENeg e)) neg) : acc))
        <|> (if allowTrailing
               then return (e0, reverse acc, Just o)
               else fail "expected an expression after the operator")

qop :: P Op
qop = (do s <- varSym; return (Op s False))
  <|> (do s <- conSym; return (Op s True))
  <|> backticks ((\v -> Op v False) <$> varId <|> (\c -> Op c True) <$> conId)

exp10 :: P Expr
exp10 = choice [pLambda, pLet, pIf, pCase, fexp]
  where
    pLambda = do
      resOp "\\"
      ps <- many1 apat
      resOp "->"
      ELam ps <$> pExp
    pLet = do
      reserved "let"
      ds <- block pLocalDecl
      reserved "in"
      ELet (concat ds) <$> pExp
    pIf = do
      reserved "if"
      c <- pExp
      optional (special ";")
      reserved "then"
      t <- pExp
      optional (special ";")
      reserved "else"
      EIf c t <$> pExp
    pCase = do
      reserved "case"
      s <- pExp
      reserved "of"
      ECase s <$> block pAlt
    pAlt = do
      p <- pat
      Alt p <$> pRhs (resOp "->")
    fexp = foldl1 EApp <$> many1 aexp

aexp :: P Expr
aexp = choice
  [ EVar <$> varId
  , ECon <$> conId
  , ELit <$> integer
  , EStr <$> stringLit
  , (\c -> EStr [c]) <$> charLit
  , parenExp
  , bracketExp
  ]

parenExp :: P Expr
parenExp = do
  special "("
  choice
    [ special ")" >> return (ECon "()")
    , try (do cs <- many1 comma
              special ")"
              return (ECon (tupleCon (length cs + 1))))
    , try (do o <- qop
              special ")"
              return (opExpr o))
    , try rightSection
    , inner
    ]
  where
    rightSection = do
      o <- qop
      when (opName o == "-") (fail "negation")
      e <- pInfixExp
      special ")"
      return (ERightSection o e)
    inner = do
      (e0, rest, tr) <- infixSeq True
      case tr of
        Just o -> do
          special ")"
          return (ELeftSection (mkOps e0 rest) o)
        Nothing -> do
          let e = mkOps e0 rest
          e' <- option e (resOp "::" >> (ETyped e <$> pSigType))
          (special ")" >> return e')
            <|> (do comma
                    es <- pExp `sepBy1` comma
                    special ")"
                    return (ETuple (e' : es)))

bracketExp :: P Expr
bracketExp = do
  special "["
  (special "]" >> return (ECon "[]")) <|> do
    e <- pExp
    choice
      [ special "]" >> return (EList [e])
      , do comma
           es <- pExp `sepBy1` comma
           special "]"
           return (EList (e : es))
      , do resOp "|"
           qs <- pQual `sepBy1` comma
           special "]"
           return (EListComp e qs)
      , resOp ".." >> fail "arithmetic sequences are not supported"
      ]
  where
    pQual = try (do p <- pat
                    resOp "<-"
                    SGen p <$> pExp)
      <|> try (do reserved "let"
                  ds <- block pLocalDecl
                  notFollowedBy (reserved "in")
                  return (SLet (concat ds)))
      <|> (SGuard <$> pExp)

--------------------------------------------------------------------------------
-- Patterns

pat :: P Pat
pat = do
  p <- pat10
  rest <- many (do o <- conOp; q <- pat10; return (o, q))
  return (if null rest then p else POps p rest)
  where
    conOp = ((\s -> Op s True) <$> conSym) <|> backticks ((\c -> Op c True) <$> conId)

pat10 :: P Pat
pat10 = (do c <- conId
            args <- many apat
            return (PCon c args))
  <|> (do minusTok
          n <- integer
          return (PLit (negate n)))
  <|> apat

apat :: P Pat
apat = choice
  [ try (do v <- varId
            resOp "@"
            PAs v <$> apat)
  , PVar <$> varId
  , PWild <$ reserved "_"
  , (\c -> PCon c []) <$> conId
  , PLit <$> integer
  , between (special "[") (special "]") (PList <$> pat `sepBy` comma)
  , parenPat
  ]
  where
    parenPat = do
      special "("
      choice
        [ special ")" >> return (PCon "()" [])
        , try (do cs <- many1 comma
                  special ")"
                  return (PCon (tupleCon (length cs + 1)) []))
        , try (do s <- varSym
                  special ")"
                  return (PVar s))
        , try (do s <- conSym
                  special ")"
                  return (PCon s []))
        , do ps <- pat `sepBy1` comma
             special ")"
             return (case ps of
                       [p] -> p
                       _ -> PTuple ps)
        ]
