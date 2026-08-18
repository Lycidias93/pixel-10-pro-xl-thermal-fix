# Alpha4 WebUI UX overhaul — 2026-08-18

State: REPO_IMPLEMENTED / GITHUB_CI_QUOTA_EXHAUSTED / PI4_LOCAL_CI_RUNNER_READY / DEVICE_TEST_PENDING

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

A quota-independent runner is now repository-owned at `dev_tools/run-vnext-local-ci.sh`. It is deliberately bound to the current `vnext-2.1-ci.yml` Git blob (`40274fe5f8c6faa76fbb2ca8311813d62b5e1223`), WebUI core commit `cb991dc8d7d982defbe5e34c5c0e0908efa9b236`, core version `0.6.0`, branch `vnext-2.1.0-alpha.4`, and module version `2.1.0-alpha.4-dev.2`. Workflow drift therefore fails closed instead of silently diverging from GitHub CI.

The local runner executes the same functional gates represented by the vNext workflow: pinned WebUI-core verification and race regressions, shell/Python syntax checks, the vNext regression suite, Pixel family matrix verification, deterministic device-test package build, package hygiene, required WebUI asset checks, SHA-256 generation, and the final local-CI PASS marker. The intended first execution host is pi4 in a fresh `/var/tmp` checkout so no existing Codex/worktree is modified.

## Verification state

Current repository head after adding the local runner: `ee3e504b0000d4a151047fe6111fd6a09b035414` before this documentation-only follow-up commit.

Next authoritative gate while GitHub-hosted minutes remain exhausted: run the repository-owned local CI on pi4, copy the generated dev.2 ZIP back to the Pixel, verify transfer SHA-256, then install it and reverify the focused mobile Inventory/Actions behavior on Mustang. Once GitHub-hosted execution is available again, the normal branch workflow can provide an additional parity check; it is no longer required to block work during the quota window.

No Pixel runtime mutation was performed by this UX-overhaul/local-CI preparation task.
