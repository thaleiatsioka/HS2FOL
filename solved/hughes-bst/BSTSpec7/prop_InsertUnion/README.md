# prop_InsertUnion (hughes-bst/BSTSpec7)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | Theorem | 9.67 | CONFIRMED |
| twee | Timeout | 15.02 | - |
| vampire | Timeout | 9.94 | - |

Counterexample (decoded from the eprover witness, checked with GHC):

```
property:   prop_InsertUnion
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec7.hs
prover:     eprover
witness:    prop_InsertUnion (Zero, Zero) (toList (Branch Leaf (Suc _X1) _X2 Leaf)) (toList (Branch Leaf Zero Zero Leaf))
evaluated:  prop_InsertUnion (Zero, Zero) [(Suc _X1, _X2)] [(Zero, Zero)]
input:      prop_InsertUnion (Zero, Zero) [(Suc undefined, undefined)] [(Zero, Zero)]
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
