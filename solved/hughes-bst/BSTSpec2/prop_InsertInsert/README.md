# prop_InsertInsert (hughes-bst/BSTSpec2)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | ResourceOut | 10.13 | - |
| twee | Theorem | 0.27 | CONFIRMED |
| vampire | Theorem | 0.26 | CONFIRMED |

Counterexample (decoded from the twee witness, checked with GHC):

```
property:   prop_InsertInsert
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec2.hs
prover:     twee
witness:    prop_InsertInsert (Zero, Zero) (Zero, Zero) []
input:      prop_InsertInsert (Zero, Zero) (Zero, Zero) []
result:     False -- counterexample confirmed
```
