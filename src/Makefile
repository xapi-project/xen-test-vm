# vim:ft=make ts=8: 
#

OPAMLIB = $(shell ocamlfind printconf path)
LIBGCC 	= $(shell gcc -print-libgcc-file-name) 
VM 	= test-vm.xen

# packages and flags are listed in _tags
OCBOPTS = -cflag -g -lflags -g,-linkpkg,-dontlink,unix
OCB  	= ocamlbuild -use-ocamlfind $(OCBOPTS)

.PHONY: all depend clean build main.native

all: 	build

_build/main.native.o: 
	$(OCB) main.native.o

LIBS +=	_build/main.native.o 
LIBS +=	-L$(OPAMLIB) 
LIBS +=	-L$(OPAMLIB)/minios-xen 
LIBS +=	-L$(OPAMLIB)/io-page 
LIBS +=	$(OPAMLIB)/mirage-xen/libxencamlbindings.a 
LIBS +=	$(OPAMLIB)/mirage-xen-ocaml/libxenasmrun.a 
LIBS +=	$(OPAMLIB)/mirage-xen-ocaml/libxenotherlibs.a 
LIBS +=	$(OPAMLIB)/mirage-xen-posix/libxenposix.a 
LIBS +=	-lio_page_xen_stubs 
LIBS +=	-lopenlibm 
LIBS +=	-lminios 
LIBS +=	-T$(OPAMLIB)/minios-xen/libminios.lds 
LIBS +=	-m elf_x86_64 
LIBS +=	-l x86_64 
LIBS +=	$(LIBGCC) 

build:  _build/main.native.o
	ld -d -static -nostdlib $(LIBS) -o $(VM)

clean:
	ocamlbuild -clean
	rm -f $(VM)


