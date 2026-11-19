# Untyped (FOF) vs. typed (TFF) translation on the BST benchmarks

Same protocol for both: all 360 properties at 10 s per prover, then the false properties (QuickCheck, 10,000 tests) that were still unsolved at 60 s. Vampire 5.1.1, E 3.5.10, Twee 2.6.2 with the command lines in PROVERS.md.

| | untyped (FOF) | typed (TFF) |
|---|---|---|
| false properties solved (any prover), of 94 | 75 | 77 |
| solved by vampire | 49 | 66 |
| solved by eprover | 45 | 43 |
| solved by twee | 60 | 67 |
| confirmed witnesses (prover runs) | 154 | 176 |
| ill-typed witnesses | 4 | 0 |
| witnesses refuted by GHC | 0 | 0 |
| witnesses that could not be checked | 0 | 0 |
| claims of a counterexample for a property QuickCheck passes | 0 | 0 |

## Per version: false properties solved

| version | false | untyped | typed | only untyped | only typed |
|---|---|---|---|---|---|
| BSTSpec0 | 0 | 0 | 0 | - | - |
| BSTSpec1 | 10 | 9 | 10 | - | prop_InsertModel |
| BSTSpec2 | 22 | 20 | 22 | - | prop_DeleteModel, prop_UnionModel |
| BSTSpec3 | 9 | 9 | 9 | - | - |
| BSTSpec4 | 12 | 11 | 11 | - | - |
| BSTSpec5 | 9 | 7 | 8 | - | prop_DeleteModel |
| BSTSpec6 | 12 | 11 | 12 | - | prop_UnionModel |
| BSTSpec7 | 11 | 6 | 5 | prop_InsertUnion, prop_UnionDeleteInsert, prop_UnionInsert | prop_FindUnion, prop_UnionPost |
| BSTSpec8 | 9 | 2 | 0 | prop_InsertUnion, prop_UnionInsert | - |

## Per prover: solved only in one encoding

* **vampire**: only untyped: 2 (BSTSpec1 prop_UnionDeleteInsert, BSTSpec5 prop_DeleteDelete); only typed: 19 (BSTSpec1 prop_InsertModel, BSTSpec2 prop_DeleteUnion, BSTSpec2 prop_DeleteValid, BSTSpec2 prop_FindPostAbsent, BSTSpec2 prop_InsertUnion, BSTSpec2 prop_UnionDeleteDelete, BSTSpec2 prop_UnionInsert, BSTSpec3 prop_InsertModel, BSTSpec3 prop_InsertUnion, BSTSpec3 prop_UnionInsert, BSTSpec4 prop_DeleteModel, BSTSpec5 prop_DeleteInsert, BSTSpec5 prop_DeleteModel, BSTSpec5 prop_DeletePost, BSTSpec5 prop_FindDelete, BSTSpec6 prop_InsertUnion, BSTSpec6 prop_UnionDeleteInsert, BSTSpec7 prop_FindUnion, BSTSpec7 prop_UnionPost)
* **eprover**: only untyped: 9 (BSTSpec2 prop_InsertModel, BSTSpec3 prop_InsertModel, BSTSpec6 prop_InsertUnion, BSTSpec6 prop_UnionDeleteInsert, BSTSpec6 prop_UnionInsert, BSTSpec7 prop_InsertUnion, BSTSpec7 prop_UnionInsert, BSTSpec8 prop_InsertUnion, BSTSpec8 prop_UnionInsert); only typed: 7 (BSTSpec1 prop_InsertCompleteForUnion, BSTSpec1 prop_InsertModel, BSTSpec1 prop_UnionDeleteInsert, BSTSpec2 prop_InsertDelete, BSTSpec2 prop_UnionModel, BSTSpec3 prop_InsertDelete, BSTSpec6 prop_UnionModel)
* **twee**: only untyped: 2 (BSTSpec2 prop_UnionDeleteInsert, BSTSpec7 prop_UnionDeleteInsert); only typed: 9 (BSTSpec1 prop_InsertModel, BSTSpec2 prop_DeleteModel, BSTSpec2 prop_InsertDelete, BSTSpec2 prop_UnionModel, BSTSpec4 prop_DeleteModel, BSTSpec5 prop_DeleteModel, BSTSpec6 prop_InsertCompleteForUnion, BSTSpec6 prop_UnionUnionAssoc, BSTSpec7 prop_UnionValid)

## Time

Of the 141 (property, prover) pairs solved in both encodings, the typed run was more than 0.5 s faster on 25 and more than 0.5 s slower on 10; total time 478.8 s untyped vs. 301.0 s typed.

## Unsolved in both

BSTSpec4 prop_DeleteDelete, BSTSpec5 prop_UnionDeleteInsert, BSTSpec7 prop_InsertCompleteForUnion, BSTSpec7 prop_UnionModel, BSTSpec7 prop_UnionUnionAssoc, BSTSpec8 prop_DeleteUnion, BSTSpec8 prop_FindUnion, BSTSpec8 prop_UnionDeleteDelete, BSTSpec8 prop_UnionDeleteInsert, BSTSpec8 prop_UnionModel, BSTSpec8 prop_UnionPost, BSTSpec8 prop_UnionUnionAssoc
