# V2 dynamic patcher safety

This change keeps V2 dynamic and does not add repository profiles.

## Stock source model

Stock files are cached under:

`/data/adb/pixel-10-pro-xl-thermal-fix/originals/<device>/<build>/vendor/etc`

The cache is accepted only when its single manifest matches every source hash,
size and PollingDelay count. A cache cannot cross build IDs.

When no valid cache exists, the patcher prefers Magisk mirror paths. Standard
vendor paths are accepted only when they are structurally valid, contain no
already-patched 5000 values, no lowercase `pollingDelay`, no accidental 30000
values, and do not match the current module overlay.

## Controlled files

The explicit V2 list contains:

- base
- aa_throttling
- bg_tasks_throttling
- charge
- earlywarnings
- lpm
- stats
- throttling

Missing optional files are skipped. Base, charge and throttling are required.
Polling counts are calculated from the actual stock files for the current
device and build. No device reuses another device's counts.

## Validation and promotion

Each source and output file receives tolerant structural validation suitable
for vendor thermal files. The patcher verifies source and output hashes,
per-file and total counts, and a normalized allowed-difference proof.

Only existing `PollingDelay` values of 300000 become 5000. Whitespace is
preserved. Lowercase keys, 30000 handling and new keys are rejected.

The complete target directory is staged beside the active target and promoted
with directory renames only after every check passes. Nonthermal files such as
`fstab.zram.100p` are preserved.

## Unsupported builds

Unsupported builds keep the module and ZRAM available but remove only thermal
overlay files and set `THERMAL_DISABLED=1`. The old forced Canary diagnostic
installer path is removed.

Action may refresh `supported_versions.json` from V2. It first resolves the V2
branch to an immutable commit SHA, downloads the file from that commit, validates
the schema and current exact device/Android/build tuple, then promotes it
atomically and records commit plus file SHA-256.
