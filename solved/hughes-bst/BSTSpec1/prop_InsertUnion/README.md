# prop_InsertUnion (hughes-bst/BSTSpec1)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | Theorem | 0.83 | CONFIRMED |
| twee | Theorem | 0.77 | CONFIRMED |
| vampire | Theorem | 4.33 | CONFIRMED |

Counterexample (decoded from the eprover witness, checked with GHC):

```
property:   prop_InsertUnion
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec1.hs
prover:     eprover
witness:    prop_InsertUnion (Zero, Zero) _X1 ((Suc _X2, _X3) : _X4)
input:      prop_InsertUnion (Zero, Zero) undefined ((Suc undefined, undefined) : undefined)
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
