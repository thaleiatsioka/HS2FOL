# prop_DeleteValid (hughes-bst/BSTSpec2)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | Theorem | 0.03 | CONFIRMED |
| twee | Theorem | 0.62 | CONFIRMED |
| vampire | Timeout | 9.95 | - |

Counterexample (decoded from the eprover witness, checked with GHC):

```
property:   prop_DeleteValid
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec2.hs
prover:     eprover
witness:    prop_DeleteValid (Suc _X1) (toList (Branch Leaf Zero _X2 (Branch Leaf Zero _X3 Leaf)))
evaluated:  prop_DeleteValid (Suc _X1) [(Zero, _X2), (Zero, _X3)]
input:      prop_DeleteValid (Suc undefined) [(Zero, undefined), (Zero, undefined)]
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
