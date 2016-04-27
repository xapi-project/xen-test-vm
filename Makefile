# vim:ft=make ts=8: 
#
#


HOST 		= "root@dt87"

all:		src
		$(MAKE) -C src/ all
		ls -lh src/test-vm.xen.gz

		
install: 	all
		ssh $(HOST) "test -d /boot/guest || mkdir /boot/guest"
		ssh $(HOST) "cd /boot/guest; rm -f test-vm.xen"
		scp src/test-vm.xen.gz $(HOST):/boot/guest

remove: 	
		true

clean:
		$(MAKE) -C src clean

release: 	opam descr


.PHONY: all clean install release









