# V2 exact Git-backed profile source foundation

## Decision

V2 materialization uses only an exact, versioned profile stored in this repository.
The live `/vendor/etc` tree is runtime evidence and is never the patch source.

Canonical path:

`profiles/<device>/17/<channel>/<family>/<build-slug>/base`

Supported foundation profiles:

- Stable `CP2A.260705.006`
- Canary `ZP11.260618.005`
- Devices `blazer`, `frankel`, `mustang`, and `rango`

## Resolver contract

`tools/core/profile-resolver.sh` requires an exact tuple:

- device codename;
- Android major;
- build ID.

There is no build-family fallback and no fallback to another device or channel.
An unsupported OTA/build blocks materialization and sets `skip_mount` during the
auto-profile path.

## Source verification

`tools/core/profile-source-verify.sh` validates every selected stock file against
`profiles/manifests/thermal-stock-inventory.tsv` before any output is created.
Stock bytes are not rewritten. Official files with a trailing comma remain
byte-preserved.

## Materialization

`tools/core/patch-thermal.sh`:

- discovers all existing `thermal_info_config*.json` files in the selected profile;
- includes `thermal_info_config_aa_throttling.json` when present;
- changes only exact existing `PollingDelay: 300000` values to `5000` in polling-mod mode;
- does not create PollingDelay keys;
- keeps `vt` and `wingboard` unchanged when no applicable key or target exists;
- retains the existing V2 VIRTUAL-SKIN/VIRTUAL-SKIN-HINT outdoor delta behavior;
- records source/output hashes and replacement counts;
- promotes the completed overlay atomically;
- preserves non-thermal overlay files such as `fstab.zram.100p`.

Build-specific originals are stored under:

`/data/adb/pixel-10-pro-xl-thermal-fix/originals/<device>/<build-slug>/vendor/etc`

They are evidence copies only. Rematerialization always starts from the Git-backed
profile in the module.

## Consumers in this foundation commit

- installer via `customize.sh` and `install-thermal-overlay.sh`;
- Action rematerialization via `action-dashboard.sh`;
- boot/OTA rematerialization via `auto-profile-switch.sh` and `post-fs-data.sh`;
- source and offline materialization verification via
  `profile-source-verify.sh` and `dev_tools/verify-v2-profile-source-foundation.sh`.

Runtime compat-check/status and debug-collector presentation are the next integration
step before building the public `1.5.2-universal-test.8` prerelease.


## Upstream compatibility baseline

The implementation is rebased on V2 commit
`f21f9fb88efb00b9e5738cb074a6874fb5759b8a`.

It preserves the upstream OTA/offline disable guard and emits both:

- `guard/patch-manifest.tsv`;
- `validation_report.json` in the module and persistent data directory.

After a supported OTA profile is rematerialized successfully,
`THERMAL_DISABLED=0` is restored. Unsupported or unverifiable builds remain blocked.

The installer accepts later fast-forward V2 commits only when none of the protected
implementation paths changed after the audited baseline. Unrelated commits do not
invalidate the package.
