#!/usr/bin/env python3
"""Merge a 10 s pass and a 60 s pass the way the original runs were made:
all rows of the 10 s pass, then for properties that no prover solved in the
10 s pass, the 60 s rows replace the 10 s rows.

usage: merge_passes.py PASS10.csv PASS60.csv [EXTRA.csv ...] > combined.csv
EXTRA files (e.g. true properties at 10 s) are appended unchanged.
"""
import csv, sys

def load(p):
    rows = list(csv.DictReader(open(p)))
    for r in rows:
        r['benchmark'] = r['benchmark'].split('/')[-1]
    return rows

p10, p60 = load(sys.argv[1]), load(sys.argv[2])
solved10 = {(r['benchmark'], r['property']) for r in p10 if r['witness'] == 'CONFIRMED'}
rows = {}
for r in p10:
    rows[(r['benchmark'], r['property'], r['prover'])] = r
for r in p60:
    if (r['benchmark'], r['property']) not in solved10:
        rows[(r['benchmark'], r['property'], r['prover'])] = r
fields = ['benchmark', 'property', 'prover', 'status', 'seconds', 'witness']
w = csv.DictWriter(sys.stdout, fieldnames=fields, lineterminator='\n')
w.writeheader()
for k in sorted(rows):
    w.writerow({f: rows[k][f] for f in fields})
for extra in sys.argv[3:]:
    for r in load(extra):
        w.writerow({f: r[f] for f in fields})
