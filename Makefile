# vim: set ft=make ts=8: 
#

PACKAGE = 	xen-test-vm
PREFIX = 	.
LIB = 		$(PREFIX)/$(PACKAGE)/lib
VM = 		./src/dist/xenserver-test-vm.xen

all:		src
		$(MAKE) -C src/ all
		ls -lh $(VM)

package: 	src
		opam pin add -y xen-test-vm .
		opam install xen-test-vm

install: 	
		mkdir -p $(LIB)
		cp $(VM) $(LIB)

remove: 	
		rm -f $(LIB)/$(VM)
		
clean:
		$(MAKE) -C src clean

.PHONY: 	all clean install release









