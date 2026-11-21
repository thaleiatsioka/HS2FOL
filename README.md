# hs2fol

> **Branch `typed-arity`:** the typed (TFF0) translation of branch `typed`,
> with one change: a function's arity comes from its polymorphic type, not
> from the specialised one (`uncurry` keeps 2 arguments when its result type
> is a function type). See section 9a of SPEC.md and
> `variants-results/COMPARISON.md`.

Translate a well-behaved subset of Haskell into first-order logic (TPTP), so
that theorem provers (E, Vampire, Twee) can search for counterexamples to
QuickCheck-style properties.

For every property `prop_X` (a top-level function whose name starts with
`prop` and whose result is `Bool`/`Property`), hs2fol writes a problem whose
axioms are the defining equations of the program and whose conjecture is

```
fof(prop_X, conjecture, ?[X1,...,Xn]: prop_X(X1,...,Xn) = false).
```

A proof is a counterexample: the answer substitution gives arguments for
which the property evaluates to `False` in Haskell. See [SPEC.md](SPEC.md) for
the full specification and the soundness argument.

## Building

Only GHC and its boot packages (`containers`, `mtl`, `parsec`, `directory`,
`filepath`) are needed:

```sh
make            # builds ./hs2fol and ./witness2input
# or
cabal build
```

## Usage

```sh
./hs2fol examples/Nat.hs                  # writes examples/Nat-fol/<prop>.p
./hs2fol --list examples/Lists.hs         # list properties and their types
./hs2fol --stdout -p prop_revId examples/Lists.hs > revId.p

vampire --question_answering answer_literal revId.p \
  | ./hs2fol --decode -p prop_revId examples/Lists.hs
# prop_revId [Suc _X, Zero]   -- evaluates to False

scripts/prove.sh examples/Lists.hs prop_revId vampire   # all of the above
```

Options: `-o DIR`, `-p/--prop PROP` (repeatable), `--stdout`, `--list`,
`-I DIR` (import path), `--decode`.

## Checking witnesses: witness2input

```sh
vampire revId.p --mode casc --question_answering plain -t 60 > revId.out
./witness2input examples/Lists.hs prop_revId revId.out
# property:   prop_revId
# witness:    prop_revId [Suc _X, Zero]
# input:      prop_revId [Suc undefined, Zero]
# result:     False -- counterexample confirmed
```

witness2input reads the output of Vampire or E (`SZS answers`) or Twee, and
decodes the witness into Haskell arguments. A variable in the witness means
any value works, so it is replaced by `undefined`. It then runs the property
on these arguments with GHC (`runghc`, through QuickCheck if the file imports
it), with a 10 s limit. Exit status: 0 = confirmed (`False`), 1 = not a
counterexample (`True`, or a `==>` precondition is false), 2 = error.

## Benchmarks

The `benchmarks` branch holds the benchmark programs (see
`benchmarks/README.md` there). `scripts/run-benchmarks.sh` runs the provers on
all of them and checks every witness. `scripts/record-solved.sh` commits the
confirmed counterexamples to the `solved` branch. Prover settings and
suggestions are in [PROVERS.md](PROVERS.md).

## Example

```haskell
data Nat = Zero | Suc Nat deriving (Eq, Show)

plus :: Nat -> Nat -> Nat
plus Zero m = m
plus (Suc n) m = Suc (plus n m)

prop_plusIdem :: Nat -> Bool
prop_plusIdem n = plus n n == n
```

becomes (abridged):

```
fof(prop_plusIdem_1, axiom, ![N]: prop_plusIdem(N) = eqNat(plus(N, N), N)).
fof(plus_1, axiom, ![M]: plus(zero, M) = M).
fof(plus_2, axiom, ![N, M]: plus(suc(N), M) = suc(plus(N, M))).
fof(eqNat_1, axiom, eqNat(zero, zero) = true).
fof(eqNat_2, axiom, ![Y1]: eqNat(zero, suc(Y1)) = false).
fof(eqNat_3, axiom, ![X1]: eqNat(suc(X1), zero) = false).
fof(eqNat_4, axiom, ![X1, Y1]: eqNat(suc(X1), suc(Y1)) = eqNat(X1, Y1)).
fof(prop_plusIdem, conjecture, ?[X1]: prop_plusIdem(X1) = false).
```

## What is translated

* pure functions, multiple equations, nested patterns, guards, `where`, `let`,
  `case`, `if`, lambdas, sections, local and mutually recursive definitions;
* algebraic data types (including records and infix constructors), type
  synonyms, lists, tuples, list comprehensions;
* type classes with default methods, instances, `deriving (Eq, Ord)`. Overloading is
  monomorphised (`==` at `[Nat]` becomes `eqListNat`);
* higher-order functions through `app` and closure symbols
  (defunctionalisation);
* function-valued counterexamples through the builders `fn_const`, `fn_id`
  and `fn_case_T`;
* QuickCheck's `===`, `==>` and `Property`;
* `Int` is abstract (uninterpreted literals and operations).

Definitions that are outside the subset (e.g. `Arbitrary` instances and
generators) are skipped with a warning, so ordinary QuickCheck files can be
used as they are.

## Layout

```
src/        the translator (see SPEC.md, section 8, for the module map)
examples/   example programs with true and false properties
scripts/    prove.sh (one property), run-benchmarks.sh, record-solved.sh
SPEC.md     specification
```
