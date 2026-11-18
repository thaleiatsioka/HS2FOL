# prop_FindPostAbsent (hughes-bst/BSTSpec5)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | Theorem | 0.02 | CONFIRMED |
| twee | Theorem | 0.35 | CONFIRMED |
| vampire | Theorem | 3.30 | CONFIRMED |

Counterexample (decoded from the eprover witness, checked with GHC):

```
property:   prop_FindPostAbsent
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec5.hs
prover:     eprover
witness:    prop_FindPostAbsent Zero [(Zero, _X1), (Suc _X2, _X3)]
input:      prop_FindPostAbsent Zero [(Zero, undefined), (Suc undefined, undefined)]
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
