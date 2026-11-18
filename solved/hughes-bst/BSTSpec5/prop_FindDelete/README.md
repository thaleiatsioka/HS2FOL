# prop_FindDelete (hughes-bst/BSTSpec5)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | Theorem | 1.92 | CONFIRMED |
| twee | Theorem | 0.53 | CONFIRMED |
| vampire | Theorem | 1.08 | ILL_TYPED |

Counterexample (decoded from the eprover witness, checked with GHC):

```
property:   prop_FindDelete
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec5.hs
prover:     eprover
witness:    prop_FindDelete Zero Zero [(Zero, _X1), (Suc _X2, _X3)]
input:      prop_FindDelete Zero Zero [(Zero, undefined), (Suc undefined, undefined)]
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
