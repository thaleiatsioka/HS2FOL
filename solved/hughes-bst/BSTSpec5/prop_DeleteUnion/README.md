# prop_DeleteUnion (hughes-bst/BSTSpec5)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | ResourceOut | 60.39 | - |
| twee | Theorem | 20.12 | CONFIRMED |
| vampire | Theorem | 29.18 | CONFIRMED |

Counterexample (decoded from the twee witness, checked with GHC):

```
property:   prop_DeleteUnion
file:       benchmarks/hughes-bst/BSTSpec5.hs
prover:     twee
witness:    prop_DeleteUnion Zero (toList (insert Zero _W nil)) (toList (insert Zero _Y (insert (Suc _Z) _X nil)))
evaluated:  prop_DeleteUnion Zero [(Zero, _W)] [(Zero, _Y), (Suc _Z, _X)]
input:      prop_DeleteUnion Zero [(Zero, undefined)] [(Zero, undefined), (Suc undefined, undefined)]
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
