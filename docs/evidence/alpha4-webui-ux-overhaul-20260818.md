# Alpha4 WebUI UX overhaul — 2026-08-18

State: REPO_IMPLEMENTED / GITHUB_CI_QUOTA_EXHAUSTED / PI4_LOCAL_CI_PASS / DEVICE_TEST_READY

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

A quota-independent runner is repository-owned at `dev_tools/run-vnext-local-ci.sh`. It is deliberately bound to the current `vnext-2.1-ci.yml` Git blob (`40274fe5f8c6faa76fbb2ca8311813d62b5e1223`), WebUI core commit `cb991dc8d7d982defbe5e34c5c0e0908efa9b236`, core version `0.6.0`, branch `vnext-2.1.0-alpha.4`, and module version `2.1.0-alpha.4-dev.2`. Workflow drift therefore fails closed instead of silently diverging from GitHub CI.

The local runner executes the same functional gates represented by the vNext workflow: pinned WebUI-core verification and race regressions, shell/Python syntax checks, the vNext regression suite, Pixel family matrix verification, deterministic device-test package build, package hygiene, required WebUI asset checks, SHA-256 generation, and the final local-CI PASS marker.

## Local-CI self-heal findings

The first local-CI bring-up exposed orchestration and portability defects that were repaired without weakening any runtime safety gate:

1. The runner initially classified its declared `.webui-core/` checkout as a dirty tree; the dirty-tree contract now excludes only that pinned nested build input.
2. The handoff initially changed the runner's tracked execute bit with `chmod`; the handoff now invokes the committed `100644` runner through `/bin/bash` without modifying the checkout.
3. DietPi `de_DE.UTF-8` plus `mawk` exposed locale-dependent decimal formatting in Thermal JSON. The materializer and the independent outdoor-delta verifier now bind numeric processing to `LC_ALL=C`, keeping JSON decimal points deterministic while preserving the strict byte-diff safety guard.
4. One LMKD regression still asserted the old dev.1 identity and was updated to dev.2 / `1016254`.

These were host-CI portability/orchestration issues; the underlying Alpha4 dev.1 Thermal core had already been device-verified. The locale fix improves deterministic host/device parity and is now regression-bound.

## Local-CI PASS — 2026-08-18

Authoritative pi4 local-CI run completed successfully with zero GitHub Actions minutes:

- repo head: `dc5f1345a630198ec0c0c9df7ed807bfc25bd57c`
- workflow blob: `40274fe5f8c6faa76fbb2ca8311813d62b5e1223`
- WebUI core commit: `cb991dc8d7d982defbe5e34c5c0e0908efa9b236`
- WebUI core version: `0.6.0`
- candidate: `pixel-thermal-memory-control-2.1.0-alpha.4-dev.2.zip`
- candidate SHA-256: `5bfea75d4b7c3be03aba4a34eeb1bbd33b4d402771cfc082ca966098f3f653aa`
- candidate bytes: `2,974,503`
- package entries: `82`
- Android copy path: `/storage/emulated/0/Download/pixel-thermal-memory-control-2.1.0-alpha.4-dev.2-pi4-local-ci-dc5f1345a630198ec0c0c9df7ed807bfc25bd57c.zip`
- `github_actions_minutes_used=0`

Passed gates include:

- pinned WebUI core Go/contract/static/integration verification;
- all four race-regression tests;
- shell/Python syntax checks;
- Stallion, Mustang and repository-stock Thermal layout/delta regressions;
- OTA transition, ZRAM defer, LMKD reload, dynamic-build admission, single-install menu, Emerald Hill, page-cluster and WebUI integration regressions;
- device-family matrix;
- deterministic package build and second-pass package verification;
- package hygiene, entry-count and size budgets;
- required WebUI assets.

Final markers:

- `RESULT: PIXEL_THERMAL_VNEXT_LOCAL_CI_PASS workflow_exit_code=0`
- `RESULT: PI4_ALPHA4_DEV2_LOCAL_CI_REMOTE_PASS`
- `RESULT: PIXEL_THERMAL_ALPHA4_DEV2_PI4_LOCAL_CI_PASS`

## Verification state

Alpha4 dev.2 is repository/build verified and ready for the Mustang device gate. The next authoritative step is to verify the transferred ZIP hash on the Pixel, install the exact candidate, run the focused pre-reboot gate, reboot only after that gate passes, and then perform the final post-reboot runtime/WebUI verification including the Inventory and Actions UX behavior that motivated this task.

No Pixel runtime mutation was performed by the local-CI task itself.
