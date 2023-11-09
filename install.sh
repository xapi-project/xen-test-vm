#! /bin/bash
#
# Download and install the xen-test-vm on a XenServer.
#
# usage: install.sh [name]
#

set -ex

NAME=${1:-xen-test-vm}

VERSION="0.1.17"
GH="https://github.com/xapi-projext"
VM="$GH/xen-test-vm/releases/download/$VERSION/test-vm.xen.gz"
KERNEL="xen-test-vm-${VERSION//./-}.xen.gz"
GUEST="/boot/guest"


mkdir -p "$GUEST"
curl --fail -s -L "$VM" > "$GUEST/$KERNEL" || rm -f "$GUEST/$KERNEL"
UUID=$(xe vm-create name-label="$NAME")
xe vm-param-set PV-kernel="$GUEST/$KERNEL" uuid="$UUID"


