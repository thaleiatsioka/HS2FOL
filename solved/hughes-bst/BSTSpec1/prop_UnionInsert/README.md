# prop_UnionInsert (hughes-bst/BSTSpec1)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | Theorem | 0.60 | CONFIRMED |
| twee | Theorem | 0.50 | CONFIRMED |
| vampire | Theorem | 0.85 | CONFIRMED |

Counterexample (decoded from the eprover witness, checked with GHC):

```
property:   prop_UnionInsert
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec1.hs
prover:     eprover
witness:    prop_UnionInsert _X1 ((Zero, _X2) : _X3) (Suc _X4, _X5)
input:      prop_UnionInsert undefined ((Zero, undefined) : undefined) (Suc undefined, undefined)
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
