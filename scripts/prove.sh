#!/bin/sh
# Look for a counterexample to one property with a theorem prover.
#
#   scripts/prove.sh FILE.hs PROP [vampire|eprover|twee] [TIMEOUT]
#
# Vampire and E print the answer substitution, which hs2fol --decode turns
# back into Haskell. Twee has no answer extraction: its proof is printed and
# the instantiation can be pasted into `hs2fol --decode -p PROP FILE.hs`.
set -eu

if [ $# -lt 2 ]; then
  echo "usage: $0 FILE.hs PROP [vampire|eprover|twee] [TIMEOUT]" >&2
  exit 2
fi

FILE=$1
PROP=$2
PROVER=${3:-vampire}
TIMEOUT=${4:-30}
HS2FOL=${HS2FOL:-hs2fol}

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

"$HS2FOL" --stdout -p "$PROP" "$FILE" > "$TMP/problem.p"

case "$PROVER" in
  vampire)
    vampire --mode casc -t "$TIMEOUT" --question_answering answer_literal "$TMP/problem.p" > "$TMP/out.txt" || true
    ;;
  eprover|e)
    eprover --auto --answers=1 --cpu-limit="$TIMEOUT" "$TMP/problem.p" > "$TMP/out.txt" || true
    ;;
  twee)
    twee --quiet "$TMP/problem.p" || true
    exit 0
    ;;
  *)
    echo "unknown prover $PROVER" >&2
    exit 2
    ;;
esac

if grep -q "SZS answers" "$TMP/out.txt"; then
  echo "Counterexample found:"
  "$HS2FOL" --decode -p "$PROP" "$FILE" < "$TMP/out.txt"
elif grep -q "SZS status Theorem" "$TMP/out.txt"; then
  echo "Proved, but the prover printed no answer:"
  cat "$TMP/out.txt"
else
  echo "No counterexample found:"
  grep "SZS status" "$TMP/out.txt" || tail -n 5 "$TMP/out.txt"
fi
