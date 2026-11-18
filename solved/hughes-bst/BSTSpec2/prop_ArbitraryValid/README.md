# prop_ArbitraryValid (hughes-bst/BSTSpec2)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | Theorem | 0.03 | CONFIRMED |
| twee | Theorem | 0.14 | CONFIRMED |
| vampire | Theorem | 1.89 | CONFIRMED |

Counterexample (decoded from the eprover witness, checked with GHC):

```
property:   prop_ArbitraryValid
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec2.hs
prover:     eprover
witness:    prop_ArbitraryValid (toList (Branch Leaf Zero _X1 (Branch Leaf Zero _X2 Leaf)))
evaluated:  prop_ArbitraryValid [(Zero, _X1), (Zero, _X2)]
input:      prop_ArbitraryValid [(Zero, undefined), (Zero, undefined)]
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
