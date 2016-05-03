# vim: set ft=make ts=8: 
#

PACKAGE = 	xen-test-vm
PREFIX = 	.
LIB = 		$(PREFIX)/$(PACKAGE)/lib
VM = 		src/test-vm.xen.gz

all:		src
		$(MAKE) -C src/ all
		ls -lh $(VM)

install: 	
		mkdir -p $(LIB)
		cp $(VM) $(LIB)

remove: 	
		rm -f $(lib)/$(VM)
		
clean:
		$(MAKE) -C src clean

.PHONY: 	all clean install release









