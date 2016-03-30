
# Xen Test VM

This repository contains OCaml code to build a minimal
para-virtualised kernel to run on the Xen hypervisor for testing Xen. The
kernel is built using the Mirage unikernel framework.


# Installing the VM

The VM is built as `src/test-vm.xen`. Installing it on a Xen host:

    HOST=host
    ssh root@$HOST "test -d /boot/guest || mkdir /boot/guest"
    scp src/test-vm.xen root@$HOST:/boot/guest

As root on $HOST:

    xe vm-create name-label=flower
    # this echoes a UUID
    xe vm-param-set PV-kernel=/boot/guest/test-vm.xen uuid=$UUID
    
