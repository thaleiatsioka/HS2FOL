#!/usr/bin/env bash
# Run the theorem provers on every property of every benchmark and check
# each witness with witness2input.
#
#   scripts/run-benchmarks.sh [options] [FILE.hs ...]
#
#   -t SECS     prover time limit (default 60)
#   -j N        number of (file, property) jobs to run in parallel (default 1)
#   -P LIST     provers, comma separated (default vampire,eprover,twee)
#   -o DIR      results directory (default results)
#   -p REGEX    only properties whose name matches REGEX (grep -E)
#
# Without FILE arguments, all files under benchmarks/ that define properties
# (lines starting with "prop") are run; directories called "template" are skipped.
#
# Prover command lines can be overridden with environment variables; the
# problem file and the time limit are passed as $1 and $2:
#   VAMPIRE_CMD  default: vampire "$1" --mode casc --question_answering plain --proof tptp -t "$2"
#   EPROVER_CMD  default: eprover --auto --conjectures-are-questions --answers=1 --cpu-limit="$2" "$1"
#   TWEE_CMD     default: twee "$1"
# Every prover additionally runs under a wall-clock limit of SECS+5 seconds.
#
# Results: DIR/<benchmark>/<property>/{problem.p, <prover>.out,
# <prover>.witness.txt, <prover>.result}, DIR/summary.csv, DIR/summary.md and
# DIR/provers.txt (prover versions and command lines).
# Use scripts/record-solved.sh to commit the solved ones to the solved branch.
set -u

HERE=$(cd "$(dirname "$0")/.." && pwd)
HS2FOL=${HS2FOL:-$HERE/hs2fol}
WITNESS2INPUT=${WITNESS2INPUT:-$HERE/witness2input}
TIME=60
JOBS=1
PROVERS=vampire,eprover,twee
OUT=results
PROPRE=.

while getopts "t:j:P:o:p:h" opt; do
  case $opt in
    t) TIME=$OPTARG ;;
    j) JOBS=$OPTARG ;;
    P) PROVERS=$OPTARG ;;
    o) OUT=$OPTARG ;;
    p) PROPRE=$OPTARG ;;
    *) sed -n '2,30p' "$0"; exit 2 ;;
  esac
done
shift $((OPTIND - 1))

for tool in "$HS2FOL" "$WITNESS2INPUT"; do
  [ -x "$tool" ] || { echo "missing $tool (run make)" >&2; exit 2; }
done

if [ $# -gt 0 ]; then
  FILES=("$@")
else
  FILES=()
  while IFS= read -r f; do FILES+=("$f"); done < <(find "$HERE/benchmarks" -name '*.hs' -not -path '*/template/*' -exec grep -l '^prop' {} + | sort)
fi
mkdir -p "$OUT"
OUT=$(cd "$OUT" && pwd)

export HS2FOL WITNESS2INPUT TIME PROVERS OUT HERE

# record the prover versions and settings of this run
{
  echo "date: $(date -u '+%Y-%m-%d %H:%M UTC')"
  echo "host: $(uname -srm)"
  echo "time limit: ${TIME}s"
  for p in ${PROVERS//,/ }; do
    echo "== $p"
    case $p in
      vampire) echo "command: ${VAMPIRE_CMD:-vampire FILE --mode casc --question_answering plain --proof tptp -t $TIME}"; vampire --version ;;
      eprover) echo "command: ${EPROVER_CMD:-eprover --auto --conjectures-are-questions --answers=1 --cpu-limit=$TIME FILE}"; eprover --version ;;
      twee) echo "command: ${TWEE_CMD:-twee FILE}"; twee --version ;;
    esac 2>&1 | head -n 4
  done
} > "$OUT/provers.txt"

run_with_timeout() { # secs cmd...
  local secs=$1; shift
  if command -v timeout >/dev/null 2>&1; then timeout "$secs" "$@"
  elif command -v gtimeout >/dev/null 2>&1; then gtimeout "$secs" "$@"
  else perl -e 'alarm shift; exec @ARGV' "$secs" "$@"
  fi
}

now() { perl -MTime::HiRes=time -e 'printf "%.2f\n", time'; }

prover_cmd() { # prover problem secs  (run in its own bash: it execs the prover)
  case $1 in
    vampire) if [ -n "${VAMPIRE_CMD:-}" ]; then exec bash -c "$VAMPIRE_CMD" _ "$2" "$3"
             else exec vampire "$2" --mode casc --question_answering plain --proof tptp -t "$3"; fi ;;
    eprover) if [ -n "${EPROVER_CMD:-}" ]; then exec bash -c "$EPROVER_CMD" _ "$2" "$3"
             else exec eprover --auto --conjectures-are-questions --answers=1 --cpu-limit="$3" "$2"; fi ;;
    twee)    if [ -n "${TWEE_CMD:-}" ]; then exec bash -c "$TWEE_CMD" _ "$2" "$3"
             else exec twee "$2"; fi ;;
    *) echo "unknown prover $1" >&2; return 2 ;;
  esac
}

bench_id() { # file -> path relative to benchmarks/ without .hs
  local f
  f=$(cd "$(dirname "$1")" && pwd)/$(basename "$1" .hs)
  case $f in
    "$HERE"/benchmarks/*) echo "${f#"$HERE"/benchmarks/}" ;;
    *) basename "$1" .hs ;;
  esac
}

run_job() { # file prop
  local file=$1 prop=$2 id d prover start end secs status verdict rc
  id=$(bench_id "$file")
  d=$OUT/$id/$prop
  mkdir -p "$d"
  if ! "$HS2FOL" --stdout -p "$prop" "$file" > "$d/problem.p" 2> "$d/hs2fol.err"; then
    echo "$id,$prop,hs2fol,ERROR,0,-" > "$d/hs2fol.result"
    echo "[$id] $prop: hs2fol failed" >&2
    return
  fi
  IFS=, read -r -a plist <<< "$PROVERS"
  for prover in "${plist[@]}"; do
    start=$(now)
    run_with_timeout $((TIME + 5)) bash -c 'prover_cmd "$@"' _ "$prover" "$d/problem.p" "$TIME" > "$d/$prover.out" 2>&1
    rc=$?
    end=$(now)
    secs=$(perl -e "printf '%.2f', $end - $start")
    status=$(grep -o "SZS status [A-Za-z]*" "$d/$prover.out" | head -n 1 | awk '{print $3}')
    [ -n "$status" ] || status=$(grep -o "RESULT: [A-Za-z]*" "$d/$prover.out" | head -n 1 | awk '{print $2}')
    if [ -z "$status" ]; then
      case $rc in 124|137|142) status=Timeout ;; *) status=NoResult ;; esac
    fi
    verdict=-
    if grep -qi -e "SZS answers" -e "goal is true when" "$d/$prover.out"; then
      "$WITNESS2INPUT" --prover "$prover" -o "$d/$prover.witness.txt" "$file" "$prop" "$d/$prover.out" > /dev/null 2> "$d/$prover.witness.err"
      case $? in
        0) verdict=CONFIRMED ;;
        1) verdict=NOT_A_COUNTEREXAMPLE ;;
        *) verdict=CHECK_ERROR ;;
      esac
    fi
    echo "$id,$prop,$prover,$status,$secs,$verdict" > "$d/$prover.result"
    echo "[$id] $prop: $prover $status ${secs}s $verdict" >&2
  done
}

export -f run_with_timeout now prover_cmd bench_id run_job

# list the jobs
JOBLIST=$(mktemp)
for f in "${FILES[@]}"; do
  if ! props=$("$HS2FOL" --list "$f" 2> /dev/null); then
    echo "hs2fol cannot translate $f:" >&2
    "$HS2FOL" --list "$f" >/dev/null
    continue
  fi
  echo "$props" | awk '{print $1}' | grep -E "$PROPRE" | while read -r p; do
    printf '%s\t%s\n' "$f" "$p"
  done >> "$JOBLIST"
done
echo "$(wc -l < "$JOBLIST" | tr -d ' ') properties, provers: $PROVERS, ${TIME}s each, $JOBS in parallel" >&2

tr '\t' '\n' < "$JOBLIST" | xargs -n 2 -P "$JOBS" bash -c 'run_job "$1" "$2"' _
rm -f "$JOBLIST"

# summaries
{
  echo "benchmark,property,prover,status,seconds,witness"
  find "$OUT" -name '*.result' | sort | xargs cat
} > "$OUT/summary.csv"

{
  echo "| benchmark | property | prover | status | seconds | witness |"
  echo "|---|---|---|---|---|---|"
  tail -n +2 "$OUT/summary.csv" | awk -F, '{printf "| %s | %s | %s | %s | %s | %s |\n", $1, $2, $3, $4, $5, $6}'
  echo
  echo "Confirmed counterexamples: $(grep -c ',CONFIRMED$' "$OUT/summary.csv")"
  echo "Witnesses that are NOT counterexamples (would indicate a translation bug): $(grep -c ',NOT_A_COUNTEREXAMPLE$' "$OUT/summary.csv")"
  echo "Witnesses that could not be checked: $(grep -c ',CHECK_ERROR$' "$OUT/summary.csv")"
} > "$OUT/summary.md"

echo "summary: $OUT/summary.md" >&2
