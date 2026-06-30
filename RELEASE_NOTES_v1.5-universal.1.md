# Pixel 10 Thermal & Memory Control 1.5

Stable release: 1.5-universal.1
Since last public stable: 1.4.12-universal.1

## What changed since v1.4.12-universal.1

### Install / UX

- Use-last flow: previous choices are reused without repeated option menus.
- Fresh-default fallback added when no saved settings exist.
- Cleaner installer output for Stable 1.5.
- Public update channel now points to 1.5-universal.1.

### Thermal

- Outdoor Extended path verified and promoted.
- Thermal overlay materialization moved into a dedicated helper.
- Polling mod path preserved and verified.
- pTune Override remains OFF by default.

### ZRAM / Memory

- ZRAM 100p install path moved into helper logic.
- Boot-early resetprop-rs ZRAM path verified.
- Post-reboot ZRAM runtime PASS.

### Safety / Compatibility

- Known-bad pTune conflict guard preserved.
- No TensorConservative sysfs/procfs writes.
- No direct profile resolver layout switch.
- No new runtime tuning beyond the verified Test25-Test29 chain.

### Profile / Refactor

- Harish / Codecity001 profile-layout mapping audit added as read-only helper/docs.
- G4 legacy outdoor variants preserved in mapping audit.
- Test25-Test29 cleanup chain promoted to stable.

## Verified on

- Pixel 10 Pro XL / mustang.
- Android 17 CP2A.260605.012 / incremental 15430684.
- Outdoor Extended, polling mod, pTune Override OFF, ZRAM 100p.
- ZRAM runtime PASS.
- Thermal tombstone index empty or absent.
- Final Stable 1.5 post-reboot verification PASS: active 1.5-universal.1, public update channel 1.5, ZRAM runtime PASS, thermal tombstone index empty or absent.

## Credits

- Harish / Codecity001, JoshuaDoes, Allen Chang, Jiggs, maicol07, and existing CREDITS.md acknowledgements.
- Detailed acknowledgements remain in CREDITS.md.

## Artifact

- ZIP: pixel-10-thermal-memory-control-1.5-universal.1.zip
- SHA256: 225013f7e51cb29b1ceebb1460f6f5125c134518ae900c2587f4416c2b6f057f
