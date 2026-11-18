# prop_DeleteInsert (hughes-bst/BSTSpec2)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | ResourceOut | 10.11 | - |
| twee | Theorem | 0.59 | CONFIRMED |
| vampire | Theorem | 3.17 | CONFIRMED |

Counterexample (decoded from the twee witness, checked with GHC):

```
property:   prop_DeleteInsert
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec2.hs
prover:     twee
witness:    prop_DeleteInsert Zero (Zero, _X) (toList (insert Zero _Y nil))
evaluated:  prop_DeleteInsert Zero (Zero, _X) [(Zero, _Y)]
input:      prop_DeleteInsert Zero (Zero, undefined) [(Zero, undefined)]
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
