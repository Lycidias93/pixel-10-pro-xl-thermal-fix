## Scope

Describe the final change and its rollback path.

## Branch lineage

Select the applicable path:

- [ ] Trivial/docs-only change with no exploratory history.
- [ ] Feature was proven on a separate test branch, then rebuilt on a fresh integration branch from the latest target branch.

## Clean integration contract

- [ ] Final history contains approximately 1–4 logical commits, or the trivial-change exception is documented.
- [ ] Temporary builders, traces, debug scaffolding and generated artifacts are absent.
- [ ] Base SHA, head SHA and changed-file matrix were reverified.
- [ ] All required CI ran successfully on this exact final head.
- [ ] Fresh device verification was repeated on this exact head when runtime, boot, installation or hardware behavior changed.
- [ ] Conflicts, reviews and unresolved threads were checked.
- [ ] Release, tag, asset and update-channel state is unchanged unless an explicit release lane is active.
- [ ] Post-merge target verification and task-branch cleanup are planned.

See [`docs/DEVELOPMENT_WORKFLOW.md`](../docs/DEVELOPMENT_WORKFLOW.md).
