# vim: set ft=make ts=8: 
#

PACKAGE = 	xen-test-vm
PREFIX = 	.
VM = 		./src/dist/xenserver-test-vm.xen

all:		src
		cd src; mirage configure -t xen
		$(MAKE) -C src/

clean:
		$(MAKE) -C src/ clean

distclean:
		git clean -fdx

.PHONY: 	all clean distclean









