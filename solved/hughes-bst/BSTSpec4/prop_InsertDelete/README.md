# prop_InsertDelete (hughes-bst/BSTSpec4)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | Theorem | 0.04 | CONFIRMED |
| twee | Theorem | 0.06 | CONFIRMED |
| vampire | Theorem | 0.04 | CONFIRMED |

Counterexample (decoded from the eprover witness, checked with GHC):

```
property:   prop_InsertDelete
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec4.hs
prover:     eprover
witness:    prop_InsertDelete (Suc _X1, _X2) Zero []
input:      prop_InsertDelete (Suc undefined, undefined) Zero []
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
