# Hughes BST properties that QuickCheck falsifies

The 94 properties from `benchmarks/hughes-bst` (40 properties × 8 buggy
versions) that QuickCheck falsifies with 10,000 tests. Each is a
self-contained file in `properties/`:

```
properties/BST<bug>_<property>.hs
```

Each file contains the property, the helpers it uses (the paper's tree
generator, `=~=`, `<|>`, the list model) and a `main` that runs QuickCheck.
A header comment gives the bug, QuickCheck's (shrunk) counterexample, and
whether hs2fol plus a theorem prover found a counterexample (and which prover,
how fast). `Nat.hs` and `BST1.hs` … `BST8.hs` are next to them, so every
file works on its own:

```sh
cd properties
runghc BST8_prop_InsertUnion.hs          # QuickCheck: Falsified
hs2fol BST8_prop_InsertUnion.hs          # one TPTP problem
```

Checked: all 94 compile with GHC 9.4 and QuickCheck falsifies each of them;
hs2fol finds exactly the one property in each file.

`INDEX.md` lists all 94 with their prover results: 75 solved, 19 not solved by
any prover (10 s pass, then 60 s). The correct implementation (`BST.hs`) has no
false properties, so it does not appear here.

## Regenerating

`generate.py` builds `properties/` and `INDEX.md` from
`../../benchmarks/hughes-bst/template/BSTSpec.template.hs`, `qc-truth.txt`
(QuickCheck verdict for all 360 properties), `qc-counterexamples/` (QuickCheck
output for the 94) and `summary.csv` (prover results, as recorded on the
`solved` branch).
