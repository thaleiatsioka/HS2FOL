# prop_InsertUnion (hughes-bst/BSTSpec6)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | Theorem | 2.91 | CONFIRMED |
| twee | Theorem | 2.86 | CONFIRMED |
| vampire | Timeout | 9.93 | - |

Counterexample (decoded from the eprover witness, checked with GHC):

```
property:   prop_InsertUnion
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec6.hs
prover:     eprover
witness:    prop_InsertUnion (Suc _X1, _X2) [] (toList (((insert Zero) _X3) Leaf))
evaluated:  prop_InsertUnion (Suc _X1, _X2) [] [(Zero, _X3)]
input:      prop_InsertUnion (Suc undefined, undefined) [] [(Zero, undefined)]
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
