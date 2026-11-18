# Prover settings

`scripts/run-benchmarks.sh` runs the three provers as follows (`$1` is the
problem, `$2` the time limit, 60 s by default). Every run also gets a
wall-clock limit of time limit + 5 s, enforced from outside.

| prover | default command line in the runner |
|---|---|
| Vampire | `vampire $1 --mode casc --question_answering plain --proof tptp -t $2` |
| E | `eprover --auto --conjectures-are-questions --answers=1 --cpu-limit=$2 $1` |
| Twee | `twee $1` |

These are your settings plus the time limit. Override them with
`VAMPIRE_CMD`, `EPROVER_CMD` and `TWEE_CMD`, e.g.

```sh
EPROVER_CMD='eprover --auto-schedule --conjectures-are-questions --answers=1 --cpu-limit="$2" "$1"' \
  scripts/run-benchmarks.sh -P eprover -o results-e-schedule
```

The versions and command lines of a run are recorded in `results/provers.txt`.

## Suggestions

1. **Give each prover the time limit itself, not only an external kill.**
   Vampire's `--mode casc` and E's scheduling divide the available time
   between strategies. If they don't know the limit, they plan for a longer run
   and get killed part-way through the schedule. Hence `-t 60` (Vampire) and
   `--cpu-limit=60` (E). The external limit is only a safety net. Twee runs a
   single strategy, so an external limit is enough for it.

2. **E: try `--auto-schedule` instead of `--auto`.** `--auto` picks one
   strategy; `--auto-schedule` runs several in sequence. The E documentation
   calls strategy scheduling "usually stronger", and it adapts the schedule
   to `--cpu-limit`. This is worth a comparison run (the override above);
   answers work the same way.

3. **Same budget for everyone, one job per core.** Use `-j` at most the number
   of physical cores. That way parallel jobs don't steal time from each other
   and the 60 s are comparable across provers. Neither command line uses
   multiple cores. (If you want that, E has `--auto-schedule=N` and Vampire
   has `--cores N`, but then use `-j` = cores / N.)

4. **`--proof tptp` (Vampire) is harmless but not needed** to recover the
   counterexample: witness2input only reads the `SZS answers` line. Keep it if
   you want the proofs in the `solved` branch, which is what you asked for.

5. **Twee and answers.** All hs2fol problems are pure unit equality, which
   Twee handles. Twee has no SZS answer output, so witness2input looks for a
   block starting with a line containing "goal is true when" followed by
   `X1 = term` lines. This format is unverified. If your Twee version proves a
   goal but prints the instantiation differently, `<prover>.witness.err` will
   say so; send me an example output and I'll adapt the parser. Also check
   that your Twee version accepts the existentially quantified conjecture at all.

6. **Fairness of the comparison.** Count a property as *solved* only when
   witness2input confirms the witness, which is what record-solved.sh does.
   A prover status of `Theorem` alone could also come from a translation bug.
   Any entry in `solved/UNCONFIRMED.md` is such a bug and should be looked at
   first.
