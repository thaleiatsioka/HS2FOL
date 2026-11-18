# prop_InsertUnion (hughes-bst/BSTSpec2)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | ResourceOut | 10.12 | - |
| twee | Theorem | 1.59 | CONFIRMED |
| vampire | Timeout | 9.97 | - |

Counterexample (decoded from the twee witness, checked with GHC):

```
property:   prop_InsertUnion
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec2.hs
prover:     twee
witness:    prop_InsertUnion (Zero, Zero) [] (toList (insert Zero Zero nil))
evaluated:  prop_InsertUnion (Zero, Zero) [] [(Zero, Zero)]
input:      prop_InsertUnion (Zero, Zero) [] [(Zero, Zero)]
result:     False -- counterexample confirmed
```
