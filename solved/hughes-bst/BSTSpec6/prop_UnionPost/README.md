# prop_UnionPost (hughes-bst/BSTSpec6)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | Theorem | 2.76 | CONFIRMED |
| twee | Theorem | 0.86 | CONFIRMED |
| vampire | Theorem | 0.22 | CONFIRMED |

Counterexample (decoded from the eprover witness, checked with GHC):

```
property:   prop_UnionPost
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec6.hs
prover:     eprover
witness:    prop_UnionPost [(Suc _X1, _X2)] [(Zero, _X3)] Zero
input:      prop_UnionPost [(Suc undefined, undefined)] [(Zero, undefined)] Zero
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
