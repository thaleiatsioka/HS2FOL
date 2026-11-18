# prop_DeleteUnion (hughes-bst/BSTSpec2)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | ResourceOut | 60.39 | - |
| twee | Theorem | 27.74 | CONFIRMED |
| vampire | Timeout | 59.96 | - |

Counterexample (decoded from the twee witness, checked with GHC):

```
property:   prop_DeleteUnion
file:       benchmarks/hughes-bst/BSTSpec2.hs
prover:     twee
witness:    prop_DeleteUnion Zero (toList (insert Zero _Z nil)) (toList (insert Zero _Y (insert Zero _X nil)))
evaluated:  prop_DeleteUnion Zero [(Zero, _Z)] [(Zero, _X), (Zero, _Y)]
input:      prop_DeleteUnion Zero [(Zero, undefined)] [(Zero, undefined), (Zero, undefined)]
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
