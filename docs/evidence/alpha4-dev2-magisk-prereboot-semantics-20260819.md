# Alpha4 dev.2 Magisk pre-reboot semantics — 2026-08-19

State: ROOT_CAUSE_CONFIRMED / V3_FALSE_POSITIVE / REPAIR_AND_RESTAGE_PENDING

## Observed device result

The rebuilt `2.1.0-alpha.4-dev.2` candidate from repo head `aabd15f52b06f9c0747e57641fcc4056013df940` passed pi4 local CI and was installed on Mustang (`CP2A.260805.005`) through `magisk --install-module`.

Candidate identity:

- SHA-256: `33e1c57ba19af33d91fd3eda9e01467843ebe1602741a874b0dc0b5d0496f775`
- bytes: `2,974,479`
- WebUI server SHA-256: `42ba503ab979920e4ab0fffba41246ea01ccbc2c681b80fb548f342dd0ecf381`
- module-control SHA-256: `8a36260d8f6928bc5742221ae294f3e27814a1a4f756ae7f53d021b03783a351`

The installer completed with `magisk_install_rc=0`. The staged module was `2.1.0-alpha.4-dev.2` / `1016254`; staged flags, runtime content and permissions, full WebUI assets, Thermal layout and validation evidence all passed. The remembered dev.1 feature configuration was restored to Polling `mod`, Thermal `outdoor-extended`, ZRAM enabled standard and LMKD 1%.

## False-positive pre-reboot guard

The handoff then failed only because it required `/data/adb/modules/pixel-10-pro-xl-thermal-fix/module.prop` to remain dev.1 until reboot. After a successful Magisk bootmode module update, that assumption is wrong.

Magisk's documented/source behavior is:

1. candidate runtime files are staged under `/data/adb/modules_update/<id>`;
2. `/data/adb/modules/<id>/update` is created;
3. live `remove` / `disable` markers are removed;
4. the staged candidate `module.prop` is copied into `/data/adb/modules/<id>/module.prop` before reboot;
5. immutable live runtime files remain the accepted baseline until the next reboot merges `modules_update`.

Therefore `active_version_after=2.1.0-alpha.4-dev.2` immediately after successful staging is expected metadata behavior, not evidence that the active runtime payload changed.

The v3 failure marker `active_module_changed_before_reboot` was a verifier false positive. Its rollback removed the staged candidate and restored the feature config, but the next recovery step must explicitly classify and, when safe, repair any candidate metadata/update marker left in the live module directory before re-staging.

## Corrected pre-reboot contract

The replacement verifier must require all of the following before declaring reboot-safe:

- exact candidate ZIP hash/size;
- Mustang / Android 17 / `CP2A.260805.005` identity and battery gate;
- staged module identity dev.2 / `1016254`;
- staged executable/helper hashes and complete WebUI assets;
- staged Thermal validation and intended remembered feature config;
- live `module.prop` candidate identity after successful install (expected Magisk metadata copy);
- live `update` marker present;
- immutable live WebUI server and module-control files still match the accepted dev.1 hashes before reboot;
- no live `remove` / `disable` / `skip_mount` failure flags;
- no reboot in the staging verifier itself.

On failure, rollback must remove only the exact dev.2 stage, clear a stale `update` marker when no candidate stage remains, restore the accepted dev.1 `module.prop` when immutable live runtime hashes prove the dev.1 baseline, and restore the pre-run config backup.

## Local-CI status

The final quota-independent pi4 run for repo head `aabd15f52b06f9c0747e57641fcc4056013df940` passed the complete suite, including the new bounded volume-key installer regression, Dev16 fixtures, WebUI/core/race tests, Thermal/OTA/ZRAM/LMKD/page-cluster regressions, device family matrix, package hygiene and deterministic candidate build.

Final local markers included:

- `RESULT: PIXEL_THERMAL_VNEXT_LOCAL_CI_PASS workflow_exit_code=0`
- `RESULT: PI4_ALPHA4_DEV2_LOCAL_CI_REMOTE_PASS`
- `RESULT: PIXEL_THERMAL_ALPHA4_DEV2_PI4_LOCAL_CI_PASS`

GitHub-hosted Actions remain unavailable through the exhausted included-minute allowance; this local CI path used zero GitHub Actions minutes.
