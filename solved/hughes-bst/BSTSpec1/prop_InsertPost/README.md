# prop_InsertPost (hughes-bst/BSTSpec1)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | Theorem | 0.02 | CONFIRMED |
| twee | Theorem | 0.08 | CONFIRMED |
| vampire | Theorem | 0.12 | CONFIRMED |

Counterexample (decoded from the eprover witness, checked with GHC):

```
property:   prop_InsertPost
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec1.hs
prover:     eprover
witness:    prop_InsertPost (Suc _X1) _X2 ((Zero, _X3) : _X4) Zero
input:      prop_InsertPost (Suc undefined) undefined ((Zero, undefined) : undefined) Zero
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
