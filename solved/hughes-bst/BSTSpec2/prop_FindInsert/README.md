# prop_FindInsert (hughes-bst/BSTSpec2)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | Theorem | 0.04 | CONFIRMED |
| twee | Theorem | 0.09 | CONFIRMED |
| vampire | Theorem | 1.72 | CONFIRMED |

Counterexample (decoded from the eprover witness, checked with GHC):

```
property:   prop_FindInsert
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec2.hs
prover:     eprover
witness:    prop_FindInsert Zero (Zero, Zero) [(Zero, Suc _X1)]
input:      prop_FindInsert Zero (Zero, Zero) [(Zero, Suc undefined)]
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
