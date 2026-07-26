# Outdoor non-stock black-screen debug flow

## Incident shape

External evidence from Allen Chang:

- Source and Polling indicators are green.
- Stock Thermal boots successfully.
- Any non-stock Thermal profile reaches the end of the boot animation and then shows a black screen before the normal progress bar appears.

This is treated as a boot-safety incident. Structural JSON, diff-boundary, and Outdoor-delta validation do not by themselves prove runtime safety on another device/build tuple.

## Collector

Use `tools/debug/collect-outdoor-boot-failure-online.sh` from the current `v2` branch. The collector is independent of the version installed inside the Magisk module.

It is read-only against module and runtime state. It writes only one archive to `Download` and temporary files under `/data/local/tmp`.

The collector records:

- the failing profile supplied as its first argument;
- device, build, boot reason, slot, verified-boot state, and current boot completion;
- active and staged module metadata, flags, install state, health, Bootguard, and manager state;
- canonical validation state, reports, manifests, source cache, module overlays, and active `/vendor/etc` files;
- current runtime mounts, processes, properties, thermal/display/power/SurfaceFlinger state, dmesg, Magisk and pTune state;
- filtered current-boot logcat;
- filtered previous-boot logcat through `logcat -L` when supported;
- pstore/ramoops, `/proc/last_kmsg` when available, crash buffer, tombstone index, and filtered recent tombstone markers;
- SHA-256 and byte size for every collected file and for the final archive.

## Required sequence

1. Record the exact failed profile: `outdoor-safe`, `outdoor-plus`, or `outdoor-extended`.
2. Reproduce the failed boot.
3. Recover without wiping module data. Prefer disabling the module or returning to Stock Thermal; do not clear `/data/adb/pixel-10-pro-xl-thermal-fix` before collection.
4. Boot Android, unlock it, and run the current online collector once.
5. Send the resulting archive plus the approximate time at which the black screen began.

The user does not need to type during the black screen. The collector attempts to recover previous-boot evidence from `logcat -L`, pstore/ramoops, and bootreason after the next successful boot.

## Privacy

The collector filters logcat to boot, display, thermal, Magisk, mount, crash, and SELinux-related terms, but the archive can still contain device identifiers and system metadata. Review `README_REVIEW_BEFORE_UPLOAD.txt` before sharing.

## Safety boundary

Until external non-stock boot evidence is understood, Stock Thermal is the safe default. Polling and ZRAM remain separate features. A structurally valid non-stock overlay must not be considered runtime-proven solely because its files and expected delta validate.