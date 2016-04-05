# vim:ft=make ts=8: 
#
#


HOST 		= "root@dt87"

all:		src
		$(MAKE) -C src/ all

		# This target is specific to Citrix
install: 	all
		ssh $(HOST) "test -d /boot/guest || mkdir /boot/guest"
		scp src/test-vm.xen $(HOST):/boot/guest

remove: 	
		true

clean:
		$(MAKE) -C src clean

release: 	opam descr


.PHONY: all clean install release









