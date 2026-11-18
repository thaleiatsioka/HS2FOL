# prop_InsertModel (hughes-bst/BSTSpec3)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | Theorem | 6.60 | CONFIRMED |
| twee | Timeout | 15.02 | - |
| vampire | Timeout | 9.94 | - |

Counterexample (decoded from the eprover witness, checked with GHC):

```
property:   prop_InsertModel
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec3.hs
prover:     eprover
witness:    prop_InsertModel (Zero, Zero) [(Zero, Suc _X1)]
input:      prop_InsertModel (Zero, Zero) [(Zero, Suc undefined)]
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
