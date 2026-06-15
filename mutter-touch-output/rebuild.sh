#!/usr/bin/env bash
set -euo pipefail

# rebuild.sh — Download mutter SRPM for a given Fedora version, apply patch, rebuild.
#
# Usage:
#   ./rebuild.sh              # rebuild for current Fedora release
#   ./rebuild.sh 44           # rebuild for Fedora 44

FEDORA_VERSION="${1:-$(rpm -E %fedora)}"

RPMBUILD_HOME="${RPMBUILD_HOME:-$HOME/rpmbuild}"
SPEC="$RPMBUILD_HOME/SPECS/mutter.spec"
SRPM_CACHE="$RPMBUILD_HOME/SRPMS"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PATCH_FILE="$SCRIPT_DIR/patches/mutter-touch-output-name.patch"
UDEV_FILE="$SCRIPT_DIR/udev/99-touch-passthrough-output.rules"

echo "=== mutter-touch-output rebuild ==="
echo "  Fedora version : $FEDORA_VERSION"
echo "  Patch          : $PATCH_FILE"
echo "  RPMBUILD_HOME  : $RPMBUILD_HOME"

# --- Check dependencies ---
if ! command -v rpmbuild &>/dev/null; then
  echo "ERROR: rpmbuild not found. Install rpm-build first."
  echo "  sudo dnf install -y rpm-build"
  exit 1
fi

# --- Ensure rpmbuild tree exists ---
if [ ! -d "$RPMBUILD_HOME" ]; then
  rpmdev-setuptree 2>/dev/null || mkdir -p "$RPMBUILD_HOME"/{SPECS,SOURCES,RPMS,SRPMS,BUILD,BUILDROOT}
fi

# --- Download SRPM ---
rm -f /tmp/mutter-*.src.rpm
echo "==> Downloading mutter SRPM for Fedora $FEDORA_VERSION..."
if ! dnf download --source --destdir /tmp "mutter-$(rpm -E %{?fedora})"; then
  # Fallback: try with dnf5 or different syntax
  dnf download --source mutter --destdir /tmp 2>/dev/null || \
  dnf download --source "mutter-$(rpm -E %fedora)" --destdir /tmp
fi

SRPM=$(ls /tmp/mutter-*.src.rpm 2>/dev/null | head -1)
if [ -z "$SRPM" ]; then
  echo "ERROR: Failed to download mutter SRPM."
  echo "Try: dnf download --source mutter"
  exit 1
fi
echo "  Downloaded: $SRPM"

# --- Install SRPM to rpmbuild tree ---
rpm -ivh "$SRPM" --define "_topdir $RPMBUILD_HOME" 2>&1 | grep -v 'package.*already installed' || true

# --- Verify spec exists ---
if [ ! -f "$SPEC" ]; then
  echo "ERROR: Spec not found at $SPEC"
  exit 1
fi

# --- Apply patch ---
if [ ! -f "$PATCH_FILE" ]; then
  echo "ERROR: Patch not found at $PATCH_FILE"
  exit 1
fi

echo "==> Replacing patch in spec..."
PATCH_BASENAME="$(basename "$PATCH_FILE")"

# Copy patch into SOURCES/
cp "$PATCH_FILE" "$RPMBUILD_HOME/SOURCES/$PATCH_BASENAME"

# Add patch reference to spec if not already present
if ! grep -q "$PATCH_BASENAME" "$SPEC"; then
  # Insert after the last Patch line (or after Source lines)
  sed -i "/^Patch[0-9]*:/!b; \$aPatch1000: $PATCH_BASENAME" "$SPEC"
  # Also ensure %patch1000 -p1 is applied in %prep
  sed -i "/^%autosetup/a\%patch1000 -p1" "$SPEC"
fi

# --- Install build dependencies ---
echo "==> Installing build dependencies..."
if command -v pkexec &>/dev/null; then
  pkexec dnf builddep -y "$SPEC"
else
  sudo dnf builddep -y "$SPEC"
fi

# --- Rebuild ---
echo "==> Building RPM (this will take a while)..."
cd "$RPMBUILD_HOME"
rpmbuild -ba "$SPEC" 2>&1

echo ""
echo "=== Build complete ==="
echo "Binary RPMs:"
ls -1 "$RPMBUILD_HOME/RPMS/x86_64/mutter-"*.rpm 2>/dev/null || echo "  (none in x86_64)"
ls -1 "$RPMBUILD_HOME/RPMS/noarch/mutter-common-"*.rpm 2>/dev/null || echo "  (none in noarch)"
echo ""
echo "Install with:  $SCRIPT_DIR/install.sh"
echo "Rollback with: $SCRIPT_DIR/rollback.sh"
