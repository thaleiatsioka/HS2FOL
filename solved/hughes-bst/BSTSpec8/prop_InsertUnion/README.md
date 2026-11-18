# prop_InsertUnion (hughes-bst/BSTSpec8)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | Theorem | 26.59 | CONFIRMED |
| twee | Timeout | 65.02 | - |
| vampire | Timeout | 59.92 | - |

Counterexample (decoded from the eprover witness, checked with GHC):

```
property:   prop_InsertUnion
file:       benchmarks/hughes-bst/BSTSpec8.hs
prover:     eprover
witness:    prop_InsertUnion (Zero, Suc _X1) (toList (Branch Leaf (Suc _X2) _X3 Leaf)) (toList (Branch Leaf Zero Zero Leaf))
evaluated:  prop_InsertUnion (Zero, Suc _X1) [(Suc _X2, _X3)] [(Zero, Zero)]
input:      prop_InsertUnion (Zero, Suc undefined) [(Suc undefined, undefined)] [(Zero, Zero)]
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
