-- | hs2fol command line.
module Main (main) where

import Control.Monad
import Data.List (isPrefixOf)
import qualified Data.Set as S
import Decode
import Parser
import PreludeSrc
import Syntax
import System.Directory
import System.Environment
import System.Exit
import System.FilePath
import System.IO
import Translate

data Opts = Opts
  { oFile :: Maybe FilePath
  , oOut :: Maybe FilePath
  , oProps :: [String]
  , oStdout :: Bool
  , oList :: Bool
  , oIncludes :: [FilePath]
  , oDecode :: Bool
  }

defaultOpts :: Opts
defaultOpts = Opts Nothing Nothing [] False False [] False

usage :: String
usage = unlines
  [ "usage: hs2fol [options] FILE.hs"
  , ""
  , "Translates the Haskell program into first-order logic (TPTP), one problem"
  , "per property (top-level function whose name starts with \"prop\")."
  , ""
  , "  -o DIR          output directory (default: FILE-fol)"
  , "  -p, --prop P    only property P (can be repeated)"
  , "  --stdout        print the problems instead of writing files"
  , "  --list          list the properties"
  , "  -I DIR          extra directory to search for imported modules"
  , "  --decode        read prover output on stdin and print the counterexample"
  , "                  (use with -p PROP)"
  ]

parseOpts :: [String] -> Opts -> Either String Opts
parseOpts args o = case args of
  [] -> Right o
  ("-o" : d : r) -> parseOpts r o { oOut = Just d }
  ("-p" : p : r) -> parseOpts r o { oProps = oProps o ++ [p] }
  ("--prop" : p : r) -> parseOpts r o { oProps = oProps o ++ [p] }
  ("--stdout" : r) -> parseOpts r o { oStdout = True }
  ("--list" : r) -> parseOpts r o { oList = True }
  ("-I" : d : r) -> parseOpts r o { oIncludes = oIncludes o ++ [d] }
  ("--decode" : r) -> parseOpts r o { oDecode = True }
  (f : r)
    | f `elem` ["-h", "--help"] -> Left usage
    | "-" `isPrefixOf` f -> Left ("unknown option " ++ f ++ "\n\n" ++ usage)
    | otherwise -> case oFile o of
        Nothing -> parseOpts r o { oFile = Just f }
        Just _ -> Left ("more than one input file\n\n" ++ usage)

die' :: String -> IO a
die' msg = hPutStrLn stderr msg >> exitFailure

main :: IO ()
main = do
  args <- getArgs
  opts <- either die' return (parseOpts args defaultOpts)
  file <- maybe (die' usage) return (oFile opts)
  usr <- loadModules (oIncludes opts) file
  (_, pre) <- either (\e -> die' ("internal error in the Prelude: " ++ e)) return (parseModule "<Prelude>" preludeSource)
  tr <- either (\e -> die' ("hs2fol: " ++ e)) return (translateProgram pre usr)
  forM_ (trWarnings tr) $ \w -> hPutStrLn stderr ("warning: " ++ w)
  let props = trProps tr
  selected <- case oProps opts of
    [] -> return props
    names -> forM names $ \n -> case [ p | p <- props, psName p == n ] of
      (p : _) -> return p
      [] -> die' ("no (translatable) property " ++ n ++ "; properties: " ++ unwords (map psName props))
  if oList opts
    then forM_ props $ \p -> putStrLn (psName p ++ " :: " ++ prettyType (psType p))
    else if oDecode opts
      then do
        input <- getContents
        let mprop = case selected of
              [p] | not (null (oProps opts)) -> Just p
              _ -> Nothing
        case decodeAnswer tr mprop input of
          Left e -> die' ("hs2fol: could not decode the answer: " ++ e)
          Right ls -> do
            mapM_ putStrLn ls
            let tokens l = words (map (\c -> if c `elem` "()[],{};" then ' ' else c) l)
            when (any (any (\w -> take 1 w == "_" && length w > 1) . tokens) ls) $
              putStrLn "-- (names starting with _ stand for arbitrary values)"
      else if oStdout opts
        then forM_ selected $ \p -> putStr (renderProblem file tr p)
        else do
          let dir = maybe (dropExtension file ++ "-fol") id (oOut opts)
          createDirectoryIfMissing True dir
          when (null selected) $ hPutStrLn stderr "warning: no properties found (names must start with \"prop\")"
          forM_ selected $ \p -> do
            let path = dir </> (psName p ++ ".p")
            writeFile path (renderProblem file tr p)
            putStrLn ("wrote " ++ path)

-- | Load a module and (transitively) the local modules it imports.
loadModules :: [FilePath] -> FilePath -> IO [Decl]
loadModules incs root = do
  (_, ds) <- visit (S.empty, []) root
  return ds
  where
    visit (seen, acc) path = do
      exists <- doesFileExist path
      unless exists $ die' ("hs2fol: file not found: " ++ path)
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
      let cands = [ d </> modFile m | d <- dirs ]
      found <- filterM doesFileExist cands
      return (case found of
                (p : _) -> Just p
                [] -> Nothing)
    ignorable m = m == "Prelude" || any (`isPrefixOf` m) ["Test.QuickCheck", "Data.", "Control.", "System."]
