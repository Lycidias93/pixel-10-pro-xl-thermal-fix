# v1.5.1-universal.1

Stable 1.5.1 promotes the verified Test7 dynamic manager status and Action dashboard release line.

## Highlights

- Manager card now combines each Ampel with its active value:
  - `P:green mod`
  - `T:green outdoor-ext`
  - `Z:green 100p`
- Action dashboard:
  - Status
  - Settings
  - Debug ZIP
  - Advanced
  - Exit
- Settings can reconfigure Polling, Thermal profile and ZRAM.
- Advanced includes pTune status and guarded override controls.
- pTune reporting now separates:
  - known-bad version
  - runtime-specific block
- ZRAM 100p runtime proof uses active swap plus non-zero zram0 disksize.
- Thermal overlay checks are dynamic across present `thermal_info_config*.json` files.
- Profile Matrix verifies all included profile directories and passed with count 67.
- Stable `update.json` now points to this release.

## Verified runtime

- Pixel 10 Pro XL / `mustang`
- Android 17 `CP2A.260605.012`
- Outdoor Extended
- Polling mod
- ZRAM 100p active
- Manager card: `P:green mod | T:green outdoor-ext | Z:green 100p | Action: settings/debug`
- Profile Matrix: PASS count 67

## Runtime and factory-basis status

Stable 1.5.1 remains intentionally honest:

- Runtime-proven on **mustang**.
- Factory-basis covered for all G5 Pixel 10 devices.
- Runtime feedback is still needed for **frankel**, **blazer**, and **rango**.

Runtime PASS:

- `mustang / CP2A.260605.012 / outdoor-extended / polling mod / ZRAM 100p`
- `mustang / CP31.260618.005 / outdoor-plus / polling mod / ZRAM 100p`

Factory-basis PASS:

- `frankel / CP31.260618.005`
- `blazer / CP31.260618.005`
- `mustang / CP31.260618.005`
- `rango / CP31.260618.005`

`CP31.260618.005` is the real QPR1 Beta 6 factory basis for frankel, blazer, mustang and rango.
Do not describe older CP31 profile sources as the current QPR1 basis.

## Credits

Special thanks to **Allen Chang** for the Ampel/Action menu idea, Beta 1/QPR1 testing, runtime verification, screenshots, debug logs, and Pixel 10 build-family feedback.

Also thanks to Harish / Codecity001, JoshuaDoes, and all existing CREDITS.md acknowledgements.

## Notes

- pTune Override remains OFF by default.
- Unknown device/build combinations remain guarded.
- This release does not bypass thermal safety.
