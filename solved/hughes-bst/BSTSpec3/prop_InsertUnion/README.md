# prop_InsertUnion (hughes-bst/BSTSpec3)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | ResourceOut | 10.08 | - |
| twee | Theorem | 0.67 | CONFIRMED |
| vampire | Timeout | 9.95 | - |

Counterexample (decoded from the twee witness, checked with GHC):

```
property:   prop_InsertUnion
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec3.hs
prover:     twee
witness:    prop_InsertUnion (Zero, Suc _X) [] (toList (insert Zero Zero nil))
evaluated:  prop_InsertUnion (Zero, Suc _X) [] [(Zero, Zero)]
input:      prop_InsertUnion (Zero, Suc undefined) [] [(Zero, Zero)]
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
