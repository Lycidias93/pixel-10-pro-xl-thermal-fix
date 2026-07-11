# Stable candidate 1.5.1-universal.1 CP31.260618.005 basis correction

This is a stable-candidate branch only. Do not tag or create/update a GitHub release until candidate ZIP install and runtime debug verify are green.

## Purpose

- Promote `CP31.260618.005` as the real/current QPR1 Beta 6 factory basis for G5 Pixel 10 devices.
- Stop advertising older CP31 sources as the current QPR1 basis.
- Keep Stable 1.5.1 honest:
  - Runtime-proven on `mustang`.
  - Factory-basis covered for `frankel`, `blazer`, `mustang`, and `rango`.
  - Runtime feedback still needed for `frankel`, `blazer`, and `rango`.

## Runtime PASS

- `mustang / CP2A.260605.012 / outdoor-extended / polling mod / ZRAM 100p`
- `mustang / CP31.260618.005 / outdoor-plus / polling mod / ZRAM 100p`

## Factory-basis PASS

- `frankel / CP31.260618.005`
- `blazer / CP31.260618.005`
- `mustang / CP31.260618.005`
- `rango / CP31.260618.005`

## Gate

No tag/release from this branch until:

- Candidate ZIP sanity is green.
- Profile Matrix PASS count 67.
- UI text guard PASS.
- Install and after-reboot runtime debug verify are green.
