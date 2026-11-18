# prop_DeletePost (hughes-bst/BSTSpec5)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | Theorem | 1.81 | CONFIRMED |
| twee | Theorem | 0.55 | CONFIRMED |
| vampire | Theorem | 1.02 | ILL_TYPED |

Counterexample (decoded from the eprover witness, checked with GHC):

```
property:   prop_DeletePost
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec5.hs
prover:     eprover
witness:    prop_DeletePost Zero [(Zero, _X1), (Suc _X2, _X3)] Zero
input:      prop_DeletePost Zero [(Zero, undefined), (Suc undefined, undefined)] Zero
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
