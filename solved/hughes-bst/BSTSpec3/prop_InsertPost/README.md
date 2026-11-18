# prop_InsertPost (hughes-bst/BSTSpec3)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | Theorem | 0.04 | CONFIRMED |
| twee | Theorem | 0.11 | CONFIRMED |
| vampire | Theorem | 0.22 | CONFIRMED |

Counterexample (decoded from the eprover witness, checked with GHC):

```
property:   prop_InsertPost
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec3.hs
prover:     eprover
witness:    prop_InsertPost Zero Zero [(Zero, Suc _X1)] Zero
input:      prop_InsertPost Zero Zero [(Zero, Suc undefined)] Zero
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
