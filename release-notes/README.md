# Release notes

Release notes are repository documentation and are never included in the flashable Magisk ZIP.

## Stable
- [2.0.1](2.0.1.md) — stable Dynamic V2 hotfix with August Stable KernelSU full post-reboot proof, August Canary verification, and July Stable Magisk regression coverage.

## V2 alpha line
- [2.0.0-alpha.3-dev.21](2.0.0-alpha.3-dev.21.md) — public device-tested prerelease with Magisk resetprop-first LMKD evidence and lightweight unchanged boots.

- [2.0.0-alpha.3-dev.19](2.0.0-alpha.3-dev.19.md) — unreleased guarded LMKD early-test and V2 cleanup source.
- [2.0.0-alpha.3-dev.18](2.0.0-alpha.3-dev.18.md) — unreleased EH UX/evidence hardening and controlled `v2` to `main` promotion preparation.
- [2.0.0-alpha.3-dev.17 — public cumulative prerelease](2.0.0-alpha.3-dev.17-public.md) — public Alpha changes and verified Mustang evidence since dev.10.
- [2.0.0-alpha.3-dev.17](2.0.0-alpha.3-dev.17.md) — private install-state preservation and choice-aware verification correction.
- [Next public prerelease — cumulative changes since dev.10](public-prerelease-next-since-dev.10.md) — retained preparation draft and release gate evidence.
- [2.0.0-alpha.3-dev.16](2.0.0-alpha.3-dev.16.md) — private Magisk staging and packaged-debug correction preserving the dev.15 defaults/menu work.
- [2.0.0-alpha.3-dev.15](2.0.0-alpha.3-dev.15.md) — private menu/defaults corrective build with transactional ZRAM layout changes and full route-matrix verification.
- [2.0.0-alpha.3-dev.14](2.0.0-alpha.3-dev.14.md) — private corrective test build with physical EH alias deduplication, migration-safe restore, adaptive defaults, stock LMK policy, and distinct risk observability.
- [2.0.0-alpha.3-dev.6](2.0.0-alpha.3-dev.6.md) — Fix 5 downstream Thermal-family alignment with dynamic inventory validation, transactional profile changes, exact Stable Mustang postboot proof, and an explicit Canary dev.6 evidence boundary.
- [2.0.0-alpha.3-dev.2](2.0.0-alpha.3-dev.2.md) — public lean development prerelease with single-pass install choices, canonical validation state, local dynamic build admission, exact Mustang runtime proof, and public asset hash verification.
- [2.0.0-alpha.2](2.0.0-alpha.2.md) — previous public guarded Android 17 Pixel 10 prerelease.
- [1.5.2-universal-v2-alpha.2-candidate.1](1.5.2-universal-v2-alpha.2-candidate.1.md) — internal Bootguard and pTune correction candidate.
- [1.5.2-universal-v2-alpha.1](1.5.2-universal-v2-alpha.1.md) — first public Dynamic V2 alpha.

## Layout contract

- New release notes belong in this directory.
- Root-level `RELEASE_NOTES_*` files are rejected by CI.
- The deterministic module builder excludes the entire `release-notes/` directory.
- Immutable changelog URLs already published for older releases remain valid at their historical commit references.
