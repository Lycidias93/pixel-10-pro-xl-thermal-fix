# Current prerelease online debug flow

## Bound prerelease

The current public test line is:

- version: `2.0.0-alpha.3-dev.6`
- versionCode: `1016217`
- tag: `v2.0.0-alpha.3-dev.6`
- target commit: `fb9caca5ca7a1f147945a500afd586dd3cd0d4d6`
- asset: `pixel-10-thermal-memory-control-2.0.0-alpha.3-dev.6.zip`
- SHA-256: `b6c7d14edc49ddded30094b984b66c0dac40d436360461bb55e5fd630148a0b9`
- bytes: `307127`

Use `tools/debug/collect-thermal-prerelease-online.sh` for new reports against this line. The previous `collect-outdoor-boot-failure-online.sh` remains available only for reconstructing the original pre-Fix-5 Canary incident.

The current collector is repo-only and is excluded from the flashable module ZIP.

## What it records

The collector accepts four labels:

1. scenario: `clean-install`, `action-switch`, `boot-failure`, `status-red`, `install-failure`, or `unknown`;
2. selected profile: `stock`, `outdoor-safe`, `outdoor-plus`, `outdoor-extended`, or `unknown`;
3. previous profile: the same set plus `none`;
4. install mode: `clean`, `upgrade`, `dirty`, or `unknown`.

It records:

- the exact expected dev.6 release identity and any local copy of the public asset;
- active and staged module version/versionCode;
- Fix-5 core, policy wrapper, validator, Action dashboard, and related runtime-file hashes;
- selected and previous profiles so Action transitions can be reconstructed;
- stock source, persistent cache, generated overlays, active Vendor files, hashes, and sizes;
- canonical validation state, patch manifest, Outdoor inventory report, Bootguard state, health log, and config;
- recent installer autosave logs already present in Download;
- Magisk, KernelSU/KernelSU Next, SukiSU, APatch, Mountify, and module inventory evidence;
- current and previous boot logcat, crash buffer, dmesg, pstore, last_kmsg, tombstone markers, display, power, SurfaceFlinger, and Thermal service state;
- pTune and ZRAM state;
- an SHA-256 manifest for every collected file and the final archive.

## Installer verbose-log assessment

The dev.6 installer autosave is still useful. It already captures package hash and size, battery and power state, device/build tuple, root/backend classification, selected profile state, pTune policy, install-state, and a filtered Thermal logcat. On install failure it also invokes the packaged full debug collector.

It should not be treated as a complete report by itself for Action-switch or postboot failures. The online collector imports the installer autosaves and adds the missing active/staged hashes, canonical validation files, Fix-5 runtime-core identity, previous-boot evidence, KernelSU logs, and transition labels. Therefore the published dev.6 ZIP does not need to be silently changed only for logging; any future packaged installer-log expansion belongs to a new version identity.

## Required handling

- Do not wipe `/data/adb/pixel-10-pro-xl-thermal-fix` before collection.
- For a boot failure, recover first and collect immediately after the next successful boot.
- Review `README_REVIEW_BEFORE_UPLOAD.txt` before sharing the archive.
- Send the archive together with the approximate failure time and a one-line description of the selected transition.
