#
#

FMT += --inplace
FMT += --enable-outside-detected-project

VM = ./src/_build/solo5/xenserver-test-vm.xen

all:		src
		cd src; mirage configure -t xen
		$(MAKE) -C src/

format: 	src
		cd src; ocamlformat $(FMT) *.ml*

clean:
		$(MAKE) -C src/ clean

distclean:
		git clean -fdx

$(VM):
		@echo "Consider running make to build $(VM)"

package: 	$(VM) README.md
		zip -j xenserver-test-vm.zip  $(VM) README.md

.PHONY: 	all clean distclean

# vim: set ft=make ts=8: 
