# Generated by mirage.v4.3.4

-include Makefile.user
BUILD_DIR = ./
MIRAGE_DIR = ./mirage
UNIKERNEL_NAME = xenserver-test-vm-xen
OPAM = opam

all::
	@$(MAKE) --no-print-directory depends
	@$(MAKE) --no-print-directory build

.PHONY: all lock install-switch pull clean depend depends build repo-add repo-rm depext-lockfile

repo-add:
	@printf "\e[2musing overlay repository mirage: [opam-overlays, mirage-overlays] \e[0m\n"
	$(OPAM) repo add opam-overlays https://github.com/dune-universe/opam-overlays.git || $(OPAM) repo set-url opam-overlays https://github.com/dune-universe/opam-overlays.git
	$(OPAM) repo add mirage-overlays https://github.com/dune-universe/mirage-opam-overlays.git || $(OPAM) repo set-url mirage-overlays https://github.com/dune-universe/mirage-opam-overlays.git


repo-rm:
	@printf "\e[2mremoving overlay repository [opam-overlays, mirage-overlays]\e[0m\n"
	$(OPAM) repo remove opam-overlays https://github.com/dune-universe/opam-overlays.git
	$(OPAM) repo remove mirage-overlays https://github.com/dune-universe/mirage-opam-overlays.git



depext-lockfile: $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam.locked
	echo " ↳ install external dependencies for monorepo"
	env OPAMVAR_monorepo="opam-monorepo" $(OPAM) monorepo depext -y -l $<


$(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam.locked: $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam
	@$(MAKE) -s repo-add
	@echo " ↳ generate lockfile for monorepo dependencies"
	@env OPAMVAR_monorepo="opam-monorepo" $(OPAM) monorepo lock --require-cross-compile --build-only $(UNIKERNEL_NAME) -l $@ --ocaml-version $(shell ocamlc --version); (ret=$$?; $(MAKE) -s repo-rm && exit $$ret)

lock::
	@$(MAKE) -B $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam.locked

pull:: $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam.locked
	@echo " ↳ fetch monorepo rependencies in the duniverse folder"
	@env OPAMVAR_monorepo="opam-monorepo" $(OPAM) monorepo pull -l $< -r $(abspath $(BUILD_DIR))

install-switch:: $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam
	@echo " ↳ opam install switch dependencies"
	@$(OPAM) install $< --deps-only --yes
	@$(MAKE) -s depext-lockfile

depends depend::
	@$(MAKE) --no-print-directory lock
	@$(MAKE) --no-print-directory install-switch
	@$(MAKE) --no-print-directory pull

build::
	mirage build -f config.ml

clean::
	mirage clean
