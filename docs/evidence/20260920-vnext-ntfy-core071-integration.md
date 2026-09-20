# vNext optional ntfy / WebUI Core 0.7.1 integration evidence

Date: 2026-09-20
Issue: #213
Base vNext source: vnext-2.1.0-alpha.9 at 7ec0b77c4837197d1c2a06e8103f93597a386b8a
Shared WebUI pin: Core 0.7.1, template commit 3f49704701d8ab665139cf3551aa9197610cbaaa

## Scope

The post-Alpha9 vNext source adopts the shared Notifications V1 contract instead of implementing module-specific HTTP/UI transport. The module-owned adapter enables provider ntfy, secret-safe status and test operations, and lifecycle events start, success, fail, and warn.

Private provider values remain in /data/adb/pixel-10-pro-xl-thermal-fix/config.env. The shared allowlisted loader reads only the supported NTFY_* keys and never sources/evaluates the file. WebUI status/test responses contain no endpoint, topic, token-file path or token value.

## Module lifecycle mapping

- detected runtime/config-state drift: warn
- confirmed state correction/materialization and successful typed actions: success
- typed action or device-verification failure: fail
- support-snapshot job start: start
- notification delivery failure: non-fatal to the primary module operation

## Diagnostic secret boundary

Existing support collectors previously copied the private module config.env into support output. With ntfy configuration in that file, this became incompatible with the Notifications V1 secret boundary. The current vNext source therefore routes support configuration snapshots through tools/debug/copy-config-redacted.sh; NTFY_URL, NTFY_TOPIC and NTFY_TOKEN_FILE are replaced with REDACTED. zram-debug.sh uses the same helper and has no raw-config fallback.

## Repository verification

The shared Core 0.7.1 verifier passed including Notifications HTTP contract, ntfy library fake transport, Action PID identity, HUP survival and static asset route parity.

Consumer regressions passed:
- RESULT: PIXEL_WEBUI_NTFY_INTEGRATION_PASS
- RESULT: PIXEL_NTFY_CONFIG_REDACTION_PASS
- RESULT: PIXEL_WEBUI_INTEGRATION_TEST_PASS
- RESULT: PIXEL11_FEEDBACK_PACKAGE_CONTRACT_PASS
- RESULT: VNEXT_DEVICE_VERIFY_CONTRACT_PASS

A staged consumer package built successfully after the integration and package hygiene/validation passed. Exact installed-candidate WebUI acceptance remains required before any public prerelease publication because the template pin, adapter surface and package bytes changed.

## Publication boundary

This document records unreleased vNext source integration only. It does not change the published Alpha9 release identity, asset or update channel. A future publication requires a newly built candidate bound to the merged source plus exact-device WebUI acceptance.
