# prop_UnionInsert (hughes-bst/BSTSpec2)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | ResourceOut | 10.06 | - |
| twee | Theorem | 0.79 | CONFIRMED |
| vampire | Timeout | 9.96 | - |

Counterexample (decoded from the twee witness, checked with GHC):

```
property:   prop_UnionInsert
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec2.hs
prover:     twee
witness:    prop_UnionInsert [] (toList (insert Zero Zero nil)) (Zero, Zero)
evaluated:  prop_UnionInsert [] [(Zero, Zero)] (Zero, Zero)
input:      prop_UnionInsert [] [(Zero, Zero)] (Zero, Zero)
result:     False -- counterexample confirmed
```
