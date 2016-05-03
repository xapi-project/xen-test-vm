#! /bin/sh

opam pin add -n -y mirage-xen git://github.com/jonludlam/mirage-platform#reenable-suspend-resume

opam pin add -n -y mirage-bootvar-xen git://github.com/jonludlam/mirage-bootvar-xen#better-parser

opam pin add -n -y minios-xen git://github.com/jonludlam/mini-os#suspend-resume3

opam pin add -n -y cstruct 1.9.0

opam install -q -y mirage-xen
opam install -q -y mirage-console
opam install -q -y mirage-bootvar-xen
opam install -q -y mirage
