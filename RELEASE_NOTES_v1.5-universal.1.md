# Pixel 10 Thermal & Memory Control 1.5

Stable release: 1.5-universal.1

## Verified refactor chain

- Test25: install-time ZRAM materialization and menu helper extracted, runtime PASS.
- Test26: debug and compatibility forbidden-token cleanup, runtime PASS.
- Test27: install-time thermal overlay helper extracted, runtime PASS.
- Test28: Use last settings short-circuit and no-saved fallback, runtime PASS.
- Test29: Harish / Codecity001 profile layout mapping docs/helper, runtime PASS.

## Verified behavior

- Pixel 10 Pro XL / mustang / Android 17 CP2A.260605.012 / 15430684.
- Outdoor Extended profile.
- Polling mod.
- pTune Override OFF.
- ZRAM 100p runtime PASS.
- Thermal tombstone index empty or absent.
- G4 legacy variants preserved in mapping audit.

## Credits since last public stable

- Harish / Codecity001: profile layout refactor concept and mockup reference for Test29.
- Harish / Codecity001: PR70 ZRAM resetprop-rs boot_early rework, script cleanup, debug-gating feedback, Pixel test iteration.
- Harish / Codecity001: install/runtime testing, ZRAM debug logs, reboot verification, issue reports, Volume-key ZRAM selection, Magisk Action UX recommendation, PR #65 cleanup/debug-gating, outdoor-g4-adapted profile UX/testing direction.
- JoshuaDoes: preserved credited ZRAM/mmd/service timing and resetprop boot-complete context.
- Allen Chang: preserved credited contribution.
- Jiggs: preserved credited contribution.
- maicol07: preserved credited contribution.
- Existing CREDITS.md acknowledgements remain part of the project credits.

## Exclusions

- No TensorConservative sysfs/procfs writes.
- No direct profile resolver layout switch in Stable 1.5.
- No additional runtime feature changes beyond the verified Test25-Test29 chain.

## Update channel

Stable channel now points to 1.5-universal.1 after final release publication.
