# 1.5.2-universal-test.6

Pre-release test build.

## Important

- Promotes the Action menu nested profile resolver and UX hardening.
- Keeps the test.5 nested Outdoor fix and makes Action Settings use the same nested resolver path.
- Runtime verified on mustang / CP2A.260605.012 / 15430684 after reboot: P mod, T outdoor-ext, Z 100p.
- Fixes verifier behavior: README is optional in the installed runtime module path.
- Adds a ZRAM verifier that uses /proc/swaps KB values and avoids Android shell byte arithmetic overflow.

## Outdoor profile temperature deltas

| Variant | VIRTUAL-SKIN thresholds | Delta vs base | VIRTUAL-SKIN-HINT thresholds | Delta vs base |
|---|---:|---:|---:|---:|
| Base | 39 / 43 / 45 / 46.5 / 52 / 55 C | baseline | 37 / 43 / 45 / 46.5 / 52 / 55 C | baseline |
| outdoor-safe | 40 / 44 / 46 / 47.5 / 53 / 56 C | +1 C each | 38 / 44 / 46 / 47.5 / 53 / 56 C | +1 C each |
| outdoor-plus | 41 / 45 / 47 / 48.5 / 54 / 57 C | +2 C each | 39 / 45 / 47 / 48.5 / 54 / 57 C | +2 C each |
| outdoor-extended | 42 / 46 / 48 / 49.5 / 55 / 58 C | +3 C each | 40 / 46 / 48 / 49.5 / 55 / 58 C | +3 C each |

## Notes for Harish / Codecity001

- Leave currently included profile/source files as-is until classified as runtime, factory-basis, or staging-only.
- Online profile download is a good vNext idea, but test.6 remains a fully offline reproducible ZIP.
- Future online mode should use a signed or hashed manifest, explicit user consent, offline fallback, and no silent build-profile downloads.
