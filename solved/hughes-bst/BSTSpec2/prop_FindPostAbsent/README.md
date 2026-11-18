# prop_FindPostAbsent (hughes-bst/BSTSpec2)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | Theorem | 0.03 | CONFIRMED |
| twee | Theorem | 0.50 | CONFIRMED |
| vampire | Theorem | 0.82 | ILL_TYPED |

Counterexample (decoded from the eprover witness, checked with GHC):

```
property:   prop_FindPostAbsent
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec2.hs
prover:     eprover
witness:    prop_FindPostAbsent Zero [(Zero, _X1), (Zero, _X2)]
input:      prop_FindPostAbsent Zero [(Zero, undefined), (Zero, undefined)]
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
