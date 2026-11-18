# prop_InsertDeleteWeak (hughes-bst/BSTSpec4)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | Theorem | 0.02 | CONFIRMED |
| twee | Theorem | 0.09 | CONFIRMED |
| vampire | Theorem | 0.23 | CONFIRMED |

Counterexample (decoded from the eprover witness, checked with GHC):

```
property:   prop_InsertDeleteWeak
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec4.hs
prover:     eprover
witness:    prop_InsertDeleteWeak (Zero, _X1) (Suc _X2) []
input:      prop_InsertDeleteWeak (Zero, undefined) (Suc undefined) []
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
