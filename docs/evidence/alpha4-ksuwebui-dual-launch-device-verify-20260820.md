# Alpha4 KsuWebUI dual-launch device verification — 2026-08-20

Status: PASS

## Bound candidate

- Module: `Pixel Thermal & Memory Control`
- Version: `2.1.0-alpha.4`
- Version code: `1016254`
- WebUI Core: `0.6.1`
- Template commit: `6fbd1b018a45fe5b1bebba7aeb9142423eab47fb`
- Pixel PR candidate: PR #187 / head `5420a4808cf6dfba67f72e0366329b0a0ccaa943`

## Device

- Device: Pixel 10 Pro XL (`mustang`)
- Android: 17
- Build: `CP2A.260805.005`
- Postboot ID: `a3594675-75b2-4f3f-bd04-33ba34939dc6`

## Verified behavior

The staged candidate was installed through Magisk, rebooted normally, and verified on the active module.

KsuWebUI path:

- package `io.github.a13e300.ksuwebui`, versionName `1.0`, versionCode `48`;
- exported `.WebUIActivity` opened the module WebUI;
- embedded bootstrap created the standalone loopback server session;
- `topResumedActivity` remained KsuWebUI's `.WebUIActivity`;
- `/api/v1/health` returned `{"ok":true,"service":"root-module-webui"}`;
- the previous embedded-host `404 Not Found` regression was absent;
- result: `ksuwebui_embedded_bootstrap=pass` and `ksuwebui_previous_404_regression=pass`.

Magisk Action path:

- module Action returned success;
- standalone browser WebUI opened in Chrome;
- loopback readiness and health passed;
- result: `magisk_action_browser_bootstrap=pass`.

Combined result:

- `dual_launch=pass`
- `server_scope=loopback_only`
- `thermal_zram_lmkd_status=pass`
- `RESULT: PIXEL_THERMAL_ALPHA4_KSUWEBUI_DUAL_LAUNCH_POSTBOOT_PASS`

## Runtime state preserved

The same postboot status confirmed:

- Polling: `5s`
- Thermal: `Outdoor Extended +3°C`
- ZRAM: `100%`
- Memory Killer: `1% active`
- ZRAM page-cluster: stock/effective `0`, module does not own an experimental write
- active vendor materialization: valid
- reboot required: no

No Thermal, ZRAM, LMKD, page-cluster, DNS, HA, VIP or route behavior was changed by the dual-launch compatibility work.

## Release implication

The reusable compatibility primitive is already merged in `Lycidias93/android-root-module-webui-template` as WebUI Core `0.6.1`.

The existing public `v2.1.0-alpha.4` tag must remain immutable. This device PASS clears the technical gate for merging PR #187 and carrying the KsuWebUI dual-launch feature into the next public prerelease rather than rewriting Alpha4.
