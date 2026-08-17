# Alpha4 WebUI device verification — 2026-08-17

Status: device verification in progress; corrected candidate reinstall passed, final post-reboot WebUI/runtime gate pending.

## Device

- Pixel 10 Pro XL (`mustang`)
- Android 17
- Build `CP2A.260805.005`
- Incremental `15828068`

## Initial alpha4-dev.1 candidate

Candidate head: `3159045dfbf46fcd6e92f1f04e9c1b8ad195a336`
Package SHA-256: `64059e6daa4cf8bab5d19f72cd1a0b9baa1da9440cf7753f030f65d58c740fae`

Post-reboot verification proved:

- module version `2.1.0-alpha.4-dev.1` active;
- Bootguard/runtime verified;
- all three Mustang Thermal overlays matched active vendor files byte-for-byte;
- dynamic validation passed with 22 polling replacements;
- ZRAM 100% active with `lz77eh`;
- LMKD experimental 1% evidence matched the current boot and service was running;
- Page Cluster runtime test applied `0`, proved same-boot ownership, and restored the captured baseline (`0`) successfully;
- support snapshot creation passed;
- no module config or network mutation occurred.

The only initial failure was WebUI startup: `server_binary_missing`.

## Root cause 1 — executable permissions

The CI package contained `bin/webui-server-arm64`, but the installed runtime had both WebUI executables without their execute bits. Root-module manager extraction may normalize ZIP modes. The shared WebUI template already reasserted these permissions; the Pixel consumer installer did not.

Fix: Pixel `customize.sh` now explicitly sets and verifies mode 0755 for `bin/webui-server-arm64` and `bin/module-control`. `tests/test-webui-integration.sh` permanently guards this requirement.

A bounded live permission-heal test proved the packaged runtime file hashes before changing permissions. The server then progressed past the missing-binary gate, proving the first root cause was fixed.

## Root cause 2 — expensive status refresh inside the WebUI self-test

After permissions were repaired, the WebUI server reached its adapter self-test but killed the `module-control status` child at the server self-test deadline: `module-control failed: signal: killed`.

The pinned WebUI core 0.3.1 gives self-test status a 10-second context, while the normal HTTP status endpoint permits 15 seconds. Pixel `module-control status` also performed a full dynamic Thermal compatibility scan on every status GET, making the common UI path unnecessarily expensive.

Consumer fix:

- normal WebUI status now uses the boot/service-owned verified `manager-status.env` cache;
- a missing cache may rebuild via the existing full status helper;
- successful WebUI mutations explicitly refresh that cache before reporting completion;
- explicit validation inventory keeps the full validation refresh path;
- regression tests fail if normal status returns to an unconditional full refresh.

The generic 10s self-test vs 15s runtime timeout mismatch is separately recorded in `Lycidias93/android-root-module-webui-template/docs/WEBUI_CONTROL_TIMEOUT_ALIGNMENT.md` for the next shared-core revision. The Pixel candidate remains pinned to tested core 0.3.1 for this device-test cycle.

## Corrected candidate

Head: `f22caa2b79d6f43ceee60f821997b5c8c7ee2ec7`
CI run: `32037541192` — SUCCESS
Package: `pixel-thermal-memory-control-2.1.0-alpha.4-dev.1.zip`
Package SHA-256: `7d40f28ffdc16f422e3aede08200b6e82297cd0144a6c9dea59cdf0860d7f2a9`
Package bytes: `2670186`
Entries: `79`
Pinned WebUI core: `bc00322bba34ea27cd40cbee9a76190ce39d16e5` / `0.3.1`
Corrected `bin/module-control` SHA-256: `73f994e0e5db83c2cc7488748c32926137637cfe3e4a66ff928d97c4a6980de2`
WebUI server SHA-256: `563b0592087dd418ca064fac2b18064035dc600f754806dcc4f83a039fdf2ec7`

## Corrected candidate reinstall — pre-reboot PASS

Normal Magisk reinstall completed on 2026-08-17 at approximately 16:20 local time.

Observed install evidence:

- installer autosave result: `success` / `install_completed`;
- installed package SHA-256 exactly matched the corrected CI candidate: `7d40f28ffdc16f422e3aede08200b6e82297cd0144a6c9dea59cdf0860d7f2a9`;
- package bytes matched: `2670186`;
- target identity remained Mustang / Android 17 / `CP2A.260805.005` / incremental `15828068` with exact build evidence;
- Dynamic Thermal validation passed for all three controlled files;
- Polling replacements remained 22/22 with no remaining 300000 values and 22 output 5000 values;
- Outdoor Extended +3 C validation passed across 3 files / 12 target zones / 84 threshold values;
- ZRAM selection remained enabled and its 100p layout was materialized;
- generated support snapshot completed successfully with SHA-256 `2ccca18a46440179dbe2c81f3d2a767edce5d759019825cd8b2a2615d509c29a`;
- staged and currently active Thermal overlays were byte-identical for all three controlled Mustang files;
- active runtime before reboot remained healthy: Bootguard full pass, dynamic manifests verified, active vendor match yes, active polling valid, ZRAM 100% active with `lz77eh`, LMKD 1% verified, and `SAFE_TO_REBOOT=yes`;
- active and staged module flags `disable`, `skip_mount`, and `remove` were absent.

The corrected installer has fail-closed 0755 readback checks for both `bin/webui-server-arm64` and `bin/module-control`. Reaching the successful installer completion marker therefore proves the staged corrected candidate passed the WebUI executable-permission gate during normal installation.

The support collector intentionally does not package the WebUI binaries themselves, so execute-bit state is bound to the installer fail-closed evidence rather than inferred from the support archive.

## Remaining gate

Reboot into the corrected candidate. Final acceptance requires the same Thermal/ZRAM/LMKD/Bootguard checks plus WebUI self-test/API PASS after boot with the installer-provided executable permissions and cache-first status path. No alpha4 prerelease promotion is allowed before that final device gate passes.