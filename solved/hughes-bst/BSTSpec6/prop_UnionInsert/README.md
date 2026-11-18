# prop_UnionInsert (hughes-bst/BSTSpec6)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | Theorem | 1.96 | CONFIRMED |
| twee | Theorem | 2.14 | CONFIRMED |
| vampire | Theorem | 4.04 | CONFIRMED |

Counterexample (decoded from the eprover witness, checked with GHC):

```
property:   prop_UnionInsert
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec6.hs
prover:     eprover
witness:    prop_UnionInsert [] (toList (((insert Zero) _X1) Leaf)) (Suc _X2, _X3)
evaluated:  prop_UnionInsert [] [(Zero, _X1)] (Suc _X2, _X3)
input:      prop_UnionInsert [] [(Zero, undefined)] (Suc undefined, undefined)
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
