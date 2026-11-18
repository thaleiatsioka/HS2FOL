# prop_DeletePost (hughes-bst/BSTSpec4)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | Theorem | 0.11 | CONFIRMED |
| twee | Theorem | 2.14 | CONFIRMED |
| vampire | Theorem | 0.04 | CONFIRMED |

Counterexample (decoded from the eprover witness, checked with GHC):

```
property:   prop_DeletePost
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec4.hs
prover:     eprover
witness:    prop_DeletePost Zero [(Zero, _X1), (Suc (Suc Zero), _X2)] (Suc (Suc Zero))
input:      prop_DeletePost Zero [(Zero, undefined), (Suc (Suc Zero), undefined)] (Suc (Suc Zero))
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
