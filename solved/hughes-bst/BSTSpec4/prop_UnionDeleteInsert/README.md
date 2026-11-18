# prop_UnionDeleteInsert (hughes-bst/BSTSpec4)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | ResourceOut | 10.06 | - |
| twee | Timeout | 15.02 | - |
| vampire | Theorem | 3.76 | CONFIRMED |

Counterexample (decoded from the vampire witness, checked with GHC):

```
property:   prop_UnionDeleteInsert
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec4.hs
prover:     vampire
witness:    prop_UnionDeleteInsert [(Zero, _X0)] [] (Suc _X1, _X2)
input:      prop_UnionDeleteInsert [(Zero, undefined)] [] (Suc undefined, undefined)
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
