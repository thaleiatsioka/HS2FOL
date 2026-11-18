# prop_UnionDeleteInsert (hughes-bst/BSTSpec1)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | ResourceOut | 10.14 | - |
| twee | Theorem | 1.53 | CONFIRMED |
| vampire | Theorem | 4.33 | CONFIRMED |

Counterexample (decoded from the twee witness, checked with GHC):

```
property:   prop_UnionDeleteInsert
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec1.hs
prover:     twee
witness:    prop_UnionDeleteInsert (toList (insert (Suc _X) _Y _T)) _Z (Zero, Zero)
evaluated:  prop_UnionDeleteInsert [(Suc _X, _Y)] _Z (Zero, Zero)
input:      prop_UnionDeleteInsert [(Suc undefined, undefined)] undefined (Zero, Zero)
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
