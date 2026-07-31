# Development and integration workflow

This repository separates exploratory testing from the history that is merged into the canonical target branch.

## Branch roles

- `main` is the canonical Dynamic V2 source branch.
- `v2` is the retained protected rollback/reference branch.
- Short-lived `repo-maintenance/*` branches are used for tests, feature work, integration and repository maintenance.
- A test branch may contain iterative fixes, temporary diagnostics and many small commits while a feature is being proven.
- A clean integration branch contains only the final reviewed implementation and is the only feature branch merged into the target branch.

## Required feature workflow

For feature work that needed iterative development or device testing:

1. Create a dedicated test branch from the intended target branch.
2. Implement, debug and test freely on that branch.
3. Freeze the scope only after the feature is functionally proven.
4. Create a fresh integration branch from the latest target branch.
5. Rebuild the final change set into approximately **one to four logical commits**.
6. Remove temporary builders, traces, debug scaffolding, generated artifacts and obsolete intermediate code.
7. Run the complete required CI suite on the exact cleaned integration head.
8. Repeat final device verification on that exact head whenever runtime, installation, boot, Thermal, ZRAM, Emerald Hill, LMKD or other hardware-dependent behavior changed.
9. Reverify base, head, changed-file matrix, checks, conflicts, reviews and PR metadata.
10. Merge only the cleaned integration branch.
11. Reverify the target branch and clean up merged task branches under the repository cleanup policy.

Results from the exploratory branch are supporting evidence only. They do **not** authorize merging a rewritten or newly reconstructed integration head until the required checks have run again on that exact commit.

## Logical commit model

The final integration branch should normally contain one to four commits, grouped by responsibility. Typical groups are:

1. Runtime or module behavior.
2. Regression tests and fixtures.
3. Documentation, credits and release notes.
4. CI, packaging or repository-maintenance updates.

Small related changes may be combined. A commit split must improve reviewability; it must not create artificial fragmentation or leave intermediate commits knowingly broken.

## No history rewriting

- Do not force-push or rewrite protected/shared branch history.
- Do not merge a long exploratory sequence merely because its final tree is correct.
- Reconstruct the final change set on a new branch from the current target branch using normal commits.
- The integration branch must remain independently reviewable and reproducible.

## Exceptions

A documentation-only, metadata-only or genuinely trivial single-commit change may use one short-lived branch directly when it has no exploratory history and still passes all applicable checks.

Release, tag, asset and update-channel operations remain separate publication gates and require the repository's explicit user-confirmed release workflow.

## Merge evidence checklist

Before merge, record or verify:

- target branch and exact base SHA;
- integration head SHA;
- one-to-four logical commit structure, or documented trivial-change exception;
- final changed-file matrix;
- absence of temporary/debug/generated files;
- all required CI results on the exact integration head;
- fresh device evidence for hardware/runtime changes;
- conflict and review-thread state;
- rollback path;
- post-merge target verification and task-branch cleanup state.
