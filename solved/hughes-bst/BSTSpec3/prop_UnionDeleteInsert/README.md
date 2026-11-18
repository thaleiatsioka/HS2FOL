# prop_UnionDeleteInsert (hughes-bst/BSTSpec3)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | ResourceOut | 10.12 | - |
| twee | Theorem | 12.81 | CONFIRMED |
| vampire | Theorem | 3.60 | CONFIRMED |

Counterexample (decoded from the twee witness, checked with GHC):

```
property:   prop_UnionDeleteInsert
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec3.hs
prover:     twee
witness:    prop_UnionDeleteInsert (toList (insert Zero (Suc _X) nil)) [] (Zero, Zero)
evaluated:  prop_UnionDeleteInsert [(Zero, Suc _X)] [] (Zero, Zero)
input:      prop_UnionDeleteInsert [(Zero, Suc undefined)] [] (Zero, Zero)
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
