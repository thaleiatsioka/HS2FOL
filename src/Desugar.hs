-- | From surface syntax to the core language: program assembly, deriving,
-- scoping, fixity resolution and pattern-match compilation.
module Desugar (desugarProgram) where

import Control.Monad
import Control.Monad.Except
import Control.Monad.State
import Data.List (nub, partition)
import qualified Data.Map as M
import Data.Maybe (fromMaybe)
import qualified Data.Set as S
import Syntax

type DM a = StateT Int (Either String) a

data DEnv = DEnv
  { deFix :: M.Map Ident (Assoc, Int)
  , deCons :: M.Map Ident ConInfo
  , deDatas :: M.Map Ident DataInfo
  , deGlobals :: M.Map Ident String -- ^ identifier -> global key
  , deScope :: M.Map Ident Name -- ^ local variables
  , deSyns :: M.Map Ident ([Ident], Type)
  , deTypes :: S.Set Ident -- ^ known type constructors
  , dePrim :: Ident -> String -- ^ key of a Prelude function
  }

dsErr :: String -> DM a
dsErr = throwError

liftE :: Either String a -> DM a
liftE = either throwError return

fresh :: String -> DM Name
fresh base = do
  n <- get
  put (n + 1)
  return (Name base n)

tryDM :: DM a -> DM (Either String a)
tryDM m = catchError (Right <$> m) (return . Left)

dups :: [String] -> [String]
dups xs = [ x | (x, n) <- M.toList (M.fromListWith (+) [ (x, 1 :: Int) | x <- xs ]), n > 1 ]

builtinDatas :: [DataInfo]
builtinDatas =
  [ DataInfo "[]" ["a"] [("[]", []), (":", [TVar "a", TCon "[]" [TVar "a"]])]
  , DataInfo "()" [] [("()", [])]
  ]
    ++ [ DataInfo (tupleCon k) vs [(tupleCon k, map TVar vs)]
       | k <- [2 .. 7]
       , let vs = [ "t" ++ show i | i <- [1 .. k] ] ]

convType :: DEnv -> Type -> Either String Type
convType env t = case t of
  TVar v -> Right (TVar v)
  TCon c ts -> do
    ts' <- mapM (convType env) ts
    case M.lookup c (deSyns env) of
      Just (vs, body)
        | length vs == length ts' -> convType env (substType (M.fromList (zip vs ts')) body)
        | otherwise -> Left ("type synonym " ++ c ++ " must be fully applied")
      Nothing
        | S.member c (deTypes env) || c == "->" -> Right (TCon c ts')
        | otherwise -> Left ("unknown type " ++ c)

groupEqns :: [Decl] -> [(Ident, [([Pat], Rhs)])]
groupEqns ds =
  [ (n, [ (ps, r) | DEqn n' ps r <- ds, n' == n ]) | n <- nub [ n | DEqn n _ _ <- ds ] ]

closeScheme :: Type -> Scheme
closeScheme t = Forall (ftv t) t

--------------------------------------------------------------------------------
-- Deriving and record selectors (generated as surface syntax)

deriveInstances :: Ident -> [Ident] -> [ConDecl] -> [Ident] -> [Decl]
deriveInstances n vs cs ds =
  [ DInst "Eq" headT eqEqns | "Eq" `elem` ds ] ++ [ DInst "Ord" headT ordEqns | "Ord" `elem` ds ]
  where
    headT = TCon n (map TVar vs)
    cons = [ (c, length ts) | ConDecl c ts _ <- cs ]
    pc c k p = PCon c [ PVar (p ++ show i) | i <- [1 .. k] ]
    v p i = EVar (p ++ show i)
    app2 f a b = EApp (EApp (EVar f) a) b
    eqEqns =
      [ DEqn "==" [pc c k "x", pc d l "y"] (Rhs (Unguarded (eqBody c k d)) [])
      | (c, k) <- cons, (d, l) <- cons ]
    eqBody c k d
      | c /= d = ECon "False"
      | k == 0 = ECon "True"
      | otherwise = foldr1 (app2 "&&") [ app2 "==" (v "x" i) (v "y" i) | i <- [1 .. k] ]
    ordEqns =
      [ DEqn "compare" [pc c k "x", pc d l "y"] (Rhs (Unguarded (ordBody i k j)) [])
      | (i, (c, k)) <- zip [0 :: Int ..] cons, (j, (d, l)) <- zip [0 ..] cons ]
    ordBody i k j
      | i < j = ECon "LT"
      | i > j = ECon "GT"
      | k == 0 = ECon "EQ"
      | otherwise = foldr1 (app2 "thenCmp") [ app2 "compare" (v "x" m) (v "y" m) | m <- [1 .. k] ]

selectors :: [Decl] -> [Decl]
selectors ds =
  [ DEqn f [PCon c [ if j == i then PVar "x" else PWild | j <- [0 .. length ts - 1] ]] (Rhs (Unguarded (EVar "x")) [])
  | DData _ _ cs _ <- ds, ConDecl c ts fs <- cs, (i, Just f) <- zip [0 :: Int ..] fs ]

--------------------------------------------------------------------------------
-- Program assembly

-- | Desugar the Prelude declarations and the user declarations into a
-- program. Returns warnings about skipped definitions.
desugarProgram :: [Decl] -> [Decl] -> Either String (Program, [String])
desugarProgram pre usr = do
  ((prog, warns), cnt) <- runStateT (build pre usr) 1
  return (prog { progFresh = cnt }, warns)

build :: [Decl] -> [Decl] -> DM (Program, [String])
build pre usr = do
  let allTop = pre ++ usr
      nested = concat [ b | DClass _ _ b <- allTop ] ++ concat [ b | DInst _ _ b <- allTop ]
      fixities = M.fromList [ (o, (a, p)) | DFixity a p os <- allTop ++ nested, o <- os ]
      syns = M.fromList [ (n, (vs, t)) | DSyn n vs t <- allTop ]
      dataDecls = [ (n, vs, cs) | DData n vs cs _ <- allTop ]
      typeNames = S.fromList ([ n | (n, _, _) <- dataDecls ] ++ map dataName builtinDatas ++ ["Int"])
      env0 = DEnv
        { deFix = fixities, deCons = M.empty, deDatas = M.empty, deGlobals = M.empty
        , deScope = M.empty, deSyns = syns, deTypes = typeNames, dePrim = id }
      dupTypes = dups ([ n | (n, _, _) <- dataDecls ] ++ M.keys syns ++ map dataName builtinDatas ++ ["Int"])
  unless (null dupTypes) $ dsErr ("duplicate type definitions: " ++ unwords dupTypes)

  userDatas <- forM dataDecls $ \(n, vs, cs) -> do
    cs' <- forM cs $ \(ConDecl c ts _) -> do
      ts' <- liftE (either (\e -> Left ("in data type " ++ n ++ ": " ++ e)) Right (mapM (convType env0) ts))
      return (c, ts')
    return (DataInfo n vs cs')
  let allDatas = builtinDatas ++ userDatas
      dataMap = M.fromList [ (dataName d, d) | d <- allDatas ]
      conList =
        [ (c, ConInfo (dataName d) i (length ts)
                (Forall (dataVars d) (foldr tFun (TCon (dataName d) (map TVar (dataVars d))) ts)))
        | d <- allDatas, (i, (c, ts)) <- zip [0 ..] (dataCons d) ]
      conMap = M.fromList conList
      dupCons = dups (map fst conList)
  unless (null dupCons) $ dsErr ("duplicate constructors: " ++ unwords dupCons)

  -- tag every declaration with its origin (True = Prelude scope)
  let derived = concat [ deriveInstances n vs cs ds | DData n vs cs ds <- allTop ]
      tagged = [ (True, d) | d <- pre ++ selectors pre ++ derived ]
            ++ [ (False, d) | d <- usr ++ selectors usr ]
      topEqns isP = groupEqns [ d | (p, d@DEqn {}) <- tagged, p == isP ]
      topSigs isP = M.fromList [ (n, t) | (p, DSig ns t) <- tagged, p == isP, n <- ns ]
      userTopNames = S.fromList (map fst (topEqns False) ++ M.keys (topSigs False))
      preKey n = if S.member n userTopNames then "Prelude." ++ n else n

  case [ () | (False, DPatBind _ _) <- tagged ] ++ [ () | (True, DPatBind _ _) <- tagged ] of
    [] -> return ()
    _ -> dsErr "top-level pattern bindings are not supported"

  -- classes and methods
  let classDecls = [ (isP, c, v, body) | (isP, DClass c v body) <- tagged ]
  methodsL <- fmap concat $ forM classDecls $ \(isP, c, v, body) ->
    forM [ (n, t) | DSig ns t <- body, n <- ns ] $ \(n, t) -> do
      t' <- liftE (convType env0 t)
      let k = if isP then preKey n else n
      return (k, (isP, MethodInfo c n v (Forall (v : filter (/= v) (ftv t')) t')))
  let methodMap = M.fromList [ (k, mi) | (k, (_, mi)) <- methodsL ]
      classMap = M.fromList
        [ (c, (isP, v, [ (methodName mi, k) | (k, (_, mi)) <- methodsL, methodClass mi == c ], groupEqns [ d | d@DEqn {} <- body ]))
        | (isP, c, v, body) <- classDecls ]

  -- global scopes
  let funNames isP = map fst (topEqns isP) ++ [ n | n <- M.keys (topSigs isP), n `notElem` map fst (topEqns isP) ]
      preGlobals = M.fromList ([ (n, preKey n) | n <- funNames True ] ++ [ (methodName mi, k) | (k, (True, mi)) <- methodsL ])
      userGlobals = M.union (M.fromList ([ (n, n) | n <- funNames False ] ++ [ (methodName mi, k) | (k, (False, mi)) <- methodsL ])) preGlobals
      preEnv = env0 { deCons = conMap, deDatas = dataMap, deGlobals = preGlobals, dePrim = preKey }
      usrEnv = preEnv { deGlobals = userGlobals }
      envFor isP = if isP then preEnv else usrEnv

  -- top-level functions and primitives
  results <- fmap concat $ forM [True, False] $ \isP -> do
    let env = envFor isP
        sigs = topSigs isP
        eqs = topEqns isP
        keyOf n = if isP then preKey n else n
        kind = if isP then BPrelude else BUser
    fs <- forM eqs $ \(n, es) -> do
      r <- tryDM $ do
        sig <- traverse (liftE . convType env) (M.lookup n sigs)
        body <- dsFunction env n es
        return (Binding (keyOf n) n (fmap closeScheme sig) (Just body) kind)
      return (isP, n, r)
    ps <- forM [ (n, t) | (n, t) <- M.toList sigs, n `notElem` map fst eqs, not (M.member (keyOf n) methodMap) ] $ \(n, t) -> do
      r <- tryDM (do
        t' <- liftE (convType env t)
        return (Binding (keyOf n) n (Just (closeScheme t')) Nothing kind))
      return (isP, n, r)
    return (fs ++ ps)
  forM_ [ (n, e) | (True, n, Left e) <- results ] $ \(n, e) ->
    dsErr ("in the Prelude, " ++ n ++ ": " ++ e)
  let failedWarnings = [ "skipping " ++ n ++ ": " ++ e | (False, n, Left e) <- results ]
      topBinds = [ b | (_, _, Right b) <- results ]

  -- instances
  instResults <- forM [ (isP, c, t, body) | (isP, DInst c t body) <- tagged ] $ \(isP, c, t, body) ->
    case M.lookup c classMap of
      Nothing -> return (Left ("ignoring instance " ++ c ++ " " ++ prettyType t ++ " (unknown class)"))
      Just (clsP, cv, meths, defaults) -> do
        let env = envFor isP
        t' <- liftE (convType env t)
        (tc, vs) <- case t' of
          TCon tc args | all isTVar args -> return (tc, [ v | TVar v <- args ])
          _ -> dsErr ("unsupported instance head: " ++ c ++ " " ++ prettyType t')
        let ren = M.fromList [ (v, TVar (v ++ "_i")) | v <- vs ]
            headR = substType ren t'
            eqs = groupEqns [ d | d@DEqn {} <- body ]
            bad = [ n | (n, _) <- eqs, n `notElem` map fst meths ]
        unless (null bad) $ dsErr ("instance " ++ c ++ " " ++ tc ++ " defines non-methods: " ++ unwords bad)
        bs <- forM meths $ \(mname, mkey) -> do
          let mi = methodMap M.! mkey
              Forall mvs mt = methodScheme mi
              others = filter (/= cv) mvs
              sig = Forall (map (++ "_i") vs ++ others) (substType (M.singleton cv headR) mt)
              bkey = "inst:" ++ c ++ ":" ++ tc ++ ":" ++ mname
              ctx e = "in instance " ++ c ++ " " ++ prettyType t' ++ ", method " ++ mname ++ ": " ++ e
              mk env' es = do
                r <- tryDM (dsFunction env' mname es)
                body' <- either (dsErr . ctx) return r
                return (mkey, Just (Binding bkey mname (Just sig) (Just body') BInstance))
          case lookup mname eqs of
            Just es -> mk env es
            Nothing -> case lookup mname defaults of
              Just es -> mk (envFor clsP) es
              Nothing -> return (mkey, Nothing)
        return (Right ((c, tc), InstInfo headR (M.fromList [ (k, fmap bindKey mb) | (k, mb) <- bs ]), [ b | (_, Just b) <- bs ]))
  let instWarnings = [ w | Left w <- instResults ]
      insts = [ (k, i) | Right (k, i, _) <- instResults ]
      instBinds = concat [ bs | Right (_, _, bs) <- instResults ]
      dupInsts = dups [ c ++ " " ++ tc | ((c, tc), _) <- insts ]
  unless (null dupInsts) $ dsErr ("duplicate instances: " ++ unwords dupInsts)

  -- drop user definitions that depend on skipped ones
  let (kept, dropped) = dropLoop methodMap (topBinds ++ instBinds)
      droppedInst = [ b | b <- dropped, bindKind b == BInstance ]
  unless (null droppedInst) $
    dsErr ("instance method " ++ bindHask (head droppedInst) ++ " uses a definition that could not be translated")
  let dropWarnings = [ "skipping " ++ bindHask b ++ ": it depends on skipped definitions" | b <- dropped ]
  return
    ( Program
        { progDatas = dataMap
        , progCons = conMap
        , progMethods = methodMap
        , progInstances = M.fromList insts
        , progBinds = kept
        , progFresh = 0
        }
    , failedWarnings ++ instWarnings ++ dropWarnings )
  where
    isTVar (TVar _) = True
    isTVar _ = False

dropLoop :: M.Map String MethodInfo -> [Binding] -> ([Binding], [Binding])
dropLoop methods bs =
  let keys = S.fromList (map bindKey bs)
      bad b = case bindBody b of
        Just body -> any (\(k, _) -> not (S.member k keys || M.member k methods)) (globalOccs body)
        Nothing -> False
      (badBs, goodBs) = partition bad bs
  in if null badBs then (bs, []) else let (r, d) = dropLoop methods goodBs in (r, badBs ++ d)

--------------------------------------------------------------------------------
-- Functions and right-hand sides

dsFunction :: DEnv -> Ident -> [([Pat], Rhs)] -> DM CExpr
dsFunction env f eqns = case eqns of
  [] -> dsErr ("no equations for " ++ f)
  [([], rhs)] -> replaceFT CFail <$> dsRhs env rhs
  ((ps0, _) : _) -> do
    let n = length ps0
    when (n == 0) $ dsErr ("multiple definitions of " ++ f)
    when (any ((/= n) . length . fst) eqns) $
      dsErr ("equations for " ++ f ++ " have different numbers of arguments")
    us <- forM [0 .. n - 1] $ \i -> fresh (paramName [ ps !! i | (ps, _) <- eqns ])
    body <- matchRows env us [ (ps, \e -> dsRhs e rhs) | (ps, rhs) <- eqns ] CFail
    return (foldr CLam body us)
  where
    paramName ps = case [ v | PVar v <- ps ] of
      (v : _) -> v
      [] -> "x"

dsRhs :: DEnv -> Rhs -> DM CExpr
dsRhs env (Rhs g wheres) = do
  (bs, env') <- dsLocalDecls env wheres
  body <- case g of
    Unguarded e -> dsExpr env' e
    Guarded gs ->
      foldM (\acc (c, e) -> do
                c' <- dsExpr env' c
                e' <- dsExpr env' e
                return (ifThenElse c' e' acc))
            CFallthrough (reverse gs)
  return (if null bs then body else CLet bs body)

ifThenElse :: CExpr -> CExpr -> CExpr -> CExpr
ifThenElse c t e = CCase c [CAlt "True" [] t, CAlt "False" [] e]

-- | Replace guard fall-through by the given expression.
replaceFT :: CExpr -> CExpr -> CExpr
replaceFT r e = case e of
  CFallthrough -> r
  CApp f a -> CApp (replaceFT r f) (replaceFT r a)
  CLam x b -> CLam x (replaceFT r b)
  CLet bs b -> CLet [ (n, replaceFT r x) | (n, x) <- bs ] (replaceFT r b)
  CCase s alts -> CCase (replaceFT r s) [ CAlt c xs (replaceFT r b) | CAlt c xs b <- alts ]
  CTyped x t -> CTyped (replaceFT r x) t
  _ -> e

dsLocalDecls :: DEnv -> [Decl] -> DM ([(Name, CExpr)], DEnv)
dsLocalDecls env [] = return ([], env)
dsLocalDecls env ds = do
  let groups = groupEqns ds
      sigs = M.fromList [ (n, t) | DSig ns t <- ds, n <- ns ]
      pbinds = [ (p, r) | DPatBind p r <- ds ]
  fnNames <- forM groups $ \(n, _) -> fresh n
  pvarsets <- forM pbinds $ \(p, _) -> forM (nub (patVars p)) $ \v -> do
    nm <- fresh v
    return (v, nm)
  let scope' = M.fromList (zip (map fst groups) fnNames ++ concat pvarsets)
      env' = env { deScope = M.union scope' (deScope env) }
  fbinds <- forM (zip groups fnNames) $ \((n, eqns), nm) -> do
    e <- dsFunction env' n eqns
    e' <- case M.lookup n sigs of
      Just t -> CTyped e <$> liftE (convType env t)
      Nothing -> return e
    return (nm, e')
  pb <- forM (zip pbinds pvarsets) $ \((p, rhs), vs) -> do
    tmp <- fresh "p"
    r <- replaceFT CFail <$> dsRhs env' rhs
    sels <- forM vs $ \(v, nm) -> do
      (cp, bs) <- convPat env' p
      let target = fromMaybe (Name v 0) (lookup v bs)
      sel <- match env' [tmp] [([cp], lvar target)] CFail
      return (nm, sel)
    return ((tmp, r) : sels)
  return (fbinds ++ concat pb, env')

patVars :: Pat -> [Ident]
patVars p = case p of
  PVar v -> [v]
  PWild -> []
  PCon _ ps -> concatMap patVars ps
  PLit _ -> []
  PAs v q -> v : patVars q
  PTuple ps -> concatMap patVars ps
  PList ps -> concatMap patVars ps
  POps q rest -> patVars q ++ concatMap (patVars . snd) rest

--------------------------------------------------------------------------------
-- Expressions

dsVar :: DEnv -> Ident -> DM CExpr
dsVar env x
  | Just n <- M.lookup x (deScope env) = return (lvar n)
  | x == "otherwise" = return (CCon "True")
  | x == "===" = dsVar env "=="
  | Just k <- M.lookup x (deGlobals env) = return (gvar k)
  | otherwise = dsErr ("unknown identifier " ++ x)

dsExpr :: DEnv -> Expr -> DM CExpr
dsExpr env expr = case expr of
  EVar x -> dsVar env x
  ECon c -> do
    unless (M.member c (deCons env)) $ dsErr ("unknown constructor " ++ c)
    return (CCon c)
  ELit n -> return (CLit n)
  EStr _ -> dsErr "string and character literals are not supported"
  EApp (EVar "error") _ | not (M.member "error" (deScope env)) -> return (gvar (dePrim env "undefined"))
  EApp f a -> CApp <$> dsExpr env f <*> dsExpr env a
  ELam ps b -> do
    us <- forM ps $ \p -> fresh (case p of
                                   PVar v -> v
                                   _ -> "x")
    body <- matchRows env us [(ps, \e -> dsExpr e b)] CFail
    return (foldr CLam body us)
  ELet ds b -> do
    (bs, env') <- dsLocalDecls env ds
    b' <- dsExpr env' b
    return (if null bs then b' else CLet bs b')
  EIf c t e -> ifThenElse <$> dsExpr env c <*> dsExpr env t <*> dsExpr env e
  ECase s alts -> do
    s' <- dsExpr env s
    u <- fresh "s"
    body <- matchRows env [u] [ ([p], \e -> dsRhs e r) | Alt p r <- alts ] CFail
    return (CLet [(u, s')] body)
  ETuple es -> cApps (CCon (tupleCon (length es))) <$> mapM (dsExpr env) es
  EList es -> do
    es' <- mapM (dsExpr env) es
    return (foldr (\x acc -> cApps (CCon ":") [x, acc]) (CCon "[]") es')
  EListComp h qs -> dsComp env h qs
  EOps e0 rest ->
    case resolveOps (deFix env) (\o l r -> EApp (EApp (opExpr o) l) r) e0 rest of
      Left err -> dsErr err
      Right e -> dsExpr env e
  ENeg e -> CApp (gvar (dePrim env "negate")) <$> dsExpr env e
  ELeftSection e o -> CApp <$> dsExpr env (opExpr o) <*> dsExpr env e
  ERightSection o e -> do
    x <- fresh "x"
    o' <- dsExpr env (opExpr o)
    e' <- dsExpr env e
    return (CLam x (cApps o' [lvar x, e']))
  ETyped e t -> CTyped <$> dsExpr env e <*> liftE (convType env t)

dsComp :: DEnv -> Expr -> [Stmt] -> DM CExpr
dsComp env h [] = do
  h' <- dsExpr env h
  return (cApps (CCon ":") [h', CCon "[]"])
dsComp env h (SGuard g : qs) = ifThenElse <$> dsExpr env g <*> dsComp env h qs <*> pure (CCon "[]")
dsComp env h (SLet ds : qs) = do
  (bs, env') <- dsLocalDecls env ds
  r <- dsComp env' h qs
  return (if null bs then r else CLet bs r)
dsComp env h (SGen p l : qs) = do
  l' <- dsExpr env l
  x <- fresh "x"
  body <- matchRows env [x] [([p], \e -> dsComp e h qs)] (CCon "[]")
  return (cApps (gvar (dePrim env "concatMap")) [CLam x body, l'])

--------------------------------------------------------------------------------
-- Pattern-match compilation

data CPat = CPVar Name | CPWild | CPCon Ident [CPat] | CPAs Name CPat

convPat :: DEnv -> Pat -> DM (CPat, [(Ident, Name)])
convPat env p = case p of
  PVar v -> do
    n <- fresh v
    return (CPVar n, [(v, n)])
  PWild -> return (CPWild, [])
  PCon c ps -> do
    ci <- maybe (dsErr ("unknown constructor " ++ c)) return (M.lookup c (deCons env))
    when (conArity ci /= length ps) $
      dsErr ("constructor " ++ c ++ " should have " ++ show (conArity ci) ++ " arguments in a pattern")
    rs <- mapM (convPat env) ps
    return (CPCon c (map fst rs), concatMap snd rs)
  PLit _ -> dsErr "integer literal patterns are not supported (Int is abstract)"
  PAs v q -> do
    n <- fresh v
    (q', bs) <- convPat env q
    return (CPAs n q', (v, n) : bs)
  PTuple ps -> convPat env (PCon (tupleCon (length ps)) ps)
  PList ps -> convPat env (foldr (\a b -> PCon ":" [a, b]) (PCon "[]" []) ps)
  POps p0 rest
    | all (opIsCon . fst) rest ->
        case resolveOps (deFix env) (\o l r -> PCon (opName o) [l, r]) p0 rest of
          Left err -> dsErr err
          Right q -> convPat env q
    | otherwise -> dsErr "variable operator in a pattern"

-- | Rename the variables of each row, desugar its right-hand side in the
-- extended scope, and compile the match.
matchRows :: DEnv -> [Name] -> [([Pat], DEnv -> DM CExpr)] -> CExpr -> DM CExpr
matchRows env us rows def = do
  crows <- forM rows $ \(ps, k) -> do
    rs <- mapM (convPat env) ps
    let env' = env { deScope = M.union (M.fromList (concatMap snd rs)) (deScope env) }
    rhs <- k env'
    return (map fst rs, rhs)
  match env us crows def

-- | The classic match algorithm. Rows are tried top to bottom; the result
-- is a tree of flat case expressions in which every case lists all
-- constructors of the type (defaults are expanded).
match :: DEnv -> [Name] -> [([CPat], CExpr)] -> CExpr -> DM CExpr
match _ [] rows def = return (foldr (\(_, rhs) acc -> replaceFT acc rhs) def rows)
match env (u : us) rows def = do
  let rows' = map (bindFirst u) rows
  foldM (\acc blk -> matchBlock env u us blk acc) def (reverse (blocks rows'))
  where
    blocks [] = []
    blocks (r : rs) =
      let (same, rest) = span (\r' -> isWild r' == isWild r) rs
      in (r : same) : blocks rest
    isWild (CPWild : _, _) = True
    isWild _ = False

bindFirst :: Name -> ([CPat], CExpr) -> ([CPat], CExpr)
bindFirst u (p : ps, rhs) = case p of
  CPVar x -> (CPWild : ps, CLet [(x, lvar u)] rhs)
  CPAs x q -> bindFirst u (q : ps, CLet [(x, lvar u)] rhs)
  _ -> (p : ps, rhs)
bindFirst _ r = r

matchBlock :: DEnv -> Name -> [Name] -> [([CPat], CExpr)] -> CExpr -> DM CExpr
matchBlock env u us blk acc = case blk of
  ((CPWild : _, _) : _) -> match env us [ (ps, rhs) | (_ : ps, rhs) <- blk ] acc
  _ -> do
    let firstCon = head ([ c | (CPCon c _ : _, _) <- blk ] ++ [""])
    di <- case M.lookup firstCon (deCons env) >>= \ci -> M.lookup (conData ci) (deDatas env) of
      Just d -> return d
      Nothing -> dsErr ("internal: unknown constructor in match: " ++ firstCon)
    alts <- forM (dataCons di) $ \(c, fts) -> do
      let rowsC = [ (subs ++ ps, rhs) | (CPCon c' subs : ps, rhs) <- blk, c' == c ]
      vs <- forM [0 .. length fts - 1] $ \i -> fresh (fieldName rowsC i)
      body <- if null rowsC then return acc else match env (vs ++ us) rowsC acc
      return (CAlt c vs body)
    return (CCase (lvar u) alts)
  where
    fieldName rowsC i = case [ nameBase n | (ps, _) <- rowsC, n <- varOf (ps !! i) ] of
      (b : _) -> b
      [] -> "y"
    varOf (CPVar n) = [n]
    varOf (CPAs n _) = [n]
    varOf _ = []
