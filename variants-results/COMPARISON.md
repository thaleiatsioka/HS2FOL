# hs2fol encodings compared on the BST benchmarks

Only the 94 properties that QuickCheck (10,000 tests) finds false can have a counterexample. A property counts as solved when a prover's witness, decoded to Haskell, makes the property return False in GHC. Every prover ran with a 60 s limit on each false property. Vampire 5.1.1, E 3.5.10, Twee 2.6.2, with the command lines in PROVERS.md.

| | untyped | typed | typed-arity | typed-tf1 |
|---|---|---|---|---|
| false properties solved (any prover), of 94 | 75 | 77 | 78 | 58 |
| solved by vampire | 49 | 66 | 61 | 58 |
| solved by eprover | 45 | 43 | 46 | n/a |
| solved by twee | 60 | 67 | 67 | n/a |
| confirmed witnesses (prover runs) | 154 | 176 | 174 | 58 |
| ill-typed witnesses | 4 | 0 | 0 | 0 |
| witnesses refuted by GHC | 0 | 0 | 0 | 0 |
| witnesses that could not be checked | 0 | 0 | 0 | 0 |
| claimed counterexamples for properties QuickCheck passes | 0 of 266 tested | 0 of 266 tested | not run | 0 of 266 tested |

## Per version: false properties solved (any prover)

| version | false | untyped | typed | typed-arity | typed-tf1 |
|---|---|---|---|---|---|
| BSTSpec0 | 0 | 0 | 0 | 0 | 0 |
| BSTSpec1 | 10 | 9 | 10 | 10 | 8 |
| BSTSpec2 | 22 | 20 | 22 | 22 | 14 |
| BSTSpec3 | 9 | 9 | 9 | 9 | 8 |
| BSTSpec4 | 12 | 11 | 11 | 11 | 11 |
| BSTSpec5 | 9 | 7 | 8 | 8 | 7 |
| BSTSpec6 | 12 | 11 | 12 | 12 | 10 |
| BSTSpec7 | 11 | 6 | 5 | 6 | 0 |
| BSTSpec8 | 9 | 2 | 0 | 0 | 0 |

## Properties solved by some encodings but not all

✓ = solved; the provers that found a confirmed witness are listed, with the time of the fastest.

| property | untyped | typed | typed-arity | typed-tf1 |
|---|---|---|---|---|
| BSTSpec1 prop_InsertCompleteForUnion | ✓ twee (22.2 s) | ✓ eprover, twee (1.6 s) | ✓ eprover, twee (0.6 s) | – |
| BSTSpec1 prop_InsertModel | – | ✓ eprover, twee, vampire (0.0 s) | ✓ eprover, twee (0.1 s) | – |
| BSTSpec2 prop_DeleteModel | – | ✓ twee (3.5 s) | ✓ twee (3.0 s) | – |
| BSTSpec2 prop_DeleteUnion | ✓ twee (27.7 s) | ✓ twee, vampire (30.0 s) | ✓ twee, vampire (29.4 s) | – |
| BSTSpec2 prop_DeleteValid | ✓ eprover, twee (0.0 s) | ✓ eprover, twee, vampire (0.0 s) | ✓ eprover, twee, vampire (0.0 s) | – |
| BSTSpec2 prop_InsertModel | ✓ eprover, vampire (23.6 s) | ✓ vampire (0.8 s) | ✓ eprover, twee, vampire (0.2 s) | – |
| BSTSpec2 prop_InsertUnion | ✓ twee (1.6 s) | ✓ twee, vampire (1.2 s) | ✓ twee, vampire (1.8 s) | – |
| BSTSpec2 prop_UnionDeleteDelete | ✓ twee (25.7 s) | ✓ twee, vampire (30.3 s) | ✓ twee, vampire (29.5 s) | – |
| BSTSpec2 prop_UnionDeleteInsert | ✓ twee, vampire (3.6 s) | ✓ vampire (3.6 s) | ✓ vampire (3.6 s) | – |
| BSTSpec2 prop_UnionModel | – | ✓ eprover, twee (9.1 s) | ✓ eprover, twee (12.6 s) | – |
| BSTSpec3 prop_InsertModel | ✓ eprover (6.6 s) | ✓ vampire (0.5 s) | ✓ eprover, twee, vampire (0.1 s) | – |
| BSTSpec5 prop_DeleteModel | – | ✓ twee, vampire (2.5 s) | ✓ twee (2.7 s) | – |
| BSTSpec6 prop_InsertCompleteForUnion | ✓ eprover (48.3 s) | ✓ eprover, twee (0.4 s) | ✓ eprover, twee (0.4 s) | – |
| BSTSpec6 prop_UnionModel | – | ✓ eprover (9.6 s) | ✓ eprover (6.6 s) | – |
| BSTSpec7 prop_DeleteUnion | ✓ twee (12.0 s) | ✓ twee (7.6 s) | ✓ twee (11.1 s) | – |
| BSTSpec7 prop_FindUnion | – | ✓ vampire (5.8 s) | ✓ vampire (6.2 s) | – |
| BSTSpec7 prop_InsertCompleteForUnion | – | – | ✓ eprover (7.5 s) | – |
| BSTSpec7 prop_InsertUnion | ✓ eprover (9.7 s) | – | – | – |
| BSTSpec7 prop_UnionDeleteDelete | ✓ twee (10.6 s) | ✓ twee (7.3 s) | ✓ twee (10.4 s) | – |
| BSTSpec7 prop_UnionDeleteInsert | ✓ twee (63.6 s) | – | – | – |
| BSTSpec7 prop_UnionInsert | ✓ eprover (8.4 s) | – | – | – |
| BSTSpec7 prop_UnionPost | – | ✓ vampire (5.9 s) | ✓ vampire (6.3 s) | – |
| BSTSpec7 prop_UnionValid | ✓ eprover (50.3 s) | ✓ eprover, twee (1.0 s) | ✓ eprover, twee (0.6 s) | – |
| BSTSpec8 prop_InsertUnion | ✓ eprover (26.6 s) | – | – | – |
| BSTSpec8 prop_UnionInsert | ✓ eprover (29.7 s) | – | – | – |

Unsolved by every encoding (11): BSTSpec4 prop_DeleteDelete, BSTSpec5 prop_UnionDeleteInsert, BSTSpec7 prop_UnionModel, BSTSpec7 prop_UnionUnionAssoc, BSTSpec8 prop_DeleteUnion, BSTSpec8 prop_FindUnion, BSTSpec8 prop_UnionDeleteDelete, BSTSpec8 prop_UnionDeleteInsert, BSTSpec8 prop_UnionModel, BSTSpec8 prop_UnionPost, BSTSpec8 prop_UnionUnionAssoc

## Vampire alone

Every encoding can be compared on Vampire alone, since Vampire is the only prover that reads TF1.

| | untyped | typed | typed-arity | typed-tf1 |
|---|---|---|---|---|
| false properties solved by Vampire | 49 | 66 | 61 | 58 |
| total time on the 45 properties all of them solve | 102.9 s | 102.1 s | 106.2 s | 238.0 s |

## How the runs were made

Every variant used the same protocol:
1. A 10 s pass on the false properties.
2. A 60 s pass on the false properties that no prover solved in the 10 s pass.

`untyped` and `typed` also ran all 266 true properties at 10 s, and `typed-tf1` ran them with Vampire. None of these runs claimed a counterexample. The `typed-tf1` column has Vampire only: E 3.5.10 and Twee 2.6.2 reject polymorphic types. `merge_passes.py` combines the two passes, `compare_variants.py` makes this file, and `run-false.sh` runs one pass over the BST files.

## How much is noise

Vampire's `--mode casc` runs a schedule of strategies that it scales to the time limit, and its timing depends on machine load. So a property can be solved at 10 s and missed at 60 s, or the other way round, and two identical runs can differ. As a check, the `typed` 10 s pass was repeated with the same binaries on the false properties. The two runs differed on 2 properties for Vampire and 2 for Twee, and agreed exactly for E. At the level of "solved by any prover", they differed on 1 property. Differences of 1–2 properties per prover are within this noise.

## typed vs. typed-arity, retested

Every (property, prover) pair where `typed` and `typed-arity` disagreed was rerun with both encodings, at 10 s and at 60 s, one at a time on an idle machine. Each cell gives the time to solve, or "no".

| property | prover | typed 10 s | typed 60 s | typed-arity 10 s | typed-arity 60 s | verdict |
|---|---|---|---|---|---|---|
| BSTSpec2 prop_InsertModel | E | no | 53 s | 0 s | 0 s | arity much faster |
| BSTSpec3 prop_InsertModel | E | no | 24 s | 1 s | 0 s | arity much faster |
| BSTSpec2 prop_InsertModel | Twee | no | no | 6 s | 6 s | arity only |
| BSTSpec3 prop_InsertModel | Twee | no | no | 6 s | 5 s | arity only |
| BSTSpec7 prop_InsertCompleteForUnion | E | no | no | 7 s | 8 s | arity only (new property) |
| BSTSpec2 prop_UnionInsert | Vampire | 8 s | 7 s | no | 33 s | typed faster |
| BSTSpec3 prop_InsertUnion | Vampire | 7 s | 8 s | no | 32 s | typed faster |
| BSTSpec3 prop_UnionInsert | Vampire | 7 s | 8 s | no | 32 s | typed faster |
| BSTSpec3 prop_UnionDeleteInsert | Twee | no | 11 s | no | 20 s | typed faster |
| BSTSpec6 prop_UnionUnionAssoc | Twee | no | 11 s | no | 22 s | typed faster |
| BSTSpec1 prop_InsertModel | Vampire | no | 11 s | no | 11 s | noise |
| BSTSpec5 prop_DeleteModel | Vampire | no | no | no | no | noise (typed's first run solved it in 6.4 s) |

The 60 s pass covers only properties that no prover solved at 10 s. So the drop in Vampire's per-prover count for `typed-arity` (66 → 61) mostly reflects slower solves, not failures: every one of these cases is still solved within 60 s.
