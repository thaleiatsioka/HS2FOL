# prop_InsertDelete (hughes-bst/BSTSpec2)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | ResourceOut | 10.07 | - |
| twee | Timeout | 15.02 | - |
| vampire | Theorem | 3.13 | CONFIRMED |

Counterexample (decoded from the vampire witness, checked with GHC):

```
property:   prop_InsertDelete
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec2.hs
prover:     vampire
witness:    prop_InsertDelete (Zero, Suc _X0) Zero [(Zero, Zero)]
input:      prop_InsertDelete (Zero, Suc undefined) Zero [(Zero, Zero)]
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
