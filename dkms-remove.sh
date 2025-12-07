#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "You must run this with superuser priviliges.  Try \"sudo ./dkms-remove.sh\"" 2>&1
  exit 1
else
  echo "About to run dkms removal steps..."
fi

DRV_DIR="$(pwd)"
DRV_NAME=r8152
DRV_VERSION=2.21.4

dkms remove ${DRV_NAME}/${DRV_VERSION} --all
rm -rf /usr/src/${DRV_NAME}-${DRV_VERSION}

RESULT=$?
if [[ "$RESULT" != "0" ]]; then
  echo "Error occurred while running dkms remove." 2>&1
else
  echo "Finished running dkms removal steps."
fi

echo "Removing the dedicated udev rules file..."
rm -f /etc/udev/rules.d/50-usb-realtek-net.rules

echo "Restarting udev..."
udevadm control --reload-rules

echo "Removing CDC driver blacklist..."
rm -f /etc/modprobe.d/99-rtl815x-usb-blacklist.conf

echo "Removing r8152 from initramfs modules..."
IMOD="/etc/initramfs-tools/modules"
if grep -qE '^\s*r8152(\s|$)' "$IMOD" 2>/dev/null; then
  sed -i '/^\s*r8152\s*$/d' "$IMOD"
  echo "  - Removed r8152 from $IMOD"
else
  echo "  - r8152 not found in $IMOD"
fi

echo "Updating initramfs for all kernels..."
update-initramfs -u -k all

echo "Finished."

exit $RESULT
