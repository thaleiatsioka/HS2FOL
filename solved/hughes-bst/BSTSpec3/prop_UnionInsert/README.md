# prop_UnionInsert (hughes-bst/BSTSpec3)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | ResourceOut | 10.11 | - |
| twee | Theorem | 0.76 | CONFIRMED |
| vampire | Timeout | 9.96 | - |

Counterexample (decoded from the twee witness, checked with GHC):

```
property:   prop_UnionInsert
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec3.hs
prover:     twee
witness:    prop_UnionInsert [] (toList (insert Zero (Suc _X) nil)) (Zero, Zero)
evaluated:  prop_UnionInsert [] [(Zero, Suc _X)] (Zero, Zero)
input:      prop_UnionInsert [] [(Zero, Suc undefined)] (Zero, Zero)
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
