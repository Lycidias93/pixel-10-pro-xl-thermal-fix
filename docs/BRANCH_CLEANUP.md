# Branch cleanup

Merged task branches are removed automatically by `.github/workflows/merged-branch-cleanup.yml`.

## Protected branches

The cleanup keeps:

- `main` and `v2`;
- GitHub-protected branches;
- `release/*`, `hotfix/*`, `stable/*`, `support/*`, and `long-lived/*`;
- branches used by an open pull request as head or base;
- branches whose current SHA does not exactly match the head SHA of a merged same-repository pull request.

## Cleanup modes

- After a merged pull request, the workflow checks only that pull request's head branch.
- When the workflow is introduced or updated on `main`, it performs a guarded sweep of the existing branch inventory.
- A manual `workflow_dispatch` performs the same guarded sweep.

A branch is deleted only when the pull request is merged, the current branch SHA still equals the recorded merged head SHA, no open pull request depends on it, and no protected-name rule applies. Fork branches are never deleted.

Every run uploads `branch-cleanup-receipt.json` with `deleted`, `skipped`, and `pending` records. API or permission failures remain `pending`; the workflow never force-pushes or rewrites history.
