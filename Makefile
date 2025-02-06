#
#

FMT += --inplace
FMT += --enable-outside-detected-project

all:		src
		cd src; mirage configure -t xen
		$(MAKE) -C src/

format: 	src
		cd src; ocamlformat $(FMT) *.ml*

clean:
		$(MAKE) -C src/ clean

distclean:
		git clean -fdx

.PHONY: 	all clean distclean

# vim: set ft=make ts=8: 
