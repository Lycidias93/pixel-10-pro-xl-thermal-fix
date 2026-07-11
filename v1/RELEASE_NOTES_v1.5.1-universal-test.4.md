# v1.5.1-universal-test.4

Prerelease test for Pixel 10 Thermal & Memory Control.

## What changed

- Keeps the dynamic manager Ampel from test3.
- Keeps the ZRAM runtime false-negative fix.
- Keeps classic `META-INF` installer entries.
- Renames the action flow to `status/settings/debug`.
- Makes the Action UI menu loop back after completed actions.
- Adds explicit `Back` options to Action and Settings submenus.
- Shows compact status before creating a debug ZIP.
- Returns to the Action menu after debug ZIP creation.
- Stable `update.json` remains on `1.5-universal.1`.

## Verify target

- Manager card: `Polling: green Thermal: green ZRAM: green`
- Action menu:
  - `1 Status`
  - `2 Settings`
  - `3 Debug ZIP`
  - `4 Back`
- Settings menu:
  - `1 Polling`
  - `2 Thermal`
  - `3 ZRAM`
  - `4 Back`
