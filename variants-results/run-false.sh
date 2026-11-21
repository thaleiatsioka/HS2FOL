#!/bin/bash
# usage: run-false.sh WORKTREE OUTDIR TIME PROVERS JOBS [PASS|FAIL]
WT=$1; OUT=$2; T=$3; P=$4; J=$5; WHICH=${6:-FAIL}
export PATH=/opt/provers/bin:$PATH
mkdir -p "$OUT"
for i in 0 1 2 3 4 5 6 7 8; do
  props=$(awk -v b=BSTSpec$i -v w=$WHICH '$1==b && $3==w {print $2}' /tmp/qc/truth.txt | paste -sd'|')
  [ -z "$props" ] && continue
  "$WT/scripts/run-benchmarks.sh" -t "$T" -j "$J" -P "$P" -o "$OUT/BSTSpec$i" -p "^($props)\$" /tmp/bwt/benchmarks/hughes-bst/BSTSpec$i.hs > "$OUT/BSTSpec$i.log" 2>&1
done
{ echo "benchmark,property,prover,status,seconds,witness"
  for f in "$OUT"/BSTSpec*/summary.csv; do tail -n +2 "$f"; done; } > "$OUT/summary.csv"
echo DONE
