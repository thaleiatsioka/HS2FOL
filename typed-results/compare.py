#!/usr/bin/env python3
"""Compare untyped (FOF) and typed (TFF) prover results on the BST benchmarks.

usage: compare.py UNTYPED.csv TYPED.csv QC-TRUTH.txt > COMPARISON.md
Benchmark names are normalised to BSTSpecN.
"""
import csv, sys

def load(path):
    rows = list(csv.DictReader(open(path)))
    for r in rows:
        r['benchmark'] = r['benchmark'].split('/')[-1]
    return rows

untyped, typed = load(sys.argv[1]), load(sys.argv[2])
truth = {}
for l in open(sys.argv[3]):
    b, p, v = l.split()
    truth[(b, p)] = v
false = {k for k, v in truth.items() if v == 'FAIL'}
provers = ['vampire', 'eprover', 'twee']

def solved(rows, prover=None):
    return {(r['benchmark'], r['property']) for r in rows
            if r['witness'] == 'CONFIRMED' and (prover is None or r['prover'] == prover)}

def count(rows, verdict):
    return sum(1 for r in rows if r['witness'] == verdict)

def times(rows):
    return {(r['benchmark'], r['property'], r['prover']): float(r['seconds'])
            for r in rows if r['witness'] == 'CONFIRMED'}

su, st = solved(untyped), solved(typed)
out = []
w = out.append
w("# Untyped (FOF) vs. typed (TFF) translation on the BST benchmarks\n")
w("Same protocol for both: all 360 properties at 10 s per prover, then the false properties (QuickCheck, 10,000 tests) that were still unsolved at 60 s. Vampire 5.1.1, E 3.5.10, Twee 2.6.2 with the command lines in PROVERS.md.\n")
w("| | untyped (FOF) | typed (TFF) |")
w("|---|---|---|")
w(f"| false properties solved (any prover), of {len(false)} | {len(su)} | {len(st)} |")
for p in provers:
    w(f"| solved by {p} | {len(solved(untyped, p))} | {len(solved(typed, p))} |")
w(f"| confirmed witnesses (prover runs) | {count(untyped, 'CONFIRMED')} | {count(typed, 'CONFIRMED')} |")
w(f"| ill-typed witnesses | {count(untyped, 'ILL_TYPED')} | {count(typed, 'ILL_TYPED')} |")
w(f"| witnesses refuted by GHC | {count(untyped, 'NOT_A_COUNTEREXAMPLE')} | {count(typed, 'NOT_A_COUNTEREXAMPLE')} |")
w(f"| witnesses that could not be checked | {count(untyped, 'CHECK_ERROR')} | {count(typed, 'CHECK_ERROR')} |")
w(f"| claims of a counterexample for a property QuickCheck passes | {len(su - false)} | {len(st - false)} |\n")

w("## Per version: false properties solved\n")
w("| version | false | untyped | typed | only untyped | only typed |")
w("|---|---|---|---|---|---|")
for i in range(9):
    b = f"BSTSpec{i}"
    f = {k for k in false if k[0] == b}
    u = {k for k in su if k[0] == b}
    t = {k for k in st if k[0] == b}
    ou = ", ".join(sorted(p for _, p in u - t)) or "-"
    ot = ", ".join(sorted(p for _, p in t - u)) or "-"
    w(f"| {b} | {len(f)} | {len(u)} | {len(t)} | {ou} | {ot} |")

w("\n## Per prover: solved only in one encoding\n")
for p in provers:
    a, b = solved(untyped, p), solved(typed, p)
    w(f"* **{p}**: only untyped: {len(a - b)}" + (f" ({', '.join(f'{x} {y}' for x, y in sorted(a - b))})" if a - b else "")
      + f"; only typed: {len(b - a)}" + (f" ({', '.join(f'{x} {y}' for x, y in sorted(b - a))})" if b - a else ""))

tu, tt = times(untyped), times(typed)
common = sorted(set(tu) & set(tt))
if common:
    faster = sum(1 for k in common if tt[k] < tu[k] - 0.5)
    slower = sum(1 for k in common if tt[k] > tu[k] + 0.5)
    w(f"\n## Time\n\nOf the {len(common)} (property, prover) pairs solved in both encodings, the typed run was more than 0.5 s faster on {faster} and more than 0.5 s slower on {slower}; total time {sum(tu[k] for k in common):.1f} s untyped vs. {sum(tt[k] for k in common):.1f} s typed.")

w("\n## Unsolved in both\n")
both = sorted(false - su - st)
w(", ".join(f"{b} {p}" for b, p in both) if both else "none")
print("\n".join(out))
