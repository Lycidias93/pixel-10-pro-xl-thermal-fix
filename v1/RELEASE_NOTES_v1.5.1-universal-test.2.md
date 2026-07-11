# v1.5.1-universal-test.2

Prerelease test for Pixel 10 Thermal & Memory Control.

## What changed

- Adds dynamic module manager description:
  - `Polling: 🟢/🟡/🔴/⚪`
  - `Thermal: 🟢/🟡/🔴/⚪`
  - `ZRAM: 🟢/🟡/🔴/⚪`
- Refreshes the manager status line after boot and from the Action button.
- Replaces the Action entry with an extended terminal dashboard.
- Adds Action options for:
  - full status / diagnostics
  - Polling cycle
  - Thermal profile cycle
  - ZRAM toggle/cycle
  - manual debug ZIP
  - Exit
- Keeps the stable public `update.json` channel on `1.5-universal.1`.

## Test scope

This is a prerelease. Install only if you can recover from root module issues.

Expected post-reboot checks:

```text
MODULE_OVERLAY_READY=yes
ACTIVE_VENDOR_MATCH=yes
SAFE_TO_REBOOT=yes
Polling: 🟢
Thermal: 🟢 or ⚪ depending on selected profile
ZRAM: 🟢 or ⚪ depending on selected ZRAM setting
```

## Notes

- No overclock.
- No thermal safety bypass.
- No background status daemon.
- Manager descriptions may be cached by Magisk/KSU; reopen the manager after Action if needed.
- Cycle/reconfigure changes may require reboot for mounted vendor files to become active.

## Stable channel

The stable public update channel remains `1.5-universal.1`.


## Test 2 fix

- Supersedes `v1.5.1-universal-test.1`.
- Fixes ZRAM Ampel false-negative: runtime props plus active `/proc/swaps` now override stale apply-fail markers.
- Adds classic `META-INF/com/google/android/update-binary` and `updater-script` entries to the prerelease ZIP.
- Stable `update.json` remains on `1.5-universal.1`.
