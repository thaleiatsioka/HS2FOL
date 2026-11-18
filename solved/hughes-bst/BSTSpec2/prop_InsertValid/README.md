# prop_InsertValid (hughes-bst/BSTSpec2)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | Theorem | 0.03 | CONFIRMED |
| twee | Theorem | 0.14 | CONFIRMED |
| vampire | Theorem | 0.27 | CONFIRMED |

Counterexample (decoded from the eprover witness, checked with GHC):

```
property:   prop_InsertValid
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec2.hs
prover:     eprover
witness:    prop_InsertValid Zero _X1 (toList (((insert Zero) _X2) Leaf))
evaluated:  prop_InsertValid Zero _X1 [(Zero, _X2)]
input:      prop_InsertValid Zero undefined [(Zero, undefined)]
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
