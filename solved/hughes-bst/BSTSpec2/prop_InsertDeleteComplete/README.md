# prop_InsertDeleteComplete (hughes-bst/BSTSpec2)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | Theorem | 1.02 | CONFIRMED |
| twee | Theorem | 0.22 | CONFIRMED |
| vampire | Timeout | 9.94 | - |

Counterexample (decoded from the eprover witness, checked with GHC):

```
property:   prop_InsertDeleteComplete
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec2.hs
prover:     eprover
witness:    prop_InsertDeleteComplete Zero [(Zero, Zero)]
input:      prop_InsertDeleteComplete Zero [(Zero, Zero)]
result:     False -- counterexample confirmed
```
