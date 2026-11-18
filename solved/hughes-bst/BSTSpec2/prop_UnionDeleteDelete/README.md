# prop_UnionDeleteDelete (hughes-bst/BSTSpec2)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | ResourceOut | 60.56 | - |
| twee | Theorem | 25.71 | CONFIRMED |
| vampire | Timeout | 59.98 | - |

Counterexample (decoded from the twee witness, checked with GHC):

```
property:   prop_UnionDeleteDelete
file:       benchmarks/hughes-bst/BSTSpec2.hs
prover:     twee
witness:    prop_UnionDeleteDelete (toList (insert Zero _Y nil)) (toList (insert Zero _W (insert Zero _X nil))) Zero
evaluated:  prop_UnionDeleteDelete [(Zero, _Y)] [(Zero, _X), (Zero, _W)] Zero
input:      prop_UnionDeleteDelete [(Zero, undefined)] [(Zero, undefined), (Zero, undefined)] Zero
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
