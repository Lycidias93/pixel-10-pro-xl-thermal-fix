# Action WebUI lifetime + stale skip_mount recovery — 2026-09-17

Target development branch: `vnext-2.1.0-alpha.5`.

## Verified device evidence

On `mustang` after reboot, Thermal/Polling activation is healthy, but standalone Action WebUI still failed. The Action-launched server bound `127.0.0.1:43095` and logged `stopped` in the same second; Chrome then returned `ERR_CONNECTION_REFUSED`. KsuWebUI remained a separate embedded-host path.

A second independent Alpha5 issue was verified before that reboot: stale `skip_mount` could survive with a valid cached layout and same build, so Action never re-entered materialization. A bounded live recovery proved that treating existing `skip_mount` as `needs_materialize=1` safely rematerializes and clears the marker only after validation.

## Root cause and shared-core classification

The browser lifetime defect is generic WebUI lifecycle behavior. Initial staging against shared Core `0.6.2` exposed a second defect in the generic contract: the launcher correctly inherited `SIGHUP=ignore`, but the Go server subscribed to `SIGHUP` with `signal.Notify`, re-enabling delivery and shutting down on HUP. Shared template Core `0.6.5`, commit `dc95d5821fdea323efaf8c4ddc459a0644f8e66d`, removes SIGHUP from the server shutdown subscription and adds runtime HUP-survival verification. This consumer therefore advances its exact pin from Core `0.6.1` to `0.6.5` and mirrors the detached launcher lifecycle boundary in `tools/webui/launch.sh`.

The stale `skip_mount` recovery is module-specific and is fixed in `action.sh` by making an existing module `skip_mount` marker force guarded rematerialization.

## Repository verification

- Shared Core `0.6.5` `scripts/verify.sh`: PASS, including `WEBUI_SERVER_HUP_SURVIVAL_PASS` and the existing Action-browser lifetime contract.
- Consumer shell syntax: PASS.
- `tests/test-webui-integration.sh`: PASS.
- `tests/test-feedback-package-contract.sh`: PASS.
- `tests/test-vnext-layouts.sh`: PASS.
- `tests/test-vnext-ota-transition.sh`: PASS.

A non-installed local test candidate was built successfully:

- file: `pixel-thermal-memory-control-2.1.0-alpha.5-webui-detach-core065-test1.zip`
- bytes: `2985299`
- entries: `84`
- SHA-256: `79fabd76408562ed492801f3c80e8201f420f0191e8363e3e43cf20692161e3a`
- WebUI pin: `dc95d5821fdea323efaf8c4ddc459a0644f8e66d`, Core `0.6.5`

## Installation boundary

This evidence does not claim installed-candidate acceptance. Installing, updating, reflashing, or replacing the installed runtime remains blocked until the exact artifact/source/hash is presented to the user and a fresh unchanged-target approval is received.
