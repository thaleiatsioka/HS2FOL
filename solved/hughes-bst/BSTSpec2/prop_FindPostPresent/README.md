# prop_FindPostPresent (hughes-bst/BSTSpec2)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | Theorem | 0.03 | CONFIRMED |
| twee | Theorem | 0.06 | CONFIRMED |
| vampire | Theorem | 0.02 | CONFIRMED |

Counterexample (decoded from the eprover witness, checked with GHC):

```
property:   prop_FindPostPresent
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec2.hs
prover:     eprover
witness:    prop_FindPostPresent Zero Zero [(Zero, Suc _X1)]
input:      prop_FindPostPresent Zero Zero [(Zero, Suc undefined)]
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
