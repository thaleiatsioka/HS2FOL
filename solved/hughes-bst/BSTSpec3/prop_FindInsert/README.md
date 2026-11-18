# prop_FindInsert (hughes-bst/BSTSpec3)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | Theorem | 0.03 | CONFIRMED |
| twee | Theorem | 0.16 | CONFIRMED |
| vampire | Theorem | 0.11 | CONFIRMED |

Counterexample (decoded from the eprover witness, checked with GHC):

```
property:   prop_FindInsert
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec3.hs
prover:     eprover
witness:    prop_FindInsert Zero (Zero, Zero) [(Zero, Suc _X1)]
input:      prop_FindInsert Zero (Zero, Zero) [(Zero, Suc undefined)]
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
