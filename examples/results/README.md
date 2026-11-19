# Results for the example programs

`scripts/run-benchmarks.sh -t 60 -j 2 -o examples/results examples/Nat.hs examples/Lists.hs examples/HigherOrder.hs`
(Vampire 5.1.1, E 3.5.10, Twee 2.6.2; versions and command lines in `provers.txt`).

* `summary.md` / `summary.csv`: one row per property and prover.
* `<file>/<property>/`: the TPTP problem, each prover's output, and
  witness2input's report (`<prover>.witness.txt`) for every witness.

All false properties are solved by all three provers with confirmed
counterexamples, except `HigherOrder/prop_mapFilter`. There, all three
provers return an ill-typed witness (`p = \x -> x` applied to Booleans
where `Nat`s are expected): the builder `fn_id` is untyped. The true
properties time out (no prover claims a proof for them).
