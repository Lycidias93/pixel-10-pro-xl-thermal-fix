# Next public prerelease — cumulative changes since dev.10

Draft only. This file does not authorize a tag, release asset, update-channel change, or public announcement.

Baseline: `2.0.0-alpha.3-dev.10`, the latest public Alpha prerelease.

## OTA and Bootguard hardening

- Tracks device, Android version, build ID, incremental and fingerprint as the platform tuple.
- Quarantines only this module's three controlled Thermal overlays during a platform transition.
- Recaptures stock sources and republishes an overlay only after local transactional validation.
- Keeps unsupported platforms or failed materialization stock-only.
- Splits Bootguard into previous-attempt evaluation, final-state arming and verified runtime success.
- Requires boot completion, safe compatibility output, expected active-overlay match and Thermal service evidence before clearing the pending state.

## ZRAM 100 percent and Emerald Hill

- Adds lz77eh ZRAM with 100 percent sizing, swappiness 100 and stock THP policy.
- Makes ZRAM 100 percent a Fresh-install default.
- Keeps Emerald Hill adaptive for normal daily use.
- Offers a separate explicit maximum-frequency minimum lock with clear power and heat warning.
- Deduplicates physical `eh_freq` sysfs aliases and stores one baseline per physical device.
- Restores old duplicate baselines using the first true original minimum.
- Removes the unverified LMK swap-low override and leaves Android's stock LMK policy untouched.
- Uses one-shot post-Bootguard application with no permanent watcher.

## Installer, Action and observability

- Makes Polling Mod, ZRAM 100 percent and Verbose Logging the Fresh defaults.
- Verifies all installer and Action menu routes, including Back and timeout behavior.
- Uses one transactional ZRAM layout materializer across installation, Action and standalone helpers.
- Preserves unrelated configuration when pTune override is disabled.
- Separates pTune, ZRAM and Emerald Hill risk receipts.
- Makes Magisk staging idempotent when the packaged ZRAM fstab already matches the destination.
- Preserves exact materializer failure evidence in `guard/install-zram-layout.log`.
- Fixes packaged-debug copy helpers so destination paths cannot compound.
- Preserves complete install evidence while merging current runtime state after boot.
- Treats explicitly selected Thermal profiles, including Outdoor Extended, as valid choices rather than requiring Stock.

## Regression coverage

- Adds platform-transition and Bootguard-v3 regression tests.
- Adds fake-devfreq alias, decoy-node, maximum-lock and legacy-baseline restore fixtures.
- Adds full installer/Action route and helper-side-effect matrices.
- Adds Magisk staging behavior that rejects replacing an existing destination.
- Adds boot-time install-state preservation and second-boot idempotence tests.
- Keeps older dev.12, dev.14, dev.15 and lean-package contracts running in CI.

## Live Mustang evidence collected after dev.10

- dev.13 repair verification restored adaptive Emerald Hill at 200–1066 MHz while keeping ZRAM 100 percent, lz77eh and swappiness 100 active.
- dev.16 installation completed with the exact CI package hash and successfully materialized Polling Mod, Outdoor Extended, ZRAM 100 percent, adaptive Emerald Hill, pTune off and Verbose Logging.
- dev.16 post-reboot runtime verified Thermal overlay integrity, 22 active 5000 polling replacements, active 100 percent ZRAM, lz77eh, swappiness 100, stock LMK policy and adaptive Emerald Hill.
- The dev.16 checker recorded 124 PASS and two nonfatal generic Thermal-process/logcat warnings; the remaining failures were checker expectation and install-state preservation issues addressed by dev.17.

## Public prerelease gate

Before publication, the selected candidate still requires:

- fresh installation of the exact CI artifact;
- successful post-reboot device verification;
- exact ZIP hash, size and entry-count binding;
- final cumulative release notes derived from this draft;
- explicit fresh release GO before tag, asset, update channel or announcement.
