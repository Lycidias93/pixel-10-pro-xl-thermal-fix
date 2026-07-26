# Outdoor non-stock black-screen debug flow

## Incident shape

External evidence from Allen Chang:

- Device: Pixel 10 Pro XL (`mustang`).
- Build: July Canary `ZP11.260618.005`.
- Source and Polling indicators are green.
- Stock Thermal boots successfully.
- Any non-stock Thermal profile reaches the end of the boot animation and then shows a black screen before the normal progress bar appears.
- Clean-flash versus upgrade install must be recorded with the diagnostic run.

This is treated as a boot-safety incident. Structural JSON, diff-boundary, and Outdoor-delta validation do not by themselves prove runtime safety on another device/build tuple.

## Collector

Use `tools/debug/collect-outdoor-boot-failure-online.sh` from the current `v2` branch. The collector is independent of the version installed inside the Magisk module and remains repo-only; it is deliberately excluded from the flashable ZIP.

It is read-only against module and runtime state. It writes only one archive to `Download` and temporary files under `/data/local/tmp`.

The first argument records the failed profile. The second argument records whether the module was installed as `clean`, `upgrade`, or `unknown`.

The collector records:

- the failing profile and clean/upgrade state;
- device, build, boot reason, slot, verified-boot state, and current boot completion;
- active and staged module metadata, flags, install state, health, Bootguard, and manager state;
- canonical validation state, reports, manifests, source cache, module overlays, and active `/vendor/etc` files;
- a dedicated `stock-source/` set containing the three requested stock Thermal files;
- preferred stock extraction from the Magisk mirror, then the exact persistent original cache, with active `/vendor/etc` used only as a clearly marked fallback;
- a hash/byte matrix comparing stock source, persistent cache, active/staged overlays, and active Vendor files;
- current runtime mounts, processes, properties, thermal/display/power/SurfaceFlinger state, dmesg, Magisk and pTune state;
- filtered current-boot logcat;
- filtered previous-boot logcat through `logcat -L` when supported;
- pstore/ramoops, `/proc/last_kmsg` when available, crash buffer, tombstone index, and filtered recent tombstone markers;
- SHA-256 and byte size for every collected file and for the final archive.

## Required sequence

1. Record the exact failed profile: `outdoor-safe`, `outdoor-plus`, or `outdoor-extended`.
2. Record whether this was a clean module install or an upgrade install.
3. Reproduce the failed boot only when recovery is available.
4. Recover without wiping module data. Prefer disabling the module or returning to Stock Thermal; do not clear `/data/adb/pixel-10-pro-xl-thermal-fix` before collection.
5. Boot Android, unlock it, and run the current online collector once.
6. Send the resulting archive plus the approximate time at which the black screen began.

The user does not need to type during the black screen. The collector attempts to recover previous-boot evidence from `logcat -L`, pstore/ramoops, and bootreason after the next successful boot.

Harish's request for the stock Thermal files is satisfied by the `stock-source/` directory inside the same archive. A separate root file manager copy is not required.

## Privacy

The collector filters logcat to boot, display, thermal, Magisk, mount, crash, and SELinux-related terms, but the archive can still contain device identifiers and system metadata. Review `README_REVIEW_BEFORE_UPLOAD.txt` before sharing.

## Safety boundary

Until the external non-stock boot failure is understood, Stock Thermal is the safe default on `mustang/ZP11.260618.005`. Polling and ZRAM remain separate features. A structurally valid non-stock overlay must not be considered runtime-proven solely because its files and expected delta validate.
