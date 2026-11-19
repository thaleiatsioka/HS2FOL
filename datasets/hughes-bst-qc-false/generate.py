#!/usr/bin/env python3
"""Generate one self-contained Haskell file per BST property that QuickCheck
falsifies (94 of the 360 in benchmarks/hughes-bst).

Inputs (paths relative to the repository root):
  benchmarks/hughes-bst/template/BSTSpec.template.hs   the properties
  qc-truth.txt         "BSTSpecN prop_X PASS|FAIL" (10,000 QuickCheck tests)
  qc-counterexamples/  QuickCheck output per version ("@@ prop" + output)
  summary.csv          prover results (from scripts/run-benchmarks.sh)
"""
import csv, os, re, shutil, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
BENCH = os.path.join(ROOT, "benchmarks", "hughes-bst")

BUGS = {
    1: "insert discards the existing tree",
    2: "insert duplicates an existing key instead of updating it",
    3: "insert does not update the value of an existing key",
    4: "delete does not rebuild the tree above the deleted key",
    5: "key comparisons reversed in delete",
    6: "union assumes all keys of the first tree precede those of the second",
    7: "union assumes that if the root of t is smaller than the root of t', all of t is",
    8: "union does not always give the left argument priority",
}

def blocks(lines):
    out, cur = [], []
    for l in lines:
        if l.strip() == "":
            if cur: out.append(cur); cur = []
        else:
            cur.append(l)
    if cur: out.append(cur)
    return out

def main():
    src = open(os.path.join(BENCH, "template", "BSTSpec.template.hs")).read().splitlines()
    body = src[[i for i, l in enumerate(src) if l.startswith("import @IMPL@")][0] + 1:]
    props, common = {}, []
    for b in blocks(body):
        names = [re.match(r"(prop_\w+)", l).group(1) for l in b if re.match(r"prop_\w+", l)]
        if names:
            props[names[0]] = b
        elif not all(l.lstrip().startswith("--") for l in b):
            common.append(b)

    truth = [l.split() for l in open(os.path.join(HERE, "qc-truth.txt")) if l.strip()]
    false = [(int(b[len("BSTSpec"):]), p) for b, p, v in truth if v == "FAIL"]

    cex = {}
    for i in range(1, 9):
        cur = None
        for l in open(os.path.join(HERE, "qc-counterexamples", f"BSTSpec{i}.txt")):
            if l.startswith("@@ "):
                cur = (i, l[3:].strip()); cex[cur] = []
            elif cur:
                cex[cur].append(l.rstrip("\n"))

    solved = {}
    for r in csv.DictReader(open(os.path.join(HERE, "summary.csv"))):
        if r["witness"] == "CONFIRMED":
            i = int(r["benchmark"].split("BSTSpec")[1])
            solved.setdefault((i, r["property"]), []).append(f"{r['prover']} ({float(r['seconds']):.1f} s)")

    out = os.path.join(HERE, "properties")
    if os.path.exists(out): shutil.rmtree(out)
    os.makedirs(out)
    shutil.copy(os.path.join(BENCH, "Nat.hs"), out)
    for i in range(1, 9):
        shutil.copy(os.path.join(BENCH, f"BST{i}.hs"), out)

    index = []
    for i, p in false:
        name = f"BST{i}_{p}.hs"
        by = solved.get((i, p))
        status = "solved by " + ", ".join(sorted(by)) if by else "not solved by any prover (10 s, then 60 s)"
        lines = [
            f"-- {p}, tested against BST{i}.hs (bug {i}: {BUGS[i]}).",
            "--",
            "-- From John Hughes, \"How to Specify It!\" (TFP 2019), adapted for hs2fol as",
            "-- described in benchmarks/hughes-bst/README.md. QuickCheck falsifies it:",
            "--",
        ] + ["--   " + l for l in cex.get((i, p), ["(no output recorded)"])] + [
            "--",
            f"-- Theorem provers (hs2fol + witness2input): {status}.",
            "--",
            "-- Run:  runghc " + name + "      (or: hs2fol " + name + ")",
            "module Main (main) where",
            "",
            "import Test.QuickCheck",
            "import Nat",
            f"import BST{i}",
            "",
        ]
        for b in common:
            lines += b + [""]
        lines += props[p] + ["", "main :: IO ()", f"main = quickCheck (withMaxSuccess 10000 {p})"]
        open(os.path.join(out, name), "w").write("\n".join(lines) + "\n")
        index.append((i, p, name, status))

    with open(os.path.join(HERE, "INDEX.md"), "w") as f:
        f.write("| bug | property | file | theorem provers |\n|---|---|---|---|\n")
        for i, p, name, status in index:
            f.write(f"| {i} | {p} | properties/{name} | {status} |\n")
    print(f"{len(index)} files written to {out}")

main()
