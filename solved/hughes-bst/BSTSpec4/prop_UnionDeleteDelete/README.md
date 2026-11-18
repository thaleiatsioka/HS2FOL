# prop_UnionDeleteDelete (hughes-bst/BSTSpec4)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | ResourceOut | 10.13 | - |
| twee | Timeout | 15.02 | - |
| vampire | Theorem | 0.25 | CONFIRMED |

Counterexample (decoded from the vampire witness, checked with GHC):

```
property:   prop_UnionDeleteDelete
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec4.hs
prover:     vampire
witness:    prop_UnionDeleteDelete [(Zero, _X2)] [(Suc _X0, _X1)] Zero
input:      prop_UnionDeleteDelete [(Zero, undefined)] [(Suc undefined, undefined)] Zero
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
