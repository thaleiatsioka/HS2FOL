# prop_FindDelete (hughes-bst/BSTSpec2)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | Theorem | 1.64 | CONFIRMED |
| twee | Theorem | 0.82 | CONFIRMED |
| vampire | Theorem | 0.93 | CONFIRMED |

Counterexample (decoded from the eprover witness, checked with GHC):

```
property:   prop_FindDelete
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec2.hs
prover:     eprover
witness:    prop_FindDelete Zero Zero [(Zero, _X1), (Zero, _X2)]
input:      prop_FindDelete Zero Zero [(Zero, undefined), (Zero, undefined)]
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
