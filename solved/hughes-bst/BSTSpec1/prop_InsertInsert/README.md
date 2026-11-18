# prop_InsertInsert (hughes-bst/BSTSpec1)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | Theorem | 0.01 | CONFIRMED |
| twee | Theorem | 0.06 | CONFIRMED |
| vampire | Theorem | 0.04 | CONFIRMED |

Counterexample (decoded from the eprover witness, checked with GHC):

```
property:   prop_InsertInsert
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec1.hs
prover:     eprover
witness:    prop_InsertInsert (Suc _X1, _X2) (Zero, _X3) _X4
input:      prop_InsertInsert (Suc undefined, undefined) (Zero, undefined) undefined
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
