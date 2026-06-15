# mutter-touch-output

Mutter patch that adds `WL_OUTPUT` support for libinput devices. Maps touchscreens
to a specific display based on the `WL_OUTPUT` udev property.

## Why

GNOME's mutter maps touchscreens by EDID, size, or built-in heuristic — but ignores
`WL_OUTPUT` set by udev rules. This patch adds `match_output_name()` as an automatic
matching criterion, so you can force a touchscreen to a specific output via udev.

## Usage

```bash
# Rebuild mutter with the patch for your Fedora version
./rebuild.sh

# Install the patched RPM + udev rule
./install.sh

# Revert to official Fedora mutter
./rollback.sh
```

## Files

| File | Purpose |
|---|---|
| `patches/mutter-touch-output-name.patch` | Adds `META_MATCH_OUTPUT_NAME` matching to `meta-input-mapper.c` and `meta-input-device-native.c` |
| `udev/99-touch-passthrough-output.rules` | Sets `ENV{WL_OUTPUT}="HDMI-1"` for a virtual touch passthrough device |
| `rebuild.sh` | Downloads Fedora SRPM, applies patch, builds RPM |
| `install.sh` | Installs RPM + udev rule |
| `rollback.sh` | Removes udev rule, restores official Fedora mutter |

## Rebuild on another machine

```bash
git clone git@github.com:victor-divo/custom-opensource-package.git
cd custom-opensource-package/mutter-touch-output
sudo dnf install -y rpm-build
./rebuild.sh
./install.sh
```

## Verify

After reboot, check the log:

```bash
journalctl -b | grep TOUCH_OUTPUT
```

Expected output:

```
TOUCH_OUTPUT: device 'Touch passthrough' -> WL_OUTPUT='HDMI-1'
TOUCH_OUTPUT: MATCHED monitor 'BBC' via output name
```
