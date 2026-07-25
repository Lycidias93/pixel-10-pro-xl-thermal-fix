# V2 dynamic build admission and lean packaging

Status date: 2026-07-25.

## Runtime admission contract

The exact build list is an evidence registry, not the Dynamic V2 activation gate.

Thermal activation is allowed when all of the following are true:

1. the device codename belongs to the supported Pixel 10 platform set;
2. the Android major version is supported;
3. all three stock thermal source files are present and structurally valid;
4. the generated overlay contains only the controlled polling and Outdoor-threshold changes;
5. the source manifest, patch manifest, validation report, and exact Outdoor delta validation pass.

An unlisted build ID is therefore reported as `dynamic_unverified`, then admitted locally only after the same stock-derived validation path succeeds. No GitHub request is required during install or Action startup.

The module remains fail-closed for:

- unknown device codenames;
- unsupported Android major versions;
- missing or malformed stock thermal files;
- source files that already appear patched without a valid build-keyed cache;
- unexpected polling values or lowercase polling keys;
- malformed, missing, reordered, renamed, or incorrectly shifted Outdoor target arrays;
- pTune conflicts without the explicit risk override.

`CANARY_DIAGNOSTIC_MODE` is not enabled merely because a build is unlisted. Dynamic build admission keeps the normal Bootguard threshold.

## Evidence levels

- `exact_verified`: the device, Android version, and build ID are present in the evidence registry.
- `dynamic_unverified`: the platform is supported but the build ID is new; runtime admission depends entirely on local source and output validation.
- `unsupported_platform`: device or Android version is outside the supported platform contract; Thermal stays disabled while ZRAM may remain available.

## Action performance

Action no longer downloads the V2 branch commit or `supported_versions.json` before opening the dashboard. Build evidence and compatibility are evaluated locally. A new build triggers local rematerialization only when the build ID changed, Thermal is disabled, or one of the three overlay files is missing.

## Release ZIP contract

The repository and the flashable module are intentionally different artifacts.

The canonical builder is `dev_tools/build-release-module.sh`. It packages tracked runtime files reproducibly and excludes repository-only content, including:

- `.git*` and `.github/`;
- `deprecated/`;
- `scratch/`;
- `dev_tools/`;
- `docs/`;
- `tests/`, `test/`, and fixture directories;
- evidence, release-work, and build-output directories;
- `RELEASE_NOTES_*`;
- README, changelog, credits, verification notes, and nested ZIP files;
- test and fixture scripts inside runtime-oriented directory trees.

`dev_tools/verify-release-module.sh` enforces required runtime entries, ZIP integrity, exclusion rules, an entry-count budget, and absence of zero-byte files.

Any changed package content requires a new versionCode, a new artifact hash, and fresh exact-package installation, reboot, and runtime verification. The published `2.0.0-alpha.2` tag and asset remain immutable.
