# Branch cleanup — 2026-07-31

Long-lived branches retained:

- `main` — canonical Dynamic V2 source;
- `v2` — protected rollback/reference branch.

The repository had no open pull requests before cleanup.

Branches approved for deletion after comparison with `main`:

| Branch | Comparison | Reason |
|---|---:|---|
| `Profiles_work` | ahead 0, behind 425 | fully contained and obsolete V1 profile work |
| `prerelease/v1413-test8-cp31-outdoor-safe-20260626-071606` | ahead 1, behind 514 | static V1 prerelease experiment superseded by Dynamic V2 and historical release records |
| `release/v1.5.2-universal-v2-alpha.1` | ahead 0, behind 368 | fully contained release branch |
| `repo-maintenance/release-v2-alpha3-dev6-user-go-20260727` | ahead 32, behind 184 | obsolete one-shot dev.6 release tooling; published history exists |
| `repo-maintenance/release-v2-alpha3-dev8-user-go-20260728` | ahead 16, behind 149 | obsolete one-shot dev.8 release tooling; published history exists |
| `repo-maintenance/v2-outdoor-runtime-evidence-guard-dev4-20260726` | ahead 1, behind 230 | old documentation branch superseded by current validation docs |
| `repo-maintenance/v2-zram-eh-dev12-20260730` | ahead 15, behind 123 | old EH implementation superseded by dev.18/dev.19 |
| `v2-perf` | ahead 5, behind 123 | old performance experiment superseded by current Action/runtime code |
| `v2-v` | ahead 1, behind 242 | old Canary patch experiment superseded by current Dynamic V2 validation model |

Deletion is fail-closed when a branch has an open PR, is `main`/`v2`, or the API does not confirm the exact ref.
