#!/usr/bin/env bash
set -euo pipefail

echo "==> Removing udev rule..."
sudo rm -f /etc/udev/rules.d/99-touch-passthrough-output.rules
sudo udevadm control --reload
sudo udevadm trigger --subsystem-match=input

echo "==> Restoring official Fedora mutter..."
sudo dnf distro-sync -y mutter mutter-common
sudo glib-compile-schemas /usr/share/glib-2.0/schemas/

echo "==> Clearing stale dconf mapping..."
dconf reset -f /org/gnome/desktop/peripherals/touchscreens/beef:dead/ 2>/dev/null || true

echo "Done. Reboot or logout/login to return fully to Fedora packages."
