#! /bin/sh

opam pin add -n mirage-xen git://github.com/jonludlam/mirage-platform#reenable-suspend-resume

opam pin add -n mirage-bootvar-xen git://github.com/jonludlam/mirage-bootvar-xen#better-parser

opam pin add -n minios-xen git://github.com/jonludlam/mini-os#suspend-resume3


opam install mirage-xen
opem install mirage-console
opem install mirage-bootvar-xen
opem install mirage
