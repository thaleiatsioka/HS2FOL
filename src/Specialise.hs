-- | Monomorphisation of overloading: every use of a class method or of an
-- overloaded function is replaced by a specialised copy.
module Specialise (specialise, SBind (..), SKind (..)) where

import Control.Monad
import Control.Monad.Except
import Control.Monad.State
import Data.Char (isAlphaNum)
import Data.List (intercalate, isPrefixOf)
import Data.Maybe (isJust)
import qualified Data.Map as M
import Names
import Syntax
import TypeCheck

data SKind = SKUser | SKPrelude | SKSpec
  deriving (Eq, Show)

-- | A monomorphic top-level binding. A missing body means an abstract
-- (uninterpreted) function.
data SBind = SBind
  { sbKey :: String
  , sbHask :: Ident -- ^ Haskell name (for decoding)
  , sbFol :: String -- ^ desired FOL name
  , sbType :: Type
  , sbBody :: Maybe CExpr
  , sbKind :: SKind
  }

data SpState = SpState
  { ssDone :: M.Map String ()
  , ssQueue :: [(String, String, M.Map String Type, String, Ident)]
  , ssOut :: [SBind]
  }

type SM a = StateT SpState (Either String) a

-- | With @full = False@, only overloading is specialised (type variables
-- that decide an instance). With @full = True@ every polymorphic function is
-- specialised to each type it is used at, so that every function symbol
-- gets a monomorphic type (needed for typed TPTP). Type variables of a
-- property that remain free are turned into abstract sorts, and ambiguous
-- type variables default to ().
specialise :: Bool -> Program -> TcResult -> Either String [SBind]
specialise full prog tc = evalStateT run (SpState M.empty [] [])
  where
    bindMap = M.fromList [ (bindKey b, b) | b <- progBinds prog ]
    relOf k
      | full, Just b <- M.lookup k bindMap, isJust (bindBody b) = case schemeOf k of Forall vs _ -> vs
      | otherwise = M.findWithDefault [] k (tcRel tc)
    isProp b = bindKind b == BUser && "prop" `isPrefixOf` bindHask b && isJust (bindBody b)
    abstractSorts b = M.fromList [ (v, TCon ("A_" ++ filter isAlphaNum v) []) | v <- case schemeOf (bindKey b) of Forall vs _ -> vs ]
    schemeOf k = M.findWithDefault (Forall [] (TVar "?")) k (tcSchemes tc)
    haskOf k = maybe k bindHask (M.lookup k bindMap)

    run = do
      forM_ (progBinds prog) $ \b -> do
        let root = bindKind b /= BInstance && (null (relOf (bindKey b)) || (full && isProp b))
            sub0 = if full && isProp b then abstractSorts b else M.empty
        when root $ do
          body' <- traverse (specExpr sub0) (bindBody b >> M.lookup (bindKey b) (tcBodies tc))
          markNew (bindKey b) >> return ()
          emit SBind
            { sbKey = bindKey b
            , sbHask = bindHask b
            , sbFol = funFolBase (bindHask b)
            , sbType = substType sub0 (schemeType (schemeOf (bindKey b)))
            , sbBody = body'
            , sbKind = if bindKind b == BPrelude then SKPrelude else SKUser
            }
      drain
      gets (reverse . ssOut)

    emit sb = modify (\s -> s { ssOut = sb : ssOut s })

    markNew k = do
      d <- gets ssDone
      if M.member k d
        then return False
        else do
          modify (\s -> s { ssDone = M.insert k () (ssDone s) })
          return True

    drain = do
      q <- gets ssQueue
      case q of
        [] -> return ()
        ((k, orig, sub, fol, hask) : rest) -> do
          modify (\s -> s { ssQueue = rest })
          body' <- traverse (specExpr sub) (M.lookup orig (tcBodies tc))
          emit (SBind k hask fol (substType sub (schemeType (schemeOf orig))) body' SKSpec)
          drain

    specExpr :: M.Map String Type -> CExpr -> SM CExpr
    specExpr sub e = case e of
      CVar n (Just t) | isGlobal n -> do
        k <- resolve (nameBase n) (substType sub t)
        return (CVar (globalName k) Nothing)
      CVar n _ -> return (CVar n Nothing)
      CApp f a -> CApp <$> specExpr sub f <*> specExpr sub a
      CLam x b -> CLam x <$> specExpr sub b
      CLet bs b -> CLet <$> mapM (\(n, r) -> (\r' -> (n, r')) <$> specExpr sub r) bs <*> specExpr sub b
      CCase s alts -> CCase <$> specExpr sub s <*> mapM (\(CAlt c xs r) -> CAlt c xs <$> specExpr sub r) alts
      _ -> return e

    resolve :: String -> Type -> SM String
    resolve g t = case M.lookup g (progMethods prog) of
      Just mi -> do
        s <- maybe (throwError ("internal: cannot match the type of method " ++ methodName mi)) return
               (matchType (schemeType (methodScheme mi)) t)
        let ct = M.findWithDefault (TVar "?") (methodVar mi) s
            what = methodClass mi ++ " " ++ prettyType ct ++ " (from a use of " ++ methodName mi ++ ")"
        tycon <- case ct of
          TCon c _ -> return c
          _ -> throwError ("ambiguous overloading: cannot resolve " ++ what ++ "; add a type signature")
        inst <- maybe (throwError ("no instance " ++ what)) return
                  (M.lookup (methodClass mi, tycon) (progInstances prog))
        let base = funFolBase (methodName mi) ++ mangleTycon tycon
        case M.findWithDefault Nothing g (instMethods inst) of
          Just bk -> request bk t base (methodName mi)
          Nothing -> do
            let k = "abstract:" ++ g ++ "@" ++ prettyType ct
            new <- markNew k
            when new $ emit (SBind k (methodName mi) (funFolBase (methodName mi) ++ mangleType ct) t Nothing SKSpec)
            return k
      Nothing
        | null (relOf g) -> return g
        | otherwise -> request g t (funFolBase (haskOf g)) (haskOf g)

    request bk t base hask = do
      s <- maybe (throwError ("internal: cannot match the type of " ++ hask)) return
             (matchType (schemeType (schemeOf bk)) t)
      let args0 = [ M.findWithDefault (TVar r) r s | r <- relOf bk ]
          args = if full then map defaultVars args0 else args0
      unless (all (null . ftv) args) $
        throwError ("ambiguous overloading in a use of " ++ hask ++ " at type(s) "
                    ++ intercalate ", " (map prettyType args) ++ "; add a type signature")
      let k = bk ++ "{" ++ intercalate "," (map prettyType args) ++ "}"
      new <- markNew k
      let s' = if full then M.union (M.fromList (zip (relOf bk) args)) s else s
      when new $ modify (\st -> st { ssQueue = ssQueue st ++ [(k, bk, s', base ++ concatMap mangleType args, hask)] })
      return k

    defaultVars t = case t of
      TVar _ -> TCon "()" []
      TCon c ts -> TCon c (map defaultVars ts)
