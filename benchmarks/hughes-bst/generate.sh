#!/bin/sh
# Regenerate BSTSpec0.hs .. BSTSpec8.hs from the template.
# BSTSpec0 tests the correct implementation BST.hs; BSTSpecN tests BSTN.hs.
set -eu
cd "$(dirname "$0")"
gen() { # number impl description
  sed -e "s/@MODULE@/BSTSpec$1/" -e "s/@IMPL@/$2/g" -e "s/@DESCRIPTION@/$3/" \
    template/BSTSpec.template.hs > "BSTSpec$1.hs"
}
gen 0 BST  "the correct implementation; every counterexample here is a genuine failure of the property itself"
gen 1 BST1 "bug 1: insert discards the existing tree"
gen 2 BST2 "bug 2: insert duplicates an existing key instead of updating it"
gen 3 BST3 "bug 3: insert does not update the value of an existing key"
gen 4 BST4 "bug 4: delete does not rebuild the tree above the deleted key"
gen 5 BST5 "bug 5: key comparisons reversed in delete"
gen 6 BST6 "bug 6: union assumes all keys of the first tree precede those of the second"
gen 7 BST7 "bug 7: union assumes that if the root of t is smaller than the root of t', all of t is"
gen 8 BST8 "bug 8: union does not always give the left argument priority"
