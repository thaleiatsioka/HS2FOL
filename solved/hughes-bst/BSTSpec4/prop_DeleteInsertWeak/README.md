# prop_DeleteInsertWeak (hughes-bst/BSTSpec4)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | Theorem | 0.03 | CONFIRMED |
| twee | Theorem | 0.11 | CONFIRMED |
| vampire | Theorem | 0.24 | CONFIRMED |

Counterexample (decoded from the eprover witness, checked with GHC):

```
property:   prop_DeleteInsertWeak
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec4.hs
prover:     eprover
witness:    prop_DeleteInsertWeak (Suc _X1) (Zero, _X2) []
input:      prop_DeleteInsertWeak (Suc undefined) (Zero, undefined) []
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
