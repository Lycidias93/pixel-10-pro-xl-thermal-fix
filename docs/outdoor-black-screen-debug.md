# Historical Outdoor non-stock black-screen debug flow

## Incident shape

External evidence from Allen Chang established the original failure on Pixel 10 Pro XL (`mustang`) July Canary `ZP11.260618.005`: Stock Thermal booted, while the pre-Fix-5 non-stock implementation failed after the boot animation or remained on the loading bar.

The incident exposed incomplete downstream `VIRTUAL-SKIN*` coordination and several independent intermediate issues in patch validation, support-state reporting, and Action rematerialization.

## Resolution boundary

Harish's confirmed Fix 5 implementation coordinated the locally present downstream Thermal family and `cellular-emergency` while preserving the dedicated `VIRTUAL-SKIN-OVER-35C-TRIGGER` exclusion. That implementation was integrated with the newer policy wrapper, dynamic inventory validation, and transactional Action path in public prerelease `2.0.0-alpha.3-dev.6`.

This document and `tools/debug/collect-outdoor-boot-failure-online.sh` are retained for historical reconstruction of the original incident. They are not the primary handoff for new reports.

## Current collector

Use `tools/debug/collect-thermal-prerelease-online.sh` for current Alpha 3 Dev 6 reports. See `docs/prerelease-online-debug.md`.

The current collector covers:

- clean installs, upgrades, dirty installs, and install failures;
- Action profile transitions, including previous and selected profile labels;
- status-red reports;
- bootloops, loading-bar hangs, and post-animation black screens;
- exact dev.6 release identity and optional local asset verification;
- Fix-5 core, policy wrapper, validator, Action, active/staged module, and Vendor hashes;
- Magisk, KernelSU/KernelSU Next, SukiSU, APatch, and mount-backend state;
- installer autosave logs, canonical validation state, previous-boot evidence, pstore, dmesg, display, and Thermal service state.

## Safety

A successful file-level validation is not by itself a postboot proof for a new device/build tuple. For a failure, stop repeated profile changes, recover to a working boot, preserve `/data/adb/pixel-10-pro-xl-thermal-fix`, and collect immediately. Review the archive before sharing because device and system metadata may be present.
