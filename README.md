# custom-opensource-package

Custom RPM builds for personal use — patched open-source packages that aren't (yet) upstream.

## Packages

| Package | Description |
|---|---|
| [`mutter-touch-output/`](mutter-touch-output/) | Mutter with `WL_OUTPUT` support for libinput — map touchscreens to displays via udev |

## How to use

Each package has its own `rebuild.sh`, `install.sh`, and `rollback.sh`.

```bash
git clone git@github.com:victor-divo/custom-opensource-package.git
cd custom-opensource-package/<package>/
./rebuild.sh          # rebuild for current Fedora
./install.sh          # install the patched package
```
