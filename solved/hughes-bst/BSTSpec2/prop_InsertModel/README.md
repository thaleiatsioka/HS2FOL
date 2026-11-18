# prop_InsertModel (hughes-bst/BSTSpec2)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | Theorem | 32.61 | CONFIRMED |
| twee | Timeout | 65.04 | - |
| vampire | Theorem | 23.64 | CONFIRMED |

Counterexample (decoded from the eprover witness, checked with GHC):

```
property:   prop_InsertModel
file:       benchmarks/hughes-bst/BSTSpec2.hs
prover:     eprover
witness:    prop_InsertModel (Zero, Zero) [(Zero, Zero)]
input:      prop_InsertModel (Zero, Zero) [(Zero, Zero)]
result:     False -- counterexample confirmed
```
