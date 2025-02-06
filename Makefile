#
#

all:		src
		cd src; mirage configure -t xen
		$(MAKE) -C src/

clean:
		$(MAKE) -C src/ clean

distclean:
		git clean -fdx

.PHONY: 	all clean distclean

# vim: set ft=make ts=8: 
