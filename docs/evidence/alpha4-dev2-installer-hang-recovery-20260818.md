# Alpha4 dev.2 installer hang recovery — 2026-08-18

Status: RECOVERY_PASS / OLD_CANDIDATE_INVALIDATED

## Observed failure

- Candidate: `pixel-thermal-memory-control-2.1.0-alpha.4-dev.2-pi4-local-ci-dc5f1345a630198ec0c0c9df7ed807bfc25bd57c.zip`
- Candidate SHA-256: `5bfea75d4b7c3be03aba4a34eeb1bbd33b4d402771cfc082ca966098f3f653aa`
- Magisk CLI install remained blocked in the install-options volume-key reader and did not return.
- The old device-test lane was terminated by the dedicated recovery lane; the install therefore ended with `STOP: magisk_install_failed` and was not accepted as a candidate install.

## Recovery evidence

Recovery lane: `thermal-alpha4-dev2-recovery`

Observed result:

- `stage_present_before_cleanup=yes`
- staged metadata was `2.1.0-alpha.4-dev.2`
- active metadata before cleanup remained `2.1.0-alpha.4-dev.1` / `1016253`
- staged candidate cleanup: `removed`
- active update marker: `not_present`
- active metadata restore: `not_needed`
- active version after cleanup: `2.1.0-alpha.4-dev.1` / `1016253`
- active WebUI server SHA-256: `563b0592087dd418ca064fac2b18064035dc600f754806dcc4f83a039fdf2ec7`
- active module-control SHA-256: `73f994e0e5db83c2cc7488748c32926137637cfe3e4a66ff928d97c4a6980de2`
- `active_dev1_runtime_unchanged=pass`
- `safe_to_reboot=no_new_candidate_not_staged`
- `RESULT: PIXEL_THERMAL_ALPHA4_DEV2_HUNG_INSTALL_RECOVERY_PASS`

No reboot occurred during the failed install or recovery.

## Root cause and permanent fix

The installer menu reader wrapped a shell pipeline with `timeout`, allowing a `getevent` descendant to retain the command-substitution pipe after the wrapper exited. This could leave CLI installs blocked indefinitely.

Permanent fixes on `vnext-2.1.0-alpha.4`:

- `0693581b3c427b6120a10292959dda9289753db3` — bound timeout directly to `getevent` and fail-safe when `timeout` is unavailable.
- `ebd118200c97929f1b3aafee1c23db2d06347825` — added the installer timeout regression contract.
- `9d5254d117ced5df5467b307d1857f3e3b47bb87` — wired `menu-cycle.sh` syntax and the installer regression into vNext CI.
- `50a7289bb186549f6c2af5e50ba4188d30d1b3d2` — synchronized the quota-independent local CI runner with the updated workflow contract.

## Candidate policy

The SHA-256 `5bfea75d4b7c3be03aba4a34eeb1bbd33b4d402771cfc082ca966098f3f653aa` is rejected for further installation or reboot acceptance. A replacement build must be produced from a commit containing the permanent fixes and must pass the full local CI/package contract before any new Pixel staging attempt.
