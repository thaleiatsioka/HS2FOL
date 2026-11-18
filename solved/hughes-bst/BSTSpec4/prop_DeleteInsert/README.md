# prop_DeleteInsert (hughes-bst/BSTSpec4)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | ResourceOut | 10.09 | - |
| twee | Theorem | 0.08 | CONFIRMED |
| vampire | Theorem | 0.24 | CONFIRMED |

Counterexample (decoded from the twee witness, checked with GHC):

```
property:   prop_DeleteInsert
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec4.hs
prover:     twee
witness:    prop_DeleteInsert Zero (Suc _X, _Y) []
input:      prop_DeleteInsert Zero (Suc undefined, undefined) []
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
