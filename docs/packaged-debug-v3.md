# Packaged debug collector v3

## Version boundary

The public prerelease remains `2.0.0-alpha.3-dev.6`. Its existing packaged collector is not modified in place.

The next test line, `2.0.0-alpha.3-dev.7` (`versionCode=1016218`), adds a unified packaged collector at `tools/bootguard/collect-debug-v3.sh`. The historical path `tools/bootguard/collect-debug.sh` remains as a compatibility entrypoint and forwards to v3.

## Invocation paths

- Installer failure: `tools/debug/install-debug.sh` invokes v3 automatically with `install-failure` context.
- Action menu: Debug → Collect ZIP continues using `collect-debug.sh`, which now forwards to v3.
- Manual root invocation remains possible through the compatibility path.

The packaged collector does not prompt. It derives module and device state itself and accepts optional scenario, selected-profile, previous-profile, and install-mode labels from its caller.

## Evidence added

The archive includes:

- caller, active and staged module views;
- module version and versionCode;
- Fix-5 core, policy, validator, Action, installer-debug and collector hashes;
- stock cache, caller/active/staged overlays and active Vendor hash matrix;
- config, validation state, reports, manifests, health and Bootguard state;
- installer autosave logs from Download;
- Magisk, KernelSU/KernelSU Next, SukiSU, APatch and Mountify evidence;
- current and previous boot logcat, crash buffer, dmesg, pstore, last_kmsg and filtered tombstone markers;
- Thermal, display, power, SurfaceFlinger, ZRAM and pTune state;
- per-file hashes plus final archive hash and byte count.

The success marker is:

`RESULT: PIXEL_THERMAL_PACKAGED_DEBUG_DONE outcome=success workflow_exit_code=0`

## Privacy and safety

The collector is read-only against module and runtime state. It writes temporary files under `/data/local/tmp` and one archive to Download. The archive can contain device, application and system metadata; review `README_REVIEW_BEFORE_UPLOAD.txt` before sharing.
