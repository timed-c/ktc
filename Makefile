DIRS = src

.PHONY: all

# Init submodules if needed and make native version.
# The resulting executable can be found under /bin and /library (symlinks)
all:   ktcutil ktcoption native

# Compile native version.
ktcutil:
	@rm -f -r libs
	@mkdir libs
	@ocamlbuild -no-hygiene -cflags '-w -a' -use-ocamlfind -pkgs 'cil,yojson,csv' -Is $(DIRS) ktcutil.cma
	@ocamlbuild   -no-hygiene -cflags '-w -a' -use-ocamlfind -pkgs 'cil,yojson,csv' -Is $(DIRS) ktcutil.cmxa
	@rm -f bytes.ml
	@cp _build/src/ktcutil.cma libs/.
	@cp _build/src/ktcutil.cmxa libs/.

ktcoption:
	@ocamlbuild -cflags '-w -a'  -no-hygiene -use-ocamlfind -pkgs 'cil,yojson,csv'  -Is $(DIRS) ktcoptions.cma > log
	@ocamlbuild  -cflags '-w -a' -no-hygiene -use-ocamlfind -pkgs 'cil,yojson,csv'  -Is $(DIRS) ktcoptions.cmxa > log
	@ocamlbuild  -cflags '-w -a' -no-hygiene -use-ocamlfind -pkgs 'cil,yojson,csv'  -Is $(DIRS) cilktc.cma > log
	@ocamlbuild  -cflags '-w -a' -no-hygiene -use-ocamlfind -pkgs 'cil,yojson,csv' -Is $(DIRS) cilktc.cmxa
	@rm -f bytes.ml
	@cp _build/src/ktcoptions.cma libs/.
	@cp _build/src/ktcoptions.cmxa libs/.



native:
	@ocamlbuild -cflags '-w -a' -no-hygiene  -use-ocamlfind -pkgs 'cil,yojson,csv'  -Is $(DIRS) main.native
	@rm -f main.native
	@cd bin; cp ../_build/src/main.native ktcexe

clean:
	@rm -f -r libs
	@rm -f -r _build
	@rm -f bin/ktcexe
	@rm -f bin/*.cil.c
	@rm -f bin/*.i


