# prop_DeleteInsert (hughes-bst/BSTSpec5)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | ResourceOut | 10.10 | - |
| twee | Theorem | 0.88 | CONFIRMED |
| vampire | Timeout | 9.95 | - |

Counterexample (decoded from the twee witness, checked with GHC):

```
property:   prop_DeleteInsert
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec5.hs
prover:     twee
witness:    prop_DeleteInsert Zero (Zero, _X) (toList (insert (Suc _Z) _Y nil))
evaluated:  prop_DeleteInsert Zero (Zero, _X) [(Suc _Z, _Y)]
input:      prop_DeleteInsert Zero (Zero, undefined) [(Suc undefined, undefined)]
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
