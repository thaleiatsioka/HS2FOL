# prop_DeleteModel (hughes-bst/BSTSpec4)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | Theorem | 2.27 | CONFIRMED |
| twee | Timeout | 15.02 | - |
| vampire | Theorem | 0.26 | ILL_TYPED |

Counterexample (decoded from the eprover witness, checked with GHC):

```
property:   prop_DeleteModel
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec4.hs
prover:     eprover
witness:    prop_DeleteModel Zero [(Suc _X1, _X2)]
input:      prop_DeleteModel Zero [(Suc undefined, undefined)]
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
