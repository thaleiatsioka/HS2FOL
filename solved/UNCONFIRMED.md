# Unconfirmed witnesses

Witnesses a prover produced that witness2input did not confirm. Each of
these indicates a problem (in hs2fol, the decoder, or the check) and
should be investigated.

| benchmark | property | prover | status | check |
|---|---|---|---|---|
| hughes-bst/BSTSpec2 | prop_FindPostAbsent | vampire | Theorem | ILL_TYPED |
| hughes-bst/BSTSpec4 | prop_DeleteModel | vampire | Theorem | ILL_TYPED |
| hughes-bst/BSTSpec5 | prop_DeletePost | vampire | Theorem | ILL_TYPED |
| hughes-bst/BSTSpec5 | prop_FindDelete | vampire | Theorem | ILL_TYPED |
