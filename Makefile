# vim:ft=make ts=8: 
#
#

OPAMLIB 	= $(HOME)/.opam/system/lib
LIBGCC 		= $(shell gcc -print-libgcc-file-name) 
HOST 		= root@dt88:/boot/guest

all:	src
	$(MAKE) OPAMLIB="$(OPAMLIB)" LIBGCC="$(LIBGCC)" -C src/ all


install: 	all
		scp src/test-vm.xen $(HOST)

release: 	opam descr


.PHONY: all clean install release









