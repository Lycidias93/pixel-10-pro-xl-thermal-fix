## WebUI vNext external reference: Encore Tweaks

Status: captured for post-stable WebUI planning.

See `docs/webui-vnext-encore-audit.md`.

Decision: use Encore only as a WebUI/config/status inspiration source. Do not import its CPU/GPU/DRAM/sysctl/thermal-policy performance tweaks or daemon requirements.

Useful ideas:
- WebUI-X / KSUWebUI launch pattern while keeping Action menu fallback
- status dashboard from module state files
- clear separation of remembered settings, runtime status, Bootguard state and update channel
- optional soft-disable concept with explicit Bootguard separation
- structured config view for later WebUI work

Status: 1.5.2-universal-test.4 published and runtime-verified on mustang / CP2A.260605.012 with Bootguard pass, ZRAM 100p and matrix count 83.

Status: 1.5.2-universal-test.4 build candidate prepared from main with Bootguard v2; requires install + reboot runtime verify.

Status: Bootguard v2 guard pack added without WebUI: Action debug export, boot-crash export, last-good diff and self-only thresholded disable.

# vNext 1.5.2 planning

Status: planning
Base stable: `1.5.1-universal.1`
Base main after Stable 1.5.1 CP31.260618.005 correction: `bfb4bfc`
Final Stable 1.5.1 ZIP SHA256: `aa4c1a630e26b32a0035145f566cc95d71a1736db7a8642ac1249a9d0e417bb7`

## Ground truth from Stable 1.5.1

Stable 1.5.1 is final and should stay honest:

- Runtime-proven on **mustang**.
- Factory-basis covered for all G5 Pixel 10 devices.
- Runtime feedback is still needed for **frankel**, **blazer**, and **rango**.

Runtime PASS:

- `mustang / CP2A.260605.012 / outdoor-extended / polling mod / ZRAM 100p`
- `mustang / CP31.260618.005 / outdoor-plus / polling mod / ZRAM 100p`

Factory-basis PASS:

- `frankel / CP31.260618.005`
- `blazer / CP31.260618.005`
- `mustang / CP31.260618.005`
- `rango / CP31.260618.005`

`CP31.260618.005` is the real QPR1 Beta 6 factory basis for the G5 Pixel 10 family.

## Do not regress

- Do not advertise CP31.260608.007 as the current QPR1 basis.
- Do not claim runtime-proven status for frankel, blazer or rango until device runtime logs exist.
- Do not silently bump `update.json`.
- Do not retag `v1.5.1-universal.1`.
- Do not remove the mustang CP2A runtime baseline.
- Do not weaken pTune strict guard defaults.

## Workstreams

### 1. CP31.260618.005 profile-name hygiene

Status: current alias selection implemented by `tools/profile-matrix-test9.sh` and verified by `tools/cp31-260618005-selection-verify.sh`.

Status: aliases implemented by `tools/cp31-260618005-alias-verify.sh` and documented in `docs/cp31-260618005-profile-aliases.md`.

Status: audit started by `tools/cp31-profile-name-hygiene-audit.sh` and `docs/cp31-profile-name-hygiene-audit.md`.

Current stable has runtime-verified CP31 behavior, but some internal CP31 profile directories still use older `cp31260608007` naming.

vNext should decide deliberately between:

- adding `cp31260618005` aliases that map to verified CP31 profile content, or
- renaming profile directories only after exact stock-file hashes are present, or
- keeping the existing paths and documenting them as compatibility aliases.

Acceptance criteria:

- no broken existing installs,
- profile matrix remains green,
- old CP31 names are not described as the current factory basis,
- aliases are clearly documented if added.

### 2. Stock-file and factory-extract pipeline

Add or refresh stock-source material only when the files are traceable and hashable.

Target basis:

- `originals/frankel/CP31.260618.005/`
- `originals/blazer/CP31.260618.005/`
- `originals/mustang/CP31.260618.005/`
- `originals/rango/CP31.260618.005/`

Minimum metadata per device:

- source build,
- source incremental if available,
- SHA256 for each imported file,
- which profile directory consumes it,
- extraction notes,
- whether the file is stock-exact or compatibility-derived.

### 3. Manager update-channel UX

Status: status-only Advanced menu entry implemented by `tools/action-dashboard.sh`.

Add an Advanced status section for update-channel state:

- Stable
- Candidate
- Test
- Local/dev build

The manager should show this as status only first. Avoid automatic channel switching until the display path is proven.

### 4. Release policy documentation

Document that the module ZIP release asset is canonical for installation.

When a release asset is replaced without retagging:

- the tag SHA remains historical,
- GitHub source archives may reflect the old tag snapshot,
- the release ZIP asset and `update.json` ZIP URL are the install source of truth.

### 5. Runtime test matrix

Next runtime tests, highest priority first:

1. `mustang / CP31.260618.005 / final ZIP / outdoor-plus / polling mod / ZRAM 100p`
2. `blazer / CP31.260618.005 / outdoor profile / polling mod / optional ZRAM`
3. `frankel / CP31.260618.005 / outdoor profile / polling mod / optional ZRAM`
4. `rango / CP31.260618.005 / outdoor profile / polling mod / optional ZRAM`

Each runtime PASS needs:

- install autosave,
- after-reboot manager status,
- `compat-check`,
- `PROFILE_MATRIX_VERIFY_PASS`,
- ZRAM runtime proof when ZRAM is enabled,
- screenshot or equivalent manager evidence.

### 6. Installer and active-module verify polish

Status: started by `tools/verify-evidence-scope.sh` and `docs/installer-vs-runtime-verify.md`.

Do not rely on installer-only files in the active module path after reboot. Some files may exist in the ZIP and install autosave but not remain under `/data/adb/modules/...`.

Verify scripts should classify files as:

- runtime files,
- ZIP/install-only files,
- repo/docs-only files.

Known example:

- `customize.sh` is installer-side evidence, not guaranteed active runtime evidence after reboot.
- `README.md` may be absent from the active module path after reboot.

Status: `1.5.2-universal-test.1` build started after selector/channel polish.

Status: `1.5.2-universal-test.1` runtime PASS recorded for mustang / CP2A.260605.012 / outdoor-extended / polling mod / ZRAM 100p.

Status: `1.5.2-universal-test.2` build scope selected: include test1 runtime evidence plus Advanced Update Ch UX polish.

Status: stock-file/factory-extract pipeline guard layer added; no stock files imported yet.

Status: `1.5.2-universal-test.3` selected for Magisk update-path channel switch: stable/test only, no ZIP download.

## Proposed vNext order

1. Add guard/docs for CP31.260618.005 basis hygiene.
2. Add profile alias decision or stock-file import plan.
3. Add update-channel status display in Advanced.
4. Build `1.5.2-universal-test.1`.
5. Runtime test on mustang.
6. Expand to frankel/blazer/rango only with explicit device logs.
7. Promote stable only after runtime logs and docs are aligned.

Policy: every release/pre-release requires install plus post-reboot runtime verify before it is marked complete. See `docs/release-reboot-verify-policy.md`.

Status: boot-crash debug collection and anti-bootloop audit added as vNext guard layer. Auto self-disable remains audit-only until boot-crash root cause is known.

## Stable promotion gate for vNext

A future stable can only claim all-G5 runtime support when all G5 devices have green runtime evidence.

Until then, wording remains:

- runtime-proven on the tested device,
- factory-basis covered where stock basis is verified,
- runtime feedback needed for untested devices.
