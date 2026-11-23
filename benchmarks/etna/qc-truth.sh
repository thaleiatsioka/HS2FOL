#!/bin/bash
# QuickCheck ground truth for every (variant, property) pair, using Etna's
# generators (the Arbitrary instances in the templates). Writes qc-truth.txt:
#   <variant> <property> PASS|FAIL
# usage: ./qc-truth.sh [TESTS]   (default 100000)
set -eu
cd "$(dirname "$0")"
N=${1:-100000}
B=$(mktemp -d)
: > qc-truth.txt
for w in RBT STLC; do
  for f in $w/${w}_*.hs; do
    mod=$(basename $f .hs)
    props=$(grep -o '^prop_[A-Za-z0-9_]*' $f | sort -u)
    {
      echo "module Main (main) where"
      echo "import $mod"
      echo "import Test.QuickCheck"
      echo "main :: IO ()"
      echo "main = do"
      for p in $props; do
        echo "  r_$p <- quickCheckWithResult stdArgs { chatty = False } (withMaxSuccess $N ($p))"
        echo "  putStrLn (\"$mod $p \" ++ (if isSuccess r_$p then \"PASS\" else \"FAIL\"))"
      done
    } > $B/Main_$mod.hs
    ghc -O1 -v0 -w -i$w -outputdir $B/o_$mod -o $B/qc_$mod $B/Main_$mod.hs
    $B/qc_$mod | tee -a qc-truth.txt
  done
done
rm -rf "$B"
