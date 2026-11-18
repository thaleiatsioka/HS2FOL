# prop_UnionValid (hughes-bst/BSTSpec7)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | Theorem | 50.30 | CONFIRMED |
| twee | Timeout | 65.05 | - |
| vampire | Timeout | 59.98 | - |

Counterexample (decoded from the eprover witness, checked with GHC):

```
property:   prop_UnionValid
file:       benchmarks/hughes-bst/BSTSpec7.hs
prover:     eprover
witness:    prop_UnionValid (toList (Branch Leaf Zero _X1 (Branch Leaf (Suc _X2) _X3 Leaf))) (toList (Branch Leaf Zero _X4 Leaf))
evaluated:  prop_UnionValid [(Zero, _X1), (Suc _X2, _X3)] [(Zero, _X4)]
input:      prop_UnionValid [(Zero, undefined), (Suc undefined, undefined)] [(Zero, undefined)]
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
