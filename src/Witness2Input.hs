-- | witness2input: turn the witness a theorem prover found for a property's
-- conjecture back into a concrete Haskell input, and check with GHC that the
-- property really returns False on it.
module Main (main) where

import Control.Exception (IOException, SomeException, catch, fromException, throwIO, try)
import Control.Monad
import Data.Char (isSpace)
import Data.List (isInfixOf, isPrefixOf)
import Decode
import Load
import System.Directory
import System.Environment
import System.Exit
import System.FilePath
import System.IO
import System.Process
import Translate

data Opts = Opts
  { oFile :: Maybe FilePath
  , oProp :: Maybe String
  , oWitness :: Maybe FilePath -- ^ prover output (default: stdin)
  , oIncludes :: [FilePath]
  , oRunghc :: String
  , oNoRun :: Bool
  , oKeep :: Bool
  , oOut :: Maybe FilePath
  , oProver :: String
  , oTimeout :: Int
  }

defaultOpts :: Opts
defaultOpts = Opts Nothing Nothing Nothing [] "runghc" False False Nothing "" 10

usage :: String
usage = unlines
  [ "usage: witness2input [options] FILE.hs PROP [PROVER-OUTPUT]"
  , ""
  , "Reads the output of Vampire, E or Twee for the hs2fol problem of property"
  , "PROP (from the file PROVER-OUTPUT, or stdin), turns the witness into Haskell"
  , "arguments and runs the property on them with GHC."
  , ""
  , "  -I DIR          extra directory for imported modules (also passed to GHC)"
  , "  --runghc CMD    command used to run the check (default: runghc)"
  , "  --timeout SEC   time limit for evaluating the property (default: 10)"
  , "  --no-run        only print the Haskell input, do not run it"
  , "  --keep          keep the generated check program"
  , "  --prover NAME   name of the prover (only used in the report)"
  , "  -o FILE         also write the report to FILE"
  , ""
  , "Exit status: 0 counterexample confirmed (property returned False);"
  , "1 not confirmed (True, or precondition false); 2 error (no witness,"
  , "exception, timeout, compile error); 3 the witness is ill-typed in Haskell."
  , ""
  , "Variables left in the witness mean that any value works; they are"
  , "replaced by 'undefined', which is a legitimate value for such positions."
  ]

parseOpts :: [String] -> Opts -> Either String Opts
parseOpts args o = case args of
  [] -> Right o
  ("-I" : d : r) -> parseOpts r o { oIncludes = oIncludes o ++ [d] }
  ("--runghc" : c : r) -> parseOpts r o { oRunghc = c }
  ("--timeout" : t : r) | all (`elem` "0123456789") t, not (null t) -> parseOpts r o { oTimeout = read t }
  ("--no-run" : r) -> parseOpts r o { oNoRun = True }
  ("--keep" : r) -> parseOpts r o { oKeep = True }
  ("--prover" : p : r) -> parseOpts r o { oProver = p }
  ("-o" : f : r) -> parseOpts r o { oOut = Just f }
  (a : r)
    | a `elem` ["-h", "--help"] -> Left usage
    | "-" `isPrefixOf` a && a /= "-" -> Left ("unknown option " ++ a ++ "\n\n" ++ usage)
    | otherwise -> case (oFile o, oProp o, oWitness o) of
        (Nothing, _, _) -> parseOpts r o { oFile = Just a }
        (_, Nothing, _) -> parseOpts r o { oProp = Just a }
        (_, _, Nothing) -> parseOpts r o { oWitness = Just a }
        _ -> Left ("too many arguments\n\n" ++ usage)

data Verdict = Confirmed | NotConfirmed String | Problem String | IllTyped String

main :: IO ()
main = mainBody `catch` \e -> case fromException e of
  Just code -> throwIO (code :: ExitCode)
  Nothing -> do
    hPutStrLn stderr ("witness2input: " ++ show (e :: SomeException))
    exitWith (ExitFailure 2)

mainBody :: IO ()
mainBody = do
  args <- getArgs
  opts <- either (\e -> hPutStrLn stderr e >> exitWith (ExitFailure 2)) return (parseOpts args defaultOpts)
  (file, propName) <- case (oFile opts, oProp opts) of
    (Just f, Just p) -> return (f, p)
    _ -> hPutStrLn stderr usage >> exitWith (ExitFailure 2)
  input <- case oWitness opts of
    Just w | w /= "-" -> readFileUtf8 w
    _ -> hSetEncoding stdin utf8 >> getContents
  (pre, usr, _) <- loadProgram (oIncludes opts) file
  tr <- either (fatal . ("hs2fol: " ++)) return (translateProgram pre usr)
  prop <- case [ p | p <- trProps tr, psName p == propName ] of
    (p : _) -> return p
    [] -> fatal ("no (translatable) property " ++ propName)
  witnesses <- either (fatal . ("could not find a witness in the prover output: " ++)) return
                 (extractWitnesses (psArity prop) input)
  w <- case witnesses of
    (w : _) | length w == psArity prop -> return w
            | otherwise -> fatal ("the witness has " ++ show (length w) ++ " values, but " ++ propName ++ " takes " ++ show (psArity prop) ++ " arguments")
    [] -> fatal "the prover output contains no witness"
  raw <- either (fatal . ("could not decode the witness: " ++)) return (decodeArgs VarsAsHoles tr w)
  let w' = normaliseWitness tr w
  holes <- either (fatal . ("could not decode the witness: " ++)) return (decodeArgs VarsAsHoles tr w')
  concrete <- either (fatal . ("could not decode the witness: " ++)) return (decodeArgs VarsAsUndefined tr w')
  let expr = unwords (propName : concrete)
      header =
        [ "property:   " ++ propName
        , "file:       " ++ file ]
        ++ [ "prover:     " ++ oProver opts | not (null (oProver opts)) ]
        ++ [ "witness:    " ++ unwords (propName : raw) ]
        ++ [ "evaluated:  " ++ unwords (propName : holes) | holes /= raw ]
        ++ [ "input:      " ++ expr ]
        ++ [ "            (variables in the witness can be any value; undefined is used)" | holes /= concrete ]
  verdict <- if oNoRun opts then return Nothing else Just <$> runCheck opts file propName concrete
  let (verdictLines, code) = case verdict of
        Nothing -> (["result:     not run (--no-run)"], ExitSuccess)
        Just Confirmed -> (["result:     False -- counterexample confirmed"], ExitSuccess)
        Just (NotConfirmed why) -> (["result:     NOT a counterexample: " ++ why], ExitFailure 1)
        Just (Problem why) -> (["result:     ERROR: " ++ why], ExitFailure 2)
        Just (IllTyped why) -> (["result:     ILL-TYPED witness (the untyped logic allows it, Haskell does not):", why], ExitFailure 3)
      report = unlines (header ++ verdictLines)
  putStr report
  forM_ (oOut opts) $ \f -> writeFile f report
  exitWith code
  where
    fatal msg = hPutStrLn stderr ("witness2input: " ++ msg) >> exitWith (ExitFailure 2)

-- | Generate a small program that evaluates the property on the input, and
-- run it with runghc.
runCheck :: Opts -> FilePath -> String -> [String] -> IO Verdict
runCheck opts file propName argExprs = do
  src <- readFile file
  tmpBase <- getTemporaryDirectory
  dir <- createTempDir tmpBase
  let usesQC = "Test.QuickCheck" `isInfixOf` src
      target = dir </> "W2ITarget.hs"
      check = dir </> "W2ICheck.hs"
  writeFile target (renameModule "W2ITarget" src)
  writeFile check (checkProgram usesQC (importsOf src) (oTimeout opts) propName argExprs)
  let incs = takeDirectory file : oIncludes opts ++ [dir]
      (cmd : cmdArgs) = words (oRunghc opts)
      ghcArgs = cmdArgs ++ [ "--ghc-arg=-i" ++ d | d <- incs ] ++ [check]
  r <- try (readProcessWithExitCode cmd ghcArgs "") :: IO (Either IOException (ExitCode, String, String))
  unless (oKeep opts) $ removeDirectoryRecursive dir
  when (oKeep opts) $ hPutStrLn stderr ("check program kept in " ++ dir)
  return $ case r of
    Left e -> Problem ("could not run " ++ cmd ++ ": " ++ show e)
    Right (_, out, err) ->
      case [ drop (length marker) l | l <- lines out, marker `isPrefixOf` l ] of
        ("FALSE" : _) -> Confirmed
        ("TRUE" : _) -> NotConfirmed "the property returned True"
        ("DISCARDED" : _) -> NotConfirmed "the precondition (==>) is False, so the test is discarded"
        (other : _) -> Problem (trim other)
        []
          | any (`isInfixOf` err) typeErrors && "W2ICheck.hs" `isInfixOf` err -> IllTyped (indent err)
          | otherwise -> Problem ("the check program did not run:\n" ++ indent (out ++ err))
  where
    marker = "W2I-RESULT: "
    typeErrors = ["Couldn't match", "No instance for", "Occurs check", "cannot construct the infinite type"]
    trim = dropWhile isSpace
    indent = unlines . map ("    " ++) . lines

createTempDir :: FilePath -> IO FilePath
createTempDir base = go (0 :: Int)
  where
    go n = do
      let d = base </> ("witness2input-" ++ show n)
      exists <- doesDirectoryExist d
      if exists
        then go (n + 1)
        else createDirectory d >> return d

-- | Give the module a new name (and drop its export list, so that every
-- top-level definition is visible to the check program).
renameModule :: String -> String -> String
renameModule newName src =
  let ls = lines src
      (before, rest) = break isHeader ls
  in case rest of
       [] ->
         let (pragmas, body) = span isPragmaOrBlank ls
         in unlines (pragmas ++ ["module " ++ newName ++ " where"] ++ body)
       (_ : _) ->
         let headerAndAfter = unlines rest
             afterWhere = dropThroughWhere headerAndAfter
         in unlines before ++ "module " ++ newName ++ " where" ++ afterWhere
  where
    isHeader l = "module " `isPrefixOf` l || l == "module"
    isPragmaOrBlank l = "{-#" `isPrefixOf` dropWhile isSpace l || all isSpace l || "--" `isPrefixOf` dropWhile isSpace l
    -- drop everything up to and including the first "where" token
    dropThroughWhere = go ' '
      where
        go _ [] = []
        go prev s
          | not (isIdChar prev) && "where" `isPrefixOf` s && boundary (drop 5 s) = drop 5 s
        go _ (c : r) = go c r
    boundary r = case r of
      [] -> True
      (c : _) -> not (isIdChar c)
    isIdChar c = c `elem` ('_' : '\'' : ['a' .. 'z'] ++ ['A' .. 'Z'] ++ ['0' .. '9'])

-- | The import declarations of a module (so that the check program sees the
-- same names, e.g. constructors from imported modules).
importsOf :: String -> [String]
importsOf src = go (lines src)
  where
    go [] = []
    go (l : rest)
      | "import " `isPrefixOf` l =
          let (cont, rest') = span (\x -> not (null x) && isSpace (head x)) rest
          in unwords (l : map (dropWhile isSpace) cont) : go rest'
      | otherwise = go rest

checkProgram :: Bool -> [String] -> Int -> String -> [String] -> String
checkProgram usesQC imports secs propName argExprs = unlines $
  [ "module Main (main) where"
  , ""
  , "import W2ITarget hiding (main)"
  ]
    ++ imports ++
  [ "import qualified Control.Exception as W2I_E"
  , "import qualified System.Timeout as W2I_T"
  ]
    ++ [ "import qualified Test.QuickCheck as W2I_QC" | usesQC ]
    ++
  [ ""
  , "main :: IO ()"
  , "main = do"
  , "  r <- W2I_T.timeout " ++ show (secs * 1000000) ++ " (W2I_E.try w2iRun)"
  , "  case r of"
  , "    Nothing -> putStrLn \"W2I-RESULT: TIMEOUT: the property did not finish within " ++ show secs ++ " seconds\""
  , "    Just (Left e) -> putStrLn (\"W2I-RESULT: EXCEPTION: \" ++ w2iOneLine (show (e :: W2I_E.SomeException)))"
  , "    Just (Right s) -> putStrLn (\"W2I-RESULT: \" ++ s)"
  , ""
  , "w2iOneLine :: String -> String"
  , "w2iOneLine = map (\\c -> if c == '\\n' then ' ' else c)"
  , ""
  , "w2iRun :: IO String"
  ]
    ++ (if usesQC then qcRun else boolRun)
  where
    call = "(" ++ unwords (propName : argExprs) ++ ")"
    boolRun =
      [ "w2iRun = do"
      , "  b <- W2I_E.evaluate " ++ call
      , "  return (if b then \"TRUE\" else \"FALSE\")"
      ]
    qcRun =
      [ "w2iRun = do"
      , "  res <- W2I_QC.quickCheckWithResult W2I_QC.stdArgs { W2I_QC.maxSuccess = 1, W2I_QC.chatty = False }"
      , "           (W2I_QC.once (W2I_QC.property " ++ call ++ "))"
      , "  return $ case res of"
      , "    W2I_QC.Success {} -> \"TRUE\""
      , "    W2I_QC.GaveUp {} -> \"DISCARDED\""
      , "    W2I_QC.Failure { W2I_QC.theException = Just e } -> \"EXCEPTION: \" ++ w2iOneLine (show e)"
      , "    W2I_QC.Failure {} -> \"FALSE\""
      , "    _ -> \"OTHER: \" ++ w2iOneLine (W2I_QC.output res)"
      ]
