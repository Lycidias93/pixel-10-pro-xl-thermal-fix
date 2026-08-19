# Alpha4 WebUI UX overhaul — 2026-08-18

State: REPO_IMPLEMENTED / GITHUB_CI_QUOTA_EXHAUSTED / PI4_LOCAL_CI_PASS / PRE_REBOOT_DEVICE_PASS / POST_REBOOT_PENDING

## Primary user evidence

Mustang screenshots from the device-verified Alpha4 dev.1 browser WebUI showed two primary UX defects:

1. Inventory view switching was noticeably laggy.
2. Actions did not make the currently active configuration clear.

The same screenshots also showed mobile presentation friction: horizontally scrolling tabs, dense action cards, generic checked `Dry-run` controls, and inventory values that were difficult to scan on a narrow display.

## Root causes

### Inventory latency

- The shared WebUI fetched an inventory again on each selection.
- Parallel inventory requests could finish out of order.
- Pixel's `validation` inventory called the full status refresh/validation path on every browser selection.

### Action state ambiguity

- The shared WebUI had action definitions but no rendered active/blocked state contract.
- Pixel status JSON did not expose which mutually exclusive Polling, Thermal, ZRAM, Emerald Hill, LMKD, and page-cluster actions represented the current state.
- `Dry-run` was technically correct but did not communicate preview-vs-apply intent clearly.

### Static core asset defect discovered on the primary path

The shared HTML references `race-guard.js/.css` and `observability.js/.css`, but the normal static allowlist served only `index.html`, `app.js`, and `app.css`. The versioned v03/v04 handlers are separate. This could silently leave browser protection/diagnostic layers unloaded.

## Shared-core fixes

Pinned source after this task: `Lycidias93/android-root-module-webui-template@cb991dc8d7d982defbe5e34c5c0e0908efa9b236`, core `0.6.0`.

Implemented in the shared core:

- session-local inventory cache;
- explicit inventory refresh instead of implicit re-fetch on every view switch;
- stale/out-of-order inventory response guard;
- active inventory launcher state and loading state;
- `action_state.active` rendering with prominent `ACTIVE` badges and a current-state summary;
- `action_state.blocked` rendering with disabled action and reason;
- clear `Preview only`, `Preview change`, `Preview current setting`, `Apply change`, and `Reapply current setting` wording;
- mobile tab/table/action-card improvements;
- static allowlist now serves race-guard and observability assets while remaining closed to arbitrary files;
- HTTP regression test covers every referenced WebUI asset and verifies an arbitrary asset still returns 404.

## Pixel consumer fixes

Alpha4 development candidate advanced to `2.1.0-alpha.4-dev.2` / `1016254`.

Pixel `bin/module-control` now:

- uses latest verified manager-status evidence for Inventory instead of rerunning the expensive validator on view selection;
- emits machine-readable active actions for Polling, Thermal, ZRAM, Emerald Hill, Memory Killer, and page-cluster;
- emits ZRAM-dependent blocked reasons;
- refreshes verified status only through the existing boot/service/action ownership paths.

Consumer packaging now includes the complete core 0.6.0 asset set:

- `app.js`, `app.css`
- `race-guard.js`, `race-guard.css`
- `observability.js`, `observability.css`
- `v03.js`, `v04.js`

Package validators, CI asset assertions, WebUI integration regression checks, module identity, and the repository-owned device verifier were advanced to dev.2.

The public Alpha3 prerelease/update feed was not changed.

## GitHub Actions quota and local CI fallback

The account-level GitHub Actions included allowance is exhausted for the current billing cycle: `2,000 min used / 2,000 min included`, with reset shown for 2026-09-01. This is the relevant reason the normal GitHub-hosted CI gate is currently unavailable through the included-minute path. The earlier connector visibility failure was only a secondary observation and is not the CI root cause.

A quota-independent runner is repository-owned at `dev_tools/run-vnext-local-ci.sh`. It is deliberately bound to the current `vnext-2.1-ci.yml` Git blob, WebUI core commit `cb991dc8d7d982defbe5e34c5c0e0908efa9b236`, core version `0.6.0`, branch `vnext-2.1.0-alpha.4`, and module version `2.1.0-alpha.4-dev.2`. Workflow drift therefore fails closed instead of silently diverging from GitHub CI.

The local runner executes the same functional gates represented by the vNext workflow: pinned WebUI-core verification and race regressions, shell/Python syntax checks, the vNext regression suite, Pixel family matrix verification, deterministic device-test package build, package hygiene, required WebUI asset checks, SHA-256 generation, and the final local-CI PASS marker.

## Local-CI self-heal findings

The local-CI bring-up exposed orchestration, portability and regression-fixture defects that were repaired without weakening runtime safety:

1. The runner initially classified its declared `.webui-core/` checkout as a dirty tree; the dirty-tree contract now excludes only that pinned nested build input.
2. The handoff initially changed the runner's tracked execute bit with `chmod`; the handoff now invokes the committed `100644` runner through `/bin/bash` without modifying the checkout.
3. DietPi `de_DE.UTF-8` plus `mawk` exposed locale-dependent decimal formatting in Thermal JSON. The materializer and the independent outdoor-delta verifier now bind numeric processing to `LC_ALL=C`, keeping JSON decimal points deterministic while preserving the strict byte-diff safety guard.
4. One LMKD regression still asserted the old dev.1 identity and was updated to dev.2 / `1016254`.
5. The newly enabled Dev16 installer regression exposed stale historical metadata assertions and an old fixture that no longer modelled the guarded install-only ZRAM materialization contract. The fixture was updated to simulate the real `modules_update/<id>` stage with `MATERIALIZE_NOW=1` and `MATERIALIZE_CALLER=install-zram`; production ZRAM safety logic remained unchanged.
6. The original volume-key reader wrapped `getevent | grep` in `timeout sh -c`, allowing `getevent` to retain the command-substitution pipe and hang CLI installs. The fix puts `getevent` itself under the timeout and fails safe to the shown selection if `timeout` is unavailable. The Dev16 regression now guards this exact failure mode and is wired into vNext CI.

## Superseded first dev.2 candidate

The first locally green dev.2 candidate at repo head `dc5f1345a630198ec0c0c9df7ed807bfc25bd57c` and SHA-256 `5bfea75d4b7c3be03aba4a34eeb1bbd33b4d402771cfc082ca966098f3f653aa` is superseded and must not be used. A Pixel CLI install exposed the bounded-key-reader defect described above. Recovery terminated the hung installer, removed the incomplete stage, and verified that the accepted dev.1 runtime hashes were unchanged before rebuilding.

## Authoritative rebuilt Local-CI PASS — 2026-08-18

The rebuilt candidate completed the full quota-independent pi4 gate successfully:

- repo head: `aabd15f52b06f9c0747e57641fcc4056013df940`
- workflow blob: `002d6f17c42649753281e9a88b6e3387b8b37fb8`
- WebUI core commit: `cb991dc8d7d982defbe5e34c5c0e0908efa9b236`
- WebUI core version: `0.6.0`
- candidate: `pixel-thermal-memory-control-2.1.0-alpha.4-dev.2.zip`
- candidate SHA-256: `33e1c57ba19af33d91fd3eda9e01467843ebe1602741a874b0dc0b5d0496f775`
- candidate bytes: `2,974,479`
- package entries: `82`
- Android copy path: `/storage/emulated/0/Download/pixel-thermal-memory-control-2.1.0-alpha.4-dev.2-pi4-local-ci-aabd15f52b06f9c0747e57641fcc4056013df940.zip`
- `github_actions_minutes_used=0`

Passed gates include pinned WebUI core verification, all four race regressions, syntax checks, Stallion/Mustang/repository-stock Thermal layout and delta tests, OTA/ZRAM/LMKD/menu/Dev16/dynamic-build/Emerald-Hill/page-cluster/WebUI regressions, the device-family matrix, deterministic package build, package hygiene and required WebUI assets.

Final markers:

- `RESULT: PIXEL_THERMAL_VNEXT_LOCAL_CI_PASS workflow_exit_code=0`
- `RESULT: PI4_ALPHA4_DEV2_LOCAL_CI_REMOTE_PASS`
- `RESULT: PIXEL_THERMAL_ALPHA4_DEV2_PI4_LOCAL_CI_PASS`

## Pixel pre-reboot device gate — 2026-08-19

The rebuilt candidate was staged on the verified Mustang device on Android 17 build `CP2A.260805.005` with battery `96%`.

Pre-reboot install evidence:

- exact candidate SHA-256 and byte count matched before install;
- installer key-reader timeout guard was present;
- `magisk --install-module` returned `0` within the bounded install watchdog;
- remembered choices were applied: Polling `mod`, Thermal `outdoor-extended`, ZRAM 100% enabled/adaptive, Memory Killer 1% enabled, pTune off;
- Thermal materialization/validation PASS with Outdoor delta `+3 C`, Polling changes `22/22`, layout `base_charge_throttling`;
- staged module identity `2.1.0-alpha.4-dev.2` / `1016254`;
- staged flags clean;
- staged WebUI server SHA-256 `42ba503ab979920e4ab0fffba41246ea01ccbc2c681b80fb548f342dd0ecf381`;
- staged `module-control` SHA-256 `8a36260d8f6928bc5742221ae294f3e27814a1a4f756ae7f53d021b03783a351`;
- staged runtime content, permissions, complete WebUI asset set, Thermal overlay and validation evidence all PASS;
- pre-reboot config readback matched the intended test configuration.

The first pre-reboot verifier falsely treated the new live `module.prop` as a runtime mutation. Magisk bootmode update semantics intentionally copy the staged candidate `module.prop` to the live module directory and create the live `update` marker before reboot while immutable live runtime files remain the accepted baseline. A repair/re-stage verifier corrected this assumption and proved the intended split state:

- live metadata: dev.2 / `1016254`;
- live `update` marker: present;
- immutable live WebUI server SHA-256 remained dev.1 `563b0592087dd418ca064fac2b18064035dc600f754806dcc4f83a039fdf2ec7`;
- immutable live `module-control` SHA-256 remained dev.1 `73f994e0e5db83c2cc7488748c32926137637cfe3e4a66ff928d97c4a6980de2`;
- staged runtime remained exact rebuilt dev.2;
- `magisk_prereboot_semantics=pass`;
- `SAFE_TO_REBOOT=yes`;
- `reboot_performed=no`;
- `RESULT: PIXEL_THERMAL_ALPHA4_DEV2_INSTALL_PRE_REBOOT_PASS`.

## Verification state

Alpha4 dev.2 is repository/build verified and has passed the focused Mustang pre-reboot device gate. The next authoritative step is one controlled reboot followed by post-reboot runtime and WebUI verification. Public Alpha4 promotion remains blocked until that post-reboot gate is green.
