
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
cp realtek-r8152-linux/50-usb-realtek-net.rules /etc/udev/rules.d/

echo "Restarting udev..."
udevadm control --reload-rules

echo "Finished."

exit $RESULT
