-- | hs2fol command line.
module Main (main) where

import Control.Monad
import Data.List (isPrefixOf)
import Decode
import Load
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
  , oUntyped :: Bool
  , oTff0 :: Bool
  }

defaultOpts :: Opts
defaultOpts = Opts Nothing Nothing [] False False [] False False False

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
  , "  --untyped       write untyped FOF instead of polymorphic TF1 problems"
  , "  --tff0          write monomorphic typed TFF0 problems (full monomorphisation)"
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
  ("--untyped" : r) -> parseOpts r o { oUntyped = True }
  ("--tff0" : r) -> parseOpts r o { oTff0 = True }
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
  (pre, usr, own) <- loadProgram (oIncludes opts) file
  tr <- either (\e -> die' ("hs2fol: " ++ e)) return (translateProgram (modeOf opts) pre usr)
  forM_ (trWarnings tr) $ \w -> hPutStrLn stderr ("warning: " ++ w)
  let props = [ p | p <- trProps tr, psName p `elem` own ]
  selected <- case oProps opts of
    [] -> return props
    names -> forM names $ \n -> case [ p | p <- props, psName p == n ] of
      (p : _) -> return p
      [] -> die' ("no (translatable) property " ++ n ++ "; properties: " ++ unwords (map psName props))
  if oList opts
    then forM_ props $ \p -> putStrLn (psName p ++ " :: " ++ prettyType (psType p))
    else if oDecode opts
      then do
        hSetEncoding stdin utf8
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

-- | Output format: TF1 (polymorphic typed) unless --untyped or --tff0.
modeOf :: Opts -> Mode
modeOf o
  | oUntyped o = MUntyped
  | oTff0 o = MTFF0
  | otherwise = MTF1
