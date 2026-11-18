# prop_DeleteInsert (hughes-bst/BSTSpec1)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | ResourceOut | 10.11 | - |
| twee | Theorem | 0.17 | CONFIRMED |
| vampire | Theorem | 0.06 | CONFIRMED |

Counterexample (decoded from the twee witness, checked with GHC):

```
property:   prop_DeleteInsert
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec1.hs
prover:     twee
witness:    prop_DeleteInsert Zero (Zero, _V) ((Suc _X, _Y) : _W)
input:      prop_DeleteInsert Zero (Zero, undefined) ((Suc undefined, undefined) : undefined)
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
