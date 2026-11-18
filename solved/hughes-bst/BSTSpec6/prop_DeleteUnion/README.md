# prop_DeleteUnion (hughes-bst/BSTSpec6)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | ResourceOut | 10.14 | - |
| twee | Theorem | 9.37 | CONFIRMED |
| vampire | Theorem | 0.32 | CONFIRMED |

Counterexample (decoded from the twee witness, checked with GHC):

```
property:   prop_DeleteUnion
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec6.hs
prover:     twee
witness:    prop_DeleteUnion Zero (toList (insert Zero _Y nil)) (toList (insert Zero _X nil))
evaluated:  prop_DeleteUnion Zero [(Zero, _Y)] [(Zero, _X)]
input:      prop_DeleteUnion Zero [(Zero, undefined)] [(Zero, undefined)]
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
