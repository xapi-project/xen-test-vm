[![Build Status](https://travis-ci.org/lindig/xen-test-vm.svg?branch=travis)](https://travis-ci.org/lindig/xen-test-vm)

# Xen Test VM

This repository contains OCaml code to build a minimal
para-virtualised kernel to run on the Xen hypervisor for testing Xen. The
kernel is built using the Mirage unikernel framework.

# Building

The code relies on some pinned OCaml packages in Opam. This dependency
cannot be expressed naturally in the depends section of an `opam` file. For
now, this requires to install the dependencies manually. Apart from that,
calling `make` will build `src/test-vm.xen`


        ./setup.sh # executes opam installations
        make

A `Dockerfile` can be used to create a Docker container environment for
compiling the VM. It is used for building on Travis.

# Travis

The VM is built on Travis using the [Dockerfile](./Dockerfile) - see the
[.travis.yml](./travis.yml).

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


