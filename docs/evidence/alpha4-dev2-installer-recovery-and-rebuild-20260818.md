# Alpha4 dev.2 installer recovery and rebuilt candidate — 2026-08-18

State: RECOVERY_PASS / PI4_LOCAL_CI_PASS / DEVICE_RETRY_READY

## Failed first device-stage attempt

The first `2.1.0-alpha.4-dev.2` device-stage candidate was build-verified but its CLI Magisk install did not return from the volume-key menu. The active module remained `2.1.0-alpha.4-dev.1` / `1016253` before the recovery.

Root cause was the menu key reader wrapping a shell pipeline with `timeout` rather than bounding `getevent` itself. The wrapper shell could terminate while `getevent` kept the command-substitution pipe open, leaving `magisk --install-module` waiting indefinitely.

The installer menu reader now applies `timeout` directly to `getevent`, and if `timeout` is unavailable it fails safe to the currently shown choice instead of waiting without a bound. The vNext CI/local-CI contract now executes the Dev16 installer regression that asserts this behavior.

The old candidate is rejected and must not be staged or rebooted:

- old repo head: `dc5f1345a630198ec0c0c9df7ed807bfc25bd57c`
- old candidate SHA-256: `5bfea75d4b7c3be03aba4a34eeb1bbd33b4d402771cfc082ca966098f3f653aa`
- old candidate bytes: `2,974,503`

## Device recovery

The dedicated recovery lane terminated the stuck install process, inspected the partial stage, and removed the incomplete `modules_update/pixel-10-pro-xl-thermal-fix` tree.

Fresh recovery evidence:

- staged version before cleanup: `2.1.0-alpha.4-dev.2`
- active version after cleanup: `2.1.0-alpha.4-dev.1`
- active versionCode after cleanup: `1016253`
- active WebUI server SHA-256: `563b0592087dd418ca064fac2b18064035dc600f754806dcc4f83a039fdf2ec7`
- active module-control SHA-256: `73f994e0e5db83c2cc7488748c32926137637cfe3e4a66ff928d97c4a6980de2`
- active dev.1 runtime unchanged: PASS
- new candidate staged after recovery: no
- reboot performed: no

Final recovery marker:

`RESULT: PIXEL_THERMAL_ALPHA4_DEV2_HUNG_INSTALL_RECOVERY_PASS`

## Dev16 regression self-heal

Enabling the historical Dev16 regression in the Alpha4 lane exposed two stale fixture assumptions rather than production defects:

1. old stable metadata pins (`2.0.0` / `1016240`) were replaced by version-independent `module.prop` well-formedness checks;
2. the ZRAM materialization fixture was updated to simulate the current three-part install gate: a real `modules_update/<id>` stage plus `MATERIALIZE_NOW=1` and `MATERIALIZE_CALLER=install-zram`.

The production ZRAM guard remained unchanged.

## Rebuilt quota-independent candidate

The final pi4 local-CI run on 2026-08-18 completed successfully with zero GitHub Actions minutes.

Authoritative candidate identity:

- repo head: `aabd15f52b06f9c0747e57641fcc4056013df940`
- workflow blob: `002d6f17c42649753281e9a88b6e3387b8b37fb8`
- WebUI core commit: `cb991dc8d7d982defbe5e34c5c0e0908efa9b236`
- WebUI core version: `0.6.0`
- version: `2.1.0-alpha.4-dev.2`
- versionCode: `1016254`
- candidate SHA-256: `33e1c57ba19af33d91fd3eda9e01467843ebe1602741a874b0dc0b5d0496f775`
- candidate bytes: `2,974,479`
- package entries: `82`
- Android copy path: `/storage/emulated/0/Download/pixel-thermal-memory-control-2.1.0-alpha.4-dev.2-pi4-local-ci-aabd15f52b06f9c0747e57641fcc4056013df940.zip`
- `github_actions_minutes_used=0`

Newly relevant PASS markers include:

- `PASS installer_volume_key_timeout_is_bounded`
- `RESULT: PIXEL_THERMAL_DEV16_INSTALL_REGRESSION_PASS`
- `RESULT: PIXEL_THERMAL_VNEXT_LOCAL_CI_PASS workflow_exit_code=0`
- `RESULT: PI4_ALPHA4_DEV2_LOCAL_CI_REMOTE_PASS`
- `RESULT: PIXEL_THERMAL_ALPHA4_DEV2_PI4_LOCAL_CI_PASS`

The next authoritative step is a new Mustang install/pre-reboot stage using only this rebuilt candidate. No reboot is permitted until that stage is green.