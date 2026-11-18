# Build without cabal: all dependencies are GHC boot packages.
GHC ?= ghc

all: hs2fol witness2input

hs2fol: src/*.hs
	$(GHC) -O -isrc -outputdir build/hs2fol -o hs2fol src/Main.hs

witness2input: src/*.hs
	$(GHC) -O -isrc -outputdir build/witness2input -o witness2input src/Witness2Input.hs

examples: hs2fol
	./hs2fol examples/Nat.hs
	./hs2fol examples/Lists.hs
	./hs2fol examples/HigherOrder.hs

clean:
	rm -rf build hs2fol witness2input examples/*-fol

.PHONY: all examples clean
