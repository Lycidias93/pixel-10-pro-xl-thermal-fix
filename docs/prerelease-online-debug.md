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

Use `tools/debug/collect-thermal-prerelease-online-menu.sh` for public interactive handoffs. It asks the four incident questions itself, downloads the immutable collector engine, verifies its Git blob, and starts it through root.

The engine remains `tools/debug/collect-thermal-prerelease-online.sh`. It can still be called directly with four explicit arguments for automated or developer-controlled collection. The previous `collect-outdoor-boot-failure-online.sh` remains available only for reconstructing the original pre-Fix-5 Canary incident.

All online debug scripts are repo-only and excluded from the flashable module ZIP.

## Interactive questions

The launcher presents numbered choices for:

1. scenario: `clean-install`, `action-switch`, `boot-failure`, `status-red`, `install-failure`, or `unknown`;
2. selected profile: `stock`, `outdoor-safe`, `outdoor-plus`, `outdoor-extended`, or `unknown`;
3. previous profile: the same set plus `none`;
4. install mode: `clean`, `upgrade`, `dirty`, or `unknown`.

Pressing Enter accepts the displayed safe default. The launcher reads from normal stdin and does not force `/dev/tty`.

## What it records

The collector records:

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

## Installer and packaged collector boundary

The published dev.6 installer autosave remains useful. It captures package hash and size, battery and power state, device/build tuple, root/backend classification, selected profile state, pTune policy, install-state, and a filtered Thermal logcat.

It is not silently changed after publication. The next test identity, dev.7, expands the installer fields and ships `tools/bootguard/collect-debug-v3.sh`. Install failures invoke it automatically, while Action → Debug → Collect ZIP reaches it through the existing compatibility path. The packaged v3 collector adds caller/active/staged module views, Fix-5 runtime hashes, previous-boot evidence, KernelSU logs, installer autosaves and explicit scenario/profile labels. See `docs/packaged-debug-v3.md`.

For reports from the currently public dev.6 package, the repo-only online collector remains the preferred complete handoff because it supplements the older packaged data without changing the released ZIP.

## Required handling

- Do not wipe `/data/adb/pixel-10-pro-xl-thermal-fix` before collection.
- For a boot failure, recover first and collect immediately after the next successful boot.
- Review `README_REVIEW_BEFORE_UPLOAD.txt` before sharing the archive.
- Send the archive together with the approximate failure time and a one-line description of the selected transition.
