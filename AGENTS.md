<!-- LYCIDIAS93_OWNER_REPO_MAINTENANCE_ADAPTER_V1_START -->
# Repository Agent and Connector Policy

## Canonical owner policy

Before repository maintenance work, read and apply:

`Lycidias93/heimnetz-geraete@main:shared/github_owner_repo_maintenance_policy_v1.txt`

This adapter applies to `Lycidias93/pixel-10-pro-xl-thermal-fix` and every target branch.

## Connector class

`ConnectorClass=repo-maintenance`

ChatGPT and Codex Desktop may read, search, audit and maintain this repository. Allowed write scope includes documentation, repository hygiene, source code, tests, fixtures, examples, non-secret configuration, CI/workflows, dependencies/lockfiles, refactors, issue/PR maintenance and justified repository-file deletion.

## Write and merge contract

- Verify the current target branch and repository-specific rules.
- Create a dedicated work branch from exactly that target branch.
- Declare scope, file matrix, risk, tests/guards and rollback.
- Commit, push and open a pull request after PASS.
- Task-level user GO authorizes merge after final base/head/diff/check/conflict/review/PR reverify; no second merge prompt.
- Cross-repo work uses one branch and pull request per repository.

## Clean integration history contract

- Exploratory or device-test branches may contain iterative fixes, temporary diagnostics and many small commits.
- Once a non-trivial feature is proven and its scope is frozen, do not merge the exploratory branch directly into the target branch.
- Create a fresh integration branch from the latest target branch and reconstruct only the final change set into approximately one to four logical commits.
- Do not force-push or rewrite protected/shared history. Reconstruct the final commits on the new integration branch.
- Remove temporary builders, traces, generated artifacts and obsolete intermediate code before final review.
- Rerun all required CI on the exact cleaned integration head. Repeat final device verification on that exact head for runtime, installation, boot or hardware-dependent changes.
- Evidence from the exploratory head does not authorize merging a different reconstructed head.
- Reverify base, head, changed-file matrix, checks, conflicts, reviews and PR metadata before merge.
- Merge only the cleaned integration branch, then reverify the target and clean up eligible task branches under the cleanup policy.
- A genuinely trivial documentation-only or single-commit maintenance change may use one short-lived branch directly when it has no exploratory history and passes all applicable checks.

The detailed workflow and checklist are canonical within this repository at `docs/DEVELOPMENT_WORKFLOW.md` and `.github/pull_request_template.md`.

## Hard boundaries

No direct target-branch write, force-push/history rewrite, release/tag/publish, branch deletion, repository/branch settings, webhooks, environments, secrets, credentials, deploy keys or host/runtime/network changes.

Repository-specific architecture, style, test and safety instructions remain binding. They may not silently downgrade owner-authorized documentation, audit or repository maintenance to read-only.
<!-- LYCIDIAS93_OWNER_REPO_MAINTENANCE_ADAPTER_V1_END -->
