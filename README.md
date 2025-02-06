<!-- vim: set ts=4 sw=4 et: -->


# Xen Test VM

This repository contains OCaml code to build a minimal para-virtualised
kernel to run on the Xen hypervisor for testing Xen Server. The kernel
is built using the Mirage unikernel framework.

## Building

This relies on the Mirage framework which generates the build
environment by installing packages in the local switch. In that regard
it is different from typical OCaml projects.

```
$ make
```

This runs `mirage`, installs packages, and compiles the sources. As
such, this does not work in a sandboxed environment because it relies on
installing more OCaml packages.

# Installing the VM

Use

```
$ ./install.sh host
```

to install the kernel on a XenServer host using ssh root access on
`host`. See the script for how it uses the `xe` command to register the
kernel as a VM.

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

3. `"action"`: what do do (either now or on shutdown). The message in
   `control/shutdown` is ignored and superseded by the `action` field: 
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

