# prop_UnionDeleteDelete (hughes-bst/BSTSpec7)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | ResourceOut | 10.07 | - |
| twee | Theorem | 10.62 | CONFIRMED |
| vampire | Timeout | 9.94 | - |

Counterexample (decoded from the twee witness, checked with GHC):

```
property:   prop_UnionDeleteDelete
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec7.hs
prover:     twee
witness:    prop_UnionDeleteDelete (toList (insert Zero _W nil)) (toList (insert Zero _Y (insert (Suc _Z) _X nil))) Zero
evaluated:  prop_UnionDeleteDelete [(Zero, _W)] [(Zero, _Y), (Suc _Z, _X)] Zero
input:      prop_UnionDeleteDelete [(Zero, undefined)] [(Zero, undefined), (Suc undefined, undefined)] Zero
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
