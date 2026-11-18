# prop_UnionInsert (hughes-bst/BSTSpec8)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | Theorem | 29.68 | CONFIRMED |
| twee | Timeout | 65.02 | - |
| vampire | Timeout | 59.99 | - |

Counterexample (decoded from the eprover witness, checked with GHC):

```
property:   prop_UnionInsert
file:       benchmarks/hughes-bst/BSTSpec8.hs
prover:     eprover
witness:    prop_UnionInsert (toList (Branch Leaf (Suc _X1) _X2 Leaf)) (toList (Branch Leaf Zero (Suc _X3) Leaf)) (Zero, Zero)
evaluated:  prop_UnionInsert [(Suc _X1, _X2)] [(Zero, Suc _X3)] (Zero, Zero)
input:      prop_UnionInsert [(Suc undefined, undefined)] [(Zero, Suc undefined)] (Zero, Zero)
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
