# prop_UnionDeleteInsert (hughes-bst/BSTSpec7)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | ResourceOut | 60.43 | - |
| twee | Theorem | 63.56 | CONFIRMED |
| vampire | Timeout | 60.00 | - |

Counterexample (decoded from the twee witness, checked with GHC):

```
property:   prop_UnionDeleteInsert
file:       benchmarks/hughes-bst/BSTSpec7.hs
prover:     twee
witness:    prop_UnionDeleteInsert (toList (insert Zero _W nil)) (toList (insert Zero _Z (insert (Suc _X) _Y nil))) (Zero, Zero)
evaluated:  prop_UnionDeleteInsert [(Zero, _W)] [(Zero, _Z), (Suc _X, _Y)] (Zero, Zero)
input:      prop_UnionDeleteInsert [(Zero, undefined)] [(Zero, undefined), (Suc undefined, undefined)] (Zero, Zero)
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
