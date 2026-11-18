# prop_InsertCompleteForUnion (hughes-bst/BSTSpec1)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | ResourceOut | 60.49 | - |
| twee | Theorem | 22.18 | CONFIRMED |
| vampire | Timeout | 59.93 | - |

Counterexample (decoded from the twee witness, checked with GHC):

```
property:   prop_InsertCompleteForUnion
file:       benchmarks/hughes-bst/BSTSpec1.hs
prover:     twee
witness:    prop_InsertCompleteForUnion ((Suc _X, _Y) : _U2) ((Zero, _W) : _V2)
input:      prop_InsertCompleteForUnion ((Suc undefined, undefined) : undefined) ((Zero, undefined) : undefined)
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
