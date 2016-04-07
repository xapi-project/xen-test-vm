
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
compiling the VM. It is not well tested so far.

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

# Out-of-Band Control Messages

The kernel reads control messages from the Xen Store from
"control/shutdown" and responds to them. In addition, it reads from 
"control/testing". Here is how the two interact:

  shutdown  testing
  -----------------
  msg                 -> regular case, responds to msg
  msg       tst       -> ignores msg, responds to tst
            tst       -> responds to tst

Valid messages are:

  suspend  
  poweroff 
  reboot   
  halt     
  crash    

Typically, control/shutdown is written only by Xen. To write to
control/testing:

  xenstore write /local/domain/<domid>/control/testing reboot

# Debugging the VM

To direct console output of the VM to a file, you can tell the $HOST:

    xenstore write /local/logconsole/@ "/tmp/console.%d"

Output then goes to `/tmp/console.<domid>`.


