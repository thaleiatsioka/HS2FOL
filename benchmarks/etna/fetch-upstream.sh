#!/bin/sh
# Fetch the original Etna sources that the ports in RBT/ and STLC/ are based
# on, at the commit they were ported from, into ./upstream (not committed:
# the Etna repository has no licence file).
set -eu
cd "$(dirname "$0")"
COMMIT=f22b56be223b88a277f2823fb4c69867ccc53199
rm -rf upstream
git clone -q https://github.com/jwshii/etna.git upstream
git -C upstream checkout -q "$COMMIT"
echo "Etna $COMMIT in ./upstream; see upstream/workloads/Haskell/{RBT,STLC}/src"
