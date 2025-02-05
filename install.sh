#!/usr/bin/env bash
#
# Install xen-test-vm on a XenServer.
#
# usage: install.sh host
#

VM=./src/dist/xenserver-test-vm.xen

set -o errexit
set -o pipefail

if [[ $# != 1 ]]; then
   cat <<EOF 
Usage: $0 host

Install $VM on host; this requires SSH access to the host.
EOF
  exit 1
fi

if ! test -f "$VM"; then
  echo "$VM not found; run make to build it"
  exit 1
fi

host="$1"
scp "$VM" "$host:/tmp"
ssh "root@$host" <<-'EOF'
  guest="/var/lib/xcp/guest"
  gzip /tmp/xenserver-test-vm.xen
  mkdir -p "$guest" && mv /tmp/xenserver-test-vm.xen.gz "$guest"
  UUID=$(xe vm-create name-label="minion-$$")
  xe vm-param-set PV-kernel="$guest/xenserver-test-vm.xen.gz" uuid="$UUID"
  xe vm-param-set uuid=$UUID domain-type=pvh
  xe vm-param-add uuid=$UUID param-name=platform pae=true nx=true
  xe vm-param-set uuid=$UUID PV-kernel=$guest/xenserver-test-vm.xen.gz
  xe vm-memory-limits-set uuid=$UUID dynamic-max=16777216 \
    dynamic-min=16777216 static-max=16777216 static-min=16777216
EOF
