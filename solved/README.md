# Solved benchmarks

This branch is the `benchmarks` branch plus the benchmarks for which a
theorem prover found a counterexample that witness2input confirmed (the
property really returns `False` on the decoded input).

It is filled by `scripts/record-solved.sh` after a run of
`scripts/run-benchmarks.sh`; nothing has been recorded yet. Layout:

```
solved/SUMMARY.md                     every solved property: provers, times, input
solved/UNCONFIRMED.md                 witnesses that did NOT check out (translation bugs)
solved/all-results.csv                all runs (also the unsolved ones)
solved/provers.txt                    prover versions and command lines
solved/<benchmark>/<property>/
    README.md                         status per prover, the concrete Haskell input
    problem.p                         the TPTP problem
    <prover>.out                      output of each prover that solved it
    <prover>.witness.txt              decoded input and check result, per prover
```

`<benchmark>` is the path of the benchmark file below `benchmarks/`, without
`.hs` (e.g. `hughes-bst/BSTSpec3`).

To update after new runs: merge `benchmarks` into this branch, then run
`scripts/record-solved.sh` from any branch.
