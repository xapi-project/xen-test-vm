
# Xen Test VM

This repository contains OCaml code to build a minimal
para-virtualised kernel to run on the Xen hypervisor for testing Xen. The
kernel is built using the Mirage unikernel framework.

# Building

The code relies on some pinned OCaml packages in Opam. This dependency
cannot be expressed naturally in the depends section of an `opam` file. For
now, this requires to install the dependencies manually. Apart from that,
calling `make` will build `src/test-vm.xen`


    opam install mirage-types-lwt functoria astring mirage-console
    opam install mirage-xen-minios # do we need this?
  
    opam add pin mirage-platform git://github.com/jonludlam/mirage-platform/tree/reenable-suspend-resume

    opam pin add mirage-xen git://github.com/jonludlam/mirage-platform#reenable-suspend-resume

    opam pin add mirage-bootvar-xen git://github.com/jonludlam/mirage-bootvar-xen#better-parser

    opam pin add minios-xen git://github.com/jonludlam/mini-os#suspend-resume3

    make


# Installing the VM

The VM is built as `src/test-vm.xen`. Installing it on a Xen host:

    HOST=host
    ssh root@$HOST "test -d /boot/guest || mkdir /boot/guest"
    scp src/test-vm.xen root@$HOST:/boot/guest

As root on $HOST:

    xe vm-create name-label=minion
    # this echoes a UUID for the new VM named "minion"
    xe vm-param-set PV-kernel=/boot/guest/test-vm.xen uuid=$UUID
    
Once installed, use the CLI on the host to operate the VM or XenCenter.


