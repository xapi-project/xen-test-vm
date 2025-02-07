#!/usr/bin/env bash
#
# Install xen-test-vm on a XenServer.
#
# usage: install.sh host [path/to/xen-test-vm.xen]
#


set -o errexit
set -o pipefail

if [[ $# < 1 ]]; then
   cat <<EOF 
Usage: $0 host [path/to/vm.xen]

Install VM on host; this requires SSH access to the host. The default
is to take the VM from the current build.
EOF
  exit 1
fi

VM=${2:-./src/dist/xenserver-test-vm.xen}

if ! test -f "$VM"; then
  echo "$VM not found; run make to build it"
  exit 1
fi

host="$1"
# use a fixed target name as otherwise the script below becomes
# complicated. Use the PID in the names to avoid collisions.
scp -q "$VM" "$host:/tmp/xen-test-vm.xen"
ssh "root@$host" <<-'EOF'
  VM=xen-test-vm.xen
  guest="/var/lib/xcp/guest"
  mkdir -p "$guest" && mv "/tmp/$VM" "$guest/$VM.$$"
  UUID=$(xe vm-create name-label="minion-$$")
  xe vm-param-set PV-kernel="$guest/$VM.$$" uuid="$UUID"
  xe vm-param-set uuid=$UUID domain-type=pvh
  xe vm-param-add uuid=$UUID param-name=platform pae=true nx=true
  xe vm-param-set uuid=$UUID PV-kernel="$guest/$VM.$$"
  xe vm-memory-limits-set uuid=$UUID dynamic-max=16777216 \
    dynamic-min=16777216 static-max=16777216 static-min=16777216
EOF
