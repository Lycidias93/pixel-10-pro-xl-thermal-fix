# v1.3-mustang.15

Stable Pixel 10 Pro XL / mustang support/tooling release.

## Runtime scope

No thermal runtime scope change versus `v1.3-mustang.14`.

The module still changes only the verified `PollingDelay=300000` `VIRTUAL-SKIN*` targets to `5000ms` and keeps missing/null `PollingDelay` entries untouched.

## What changed

- Bundled debug/compatibility report tool now writes the ZIP to `/storage/emulated/0/Download` by default.
- Added `--out-dir` support for custom report locations.
- Added report schema manifest, thermal file hashes and stronger sanitizer metadata.
- README now documents daily-use expectations, public verify command, compatibility report workflow, support matrix and AshLooper credit.
- Added `.sha256` checksum release asset.

## Credits

- Original thermal polling fix idea and upstream inspiration: `marx161` / original upstream author credit kept from installer metadata.
- Mustang fork, controlled bisect, verification and packaging: Lycidias93.
- External bootloop safety during testing: AshLooper by RipperHybrid: https://github.com/RipperHybrid/AshLooper

AshLooper is not bundled. It is credited and recommended as an external bootloop protection layer during testing or porting.

## Links

- Project: https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix
- Releases: https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/releases
- Issues / compatibility requests: https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/issues
- AshLooper: https://github.com/RipperHybrid/AshLooper
