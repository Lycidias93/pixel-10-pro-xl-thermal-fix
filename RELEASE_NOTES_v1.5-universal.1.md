# Pixel 10 Thermal & Memory Control 1.5

Stable release: 1.5-universal.1
Since last public stable: 1.4.12-universal.1

## What changed

- Promotes the verified Test25-Test29 cleanup chain to stable.
- Keeps the verified ZRAM 100p path and post-reboot runtime behavior.
- Keeps previous install choices with the Use-last flow, without repeated option menus.
- Uses the cleaner install-time thermal overlay and ZRAM helper structure.
- Adds the Harish / Codecity001 profile-layout mapping audit as read-only helper/docs.

## Verified on

- Pixel 10 Pro XL / mustang.
- Android 17 CP2A.260605.012 / incremental 15430684.
- Outdoor Extended, polling mod, pTune Override OFF, ZRAM 100p.
- ZRAM runtime PASS; thermal tombstone index empty or absent.
- Final Stable 1.5 post-reboot verification PASS: active 1.5-universal.1, public update channel 1.5, ZRAM runtime PASS, thermal tombstone index empty or absent.

## Credits

- Harish / Codecity001, JoshuaDoes, Allen Chang, Jiggs, maicol07, and existing CREDITS.md acknowledgements.
- Detailed acknowledgements remain in CREDITS.md.

## Not included

- No TensorConservative sysfs/procfs writes.
- No direct profile resolver layout switch.
- No new runtime tuning beyond the verified Test25-Test29 chain.
