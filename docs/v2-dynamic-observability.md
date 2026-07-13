# V2 dynamic runtime observability

The runtime verifier follows the dynamic three-file model agreed for V2:

- `thermal_info_config.json`
- `thermal_info_config_charge.json`
- `thermal_info_config_throttling.json`

It does not reintroduce repository profiles or patch the other thermal files.

## Compatibility gate

`tools/bootguard/compat-check.sh` verifies:

- exact device, Android and build support;
- build-keyed source cache and `source-manifest.tsv`;
- source hashes, sizes and original `PollingDelay: 300000` counts;
- `patch-manifest.tsv`, output hashes and per-file replacement counts;
- module and persistent validation reports;
- exact three-file overlay inventory;
- active vendor hashes and active PollingDelay counts.

Hash equality alone is not enough. Polling Mod is active only when the active
files contain the manifest-backed `5000` count and no remaining `300000`.

A valid staged overlay may be safe to reboot while the active vendor files still
show the previous state. This is reported as pending, not active.

## Status

The manager keeps the existing P/T/Z description. Polling turns green only when:

- dynamic materialization is valid;
- the active vendor files match the module overlay;
- the active PollingDelay counts match the selected mode.

The detailed status also exposes source, manifest, report and active-value state.

## Debug collector

The debug ZIP includes:

- build-keyed source cache;
- source and patch manifests;
- module and persistent validation reports;
- all three source, module and active files;
- per-origin PollingDelay counts and hashes;
- compatibility and manager status;
- root/overlay backend, pTune, ThermalHAL, mount, crash and ZRAM context.

The collector prints the ZIP SHA-256 to stdout and does not create a sidecar.
