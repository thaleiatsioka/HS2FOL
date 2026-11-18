# Coverage against QuickCheck

QuickCheck was run on every benchmark property with 10,000 tests (`maxSuccess = 10000`) as a reference for which properties are false. QuickCheck cannot show that a property is true, so this is a reference, not ground truth.

Provers: Vampire 5.1.1, E 3.5.10, Twee 2.6.2 (details in provers.txt). Pass 1 ran all 360 properties at 10 s per prover. Pass 2 reran, at 60 s, the 31 properties that QuickCheck falsifies but pass 1 did not solve.

| version | false (QuickCheck) | solved (any prover) | Vampire | E | Twee | ill-typed witnesses |
|---|---|---|---|---|---|---|
| BST (correct) | 0 | 0 | 0 | 0 | 0 | 0 |
| BST1 | 10 | 9 | 8 | 6 | 9 | 0 |
| BST2 | 22 | 20 | 13 | 12 | 18 | 1 |
| BST3 | 9 | 9 | 6 | 4 | 8 | 0 |
| BST4 | 12 | 11 | 10 | 7 | 7 | 1 |
| BST5 | 9 | 7 | 4 | 3 | 7 | 2 |
| BST6 | 12 | 11 | 8 | 8 | 8 | 0 |
| BST7 | 11 | 6 | 0 | 3 | 3 | 0 |
| BST8 | 9 | 2 | 0 | 2 | 0 | 0 |
| **total** | **94** | **75** | 49 | 45 | 60 | 4 |

Every property a prover solved is also falsified by QuickCheck, and no prover produced a witness that GHC refuted.

Twee has no internal time limit (only the external kill at 65 s). It solved `BSTSpec7 prop_UnionDeleteInsert` in 63.6 s, over the 60 s budget; this is the only such case.

## False properties that no prover solved

| version | property |
|---|---|
| BSTSpec1 | prop_InsertModel |
| BSTSpec2 | prop_DeleteModel |
| BSTSpec2 | prop_UnionModel |
| BSTSpec4 | prop_DeleteDelete |
| BSTSpec5 | prop_DeleteModel |
| BSTSpec5 | prop_UnionDeleteInsert |
| BSTSpec6 | prop_UnionModel |
| BSTSpec7 | prop_FindUnion |
| BSTSpec7 | prop_InsertCompleteForUnion |
| BSTSpec7 | prop_UnionModel |
| BSTSpec7 | prop_UnionPost |
| BSTSpec7 | prop_UnionUnionAssoc |
| BSTSpec8 | prop_DeleteUnion |
| BSTSpec8 | prop_FindUnion |
| BSTSpec8 | prop_UnionDeleteDelete |
| BSTSpec8 | prop_UnionDeleteInsert |
| BSTSpec8 | prop_UnionModel |
| BSTSpec8 | prop_UnionPost |
| BSTSpec8 | prop_UnionUnionAssoc |

## All QuickCheck results

```
BSTSpec0 prop_ArbitraryValid PASS
BSTSpec0 prop_NilValid PASS
BSTSpec0 prop_InsertValid PASS
BSTSpec0 prop_DeleteValid PASS
BSTSpec0 prop_UnionValid PASS
BSTSpec0 prop_InsertPost PASS
BSTSpec0 prop_DeletePost PASS
BSTSpec0 prop_FindPostPresent PASS
BSTSpec0 prop_FindPostAbsent PASS
BSTSpec0 prop_InsertDeleteComplete PASS
BSTSpec0 prop_UnionPost PASS
BSTSpec0 prop_InsertInsertWeak PASS
BSTSpec0 prop_InsertInsert PASS
BSTSpec0 prop_InsertDeleteWeak PASS
BSTSpec0 prop_InsertDelete PASS
BSTSpec0 prop_InsertUnion PASS
BSTSpec0 prop_DeleteNil PASS
BSTSpec0 prop_DeleteInsertWeak PASS
BSTSpec0 prop_DeleteInsert PASS
BSTSpec0 prop_DeleteDelete PASS
BSTSpec0 prop_DeleteUnion PASS
BSTSpec0 prop_UnionInsert PASS
BSTSpec0 prop_UnionNil1 PASS
BSTSpec0 prop_UnionNil2 PASS
BSTSpec0 prop_UnionDeleteInsert PASS
BSTSpec0 prop_UnionDeleteDelete PASS
BSTSpec0 prop_UnionUnionIdem PASS
BSTSpec0 prop_UnionUnionAssoc PASS
BSTSpec0 prop_FindNil PASS
BSTSpec0 prop_FindInsert PASS
BSTSpec0 prop_FindDelete PASS
BSTSpec0 prop_FindUnion PASS
BSTSpec0 prop_InsertComplete PASS
BSTSpec0 prop_InsertCompleteForDelete PASS
BSTSpec0 prop_InsertCompleteForUnion PASS
BSTSpec0 prop_NilModel PASS
BSTSpec0 prop_InsertModel PASS
BSTSpec0 prop_DeleteModel PASS
BSTSpec0 prop_UnionModel PASS
BSTSpec0 prop_FindModel PASS
BSTSpec1 prop_ArbitraryValid PASS
BSTSpec1 prop_NilValid PASS
BSTSpec1 prop_InsertValid PASS
BSTSpec1 prop_DeleteValid PASS
BSTSpec1 prop_UnionValid PASS
BSTSpec1 prop_InsertPost FAIL
BSTSpec1 prop_DeletePost PASS
BSTSpec1 prop_FindPostPresent PASS
BSTSpec1 prop_FindPostAbsent PASS
BSTSpec1 prop_InsertDeleteComplete PASS
BSTSpec1 prop_UnionPost PASS
BSTSpec1 prop_InsertInsertWeak FAIL
BSTSpec1 prop_InsertInsert FAIL
BSTSpec1 prop_InsertDeleteWeak PASS
BSTSpec1 prop_InsertDelete PASS
BSTSpec1 prop_InsertUnion FAIL
BSTSpec1 prop_DeleteNil PASS
BSTSpec1 prop_DeleteInsertWeak PASS
BSTSpec1 prop_DeleteInsert FAIL
BSTSpec1 prop_DeleteDelete PASS
BSTSpec1 prop_DeleteUnion PASS
BSTSpec1 prop_UnionInsert FAIL
BSTSpec1 prop_UnionNil1 PASS
BSTSpec1 prop_UnionNil2 PASS
BSTSpec1 prop_UnionDeleteInsert FAIL
BSTSpec1 prop_UnionDeleteDelete PASS
BSTSpec1 prop_UnionUnionIdem PASS
BSTSpec1 prop_UnionUnionAssoc PASS
BSTSpec1 prop_FindNil PASS
BSTSpec1 prop_FindInsert FAIL
BSTSpec1 prop_FindDelete PASS
BSTSpec1 prop_FindUnion PASS
BSTSpec1 prop_InsertComplete PASS
BSTSpec1 prop_InsertCompleteForDelete PASS
BSTSpec1 prop_InsertCompleteForUnion FAIL
BSTSpec1 prop_NilModel PASS
BSTSpec1 prop_InsertModel FAIL
BSTSpec1 prop_DeleteModel PASS
BSTSpec1 prop_UnionModel PASS
BSTSpec1 prop_FindModel PASS
BSTSpec2 prop_ArbitraryValid FAIL
BSTSpec2 prop_NilValid PASS
BSTSpec2 prop_InsertValid FAIL
BSTSpec2 prop_DeleteValid FAIL
BSTSpec2 prop_UnionValid FAIL
BSTSpec2 prop_InsertPost FAIL
BSTSpec2 prop_DeletePost FAIL
BSTSpec2 prop_FindPostPresent FAIL
BSTSpec2 prop_FindPostAbsent FAIL
BSTSpec2 prop_InsertDeleteComplete FAIL
BSTSpec2 prop_UnionPost PASS
BSTSpec2 prop_InsertInsertWeak PASS
BSTSpec2 prop_InsertInsert FAIL
BSTSpec2 prop_InsertDeleteWeak PASS
BSTSpec2 prop_InsertDelete FAIL
BSTSpec2 prop_InsertUnion FAIL
BSTSpec2 prop_DeleteNil PASS
BSTSpec2 prop_DeleteInsertWeak PASS
BSTSpec2 prop_DeleteInsert FAIL
BSTSpec2 prop_DeleteDelete PASS
BSTSpec2 prop_DeleteUnion FAIL
BSTSpec2 prop_UnionInsert FAIL
BSTSpec2 prop_UnionNil1 PASS
BSTSpec2 prop_UnionNil2 PASS
BSTSpec2 prop_UnionDeleteInsert FAIL
BSTSpec2 prop_UnionDeleteDelete FAIL
BSTSpec2 prop_UnionUnionIdem PASS
BSTSpec2 prop_UnionUnionAssoc PASS
BSTSpec2 prop_FindNil PASS
BSTSpec2 prop_FindInsert FAIL
BSTSpec2 prop_FindDelete FAIL
BSTSpec2 prop_FindUnion PASS
BSTSpec2 prop_InsertComplete PASS
BSTSpec2 prop_InsertCompleteForDelete PASS
BSTSpec2 prop_InsertCompleteForUnion PASS
BSTSpec2 prop_NilModel PASS
BSTSpec2 prop_InsertModel FAIL
BSTSpec2 prop_DeleteModel FAIL
BSTSpec2 prop_UnionModel FAIL
BSTSpec2 prop_FindModel PASS
BSTSpec3 prop_ArbitraryValid PASS
BSTSpec3 prop_NilValid PASS
BSTSpec3 prop_InsertValid PASS
BSTSpec3 prop_DeleteValid PASS
BSTSpec3 prop_UnionValid PASS
BSTSpec3 prop_InsertPost FAIL
BSTSpec3 prop_DeletePost PASS
BSTSpec3 prop_FindPostPresent FAIL
BSTSpec3 prop_FindPostAbsent PASS
BSTSpec3 prop_InsertDeleteComplete PASS
BSTSpec3 prop_UnionPost PASS
BSTSpec3 prop_InsertInsertWeak PASS
BSTSpec3 prop_InsertInsert FAIL
BSTSpec3 prop_InsertDeleteWeak PASS
BSTSpec3 prop_InsertDelete FAIL
BSTSpec3 prop_InsertUnion FAIL
BSTSpec3 prop_DeleteNil PASS
BSTSpec3 prop_DeleteInsertWeak PASS
BSTSpec3 prop_DeleteInsert PASS
BSTSpec3 prop_DeleteDelete PASS
BSTSpec3 prop_DeleteUnion PASS
BSTSpec3 prop_UnionInsert FAIL
BSTSpec3 prop_UnionNil1 PASS
BSTSpec3 prop_UnionNil2 PASS
BSTSpec3 prop_UnionDeleteInsert FAIL
BSTSpec3 prop_UnionDeleteDelete PASS
BSTSpec3 prop_UnionUnionIdem PASS
BSTSpec3 prop_UnionUnionAssoc PASS
BSTSpec3 prop_FindNil PASS
BSTSpec3 prop_FindInsert FAIL
BSTSpec3 prop_FindDelete PASS
BSTSpec3 prop_FindUnion PASS
BSTSpec3 prop_InsertComplete PASS
BSTSpec3 prop_InsertCompleteForDelete PASS
BSTSpec3 prop_InsertCompleteForUnion PASS
BSTSpec3 prop_NilModel PASS
BSTSpec3 prop_InsertModel FAIL
BSTSpec3 prop_DeleteModel PASS
BSTSpec3 prop_UnionModel PASS
BSTSpec3 prop_FindModel PASS
BSTSpec4 prop_ArbitraryValid PASS
BSTSpec4 prop_NilValid PASS
BSTSpec4 prop_InsertValid PASS
BSTSpec4 prop_DeleteValid PASS
BSTSpec4 prop_UnionValid PASS
BSTSpec4 prop_InsertPost PASS
BSTSpec4 prop_DeletePost FAIL
BSTSpec4 prop_FindPostPresent PASS
BSTSpec4 prop_FindPostAbsent PASS
BSTSpec4 prop_InsertDeleteComplete FAIL
BSTSpec4 prop_UnionPost PASS
BSTSpec4 prop_InsertInsertWeak PASS
BSTSpec4 prop_InsertInsert PASS
BSTSpec4 prop_InsertDeleteWeak FAIL
BSTSpec4 prop_InsertDelete FAIL
BSTSpec4 prop_InsertUnion PASS
BSTSpec4 prop_DeleteNil PASS
BSTSpec4 prop_DeleteInsertWeak FAIL
BSTSpec4 prop_DeleteInsert FAIL
BSTSpec4 prop_DeleteDelete FAIL
BSTSpec4 prop_DeleteUnion FAIL
BSTSpec4 prop_UnionInsert PASS
BSTSpec4 prop_UnionNil1 PASS
BSTSpec4 prop_UnionNil2 PASS
BSTSpec4 prop_UnionDeleteInsert FAIL
BSTSpec4 prop_UnionDeleteDelete FAIL
BSTSpec4 prop_UnionUnionIdem PASS
BSTSpec4 prop_UnionUnionAssoc PASS
BSTSpec4 prop_FindNil PASS
BSTSpec4 prop_FindInsert PASS
BSTSpec4 prop_FindDelete FAIL
BSTSpec4 prop_FindUnion PASS
BSTSpec4 prop_InsertComplete PASS
BSTSpec4 prop_InsertCompleteForDelete PASS
BSTSpec4 prop_InsertCompleteForUnion PASS
BSTSpec4 prop_NilModel PASS
BSTSpec4 prop_InsertModel PASS
BSTSpec4 prop_DeleteModel FAIL
BSTSpec4 prop_UnionModel PASS
BSTSpec4 prop_FindModel PASS
BSTSpec5 prop_ArbitraryValid PASS
BSTSpec5 prop_NilValid PASS
BSTSpec5 prop_InsertValid PASS
BSTSpec5 prop_DeleteValid PASS
BSTSpec5 prop_UnionValid PASS
BSTSpec5 prop_InsertPost PASS
BSTSpec5 prop_DeletePost FAIL
BSTSpec5 prop_FindPostPresent PASS
BSTSpec5 prop_FindPostAbsent FAIL
BSTSpec5 prop_InsertDeleteComplete PASS
BSTSpec5 prop_UnionPost PASS
BSTSpec5 prop_InsertInsertWeak PASS
BSTSpec5 prop_InsertInsert PASS
BSTSpec5 prop_InsertDeleteWeak PASS
BSTSpec5 prop_InsertDelete PASS
BSTSpec5 prop_InsertUnion PASS
BSTSpec5 prop_DeleteNil PASS
BSTSpec5 prop_DeleteInsertWeak PASS
BSTSpec5 prop_DeleteInsert FAIL
BSTSpec5 prop_DeleteDelete FAIL
BSTSpec5 prop_DeleteUnion FAIL
BSTSpec5 prop_UnionInsert PASS
BSTSpec5 prop_UnionNil1 PASS
BSTSpec5 prop_UnionNil2 PASS
BSTSpec5 prop_UnionDeleteInsert FAIL
BSTSpec5 prop_UnionDeleteDelete FAIL
BSTSpec5 prop_UnionUnionIdem PASS
BSTSpec5 prop_UnionUnionAssoc PASS
BSTSpec5 prop_FindNil PASS
BSTSpec5 prop_FindInsert PASS
BSTSpec5 prop_FindDelete FAIL
BSTSpec5 prop_FindUnion PASS
BSTSpec5 prop_InsertComplete PASS
BSTSpec5 prop_InsertCompleteForDelete PASS
BSTSpec5 prop_InsertCompleteForUnion PASS
BSTSpec5 prop_NilModel PASS
BSTSpec5 prop_InsertModel PASS
BSTSpec5 prop_DeleteModel FAIL
BSTSpec5 prop_UnionModel PASS
BSTSpec5 prop_FindModel PASS
BSTSpec6 prop_ArbitraryValid PASS
BSTSpec6 prop_NilValid PASS
BSTSpec6 prop_InsertValid PASS
BSTSpec6 prop_DeleteValid PASS
BSTSpec6 prop_UnionValid FAIL
BSTSpec6 prop_InsertPost PASS
BSTSpec6 prop_DeletePost PASS
BSTSpec6 prop_FindPostPresent PASS
BSTSpec6 prop_FindPostAbsent PASS
BSTSpec6 prop_InsertDeleteComplete PASS
BSTSpec6 prop_UnionPost FAIL
BSTSpec6 prop_InsertInsertWeak PASS
BSTSpec6 prop_InsertInsert PASS
BSTSpec6 prop_InsertDeleteWeak PASS
BSTSpec6 prop_InsertDelete PASS
BSTSpec6 prop_InsertUnion FAIL
BSTSpec6 prop_DeleteNil PASS
BSTSpec6 prop_DeleteInsertWeak PASS
BSTSpec6 prop_DeleteInsert PASS
BSTSpec6 prop_DeleteDelete PASS
BSTSpec6 prop_DeleteUnion FAIL
BSTSpec6 prop_UnionInsert FAIL
BSTSpec6 prop_UnionNil1 PASS
BSTSpec6 prop_UnionNil2 PASS
BSTSpec6 prop_UnionDeleteInsert FAIL
BSTSpec6 prop_UnionDeleteDelete FAIL
BSTSpec6 prop_UnionUnionIdem FAIL
BSTSpec6 prop_UnionUnionAssoc FAIL
BSTSpec6 prop_FindNil PASS
BSTSpec6 prop_FindInsert PASS
BSTSpec6 prop_FindDelete PASS
BSTSpec6 prop_FindUnion FAIL
BSTSpec6 prop_InsertComplete PASS
BSTSpec6 prop_InsertCompleteForDelete PASS
BSTSpec6 prop_InsertCompleteForUnion FAIL
BSTSpec6 prop_NilModel PASS
BSTSpec6 prop_InsertModel PASS
BSTSpec6 prop_DeleteModel PASS
BSTSpec6 prop_UnionModel FAIL
BSTSpec6 prop_FindModel PASS
BSTSpec7 prop_ArbitraryValid PASS
BSTSpec7 prop_NilValid PASS
BSTSpec7 prop_InsertValid PASS
BSTSpec7 prop_DeleteValid PASS
BSTSpec7 prop_UnionValid FAIL
BSTSpec7 prop_InsertPost PASS
BSTSpec7 prop_DeletePost PASS
BSTSpec7 prop_FindPostPresent PASS
BSTSpec7 prop_FindPostAbsent PASS
BSTSpec7 prop_InsertDeleteComplete PASS
BSTSpec7 prop_UnionPost FAIL
BSTSpec7 prop_InsertInsertWeak PASS
BSTSpec7 prop_InsertInsert PASS
BSTSpec7 prop_InsertDeleteWeak PASS
BSTSpec7 prop_InsertDelete PASS
BSTSpec7 prop_InsertUnion FAIL
BSTSpec7 prop_DeleteNil PASS
BSTSpec7 prop_DeleteInsertWeak PASS
BSTSpec7 prop_DeleteInsert PASS
BSTSpec7 prop_DeleteDelete PASS
BSTSpec7 prop_DeleteUnion FAIL
BSTSpec7 prop_UnionInsert FAIL
BSTSpec7 prop_UnionNil1 PASS
BSTSpec7 prop_UnionNil2 PASS
BSTSpec7 prop_UnionDeleteInsert FAIL
BSTSpec7 prop_UnionDeleteDelete FAIL
BSTSpec7 prop_UnionUnionIdem PASS
BSTSpec7 prop_UnionUnionAssoc FAIL
BSTSpec7 prop_FindNil PASS
BSTSpec7 prop_FindInsert PASS
BSTSpec7 prop_FindDelete PASS
BSTSpec7 prop_FindUnion FAIL
BSTSpec7 prop_InsertComplete PASS
BSTSpec7 prop_InsertCompleteForDelete PASS
BSTSpec7 prop_InsertCompleteForUnion FAIL
BSTSpec7 prop_NilModel PASS
BSTSpec7 prop_InsertModel PASS
BSTSpec7 prop_DeleteModel PASS
BSTSpec7 prop_UnionModel FAIL
BSTSpec7 prop_FindModel PASS
BSTSpec8 prop_ArbitraryValid PASS
BSTSpec8 prop_NilValid PASS
BSTSpec8 prop_InsertValid PASS
BSTSpec8 prop_DeleteValid PASS
BSTSpec8 prop_UnionValid PASS
BSTSpec8 prop_InsertPost PASS
BSTSpec8 prop_DeletePost PASS
BSTSpec8 prop_FindPostPresent PASS
BSTSpec8 prop_FindPostAbsent PASS
BSTSpec8 prop_InsertDeleteComplete PASS
BSTSpec8 prop_UnionPost FAIL
BSTSpec8 prop_InsertInsertWeak PASS
BSTSpec8 prop_InsertInsert PASS
BSTSpec8 prop_InsertDeleteWeak PASS
BSTSpec8 prop_InsertDelete PASS
BSTSpec8 prop_InsertUnion FAIL
BSTSpec8 prop_DeleteNil PASS
BSTSpec8 prop_DeleteInsertWeak PASS
BSTSpec8 prop_DeleteInsert PASS
BSTSpec8 prop_DeleteDelete PASS
BSTSpec8 prop_DeleteUnion FAIL
BSTSpec8 prop_UnionInsert FAIL
BSTSpec8 prop_UnionNil1 PASS
BSTSpec8 prop_UnionNil2 PASS
BSTSpec8 prop_UnionDeleteInsert FAIL
BSTSpec8 prop_UnionDeleteDelete FAIL
BSTSpec8 prop_UnionUnionIdem PASS
BSTSpec8 prop_UnionUnionAssoc FAIL
BSTSpec8 prop_FindNil PASS
BSTSpec8 prop_FindInsert PASS
BSTSpec8 prop_FindDelete PASS
BSTSpec8 prop_FindUnion FAIL
BSTSpec8 prop_InsertComplete PASS
BSTSpec8 prop_InsertCompleteForDelete PASS
BSTSpec8 prop_InsertCompleteForUnion PASS
BSTSpec8 prop_NilModel PASS
BSTSpec8 prop_InsertModel PASS
BSTSpec8 prop_DeleteModel PASS
BSTSpec8 prop_UnionModel FAIL
BSTSpec8 prop_FindModel PASS
```
