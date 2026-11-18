# prop_UnionDeleteInsert (hughes-bst/BSTSpec2)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | ResourceOut | 10.10 | - |
| twee | Theorem | 12.02 | CONFIRMED |
| vampire | Theorem | 3.60 | CONFIRMED |

Counterexample (decoded from the twee witness, checked with GHC):

```
property:   prop_UnionDeleteInsert
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec2.hs
prover:     twee
witness:    prop_UnionDeleteInsert (toList (insert Zero Zero nil)) [] (Zero, Zero)
evaluated:  prop_UnionDeleteInsert [(Zero, Zero)] [] (Zero, Zero)
input:      prop_UnionDeleteInsert [(Zero, Zero)] [] (Zero, Zero)
result:     False -- counterexample confirmed
```
