# hs2fol — specification

hs2fol translates a "well-behaved" subset of Haskell into untyped first-order
logic with equality (TPTP `fof`). For every QuickCheck-style property
`prop_X` it writes one TPTP problem. A theorem prover (E, Vampire, Twee)
looking for a proof of that problem is looking for a counterexample.

```
fof(prop_X, conjecture, ?[X1,...,Xn] : prop_X(X1,...,Xn) = false).
```

If the prover proves the conjecture, its answer substitution (`SZS answers`)
is a counterexample, and `hs2fol --decode` prints it as Haskell.

This document refines the original project description. Section 9 lists the
places where the description needed tightening or correcting.

---------------------------------------------------------------------------

## 1. Accepted language

| Feature | Supported |
|---|---|
| Modules | `module M where`, `import M` loads `M.hs` (dots become `/`) from the importing file's directory or `-I` dirs. Import lists, `qualified`, `as` and `hiding` are parsed and ignored. Imports that are not local files (e.g. `Test.QuickCheck`) are ignored. |
| Data types | `data`/`newtype`, parameters, records (selector functions are generated), infix constructors, `deriving (Eq, Ord)`; other derived classes are ignored. |
| Type synonyms | `type T a = ...` (expanded). |
| Functions | Multiple equations, nested patterns, wildcards, as-patterns, guards (incl. `otherwise` and comma-separated boolean guards), `where`, `let`, `case`, `if`, lambdas, operator sections, user-defined operators with fixity declarations, local (recursive) definitions, local pattern bindings. |
| Lists and tuples | `[]`, `[a,b,c]`, `x:xs`, tuples up to 7, list comprehensions (generators, guards, `let`). |
| Overloading | Single-parameter type classes with default methods and superclasses; instances with contexts (`instance Eq a => Eq [a]`); `deriving (Eq, Ord)`. Resolved by monomorphisation. |
| Int | Abstract: literals become constants `int_0`, `int_1`, …; `+ - * negate` and `==`/`compare` on `Int` are uninterpreted symbols with no axioms. |
| Primitives | A type signature without a definition declares an abstract (uninterpreted) function. |
| QuickCheck | `===` (same as `==`), `==>` (`implies`), `Property` (synonym for `Bool`). |
| Not supported | Strings and characters (except `error "..."`, which becomes `undefined`), arithmetic sequences, `do`, literal patterns, irrefutable/bang patterns, multi-parameter or constructor classes, higher-kinded type variables, `seq`, records syntax in expressions, GADTs, pattern guards. |

Top-level definitions that use unsupported or unknown things (e.g. QuickCheck
generators such as `Gen`, `sized`, `Arbitrary` instances) are skipped with a
warning. So are definitions that depend on skipped ones. This lets a normal
QuickCheck test file be translated without editing it.

User definitions shadow Prelude definitions with the same name. The Prelude
keeps its own copy, so Prelude functions keep their meaning.

The input is assumed to be accepted by GHC. hs2fol does its own
Hindley–Milner type inference, because it needs types to resolve
overloading. It is not a full type checker; for example, it does not check
class constraints.

## 2. Pipeline

1. **Lex + layout.** Haskell 2010 layout algorithm. The `parse-error(t)` rule
   is approximated: implicit blocks are closed by `in`, by closing brackets and
   commas inside brackets, by `then`/`else` (of an enclosing `if`) and by `of`.
2. **Parse** into a surface AST. Operator expressions are kept flat and are
   resolved with the fixity table once all modules are loaded.
3. **Desugar** into a small core language: variables, constructors, literals,
   application, λ, `letrec`, flat `case` (one constructor per alternative, no
   nested patterns) and `Fail` (no match).
   * Patterns are compiled with the classic match algorithm (Wadler, ch. 5 of
     *The Implementation of Functional Programming Languages*). A default
     (variable/wildcard) row is expanded into one alternative for every
     remaining constructor. Incomplete matches produce `Fail`.
   * Guards become `case g of True -> e; False -> <fall through>`, and the
     fall-through is the match of the remaining equations, exactly as in
     Haskell.
   * Derived `Eq`/`Ord` instances are generated as ordinary instance
     declarations: one equation for every pair of constructors.
4. **Type inference** (Hindley–Milner, binding groups by SCC, explicit
   signatures trusted). Every occurrence of a global identifier is annotated
   with its type at that occurrence.
5. **Monomorphisation of overloading.** A top-level function is *overloaded*
   if one of its quantified type variables decides which instance a class
   method inside it resolves to (computed as a fixpoint). Every use of a class
   method, or of an overloaded function, is replaced by a specialised copy:
   * method `m` at type `T t1..tn` → the instance's method body, named
     `m` + `T` + types of the relevant instance parameters, e.g. `==` at
     `Nat` → `eqNat`, at `[Nat]` → `eqListNat`, at `(Nat,Bool)` →
     `eqPairNatBool`;
   * overloaded function `f` at the relevant types → `f` + types, e.g.
     `elem` at `Nat` → `elemNat`, `sort` at `[Bool]` → `sortListBool`;
   * a method that an instance neither defines nor inherits from a default
     becomes an abstract symbol (e.g. `eqInt`).
   Properties must be monomorphic in their class-constrained type variables.
   Unconstrained type variables are fine, because the logic is untyped.
6. **Lambda lifting / closure conversion.**
   * Local functions and recursive local values become top-level functions;
     their free variables become extra leading parameters. They are named
     `parent_local`.
   * Non-recursive local values are inlined (substituted) if they are cheap
     (only applications of variables/constructors/literals) or used at most
     once; otherwise they are lifted like local functions.
   * Lambdas: if a lambda is an η-expanded partial application
     (`\x -> f a x`), it is replaced by that partial application. Otherwise it
     becomes a function `lamN` whose parameters are its free variables followed
     by its arguments.
   * Top-level functions are η-expanded to the arity of their type, so
     `f = map g` gives `f(Xs) = map(g_0, Xs)` instead of a constant.
7. **Flattening into equations.** The body of every function (parameters
   `X1..Xn`) is turned into unit equations:
   * `case x of ...` where `x` is (part of) a parameter: the clause is split,
     with `x` replaced by `C(Y1..Yk)` in the left-hand side. One clause per
     constructor. A missing alternative gives no clause.
   * `case` on anything else, or a `case` nested inside an argument: an
     auxiliary function `f_caseN(s, free vars)` is created that pattern
     matches on its first argument. `if` and guards are `case` on `Bool`,
     so they become `f_caseN(cond, ...)` with a `true` and a `false` clause.
   * `case` of a known constructor is reduced statically.
   * `Fail` gives no clause.
   The result: the left-hand sides of any one function never overlap, so for
   any ground term at most one equation in the whole file applies at the root.
8. **Higher-order encoding (defunctionalisation).**
   * Application of an unknown function: `app(F, X)`; `f a b` with `f` a
     variable is `app(app(F, A), B)`.
   * Over-saturated calls: `f(args...)` for the first `arity` arguments, then
     `app`.
   * Partial application of a function/constructor `f` of arity `n` to `k < n`
     arguments: closure symbol `f_k(A1..Ak)`, with rules
     `app(f_k(X1..Xk), Y) = f_{k+1}(X1..Xk, Y)` and finally
     `app(f_{n-1}(X1..X_{n-1}), Y) = f(X1..X_{n-1}, Y)`.
     Only the closure levels that are actually used (and the ones above them)
     are generated.
   * A lambda `lamN` with free variables `V1..Vm`: closure `lamN(V1..Vm)`, and
     `app(lamN(V1..Vm), X) = <body>`. If the body is one equation with only
     variables on the left, it is inlined into the `app` rule and no separate
     `lamN_body` function is emitted. This matches the example
     `app(lam1(Ys), Xs) = opAppend(Xs, Ys)`.
9. **Function-valued counterexamples.** If a property has an argument of
   function type, these "builders" are added:
   ```
   app(fn_const(Y), X) = Y.
   app(fn_id, X)       = X.
   app(fn_case_T(R1..Rk), Ci(Z1..Zm)) = app(..app(Ri, Z1).., Zm).   (one per constructor)
   ```
   `fn_case_T` is generated for every data type `T` in the domain of a
   function-typed argument, and for the types of their fields (transitively).
   The prover can then answer with terms like `fn_case_Nat(true, fn_const(false))`,
   which `--decode` prints as `\x -> case x of { Zero -> True; Suc y -> (\_ -> False) y }`.
   Builders cannot express recursion, so a counterexample that needs a
   recursive function argument cannot be found.
10. **Slicing.** Each problem contains only the equations of symbols that
    can be reached from the property (and from the builders).
11. **Naming.** All FOL names are chosen globally, in priority order:
    builders and `app`; constructors; user top-level functions; Prelude,
    specialised and abstract functions; literals; generated symbols.
    A clash is resolved by appending `_1`, `_2`, … to the later name.
    * functions keep their Haskell name (`'` → `_`): `map`, `prop_rev`;
    * constructors start in lowercase (`Suc` → `suc`, `True` → `true`); all-caps
      names are lowercased fully (`LT` → `lt`); built-ins: `nil`, `cons`,
      `unit`, `pair`, `tuple3`…;
    * operators: `++` `opAppend`, `.` `opCompose`, `$` `opApply`, `&&` `opAnd`,
      `||` `opOr`, `==` `eq`, `/=` `neq`, `<` `lt`, `<=` `le`, `>` `gt`, `>=` `ge`,
      `+` `opPlus`, `-` `opMinus`, `*` `opTimes`, `!!` `opIndex`, `==>` `implies`;
      any other operator becomes `op` + character names (`<+>` → `opLtPlusGt`);
    * generated: `f_caseN` (lifted case), `f_go` (lifted local), `lamN`
      (lambda closure), `f_k` (closure of `f` with `k` arguments), `int_N`
      (literal);
    * variables: the Haskell variable name, capitalised (`xs` → `Xs`); the
      conjecture uses `X1..Xn`.

## 3. Output format

One file `<prop>.p` per property:

```
% hs2fol: property prop_revrev :: [Nat] -> Bool
% reverse
fof(reverse_1, axiom, reverse(nil) = nil).
fof(reverse_2, axiom, ![X, Xs]: reverse(cons(X, Xs)) = opAppend(reverse(Xs), cons(X, nil))).
...
fof(prop_revrev, conjecture, ?[X1]: prop_revrev(X1) = false).
```

Everything is a unit equation, so every problem is Horn (in fact pure
unit-equality, i.e. UEQ), which is what Twee needs.

## 4. Decoding answers

`hs2fol --decode -p PROP FILE.hs < prover-output` translates the program again
(so all names are the same), finds the `SZS answers Tuple [[t1,...,tn]|_]` line
(as written by Vampire and E) and prints `PROP t1' ... tn'` in Haskell syntax.
If there is no such line, the input is read as comma-separated TPTP terms, so
answers from provers without answer extraction (Twee) can be pasted in by
hand. Lists are printed as `[a, b]`; closures as partial applications or as
the original lambda; builders as lambdas; prover variables `X` as `_X`. A
variable means that any value works there (`undefined` is one choice).

## 5. Why counterexamples are sound

Read the generated axioms in the standard denotational model of the Haskell
program: an untyped domain of values, including ⊥, partial and infinite
values and functions. Interpret each function symbol as the corresponding
Haskell function. Interpret a closure `f_k(a..)` and `lamN(v..)` as the
function value it denotes. Interpret `app` as application. Ill-typed
combinations are interpreted as ⊥. Then every generated equation is **true**
in this model:

* An equation `f(p1..pn) = rhs` with constructor patterns is the defining
  equation of `f` for arguments of that shape. Variables in patterns range over
  all values, including ⊥ and partial values, and that is still true because
  matching on a constructor is lazy in its fields.
* Clauses never overlap, so Haskell's "first matching equation wins" rule is
  respected. (Overlapping equations such as `f [] = A; f _ = B` would be
  *false* in the model for `f []`, which is why defaults are expanded.)
* Inlining `let`s, β-reduction, η-reduction of lambdas, η-expansion of
  top-level functions, case-of-known-constructor and lambda lifting all
  preserve the denotation in a language without `seq`.
* Specialised instance code is the code that dictionary passing would run.

So anything the prover derives, in particular `prop(t1..tn) = false`, holds in
the model: `prop t1 .. tn` evaluates to `False` in Haskell, so it is a real
counterexample. No datatype axioms (distinctness, injectivity, domain
closure) are needed or wanted. They would be true only for the term model,
not for the Haskell model with ⊥ and junk values, and in any case derivations
of `= false` don't use them. Proving that a property *holds* would need
induction and is out of scope.

The answer terms need not be constructor terms (e.g. `reverse(nil)`). That is
fine: they are Haskell expressions. Variables in answers can be instantiated
with anything.

Caveats: soundness assumes the input is a well-typed Haskell program that
GHC accepts, with the meaning of the hs2fol Prelude. `Int` is abstract, so no
counterexample can depend on arithmetic facts.

**Ill-typed witnesses.** The argument above shows that `prop(t1..tn)` is
`False` in the untyped model. It does not show that the `ti` are well-typed.
The logic has no types, so a prover may answer with, for example, `True`
where a `Nat` is expected. That is fine in the model but is not a Haskell
input. This happens in practice: in the BST benchmarks, 4 of 158 witnesses
were ill-typed, both for higher-order properties (built functions applied to
values of the wrong type) and for first-order ones (a tree in an unused
`Nat` position). witness2input reports these separately (`ILL_TYPED`). The
principled fix is a typed encoding (TPTP TFF, with polymorphic functions
monomorphised per use), so that the provers themselves respect the types.

**Evaluating witnesses.** A witness may mention auxiliary functions that
hs2fol generated (e.g. `insertBad_case1(...)`), which have no Haskell name.
witness2input first rewrites each witness term with the generated equations.
They do not overlap, so this is deterministic, and it does not change the
denoted value. The normal form is usually a constructor term.

## 6. Command line

```
hs2fol [options] FILE.hs
  -o DIR          output directory (default: FILE-fol/)
  -p, --prop P    only property P (repeatable)
  --stdout        write problems to standard output instead of files
  --list          list the properties and their types
  -I DIR          extra directory for imports
  --decode        read prover output on stdin and print the counterexample
                  (use together with -p PROP)
```

## 7. Prelude

Built in (see `src/PreludeSrc.hs`): `Bool`, `Ordering`, `Maybe`, `Either`,
lists, tuples, unit; classes `Eq` (`==`, `/=`) and `Ord` (`compare`, `<`, `<=`,
`>`, `>=`, `max`, `min`) with instances for all of these; `not && || otherwise
==> id const flip . $ fst snd curry uncurry maybe either fromMaybe head tail
null ++ map filter foldr foldl concat concatMap reverse length sum and or any
all elem notElem lookup zip zipWith unzip last init takeWhile dropWhile
insert sort delete nub maximum minimum undefined`, and abstract `Int`
operations.

## 8. Implementation map

| Module | Role |
|---|---|
| `Lexer` | tokens, comments, layout algorithm |
| `Parser` | Parsec parser over tokens → surface AST |
| `Syntax` | surface AST, core language, types, fixity resolution |
| `Desugar` | program assembly, deriving, scoping, match compiler, core |
| `TypeCheck` | HM inference, occurrence annotations, overloading relevance |
| `Specialise` | monomorphisation of class methods and overloaded functions |
| `Lift` | simplifier, η-expansion, lambda lifting, flattening into equations, closures |
| `FOL` | terms, equations, slicing, TPTP printing |
| `Translate` | pipeline, properties, builders, naming, problem rendering |
| `Decode` | parse prover answers, print Haskell |
| `Names` | FOL naming conventions |
| `Main` | command line, module loading |

## 9. Issues found in the original description, and how they are resolved

1. **Monomorphised names must include element types.** `eqList` cannot serve
   both `[Nat]` and `[Bool]`, since its body calls the element equality. Names
   therefore include the relevant type arguments: `eqListNat`. (Without
   overloading, dictionary passing via `app` would be the alternative, but the
   description asks for monomorphisation.) The examples also have small typos:
   `Suc n == Suc m` translates to `eqNat(suc(N), suc(M))`, and `(x:xs) == (y:ys)`
   to `eqListNat(cons(X, Xs), cons(Y, Ys))`.
2. **Guards fall through.** A failing guard in Haskell continues with the next
   equation. "One clause per input case" alone cannot express this. The
   fall-through is compiled into the decision tree, and the guard test becomes
   an auxiliary function on `Bool`, so clauses still never overlap.
3. **"Datatypes get no axioms" vs. `deriving Eq`.** Derived `Eq`/`Ord` produce
   *function* definitions (`eqNat`, `compareNat`), one equation per
   constructor pair (k² equations for k constructors). This does not
   contradict the rule; it is still only function definitions.
4. **`==>` semantics.** QuickCheck *discards* tests whose precondition is false.
   For counterexample search `implies(false, B) = true; implies(true, B) = B`
   is right: `= false` requires the precondition to be `true`.
5. **Polymorphic properties.** QuickCheck itself needs a monomorphic type.
   hs2fol requires this only for class-constrained type variables, since the
   logic is untyped. An overloaded property is skipped with a message asking
   for a signature.
6. **Partial application of constructors** (`map Suc xs`) needs closures as
   well (`suc_0`). The same mechanism as for functions is used.
7. **Twee.** Twee accepts the output (pure unit equalities). Two things remain
   to check against your Twee version. First, that it handles an existentially
   quantified goal. Second, that it reports the instantiation, since Twee has
   no SZS answer output (paste the term into `--decode` instead).
8. **Function builders are incomplete by design.** Only non-recursive,
   finitely-branching functions can be built. Add more builders (e.g. a fold) if
   needed.
9. **Size.** Expanding defaults can multiply clauses (a wildcard row against a
   type with many constructors). This is inherent in the non-overlap
   requirement.
10. **Int.** Literals are constants without distinctness axioms, and
    arithmetic is uninterpreted, so `eqInt(int_0, int_1)` is not reducible.
    Counterexamples that need arithmetic will not be found, which is consistent
    with "keep Int abstract".
