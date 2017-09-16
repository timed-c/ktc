DIRS = src

.PHONY: all 

# Init submodules if needed and make native version. 
# The resulting executable can be found under /bin and /library (symlinks)
all:   ktcutil ktcoption native 

# Compile native version.
ktcutil:
	@rm -f -r libs
	@mkdir libs
	@ocamlbuild -no-hygiene -use-ocamlfind -package cil -Is $(DIRS) ktcutil.cma 
	@ocamlbuild -no-hygiene -use-ocamlfind -package cil -Is $(DIRS) ktcutil.cmxa 
	@rm -f bytes.ml
	@cp _build/src/ktcutil.cma libs/.
	@cp _build/src/ktcutil.cmxa libs/.

ktcoption:
	@ocamlbuild -no-hygiene -use-ocamlfind -package cil -Is $(DIRS) ktcoptions.cma > log
	@ocamlbuild -no-hygiene -use-ocamlfind -package cil -Is $(DIRS) ktcoptions.cmxa > log
	@ocamlbuild -no-hygiene -use-ocamlfind -package cil -Is $(DIRS) cilktc.cma > log
	@ocamlbuild -no-hygiene -use-ocamlfind -package cil -Is $(DIRS) cilktc.cmxa 
	@rm -f bytes.ml
	@cp _build/src/ktcoptions.cma libs/. 
	@cp _build/src/ktcoptions.cmxa libs/.



native:
	@ocamlbuild -no-hygiene -use-ocamlfind -package cil  -Is $(DIRS) main.native 
	@rm -f main.native 
	@cd bin; cp ../_build/src/main.native ktcexe

clean:
	@rm -f -r libs
	@rm -f -r _build
	@rm -f bin/ktcexe
	@rm -f bin/*.cil.c
	@rm -f bin/*.i 
	
	
