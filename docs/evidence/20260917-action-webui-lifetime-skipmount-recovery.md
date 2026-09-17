# Action WebUI lifetime + stale skip_mount recovery — 2026-09-17

Target development branch: `vnext-2.1.0-alpha.5`.

## Verified device evidence

On `mustang` after reboot, Thermal/Polling activation is healthy, but standalone Action WebUI still failed. The Action-launched server bound `127.0.0.1:43095` and logged `stopped` in the same second; Chrome then returned `ERR_CONNECTION_REFUSED`. KsuWebUI remained a separate embedded-host path.

A second independent Alpha5 issue was verified before that reboot: stale `skip_mount` could survive with a valid cached layout and same build, so Action never re-entered materialization. A bounded live recovery proved that treating existing `skip_mount` as `needs_materialize=1` safely rematerializes and clears the marker only after validation.

## Root cause and shared-core classification

The browser lifetime defect is generic WebUI lifecycle behavior. Shared template WebUI Core `0.6.2`, commit `619efa89588cc76d081aefb8669aa8c17b1b5ed9`, already contains the canonical HUP-safe Action-server detach contract. This consumer therefore advances its exact pin from Core `0.6.1` to `0.6.2` and mirrors that lifecycle boundary in `tools/webui/launch.sh`.

The stale `skip_mount` recovery is module-specific and is fixed in `action.sh` by making an existing module `skip_mount` marker force guarded rematerialization.

## Repository verification

- Shared Core `0.6.2` `scripts/verify.sh`: PASS, including `WEBUI_CORE_V062_ACTION_BROWSER_LIFETIME_CONTRACT_PASS`.
- Consumer shell syntax: PASS.
- `tests/test-webui-integration.sh`: PASS.
- `tests/test-feedback-package-contract.sh`: PASS.
- `tests/test-vnext-layouts.sh`: PASS.
- `tests/test-vnext-ota-transition.sh`: PASS.

A non-installed local test candidate was built successfully:

- file: `pixel-thermal-memory-control-2.1.0-alpha.5-webui-detach-test1.zip`
- bytes: `2984426`
- entries: `84`
- SHA-256: `f4d92ce9c944ad7cb4c42a5be18366766425b90568d800f04b80a590d7f05c36`
- WebUI pin: `619efa89588cc76d081aefb8669aa8c17b1b5ed9`, Core `0.6.2`

## Installation boundary

This evidence does not claim installed-candidate acceptance. Installing, updating, reflashing, or replacing the installed runtime remains blocked until the exact artifact/source/hash is presented to the user and a fresh unchanged-target approval is received.
