#!/usr/bin/env python3
"""Expand Etna-style mutant markers in the templates.

    {-! -}
    correct code
    {-!! mutant_a -}
    {-!
    code of mutant_a
    -}
    {-!! mutant_b -}
    ...

For template/RBT.template.hs and template/STLC.template.hs, writes <W>_base.hs (the
correct code) and <W>_<mutant>.hs for every mutant, each a module of the
same name. Run from this directory: ./generate.py
"""
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
MUT = re.compile(r'^\s*\{-!!\s*(\S+)\s*-\}\s*$')


def parse(lines):
    """Return a list of items: ('text', line) or ('choice', base, {name: body})."""
    items, i = [], 0
    while i < len(lines):
        if lines[i].strip() == '{-! -}':
            i += 1
            base = []
            while not MUT.match(lines[i]):
                base.append(lines[i])
                i += 1
            muts = {}
            while i < len(lines) and MUT.match(lines[i]):
                name = MUT.match(lines[i]).group(1)
                i += 1
                assert lines[i].strip() == '{-!', (name, lines[i])
                i += 1
                body = []
                while lines[i].strip() != '-}':
                    body.append(lines[i])
                    i += 1
                i += 1
                muts[name] = body
            items.append(('choice', base, muts))
        else:
            items.append(('text', lines[i]))
            i += 1
    return items


def render(items, mutant):
    out = []
    for it in items:
        if it[0] == 'text':
            out.append(it[1])
        else:
            _, base, muts = it
            out.extend(muts[mutant] if mutant in muts else base)
    return out


def main():
    fuel40 = 'Suc (' * 40 + 'Zero' + ')' * 40
    for w in ['RBT', 'STLC']:
        src = open(os.path.join(HERE, 'template', w + '.template.hs')).read().splitlines()
        items = parse(src)
        mutants = []
        for it in items:
            if it[0] == 'choice':
                mutants += [m for m in it[2] if m not in mutants]
        for m in ['base'] + mutants:
            mod = f'{w}_{m}'
            text = '\n'.join(render(items, m)) + '\n'
            text = text.replace('@MODULE@', mod).replace('@FUEL40@', fuel40)
            header = (f'-- GENERATED from template/{w}.template.hs by ../generate.py; do not edit.\n'
                      f'-- Variant: {"the correct implementation" if m == "base" else "mutant " + m}.\n')
            open(os.path.join(HERE, w, mod + '.hs'), 'w').write(header + text)
        for lib in (['Nat.hs'] if w == 'RBT' else ['Nat.hs', 'Z.hs']):
            text = open(os.path.join(HERE, lib)).read()
            open(os.path.join(HERE, w, lib), 'w').write(
                f'-- GENERATED: copy of ../{lib} made by ../generate.py; do not edit.\n' + text)
        open(os.path.join(HERE, w, 'mutants.txt'), 'w').write('\n'.join(mutants) + '\n')
        print(w, len(mutants), 'mutants:', ' '.join(mutants))


if __name__ == '__main__':
    main()
