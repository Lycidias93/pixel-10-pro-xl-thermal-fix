# Release notes

Release notes are repository documentation and are never included in the flashable Magisk ZIP.

## V2 alpha line

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
