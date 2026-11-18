# Build without cabal: all dependencies are GHC boot packages.
GHC ?= ghc

hs2fol: src/*.hs
	$(GHC) -O -isrc -outputdir build -o hs2fol src/Main.hs

examples: hs2fol
	./hs2fol examples/Nat.hs
	./hs2fol examples/Lists.hs
	./hs2fol examples/HigherOrder.hs

clean:
	rm -rf build hs2fol examples/*-fol

.PHONY: examples clean
