<!-- vim: set ts=4 sw=4 et: -->

[![Build Status](https://travis-ci.org/xapi-project/xen-test-vm.svg?branch=master)](https://travis-ci.org/xapi-project/xen-test-vm)

# Xen Test VM

This repository contains OCaml code to build a minimal para-virtualised
kernel to run on the Xen hypervisor for testing Xen. The kernel is built
using the Mirage unikernel framework.

# Binary Releases

Binary releases are hosted on
[GitHub](https://github.com/xapi-project/xen-test-vm/releases) as
`xen-test.vm.gz`. 

    VERSION="0.0.5"
    GH="https://github.com/xapi-project"
    VM="$GH/xen-test-vm/releases/download/$VERSION/test-vm.xen.gz"
    KERNEL="xen-test-vm-${VERSION//./-}.xen.gz"

    curl --fail -s -L "$VM" > "$KERNEL"

# Installing the VM

The VM is built as `src/test-vm.xen.gz` and available as binary
release. The file goes into `/boot/guest` on a host:

    HOST=host
    ssh root@$HOST "test -d /boot/guest || mkdir /boot/guest"
    scp test-vm.xen.gz root@$HOST:/boot/guest

The kernel needs to be registered with Xen on the host.  As root on
`$HOST`, do:

    xe vm-create name-label=minion
    # this echoes a UUID for the new VM named "minion"
    xe vm-param-set PV-kernel=/boot/guest/test-vm.xen.gz uuid=$UUID
    
Once installed, use the CLI on the host to operate the VM or use
XenCenter.

# Building from Source Code

    opam pin add xen-test-vm .
    opam install xen-test-vm

Watch the output for where the kernel gets installed.

# Travis CI

The VM is built on Travis using the [Dockerfile](./Dockerfile) - see the
[.travis.yml](.travis.yml). Travis also creates the releases hosted on
[GitHub](https://github.com/xapi-project/xen-test-vm/releases).

# Out-of-Band Control Messages

In addition to the shutdown messages sent by Xen, the kernel monitors
the Xen Store for messages. These are used to control the response to
shutdown messages.

## Shutdown Messages

The kernel responds to these messages in "control/shutdown". Usually
the hypervisor only sends these.

    suspend  
    poweroff 
    reboot   
    halt     
    crash    

All other messages are logged and ignored. 

## Testing Messages

The kernel reads messages in "control/testing". It acknowledges a
message by replacing the read message with the empty string.

A message in "control/testing" is a JSON object: 

    { "when":       "now"           // when to react
    , "ack":        "ok"            // how to ack control/shutdown
    , "action":     "reboot"        // how to react to control/shutdown
    }

Note that proper JSON does not permit _//_-style comments.  The message
describes three aspects:

1. `"when"`: either `"now"` or `"onshutdown"`. The kernel will either
   immediately or when then next shutdown message arrives perform the
   `"action"`.

2. `"ack"`: either `"ok"`, `"none"`, `"delete"`, or something else. This
  controls, how the kernel acknowledges the next shutdown message.
    * `"ok"`: regular behavior
    * `"none"`: don't acknowledge the message
    * `"delete"`: delete "control/shutdown"
    * `"something"`: write the string read to "control/shutdown"

3. `"action"`: what do do (eiter now or on shutdown). The message in
   `control/shutdown` is ignored and superseeded by the `action` field: 
    * `"suspend"`: suspend
    * `"poweroff"`: power off
    * `"reboot"`: reboot
    * `"halt"`: halt
    * `"crash"`: crash
    * `"ignore"`: do nothing - ignore the message

To write to `control/testing`, use:

    msg='{"when":"now","ack":"ok","action":"reboot"}'
    xenstore write /local/domain/<domid>/control/testing "$msg"

The _domid_ is logged to the console and can be obtained through the Xen
API.

# Debugging the VM

To direct console output of the VM to a file, you can tell the $HOST:

    xenstore write /local/logconsole/@ "/tmp/console.%d"

Output then goes to `/tmp/console.<domid>`.

