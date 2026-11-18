# prop_UnionUnionAssoc (hughes-bst/BSTSpec6)

| prover | SZS status | seconds | witness |
|---|---|---|---|
| eprover | ResourceOut | 10.05 | - |
| twee | Timeout | 15.02 | - |
| vampire | Theorem | 3.71 | CONFIRMED |

Counterexample (decoded from the vampire witness, checked with GHC):

```
property:   prop_UnionUnionAssoc
file:       /home/claude/hs2fol/benchmarks/hughes-bst/BSTSpec6.hs
prover:     vampire
witness:    prop_UnionUnionAssoc [(Zero, Zero)] [(_X0, _X1)] [(fst _X2, snd _X2)]
input:      prop_UnionUnionAssoc [(Zero, Zero)] [(undefined, undefined)] [(fst undefined, snd undefined)]
            (variables in the witness can be any value; undefined is used)
result:     False -- counterexample confirmed
```
