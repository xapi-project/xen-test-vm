
# these are overridden when make is called from ../Makefile
OPAMLIB 	= $(HOME)/.opam/system/lib
LIBGCC 		= /usr/lib/gcc/x86_64-linux-gnu/5/libgcc.a  

FLAGS  		= -cflag -g -lflags -g,-linkpkg,-dontlink,unix
BUILD  		= ocamlbuild -use-ocamlfind $(FLAGS)

.PHONY: all depend clean build main.native

all:: build

main.native.o: 
		$(BUILD) main.native.o

build:: main.native.o
		ld -d -static -nostdlib \
			_build/main.native.o \
			-L$(OPAMLIB) \
			-L$(OPAMLIB)/minios-xen \
			-L$(OPAMLIB)/io-page \
			$(OPAMLIB)/mirage-xen/libxencamlbindings.a \
			$(OPAMLIB)/mirage-xen-ocaml/libxenasmrun.a \
			$(OPAMLIB)/mirage-xen-ocaml/libxenotherlibs.a \
			$(OPAMLIB)/mirage-xen-posix/libxenposix.a \
			-lio_page_xen_stubs \
			-lopenlibm \
			-lminios \
			-T$(OPAMLIB)/minios-xen/libminios.lds \
			-m elf_x86_64 \
			-l x86_64 \
			$(LIBGCC) \
			-o test-vm.xen

clean::
		ocamlbuild -clean
		rm -f mir-suspend.xen


