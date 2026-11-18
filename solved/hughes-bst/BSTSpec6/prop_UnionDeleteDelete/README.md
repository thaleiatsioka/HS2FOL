# prop_UnionDeleteDelete (hughes-bst/BSTSpec6)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | ResourceOut | 10.11 | - |
| twee | Theorem | 9.76 | CONFIRMED |
| vampire | Theorem | 0.32 | CONFIRMED |

Counterexample (decoded from the twee witness, checked with GHC):

```
property:   prop_UnionDeleteDelete
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec6.hs
prover:     twee
witness:    prop_UnionDeleteDelete (toList (insert Zero _Y nil)) (toList (insert Zero _X nil)) Zero
evaluated:  prop_UnionDeleteDelete [(Zero, _Y)] [(Zero, _X)] Zero
input:      prop_UnionDeleteDelete [(Zero, undefined)] [(Zero, undefined)] Zero
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
