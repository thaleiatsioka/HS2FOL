# prop_InsertDeleteComplete (hughes-bst/BSTSpec4)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | Theorem | 0.05 | CONFIRMED |
| twee | Theorem | 0.21 | CONFIRMED |
| vampire | Theorem | 0.08 | CONFIRMED |

Counterexample (decoded from the eprover witness, checked with GHC):

```
property:   prop_InsertDeleteComplete
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec4.hs
prover:     eprover
witness:    prop_InsertDeleteComplete (Suc _X1) [(Zero, _X2)]
input:      prop_InsertDeleteComplete (Suc undefined) [(Zero, undefined)]
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
