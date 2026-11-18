# Solved benchmarks

Results from results-combined (recorded 2026-11-18). A property is solved when a prover
found a witness and witness2input confirmed that the property returns False on it.

| benchmark | property | solved by | input |
|---|---|---|---|
| hughes-bst/BSTSpec1 | prop_DeleteInsert | twee (0.17s), vampire (0.06s) | `prop_DeleteInsert Zero (Zero, undefined) ((Suc undefined, undefined) : undefined)` |
| hughes-bst/BSTSpec1 | prop_FindInsert | eprover (0.02s), twee (0.08s), vampire (0.02s) | `prop_FindInsert Zero (Suc undefined, undefined) ((Zero, undefined) : undefined)` |
| hughes-bst/BSTSpec1 | prop_InsertCompleteForUnion | twee (22.18s) | `prop_InsertCompleteForUnion ((Suc undefined, undefined) : undefined) ((Zero, undefined) : undefined)` |
| hughes-bst/BSTSpec1 | prop_InsertInsert | eprover (0.01s), twee (0.06s), vampire (0.04s) | `prop_InsertInsert (Suc undefined, undefined) (Zero, undefined) undefined` |
| hughes-bst/BSTSpec1 | prop_InsertInsertWeak | eprover (0.01s), twee (0.08s), vampire (0.02s) | `prop_InsertInsertWeak (Suc undefined, undefined) (Zero, undefined) undefined` |
| hughes-bst/BSTSpec1 | prop_InsertPost | eprover (0.02s), twee (0.08s), vampire (0.12s) | `prop_InsertPost (Suc undefined) undefined ((Zero, undefined) : undefined) Zero` |
| hughes-bst/BSTSpec1 | prop_InsertUnion | eprover (0.83s), twee (0.77s), vampire (4.33s) | `prop_InsertUnion (Zero, Zero) undefined ((Suc undefined, undefined) : undefined)` |
| hughes-bst/BSTSpec1 | prop_UnionDeleteInsert | twee (1.53s), vampire (4.33s) | `prop_UnionDeleteInsert [(Suc undefined, undefined)] undefined (Zero, Zero)` |
| hughes-bst/BSTSpec1 | prop_UnionInsert | eprover (0.60s), twee (0.50s), vampire (0.85s) | `prop_UnionInsert undefined ((Zero, undefined) : undefined) (Suc undefined, undefined)` |
| hughes-bst/BSTSpec2 | prop_ArbitraryValid | eprover (0.03s), twee (0.14s), vampire (1.89s) | `prop_ArbitraryValid [(Zero, undefined), (Zero, undefined)]` |
| hughes-bst/BSTSpec2 | prop_DeleteInsert | twee (0.59s), vampire (3.17s) | `prop_DeleteInsert Zero (Zero, undefined) [(Zero, undefined)]` |
| hughes-bst/BSTSpec2 | prop_DeletePost | eprover (1.22s), twee (0.56s), vampire (0.94s) | `prop_DeletePost Zero [(Zero, undefined), (Zero, undefined)] Zero` |
| hughes-bst/BSTSpec2 | prop_DeleteUnion | twee (27.74s) | `prop_DeleteUnion Zero [(Zero, undefined)] [(Zero, undefined), (Zero, undefined)]` |
| hughes-bst/BSTSpec2 | prop_DeleteValid | eprover (0.03s), twee (0.62s) | `prop_DeleteValid (Suc undefined) [(Zero, undefined), (Zero, undefined)]` |
| hughes-bst/BSTSpec2 | prop_FindDelete | eprover (1.64s), twee (0.82s), vampire (0.93s) | `prop_FindDelete Zero Zero [(Zero, undefined), (Zero, undefined)]` |
| hughes-bst/BSTSpec2 | prop_FindInsert | eprover (0.04s), twee (0.09s), vampire (1.72s) | `prop_FindInsert Zero (Zero, Zero) [(Zero, Suc undefined)]` |
| hughes-bst/BSTSpec2 | prop_FindPostAbsent | eprover (0.03s), twee (0.50s) | `prop_FindPostAbsent Zero [(Zero, undefined), (Zero, undefined)]` |
| hughes-bst/BSTSpec2 | prop_FindPostPresent | eprover (0.03s), twee (0.06s), vampire (0.02s) | `prop_FindPostPresent Zero Zero [(Zero, Suc undefined)]` |
| hughes-bst/BSTSpec2 | prop_InsertDelete | vampire (3.13s) | `prop_InsertDelete (Zero, Suc undefined) Zero [(Zero, Zero)]` |
| hughes-bst/BSTSpec2 | prop_InsertDeleteComplete | eprover (1.02s), twee (0.22s) | `prop_InsertDeleteComplete Zero [(Zero, Zero)]` |
| hughes-bst/BSTSpec2 | prop_InsertInsert | twee (0.27s), vampire (0.26s) | `prop_InsertInsert (Zero, Zero) (Zero, Zero) []` |
| hughes-bst/BSTSpec2 | prop_InsertModel | eprover (32.61s), vampire (23.64s) | `prop_InsertModel (Zero, Zero) [(Zero, Zero)]` |
| hughes-bst/BSTSpec2 | prop_InsertPost | eprover (0.04s), twee (0.09s), vampire (0.05s) | `prop_InsertPost Zero Zero [(Zero, Suc undefined)] Zero` |
| hughes-bst/BSTSpec2 | prop_InsertUnion | twee (1.59s) | `prop_InsertUnion (Zero, Zero) [] [(Zero, Zero)]` |
| hughes-bst/BSTSpec2 | prop_InsertValid | eprover (0.03s), twee (0.14s), vampire (0.27s) | `prop_InsertValid Zero undefined [(Zero, undefined)]` |
| hughes-bst/BSTSpec2 | prop_UnionDeleteDelete | twee (25.71s) | `prop_UnionDeleteDelete [(Zero, undefined)] [(Zero, undefined), (Zero, undefined)] Zero` |
| hughes-bst/BSTSpec2 | prop_UnionDeleteInsert | twee (12.02s), vampire (3.60s) | `prop_UnionDeleteInsert [(Zero, Zero)] [] (Zero, Zero)` |
| hughes-bst/BSTSpec2 | prop_UnionInsert | twee (0.79s) | `prop_UnionInsert [] [(Zero, Zero)] (Zero, Zero)` |
| hughes-bst/BSTSpec2 | prop_UnionValid | eprover (0.04s), twee (0.17s), vampire (1.79s) | `prop_UnionValid [] [(Zero, undefined), (Zero, undefined)]` |
| hughes-bst/BSTSpec3 | prop_FindInsert | eprover (0.03s), twee (0.16s), vampire (0.11s) | `prop_FindInsert Zero (Zero, Zero) [(Zero, Suc undefined)]` |
| hughes-bst/BSTSpec3 | prop_FindPostPresent | eprover (0.06s), twee (0.09s), vampire (0.03s) | `prop_FindPostPresent Zero Zero [(Zero, Suc undefined)]` |
| hughes-bst/BSTSpec3 | prop_InsertDelete | twee (13.89s), vampire (3.11s) | `prop_InsertDelete (Zero, Zero) Zero [(Zero, Suc undefined)]` |
| hughes-bst/BSTSpec3 | prop_InsertInsert | twee (0.06s), vampire (0.23s) | `prop_InsertInsert (Zero, Suc undefined) (Zero, Zero) []` |
| hughes-bst/BSTSpec3 | prop_InsertModel | eprover (6.60s) | `prop_InsertModel (Zero, Zero) [(Zero, Suc undefined)]` |
| hughes-bst/BSTSpec3 | prop_InsertPost | eprover (0.04s), twee (0.11s), vampire (0.22s) | `prop_InsertPost Zero Zero [(Zero, Suc undefined)] Zero` |
| hughes-bst/BSTSpec3 | prop_InsertUnion | twee (0.67s) | `prop_InsertUnion (Zero, Suc undefined) [] [(Zero, Zero)]` |
| hughes-bst/BSTSpec3 | prop_UnionDeleteInsert | twee (12.81s), vampire (3.60s) | `prop_UnionDeleteInsert [(Zero, Suc undefined)] [] (Zero, Zero)` |
| hughes-bst/BSTSpec3 | prop_UnionInsert | twee (0.76s) | `prop_UnionInsert [] [(Zero, Suc undefined)] (Zero, Zero)` |
| hughes-bst/BSTSpec4 | prop_DeleteInsert | twee (0.08s), vampire (0.24s) | `prop_DeleteInsert Zero (Suc undefined, undefined) []` |
| hughes-bst/BSTSpec4 | prop_DeleteInsertWeak | eprover (0.03s), twee (0.11s), vampire (0.24s) | `prop_DeleteInsertWeak (Suc undefined) (Zero, undefined) []` |
| hughes-bst/BSTSpec4 | prop_DeleteModel | eprover (2.27s) | `prop_DeleteModel Zero [(Suc undefined, undefined)]` |
| hughes-bst/BSTSpec4 | prop_DeletePost | eprover (0.11s), twee (2.14s), vampire (0.04s) | `prop_DeletePost Zero [(Zero, undefined), (Suc (Suc Zero), undefined)] (Suc (Suc Zero))` |
| hughes-bst/BSTSpec4 | prop_DeleteUnion | vampire (0.25s) | `prop_DeleteUnion Zero [(Zero, undefined)] [(Suc undefined, undefined)]` |
| hughes-bst/BSTSpec4 | prop_FindDelete | eprover (0.10s), twee (0.80s), vampire (0.03s) | `prop_FindDelete (Suc (Suc Zero)) Zero [(Zero, undefined), (Suc (Suc Zero), undefined)]` |
| hughes-bst/BSTSpec4 | prop_InsertDelete | eprover (0.04s), twee (0.06s), vampire (0.04s) | `prop_InsertDelete (Suc undefined, undefined) Zero []` |
| hughes-bst/BSTSpec4 | prop_InsertDeleteComplete | eprover (0.05s), twee (0.21s), vampire (0.08s) | `prop_InsertDeleteComplete (Suc undefined) [(Zero, undefined)]` |
| hughes-bst/BSTSpec4 | prop_InsertDeleteWeak | eprover (0.02s), twee (0.09s), vampire (0.23s) | `prop_InsertDeleteWeak (Zero, undefined) (Suc undefined) []` |
| hughes-bst/BSTSpec4 | prop_UnionDeleteDelete | vampire (0.25s) | `prop_UnionDeleteDelete [(Zero, undefined)] [(Suc undefined, undefined)] Zero` |
| hughes-bst/BSTSpec4 | prop_UnionDeleteInsert | vampire (3.76s) | `prop_UnionDeleteInsert [(Zero, undefined)] [] (Suc undefined, undefined)` |
| hughes-bst/BSTSpec5 | prop_DeleteDelete | twee (22.00s), vampire (22.00s) | `prop_DeleteDelete (Suc Zero) Zero [(Zero, undefined), (Suc Zero, undefined)]` |
| hughes-bst/BSTSpec5 | prop_DeleteInsert | twee (0.88s) | `prop_DeleteInsert Zero (Zero, undefined) [(Suc undefined, undefined)]` |
| hughes-bst/BSTSpec5 | prop_DeletePost | eprover (1.81s), twee (0.55s) | `prop_DeletePost Zero [(Zero, undefined), (Suc undefined, undefined)] Zero` |
| hughes-bst/BSTSpec5 | prop_DeleteUnion | twee (20.12s), vampire (29.18s) | `prop_DeleteUnion Zero [(Zero, undefined)] [(Zero, undefined), (Suc undefined, undefined)]` |
| hughes-bst/BSTSpec5 | prop_FindDelete | eprover (1.92s), twee (0.53s) | `prop_FindDelete Zero Zero [(Zero, undefined), (Suc undefined, undefined)]` |
| hughes-bst/BSTSpec5 | prop_FindPostAbsent | eprover (0.02s), twee (0.35s), vampire (3.30s) | `prop_FindPostAbsent Zero [(Zero, undefined), (Suc undefined, undefined)]` |
| hughes-bst/BSTSpec5 | prop_UnionDeleteDelete | twee (21.47s), vampire (29.11s) | `prop_UnionDeleteDelete [(Zero, undefined)] [(Zero, undefined), (Suc undefined, undefined)] Zero` |
| hughes-bst/BSTSpec6 | prop_DeleteUnion | twee (9.37s), vampire (0.32s) | `prop_DeleteUnion Zero [(Zero, undefined)] [(Zero, undefined)]` |
| hughes-bst/BSTSpec6 | prop_FindUnion | eprover (2.74s), twee (0.85s), vampire (0.22s) | `prop_FindUnion Zero [(Suc undefined, undefined)] [(Zero, undefined)]` |
| hughes-bst/BSTSpec6 | prop_InsertCompleteForUnion | eprover (48.28s) | `prop_InsertCompleteForUnion [(Suc undefined, undefined)] [(Zero, undefined)]` |
| hughes-bst/BSTSpec6 | prop_InsertUnion | eprover (2.91s), twee (2.86s) | `prop_InsertUnion (Suc undefined, undefined) [] [(Zero, undefined)]` |
| hughes-bst/BSTSpec6 | prop_UnionDeleteDelete | twee (9.76s), vampire (0.32s) | `prop_UnionDeleteDelete [(Zero, undefined)] [(Zero, undefined)] Zero` |
| hughes-bst/BSTSpec6 | prop_UnionDeleteInsert | eprover (2.58s) | `prop_UnionDeleteInsert [(Suc undefined, undefined)] [] (Zero, undefined)` |
| hughes-bst/BSTSpec6 | prop_UnionInsert | eprover (1.96s), twee (2.14s), vampire (4.04s) | `prop_UnionInsert [] [(Zero, undefined)] (Suc undefined, undefined)` |
| hughes-bst/BSTSpec6 | prop_UnionPost | eprover (2.76s), twee (0.86s), vampire (0.22s) | `prop_UnionPost [(Suc undefined, undefined)] [(Zero, undefined)] Zero` |
| hughes-bst/BSTSpec6 | prop_UnionUnionAssoc | vampire (3.71s) | `prop_UnionUnionAssoc [(Zero, Zero)] [(undefined, undefined)] [(fst undefined, snd undefined)]` |
| hughes-bst/BSTSpec6 | prop_UnionUnionIdem | eprover (0.02s), twee (0.25s), vampire (0.22s) | `prop_UnionUnionIdem [(Zero, Zero)]` |
| hughes-bst/BSTSpec6 | prop_UnionValid | eprover (0.02s), twee (0.17s), vampire (0.23s) | `prop_UnionValid [(Suc undefined, undefined)] [(Zero, undefined)]` |
| hughes-bst/BSTSpec7 | prop_DeleteUnion | twee (11.98s) | `prop_DeleteUnion Zero [(Zero, undefined)] [(Zero, undefined), (Suc undefined, undefined)]` |
| hughes-bst/BSTSpec7 | prop_InsertUnion | eprover (9.67s) | `prop_InsertUnion (Zero, Zero) [(Suc undefined, undefined)] [(Zero, Zero)]` |
| hughes-bst/BSTSpec7 | prop_UnionDeleteDelete | twee (10.62s) | `prop_UnionDeleteDelete [(Zero, undefined)] [(Zero, undefined), (Suc undefined, undefined)] Zero` |
| hughes-bst/BSTSpec7 | prop_UnionDeleteInsert | twee (63.56s) | `prop_UnionDeleteInsert [(Zero, undefined)] [(Zero, undefined), (Suc undefined, undefined)] (Zero, Zero)` |
| hughes-bst/BSTSpec7 | prop_UnionInsert | eprover (8.42s) | `prop_UnionInsert [(Suc undefined, undefined)] [(Zero, Zero)] (Zero, Zero)` |
| hughes-bst/BSTSpec7 | prop_UnionValid | eprover (50.30s) | `prop_UnionValid [(Zero, undefined), (Suc undefined, undefined)] [(Zero, undefined)]` |
| hughes-bst/BSTSpec8 | prop_InsertUnion | eprover (26.59s) | `prop_InsertUnion (Zero, Suc undefined) [(Suc undefined, undefined)] [(Zero, Zero)]` |
| hughes-bst/BSTSpec8 | prop_UnionInsert | eprover (29.68s) | `prop_UnionInsert [(Suc undefined, undefined)] [(Zero, Suc undefined)] (Zero, Zero)` |
