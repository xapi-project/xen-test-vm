[![Build Status](https://travis-ci.org/xapi-project/xen-test-vm.svg?branch=master)](https://travis-ci.org/xapi-project/xen-test-vm)

# Xen Test VM

This repository contains OCaml code to build a minimal para-virtualised
kernel to run on the Xen hypervisor for testing Xen. The kernel is built
using the Mirage unikernel framework.

# Binary Releases

Binary releases are hosted on 
[GitHub](https://github.com/xapi-project/xen-test-vm/releases) as
`xen-test.vm.gz`. The uncompressed file is the kernel that needs to be
installed. You could use the following code in a script:

```sh
VERSION="0.0.5"
NAME="xen-test-vm-$VERSION"
GH="https://github.com/xapi-project"
VM="$GH/xen-test-vm/releases/download/$VERSION/test-vm.xen.gz"
KERNEL="xen-test-vm-${VERSION//./-}.xen.gz"

curl --fail -s -L "$VM" > "$KERNEL"
```

# Installing the VM

The VM is built as `src/test-vm.xen` and available as binary
release. The file goes into `/boot/guest` on a host:

    HOST=host
    ssh root@$HOST "test -d /boot/guest || mkdir /boot/guest"
    scp test-vm.xen root@$HOST:/boot/guest

The kernel needs to be registered with Xen on the host.  As root on
`$HOST`, do:

    xe vm-create name-label=minion
    # this echoes a UUID for the new VM named "minion"
    xe vm-param-set PV-kernel=/boot/guest/test-vm.xen uuid=$UUID
    
Once installed, use the CLI on the host to operate the VM or use
XenCenter.

# Building from Source Code

The code relies on some pinned OCaml packages in Opam. This dependency
cannot be expressed naturally in the depends section of an `opam` file. For
now, this requires to install the dependencies manually. Apart from that,
calling `make` will build `src/test-vm.xen`


        ./setup.sh # executes opam installations
        make

A `Dockerfile` can be used to create a Docker container environment for
compiling the VM. It is used for building on Travis.

# Travis CI

The VM is built on Travis using the [Dockerfile](./Dockerfile) - see the
[.travis.yml](.travis.yml). Travis also creates the releases hosted on
[GitHub](https://github.com/xapi-project/xen-test-vm/releases).

# Out-of-Band Control Messages

The kernel reads control messages from the Xen Store from
"control/shutdown" and responds to them. In addition, it reads from 
"control/testing". 

## Shutdown Messages

The kernel responds to these messages in the "control/shutdown". Usually
the hypervisor only sends these.

    suspend  
    poweroff 
    reboot   
    halt     
    crash    

## Testing Messages

The kernel reads messages in "control/testing". Legal messages are:

    now:suspend  
    now:poweroff 
    now:reboot   
    now:halt     
    now:crash    

Each makes the kernel respond to these immediately. In addition, these
messages are legal:

    next:suspend  
    next:poweroff 
    next:reboot   
    next:halt     
    next:crash    

The next time the kernel receives a shutdown message, it ignores the
message it received and acts on the next:message instead. This permits
to surprise the hypervisor.

Typically, control/shutdown is written only by Xen. To write to
control/testing, use:

  xenstore write /local/domain/<domid>/control/testing now:reboot

# Debugging the VM

To direct console output of the VM to a file, you can tell the $HOST:

    xenstore write /local/logconsole/@ "/tmp/console.%d"

Output then goes to `/tmp/console.<domid>`.


