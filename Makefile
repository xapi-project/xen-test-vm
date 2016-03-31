# vim:ft=make ts=8: 
#
#

HOST 		= root@dt88:/boot/guest

all:		src
		$(MAKE) -C src/ all


install: 	all
		scp src/test-vm.xen $(HOST)

remove: 	
		true

clean:
		$(MAKE) -C src clean

release: 	opam descr


.PHONY: all clean install release









