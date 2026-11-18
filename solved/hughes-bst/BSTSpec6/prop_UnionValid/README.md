# prop_UnionValid (hughes-bst/BSTSpec6)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | Theorem | 0.02 | CONFIRMED |
| twee | Theorem | 0.17 | CONFIRMED |
| vampire | Theorem | 0.23 | CONFIRMED |

Counterexample (decoded from the eprover witness, checked with GHC):

```
property:   prop_UnionValid
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec6.hs
prover:     eprover
witness:    prop_UnionValid (toList (Branch Leaf (Suc _X1) _X2 Leaf)) (toList (Branch Leaf Zero _X3 Leaf))
evaluated:  prop_UnionValid [(Suc _X1, _X2)] [(Zero, _X3)]
input:      prop_UnionValid [(Suc undefined, undefined)] [(Zero, undefined)]
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
