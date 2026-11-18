# prop_UnionInsert (hughes-bst/BSTSpec7)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | Theorem | 8.42 | CONFIRMED |
| twee | Timeout | 15.02 | - |
| vampire | Timeout | 9.95 | - |

Counterexample (decoded from the eprover witness, checked with GHC):

```
property:   prop_UnionInsert
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec7.hs
prover:     eprover
witness:    prop_UnionInsert (toList (Branch Leaf (Suc _X1) _X2 Leaf)) (toList (Branch Leaf Zero Zero Leaf)) (Zero, Zero)
evaluated:  prop_UnionInsert [(Suc _X1, _X2)] [(Zero, Zero)] (Zero, Zero)
input:      prop_UnionInsert [(Suc undefined, undefined)] [(Zero, Zero)] (Zero, Zero)
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
