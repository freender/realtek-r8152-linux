
#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "You must run this with superuser priviliges.  Try \"sudo ./dkms-install.sh\"" 2>&1
  exit 1
else
  echo "About to run dkms install steps..."
fi

DRV_DIR="$(pwd)"
DRV_NAME=r8152
DRV_VERSION=2.21.4

cp -r ${DRV_DIR} /usr/src/${DRV_NAME}-${DRV_VERSION}

# Only add if not already in DKMS tree
if ! dkms status -m ${DRV_NAME} -v ${DRV_VERSION} 2>/dev/null | grep -q "${DRV_NAME}/${DRV_VERSION}"; then
  dkms add -m ${DRV_NAME} -v ${DRV_VERSION}
fi

dkms build -m ${DRV_NAME} -v ${DRV_VERSION}
dkms install --force -m ${DRV_NAME} -v ${DRV_VERSION}
RESULT=$?

echo "Finished running dkms install steps."

echo "Copy the dedicated udev rules file..."
cp 50-usb-realtek-net.rules /etc/udev/rules.d/

echo "Restarting udev..."
udevadm control --reload-rules

echo "Blacklisting competing CDC drivers..."
tee /etc/modprobe.d/99-rtl815x-usb-blacklist.conf >/dev/null <<'EOF'
# Prevent generic/alternate drivers from binding RTL815x USB NICs
blacklist cdc_ncm
blacklist cdc_ether
blacklist r8153_ecm
# Block explicit module loading attempts
install cdc_ncm /bin/false
install cdc_ether /bin/false
install r8153_ecm /bin/false
EOF

echo "Adding r8152 to initramfs modules..."
IMOD="/etc/initramfs-tools/modules"
if ! grep -qE '^\s*r8152(\s|$)' "$IMOD" 2>/dev/null; then
  echo "r8152" >> "$IMOD"
  echo "  - Added r8152 to $IMOD"
else
  echo "  - r8152 already in $IMOD"
fi

echo "Updating initramfs for all kernels..."
update-initramfs -u -k all

echo "Finished."

exit $RESULT
