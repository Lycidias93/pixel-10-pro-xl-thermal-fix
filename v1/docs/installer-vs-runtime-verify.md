# Installer-vs-runtime verify evidence scope

## Purpose

vNext 1.5.2 separates evidence sources so verify scripts do not produce false failures after reboot.

Some files are install-time or repo documentation evidence and are not guaranteed to remain in the active Magisk/KSU module path after reboot.

Known examples:

- `customize.sh` is installer-side evidence.
- `README.md` is repo/ZIP documentation evidence and may be absent under `/data/adb/modules/...` after reboot.
- Runtime evidence must come from active module files, guard state, status tools and live kernel/runtime state.

## Evidence classes

### Runtime evidence

Runtime evidence is read from the active module path, normally:

`/data/adb/modules/pixel-10-pro-xl-thermal-fix`

Runtime evidence includes:

- `module.prop`
- `update.json`
- `guard/manager-status.env`
- `tools/status-lib.sh`
- `tools/compat-check.sh`
- `tools/profile-matrix-verify.sh`
- active overlay files under `system/vendor/etc`
- `/proc/swaps`
- `/sys/block/zram0/disksize`

Runtime evidence is used for:

- active version/versionCode,
- manager Ampel text,
- thermal overlay readiness,
- active vendor match,
- safe-to-reboot state,
- ZRAM runtime state,
- pTune runtime conflict state.

### ZIP / install-only evidence

ZIP or install-time evidence includes files that may be used during installation but not retained in the active module path after reboot.

Examples:

- `customize.sh`
- installer UI wording,
- installer-only menu text,
- full package documentation included in the ZIP.

Use ZIP extraction or install autosave for this class.

### Repo/docs evidence

Repo/docs evidence includes files that are authoritative for documentation but may not be part of the active runtime path.

Examples:

- `README.md`
- planning docs under `docs/`
- release policy text,
- source comments and development-only notes.

## Tool

`tools/verify-evidence-scope.sh` supports three modes:

```text
tools/verify-evidence-scope.sh runtime /data/adb/modules/pixel-10-pro-xl-thermal-fix
tools/verify-evidence-scope.sh repo .
tools/verify-evidence-scope.sh zip /path/to/unzipped/module
```

The tool emits `PASS`, `WARN`, `FAIL`, and final `RESULT:` markers.

## Guard principles

- Missing `customize.sh` in runtime mode is `INFO`, not `FAIL`.
- Missing `README.md` in runtime mode is `INFO`, not `FAIL`.
- Stale current-basis claims remain `FAIL`.
- Runtime status must not be inferred from repo-only files.
- Repo docs must not claim runtime support for devices without runtime logs.

## Stable 1.5.1 baseline

Stable 1.5.1 remains:

- Runtime-proven on **mustang**.
- Factory-basis covered for all G5 Pixel 10 devices.
- Runtime feedback still needed for **frankel**, **blazer**, and **rango**.
