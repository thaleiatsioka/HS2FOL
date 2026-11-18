# prop_UnionUnionIdem (hughes-bst/BSTSpec6)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | Theorem | 0.02 | CONFIRMED |
| twee | Theorem | 0.25 | CONFIRMED |
| vampire | Theorem | 0.22 | CONFIRMED |

Counterexample (decoded from the eprover witness, checked with GHC):

```
property:   prop_UnionUnionIdem
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec6.hs
prover:     eprover
witness:    prop_UnionUnionIdem [(Zero, Zero)]
input:      prop_UnionUnionIdem [(Zero, Zero)]
result:     False -- counterexample confirmed
```
