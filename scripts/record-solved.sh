#!/usr/bin/env bash
# Copy the solved benchmarks from a results directory (made by
# run-benchmarks.sh) to the "solved" branch and commit them.
#
#   scripts/record-solved.sh [-o RESULTS] [-b BRANCH]
#
# A benchmark property counts as solved when at least one prover produced a
# witness that witness2input confirmed (the property returns False on it).
# For each one, the branch gets solved/<benchmark>/<property>/ with
#   README.md               which provers solved it, time, and the Haskell input
#   problem.p               the TPTP problem
#   <prover>.out            the prover's output
#   <prover>.witness.txt    the decoded input and the check result
# plus solved/SUMMARY.md (all solved properties) and solved/UNCONFIRMED.md
# (witnesses that were not confirmed; each of these points to a problem).
set -eu

HERE=$(cd "$(dirname "$0")/.." && pwd)
RESULTS=results
BRANCH=solved
while getopts "o:b:h" opt; do
  case $opt in
    o) RESULTS=$OPTARG ;;
    b) BRANCH=$OPTARG ;;
    *) sed -n '2,16p' "$0"; exit 2 ;;
  esac
done
RESULTS=$(cd "$RESULTS" && pwd)
SUMMARY=$RESULTS/summary.csv
[ -f "$SUMMARY" ] || { echo "no $SUMMARY; run scripts/run-benchmarks.sh first" >&2; exit 2; }

cd "$HERE"
git rev-parse --verify -q "$BRANCH" >/dev/null || { echo "branch $BRANCH does not exist" >&2; exit 2; }
WT=$(mktemp -d)
git worktree add -q "$WT" "$BRANCH"
trap 'git worktree remove --force "$WT"' EXIT

mkdir -p "$WT/solved"
SOLVED_LIST=$(mktemp)
grep ',CONFIRMED$' "$SUMMARY" | cut -d, -f1,2 | sort -u > "$SOLVED_LIST" || true

while IFS=, read -r bench prop; do
  src=$RESULTS/$bench/$prop
  dst=$WT/solved/$bench/$prop
  rm -rf "$dst"
  mkdir -p "$dst"
  cp "$src/problem.p" "$dst/"
  {
    echo "# $prop ($bench)"
    echo
    echo "| prover | SZS status | seconds | witness |"
    echo "|---|---|---|---|"
    grep "^$bench,$prop," "$SUMMARY" | awk -F, '{printf "| %s | %s | %s | %s |\n", $3, $4, $5, $6}'
    echo
  } > "$dst/README.md"
  first=1
  for res in $(grep "^$bench,$prop,.*,CONFIRMED$" "$SUMMARY" | cut -d, -f3); do
    cp "$src/$res.out" "$dst/"
    cp "$src/$res.witness.txt" "$dst/"
    if [ $first = 1 ]; then
      {
        echo "Counterexample (decoded from the $res witness, checked with GHC):"
        echo
        echo '```'
        cat "$src/$res.witness.txt"
        echo '```'
      } >> "$dst/README.md"
      first=0
    fi
  done
done < "$SOLVED_LIST"

{
  echo "# Solved benchmarks"
  echo
  echo "Results from $(basename "$RESULTS") (recorded $(date -u +%Y-%m-%d)). A property is solved when a prover"
  echo "found a witness and witness2input confirmed that the property returns False on it."
  echo
  echo "| benchmark | property | solved by | input |"
  echo "|---|---|---|---|"
  while IFS=, read -r bench prop; do
    provers=$(grep "^$bench,$prop,.*,CONFIRMED$" "$SUMMARY" | awk -F, '{printf "%s%s (%ss)", sep, $3, $5; sep=", "}')
    input=$(grep -h '^input:' "$WT/solved/$bench/$prop/"*.witness.txt | head -n 1 | sed 's/^input: *//; s/|/\\|/g')
    echo "| $bench | $prop | $provers | \`$input\` |"
  done < "$SOLVED_LIST"
} > "$WT/solved/SUMMARY.md"

{
  echo "# Unconfirmed witnesses"
  echo
  echo "Witnesses a prover produced that witness2input did not confirm. Each of"
  echo "these indicates a problem (in hs2fol, the decoder, or the check) and"
  echo "should be investigated."
  echo
  echo "| benchmark | property | prover | status | check |"
  echo "|---|---|---|---|---|"
  grep -E ',(NOT_A_COUNTEREXAMPLE|CHECK_ERROR)$' "$SUMMARY" | awk -F, '{printf "| %s | %s | %s | %s | %s |\n", $1, $2, $3, $4, $6}' || true
} > "$WT/solved/UNCONFIRMED.md"

cp "$SUMMARY" "$WT/solved/all-results.csv"
NSOLVED=$(grep -c . "$SOLVED_LIST" || true)
rm -f "$SOLVED_LIST"

cd "$WT"
git add -A solved
if git diff --cached --quiet; then
  echo "nothing new to record"
else
  git commit -q -m "Record solved benchmarks ($(date -u +%Y-%m-%d))"
  echo "committed $NSOLVED solved properties to branch $BRANCH"
fi
