# Benchmarks

Haskell programs with QuickCheck-style properties for evaluating hs2fol
with E, Vampire and Twee. Every top-level `prop_*` in a benchmark file is one
benchmark problem.

| directory | source | problems |
|---|---|---|
| [hughes-bst](hughes-bst) | Hughes, *How to Specify It!* (TFP 2019): BST with 8 bugs | 9 × 40 |
| [etna](etna) | Etna (Shi et al., ICFP 2023): red-black trees with 15 mutants, STLC with 10 mutants | 16 × 10 + 11 × 2 |

## Running

```sh
make                                     # builds hs2fol and witness2input
scripts/run-benchmarks.sh -j 4           # all benchmarks, 3 provers, 60 s each
scripts/run-benchmarks.sh -j 4 benchmarks/hughes-bst/BSTSpec1.hs
scripts/run-benchmarks.sh -p 'Insert' -P vampire benchmarks/hughes-bst/BSTSpec*.hs
scripts/record-solved.sh                 # commit the solved ones to branch "solved"
```

`run-benchmarks.sh` writes, for every benchmark property,
`results/<benchmark>/<property>/` containing:

* `problem.p`, the TPTP problem;
* `<prover>.out`, the raw prover output;
* `<prover>.witness.txt`, the decoded Haskell input and the check result.

It also writes `results/summary.csv` and `results/summary.md`. A witness is
checked by `witness2input`, which runs the property on the decoded input with
GHC (`runghc`; QuickCheck must be installed).

`record-solved.sh` copies every property with a confirmed counterexample to
the `solved` branch, under `solved/<benchmark>/<property>/`. It also writes
`solved/SUMMARY.md` and `solved/UNCONFIRMED.md`, which lists witnesses that
did not check out.

## Adding benchmarks

Put the program in a new directory with a README stating its source and any
adaptations. Files that define `prop_*` functions are picked up by
`run-benchmarks.sh`; files in directories called `template` are skipped.
