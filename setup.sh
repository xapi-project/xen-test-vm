#! /bin/sh


opam install mirage-types-lwt 
opam install mirage-xen-minios 

opam pin add mirage-xen git://github.com/jonludlam/mirage-platform#reenable-suspend-resume

opam pin add mirage-bootvar-xen git://github.com/jonludlam/mirage-bootvar-xen#better-parser

opam pin add minios-xen git://github.com/jonludlam/mini-os#suspend-resume3


