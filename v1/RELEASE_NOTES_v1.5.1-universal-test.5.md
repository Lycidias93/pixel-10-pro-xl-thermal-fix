# v1.5.1-universal-test.5

Prerelease final hardening for Pixel 10 Thermal & Memory Control.

## What changed

- Combines each manager Ampel with its active value:
  - `P:🟢 mod`
  - `T:🟢 outdoor-ext`
  - `Z:🟢 100p`
- Changes manager action text to `Action: settings/debug`.
- Uses active ZRAM swap plus non-zero `zram0/disksize` as primary runtime proof.
- Keeps ZRAM props as supporting evidence.
- Makes thermal overlay checks dynamic across present `thermal_info_config*.json` files.
- Handles missing `menu-cycle.sh` gracefully in Action mode.
- Splits visible installer debug/autosave output.
- Keeps stable `update.json` on `1.5-universal.1`.

## Verify target

`P:🟢 mod | T:🟢 outdoor-ext | Z:🟢 100p | Action: settings/debug`
