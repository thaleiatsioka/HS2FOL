#!/usr/bin/env python3
"""Compare prover results of several hs2fol encodings on the BST benchmarks.

usage: compare_variants.py QC-TRUTH.txt NAME=SUMMARY.csv [NAME=SUMMARY.csv ...] > COMPARISON.md

Only the false properties (QuickCheck) count as solvable. Benchmark names are
normalised to BSTSpecN. A property is solved if some prover's witness was
confirmed by running the property in GHC.
"""
import csv, sys

truth = {}
for l in open(sys.argv[1]):
    b, p, v = l.split()
    truth[(b, p)] = v
false = sorted(k for k, v in truth.items() if v == 'FAIL')
true_ = {k for k, v in truth.items() if v == 'PASS'}

variants = []
for arg in sys.argv[2:]:
    name, path = arg.split('=', 1)
    rows = list(csv.DictReader(open(path)))
    for r in rows:
        r['benchmark'] = r['benchmark'].split('/')[-1]
    variants.append((name, rows))
names = [n for n, _ in variants]
provers = ['vampire', 'eprover', 'twee']


def solved(rows, prover=None, keys=None):
    return {(r['benchmark'], r['property']) for r in rows
            if r['witness'] == 'CONFIRMED' and (prover is None or r['prover'] == prover)
            and (keys is None or (r['benchmark'], r['property']) in keys)}


def ran(rows, prover):
    return any(r['prover'] == prover for r in rows)


def count(rows, verdict, keys):
    return sum(1 for r in rows if r['witness'] == verdict and (r['benchmark'], r['property']) in keys)


fset = set(false)
out = []
w = out.append
w("# hs2fol encodings compared on the BST benchmarks\n")
w("Only the 94 properties that QuickCheck (10,000 tests) finds false can have a counterexample. "
  "A property counts as solved when a prover's witness, decoded to Haskell, makes the property return False in GHC. "
  "Every prover ran with a 60 s limit on each false property. Vampire 5.1.1, E 3.5.10, Twee 2.6.2, with the command lines in PROVERS.md.\n")
w("| | " + " | ".join(names) + " |")
w("|---|" + "---|" * len(names))
w("| false properties solved (any prover), of 94 | " + " | ".join(str(len(solved(r, keys=fset))) for _, r in variants) + " |")
for p in provers:
    w(f"| solved by {p} | " + " | ".join(str(len(solved(r, p, fset))) if ran(r, p) else "n/a" for _, r in variants) + " |")
for label, verdict in [("confirmed witnesses (prover runs)", 'CONFIRMED'), ("ill-typed witnesses", 'ILL_TYPED'),
                       ("witnesses refuted by GHC", 'NOT_A_COUNTEREXAMPLE'), ("witnesses that could not be checked", 'CHECK_ERROR')]:
    w(f"| {label} | " + " | ".join(str(count(r, verdict, fset)) for _, r in variants) + " |")
cells = []
for _, r in variants:
    tested = {(x['benchmark'], x['property']) for x in r} & true_
    cells.append(f"{len(solved(r, keys=true_))} of {len(tested)} tested" if tested else "not run")
w("| claimed counterexamples for properties QuickCheck passes | " + " | ".join(cells) + " |\n")

w("## Per version: false properties solved (any prover)\n")
w("| version | false | " + " | ".join(names) + " |")
w("|---|---|" + "---|" * len(names))
for i in range(9):
    b = f"BSTSpec{i}"
    f = {k for k in false if k[0] == b}
    w(f"| {b} | {len(f)} | " + " | ".join(str(len(solved(r, keys=f))) for _, r in variants) + " |")
w("")

w("## Properties solved by some encodings but not all\n")
w("✓ = solved; the provers that found a confirmed witness are listed, with the time of the fastest.\n")
w("| property | " + " | ".join(names) + " |")
w("|---|" + "---|" * len(names))
for k in false:
    per = []
    for _, r in variants:
        hits = sorted((float(x['seconds']), x['prover']) for x in r
                      if (x['benchmark'], x['property']) == k and x['witness'] == 'CONFIRMED')
        per.append(hits)
    if all(per) or not any(per):
        continue
    w(f"| {k[0]} {k[1]} | " + " | ".join(
        ("✓ " + ", ".join(sorted({p for _, p in h})) + f" ({h[0][0]:.1f} s)") if h else "–" for h in per) + " |")
none = [k for k in false if not any(solved(r, keys={k}) for _, r in variants)]
w(f"\nUnsolved by every encoding ({len(none)}): " + ", ".join(f"{b} {p}" for b, p in none) + "\n")

w("## Vampire alone\n")
w("Every encoding can be compared on Vampire alone, since Vampire is the only prover that reads TF1.\n")
w("| | " + " | ".join(names) + " |")
w("|---|" + "---|" * len(names))
w("| false properties solved by Vampire | " + " | ".join(str(len(solved(r, 'vampire', fset))) for _, r in variants) + " |")
common = set(fset)
for _, r in variants:
    common &= solved(r, 'vampire', fset)
def vt(rows):
    return sum(float(x['seconds']) for x in rows if x['prover'] == 'vampire' and x['witness'] == 'CONFIRMED'
               and (x['benchmark'], x['property']) in common)
w(f"| total time on the {len(common)} properties all of them solve | " + " | ".join(f"{vt(r):.1f} s" for _, r in variants) + " |\n")

print("\n".join(out))
