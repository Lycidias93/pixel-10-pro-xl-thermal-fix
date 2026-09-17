# Alpha6 WebUI Android dry-run release blocker and Core 0.6.6 remediation

Date: 2026-09-17

## Exact accepted/install context

The public Alpha6 candidate `4a7694f6abaa5b2766c487114037819f1274b0c5e10226e48bac2dac4693526c` installed and rebooted on `mustang` / `CP3A.260905.009`. Postboot runtime identity matched the candidate, including `webui-server-arm64` SHA-256 `67cc1a359950bdd1822c2b514c0ec017e3fbb9698f6dc0452f7112e6a69dc41c`. The device verifier reported complete evidence, `verdict=pass`, `failure_count=0`, with 23/23 polling replacements, Outdoor Extended +3 C, ZRAM 100% and LMKD 1% active.

## Release-blocking WebUI finding

The exact installed candidate failed the deeper WebUI release audit: an authenticated `POST /api/v1/action` carrying `dry_run=true` entered the productive adapter path and could mutate persistent module config. A bounded reproduction with the already-active `debug-verbose` action timed out while the config hash changed. Publication therefore remained blocked and the public prerelease channel stayed on Alpha5.

Root cause was the module-owned `json_bool()` using GNU-style BRE alternation `\(true\|false\)` in `sed`. Android/Toybox-compatible behavior did not reliably parse that expression, yielding an empty value; the adapter then defaulted the missing value to `false`.

## Shared-core remediation

Generic remediation landed in `Lycidias93/android-root-module-webui-template` Core `0.6.6`, merged main commit `0d5c724711733b6f794790ef96d718e96c64c258`. Boolean extraction now avoids BRE alternation and validates the scalar with shell `case`; the template includes an Android-like portability regression.

## Consumer remediation requirements

This Pixel consumer must pin Core 0.6.6, update its module-owned boolean parser, run the consumer portability regression plus pinned-core verification, rebuild Alpha6, and repeat exact-candidate device/WebUI release acceptance. Any rebuilt ZIP has a new immutable identity and needs a fresh installation approval before device flashing.

## Parallel Pixel 11 hardware lane

PR #199 remains a separate hardware-gated Pixel 11/Tensor G6 test lane. Live readback on 2026-09-17 confirmed head `c9980e8270d5bde4b54a506d2de40f540ac3b5eb`, base `vnext-2.1.0-alpha.5`, exact-head `vNext 2.1 CI` run #238 success, and an open hardware merge gate. Do not merge it merely because CI is green; do not create a Harish-specific release stream or message Harish unless explicitly requested.
