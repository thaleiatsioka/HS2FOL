# prop_InsertInsert (hughes-bst/BSTSpec3)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | ResourceOut | 10.08 | - |
| twee | Theorem | 0.06 | CONFIRMED |
| vampire | Theorem | 0.23 | CONFIRMED |

Counterexample (decoded from the twee witness, checked with GHC):

```
property:   prop_InsertInsert
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec3.hs
prover:     twee
witness:    prop_InsertInsert (Zero, Suc _X) (Zero, Zero) []
input:      prop_InsertInsert (Zero, Suc undefined) (Zero, Zero) []
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
