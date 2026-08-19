# Alpha4 Action WebUI startup-race fix — 2026-08-19

State: ROOT_CAUSE_REPRODUCED / SHARED_TEMPLATE_FIX_MERGED / PIXEL_FIX_MERGED / GITHUB_CI_PASS / DEVICE_ACTION_REVERIFY_PASS / PUBLIC_ALPHA4_PROMOTION_TECHNICALLY_READY

## Device regression

After the earlier Alpha4 dev.2 post-reboot runtime verifier had passed, a later real Magisk Action invocation returned `server_not_ready` from the standalone WebUI launcher and fell back to the legacy Action menu. Thermal, ZRAM and LMKD status remained green, isolating the regression to the Action → browser startup path.

## Root cause

Both the shared WebUI template and Pixel consumer launched the native server in the background and immediately used `/proc/<pid>/cmdline` executable identity as the pre-ready liveness condition. During the short shell fork → native exec transition, the child can be alive while its command line has not yet become the final server command line. The readiness loop could therefore break before the server had a chance to write its ready file.

A local stress reproduction of the same launch/check ordering produced 22 false first-check failures in 500 iterations, confirming the race rather than leaving it as a source-only hypothesis.

The fix uses process liveness during the pre-ready window. Once the server-created ready file exists, executable identity is enforced and the ready-file PID must equal the spawned PID. Security checks therefore move to the point where their identity assumption is valid rather than being weakened.

## Shared WebUI template

Repository: `Lycidias93/android-root-module-webui-template`

- PR: `#11` — `Fix Action WebUI startup race`
- CI run: `32294678979`
- verify, WebUI race regressions, module build and artifact upload: PASS
- merged core commit: `7cf49cafb99664dc2772679bf12c4a8e693b46e8`
- core version remains `0.6.0`

The shared integration test now fails if the old pre-ready `is_our_pid "$SERVER_PID" || break` condition returns and requires the post-ready identity and PID-equality guards.

## Pixel consumer

Repository branch: `vnext-2.1.0-alpha.4`

- PR: `#186` — `Fix Alpha4 Action WebUI startup race`
- PR head: `510da35a7a28d3948aff4735eaa6a63108edf9c3`
- CI synthetic merge: `6a7a7d51e025c146547abb31f5ddf4e25ee189b3`
- squash merge: `df0e7e91f5b31c59f57dc9c13f4d873691d1b216`
- CI synthetic merge tree and squash-merge tree: `6bb17e611010949de28600299399d15e80741853`
- changed paths: `.github/workflows/vnext-2.1-ci.yml`, `dev_tools/run-vnext-local-ci.sh`, `tests/test-webui-integration.sh`, `tools/webui/launch.sh`, `webui.lock`
- Thermal, ZRAM and LMKD implementation paths were not changed.

Pixel CI run `32295207554` passed the pinned shared-core verification, shell checks, full vNext regression set, device-family matrix, device-test package build and artifact upload. GitHub Actions was available for this run; Actions availability is treated as dynamic state rather than a permanent quota condition.

## Bound device-test candidate

CI artifact ID: `9380982777`

- candidate: `pixel-thermal-memory-control-2.1.0-alpha.4-dev.2.zip`
- SHA-256: `94a84f9031b8231cf8e9ef7483959db728aefca35cb738c45202f29f0621c7b4`
- bytes: `2,705,492`
- package entries: `82`
- WebUI core: `7cf49cafb99664dc2772679bf12c4a8e693b46e8`
- package hygiene: PASS
- lean package verification: PASS

Because the CI synthetic merge and the actual squash merge have the same Git tree, this artifact is source-tree-bound to the merged Alpha4 vNext state despite the different commit topology.

## Device Action reverify closure — 2026-08-20

The exact bound candidate was staged on Mustang and activated by a real reboot. The first postboot verifier invocation before that reboot correctly stopped with `modules_update_not_consumed`; no restage was performed. After the reboot, boot ID changed from `0656a74c-b444-4014-ae4e-3e3f4e5212c8` to `9ef82fde-2fde-4c0e-a40d-7c7b475553fe`, proving a new boot boundary and consumption of the staged Magisk update.

Final device evidence:

- device/build: Pixel 10 Pro XL `mustang`, Android 17, `CP2A.260805.005`;
- battery: `58%`;
- active module: `2.1.0-alpha.4-dev.2` / `1016254`;
- active launcher SHA-256: `cfdcafe76d1fd4f90debdcae8a680c94f6c17a892251ee67ca66accf5de036bb`;
- active WebUI server SHA-256: `9a3e439e0a2211ad9478584326087d014bea6c1ac777173df78d80c26d006b21`;
- active `module-control` SHA-256: `8a36260d8f6928bc5742221ae294f3e27814a1a4f756ae7f53d021b03783a351`;
- active `webui.lock` SHA-256: `a2898f63b04164da203c5e9e2ba5cce4da60210b95dbfa0544e81766b023d2d5`;
- real Magisk Action exit: `0`;
- Action preparation: `3040 ms`;
- standalone browser opened successfully on loopback port `43969`;
- ready-file PID `22320` matched the spawned server identity;
- `/api/v1/health`: PASS with `{"ok":true,"service":"root-module-webui"}`;
- status API: PASS with Polling `5s`, Thermal `Outdoor Extended +3°C`, ZRAM `100%`, Memory Killer `1% active`, reboot required `no`;
- `real_action_browser_start=pass`;
- `server_ready_identity=pass`;
- `health_endpoint=pass`;
- `thermal_zram_lmkd_status=pass`;
- `RESULT: PIXEL_WEBUI_OPEN_DONE outcome=success command_exit_code=0 workflow_exit_code=0`;
- `RESULT: PIXEL_THERMAL_ALPHA4_ACTION_RACE_FIX_POSTBOOT_PASS`;
- bound cgrun receipt outcome `success`, command exit `0`.

The real user-facing Action → standalone-browser path is therefore accepted on the target device. The startup-race regression is closed technically. Public Alpha4 publication/update-channel promotion is technically ready, but no public release or update-feed mutation is performed by this verification/evidence change.
