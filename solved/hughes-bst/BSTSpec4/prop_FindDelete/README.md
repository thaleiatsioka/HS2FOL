# prop_FindDelete (hughes-bst/BSTSpec4)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | Theorem | 0.10 | CONFIRMED |
| twee | Theorem | 0.80 | CONFIRMED |
| vampire | Theorem | 0.03 | CONFIRMED |

Counterexample (decoded from the eprover witness, checked with GHC):

```
property:   prop_FindDelete
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec4.hs
prover:     eprover
witness:    prop_FindDelete (Suc (Suc Zero)) Zero [(Zero, _X1), (Suc (Suc Zero), _X2)]
input:      prop_FindDelete (Suc (Suc Zero)) Zero [(Zero, undefined), (Suc (Suc Zero), undefined)]
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
