#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RPMBUILD_HOME="${RPMBUILD_HOME:-$HOME/rpmbuild}"

RPM_MUTTER=$(ls "$RPMBUILD_HOME/RPMS/x86_64/mutter-"*.rpm 2>/dev/null | grep -v debug | grep -v devel | grep -v tests | head -1)
RPM_COMMON=$(ls "$RPMBUILD_HOME/RPMS/noarch/mutter-common-"*.rpm 2>/dev/null | head -1)
UDEV_RULES="$SCRIPT_DIR/udev/99-touch-passthrough-output.rules"

if [ -z "$RPM_MUTTER" ] || [ -z "$RPM_COMMON" ]; then
  echo "ERROR: RPM not found in $RPMBUILD_HOME/RPMS/"
  echo "Run ./rebuild.sh first."
  exit 1
fi

echo "==> Installing RPMs..."
sudo rpm -Uvh --force "$RPM_MUTTER" "$RPM_COMMON"

echo "==> Installing udev rule..."
sudo install -m 0644 "$UDEV_RULES" /etc/udev/rules.d/99-touch-passthrough-output.rules
sudo udevadm control --reload
sudo udevadm trigger --subsystem-match=input

echo "==> Clearing stale dconf mapping (if any)..."
dconf reset -f /org/gnome/desktop/peripherals/touchscreens/beef:dead/ 2>/dev/null || true

echo "Done. Reboot or logout/login for changes to take effect."
