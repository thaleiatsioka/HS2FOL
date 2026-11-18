# prop_FindUnion (hughes-bst/BSTSpec6)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | Theorem | 2.74 | CONFIRMED |
| twee | Theorem | 0.85 | CONFIRMED |
| vampire | Theorem | 0.22 | CONFIRMED |

Counterexample (decoded from the eprover witness, checked with GHC):

```
property:   prop_FindUnion
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec6.hs
prover:     eprover
witness:    prop_FindUnion Zero [(Suc _X1, _X2)] [(Zero, _X3)]
input:      prop_FindUnion Zero [(Suc undefined, undefined)] [(Zero, undefined)]
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
