-- | Loading a program: the main file, the local modules it imports, and the
-- built-in Prelude. Shared by hs2fol and witness2input.
module Load (loadProgram, loadModules, preludeDecls) where

import Control.Monad
import Data.List (isPrefixOf)
import qualified Data.Set as S
import Parser
import PreludeSrc
import Syntax
import System.Directory
import System.Exit
import System.FilePath
import System.IO

die' :: String -> IO a
die' msg = hPutStrLn stderr msg >> exitFailure

preludeDecls :: IO [Decl]
preludeDecls = case parseModule "<Prelude>" preludeSource of
  Left e -> die' ("internal error in the Prelude: " ++ e)
  Right (_, ds) -> return ds

-- | Prelude declarations and user declarations.
loadProgram :: [FilePath] -> FilePath -> IO ([Decl], [Decl])
loadProgram incs file = do
  usr <- loadModules incs file
  pre <- preludeDecls
  return (pre, usr)

-- | Load a module and (transitively) the local modules it imports.
loadModules :: [FilePath] -> FilePath -> IO [Decl]
loadModules incs root = do
  (_, ds) <- visit (S.empty, []) root
  return ds
  where
    visit (seen, acc) path = do
      exists <- doesFileExist path
      unless exists $ die' ("file not found: " ++ path)
      canon <- canonicalizePath path
      if S.member canon seen
        then return (seen, acc)
        else do
          src <- readFile path
          (imps, ds) <- either die' return (parseModule path src)
          let dirs = takeDirectory path : incs
          foldM (\st m -> do
                   mp <- findModule dirs m
                   case mp of
                     Just p -> visit st p
                     Nothing -> do
                       unless (ignorable m) $
                         hPutStrLn stderr ("warning: ignoring import " ++ m ++ " (no local file " ++ modFile m ++ ")")
                       return st)
                (S.insert canon seen, acc ++ ds) imps
    modFile m = map (\c -> if c == '.' then pathSeparator else c) m ++ ".hs"
    findModule dirs m = do
      found <- filterM doesFileExist [ d </> modFile m | d <- dirs ]
      return (case found of
                (p : _) -> Just p
                [] -> Nothing)
    ignorable m = m == "Prelude" || any (`isPrefixOf` m) ["Test.QuickCheck", "Data.", "Control.", "System.", "GHC."]
