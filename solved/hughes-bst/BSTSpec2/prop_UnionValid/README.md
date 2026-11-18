# prop_UnionValid (hughes-bst/BSTSpec2)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | Theorem | 0.04 | CONFIRMED |
| twee | Theorem | 0.17 | CONFIRMED |
| vampire | Theorem | 1.79 | CONFIRMED |

Counterexample (decoded from the eprover witness, checked with GHC):

```
property:   prop_UnionValid
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec2.hs
prover:     eprover
witness:    prop_UnionValid [] (toList (Branch Leaf Zero _X1 (Branch Leaf Zero _X2 Leaf)))
evaluated:  prop_UnionValid [] [(Zero, _X1), (Zero, _X2)]
input:      prop_UnionValid [] [(Zero, undefined), (Zero, undefined)]
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
