# 1.5.2-universal-test.5

Pre-release test build.

## Important

- Fixes the nested Android 17 Outdoor menu and profile resolver.
- Required for Outdoor Extended on the nested profile layout.
- Previous build 1.5.2-universal-test.4 can fall back to Stock because the Outdoor menu still checked old flat profile paths.
- Verified on mustang / CP2A.260605.012 / 15430684 after reboot: P mod, T outdoor-ext, Z 100p.

## Included

- Adapts tools/thermal-outdoor-menu.sh to use the nested profile matrix.
- Adds CP2A nested Outdoor variants for blazer, frankel, mustang, and rango to the matrix helper.
- Keeps stable update.json unchanged on 1.5.1-universal.1.
- Keeps contributor banner compact: Lycidias93, marx161, Codecity001.

## Validation

- Matrix PASS for CP2A, CP21, and CP31 base/outdoor variants across blazer, frankel, mustang, and rango.
- Install PASS on mustang / CP2A.260605.012 with Outdoor Extended.
- Post-reboot runtime PASS: overlay hashes match /vendor/etc, ZRAM runtime near 100 percent.
