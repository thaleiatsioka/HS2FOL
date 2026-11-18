# prop_UnionDeleteInsert (hughes-bst/BSTSpec6)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | Theorem | 2.58 | CONFIRMED |
| twee | Timeout | 15.03 | - |
| vampire | Timeout | 9.94 | - |

Counterexample (decoded from the eprover witness, checked with GHC):

```
property:   prop_UnionDeleteInsert
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec6.hs
prover:     eprover
witness:    prop_UnionDeleteInsert (toList (Branch Leaf (Suc _X1) _X2 Leaf)) [] (Zero, _X3)
evaluated:  prop_UnionDeleteInsert [(Suc _X1, _X2)] [] (Zero, _X3)
input:      prop_UnionDeleteInsert [(Suc undefined, undefined)] [] (Zero, undefined)
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
