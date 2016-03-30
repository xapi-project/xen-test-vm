# vim:ft=make ts=8: 
#
#

OPAMLIB 	= $(HOME)/.opam/system/lib
LIBGCC 		= /usr/lib/gcc/x86_64-linux-gnu/5/libgcc.a  

all:	src
	$(MAKE) OPAMLIB="$(OPAMLIB)" LIBGCC="$(LIBGCC)" -C src/ all


release: 	opam descr


.PHONY: all clean install release









