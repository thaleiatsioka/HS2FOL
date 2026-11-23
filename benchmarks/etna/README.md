# Etna benchmarks: red-black trees (RBT) and simply-typed lambda calculus (STLC)

From Etna, the property-based testing evaluation platform of Shi, Keleş,
Goldstein, Pierce and Lampropoulos, "Etna: An Evaluation Platform for
Property-Based Testing", ICFP 2023. Upstream: https://github.com/jwshii/etna,
commit `f22b56be223b88a277f2823fb4c69867ccc53199`, workloads
`workloads/Haskell/RBT` and `workloads/Haskell/STLC`.

The Etna repository has no licence file, so its sources are not copied here:
`./fetch-upstream.sh` downloads them at that commit into `upstream/`. The files
here are ports of Etna's `Impl.hs` and `Spec.hs` to the Haskell subset hs2fol
accepts, written for this evaluation.

## Files

| | |
|---|---|
| `template/RBT.template.hs`, `template/STLC.template.hs` | the ports, with Etna's mutants in Etna's marker syntax |
| `generate.py` | writes `RBT/RBT_<variant>.hs` and `STLC/STLC_<variant>.hs`: `base` is the correct code, every other variant is one mutant |
| `Nat.hs`, `Z.hs` | Peano naturals and integers built from them (copied into `RBT/` and `STLC/` by `generate.py`) |
| `qc-truth.sh`, `qc-truth.txt` | QuickCheck ground truth for every (variant, property) pair |
| `fetch-upstream.sh` | fetches the original Etna sources |

Every generated file is a complete module containing the implementation, the
properties and Etna's QuickCheck generators (which hs2fol skips), and
compiles with GHC 9.4.

## Changes from Etna

None of these changes affect when a property fails.

* **Int.** hs2fol keeps `Int` abstract, so a prover could not evaluate any
  arithmetic or comparison on it.
  * RBT keys are `Key Nat` instead of `Key Int`. Keys are only compared, so
    every counterexample over `Int` has an order-isomorphic one over `Nat`.
  * RBT black heights are `Nat`.
  * STLC de Bruijn indices are integers built from naturals (`Z.hs`: `Pos n`
    is n, `Neg n` is −(n+1)), because `substTop` shifts by −1.
  * `n + d` becomes `zadd n d`; the literals `0`, `1` and `-1` become `zero`,
    `one` and `minusOne`.
  * `length` and `!!` become `lengthN` and `nth`, on `Nat`.
  * The fuel of `multistep` is a `Nat`; the literal `40` is written out.
* **Monads.** hs2fol has no constructor classes, so there is no `Monad` or
  `Functor`.
  * `do`, `<$>`, `=<<` and `return` in the `Either Error` monad (RBT) become
    `bindE`, `fmapE` and `Right`.
  * In the `Maybe` monad (STLC) they become `case`, `fmapM` and `Just`.
  * STLC's failing pattern bind `TFun t11 t12 <- getTyp ctx e1` becomes a
    `case` with a `Nothing` branch.
* **Properties.**
  * They take curried arguments instead of one tuple.
  * Etna's `pre --> post` (discard the test when `pre` is false) is written
    `pre ==> post`, which means the same in QuickCheck and is implication in
    hs2fol.
  * RBT properties keep Etna's form `isRBT t ==> ...` over arbitrary trees.
    (The Hughes BST port instead builds trees from key/value lists.) So a
    prover must construct a tree that satisfies the red-black invariant,
    including black heights.
* **Library functions.** `fromRight`, `isJust`, `fromJust` and `Data.List.insert`
  (`insertL`) are defined in the file.
* **Mutant `no_balance_insert_2`.** In Etna it puts `insert x vx b`, of type
  `Either Error (Tree k v)`, into a tree field, which does not type-check.
  Here it calls `ins x vx b`, matching the mutant's name (no rebalancing on the
  right).
* **Left out:** `sizeRBT` and `sizeSTLC` (used only for Etna's statistics) and
  `isNF` (not used by a property).

## Variants and properties

* **RBT:** 15 mutants × 10 properties.
  * Mutants: `miscolor_insert`, `insert_1`, `insert_2`, `insert_3`,
    `no_balance_insert_1`, `no_balance_insert_2`, `miscolor_delete`,
    `delete_4`, `delete_5`, `miscolor_balLeft`, `miscolor_balRight`,
    `miscolor_join_1`, `miscolor_join_2`, `swap_cd`, `swap_bc`.
  * Properties: `InsertValid`, `DeleteValid`, `InsertPost`, `DeletePost`,
    `InsertModel`, `DeleteModel`, `InsertInsert`, `InsertDelete`,
    `DeleteInsert`, `DeleteDelete`.
* **STLC:** 10 mutants × 2 properties.
  * Mutants: `shift_var_none`, `shift_var_all`, `shift_var_leq`,
    `shift_abs_no_incr`, `subst_var_all`, `subst_var_none`,
    `subst_abs_no_shift`, `subst_abs_no_incr`, `substTop_no_shift`,
    `substTop_no_shift_back`.
  * Properties: `SinglePreserve`, `MultiPreserve`.

## Ground truth

`qc-truth.sh` runs every property of every variant for 100,000 QuickCheck
tests with Etna's generators. RBT trees are built by inserting random keys
with the correct `insert`; STLC terms are generated well-typed.

* **The correct code passes every property.**
* **RBT:** 59 of the 150 mutant/property pairs fail. Etna's task list
  (`tool/benchtool/Tasks.py`, which pairs each mutant with the properties it
  should break) has 58 RBT tasks, and all 58 are among the 59. The extra pair
  is `delete_5` with `prop_InsertDelete`: QuickCheck finds a real
  counterexample, and Etna's list just doesn't include it.
* **STLC:** all 20 mutant/property pairs fail. Etna has no STLC task list.

So 79 pairs have a counterexample to find, and 103 do not.
