# v1.5.2-universal-test.2

Status: pre-release test build.

This is a small vNext follow-up to `1.5.2-universal-test.1`.

## Included since test.1

- Runtime evidence from `1.5.2-universal-test.1` is now integrated into repo docs and release notes.
- `tools/runtime-verify-152-test1.sh` is included in the ZIP.
- `tools/runtime-verify-152-test2.sh` is added for this build.
- `tools/verify-evidence-scope.sh` recognizes `1.5.2-universal-test.2`.
- Advanced `Update Ch` status is more explicit:
  - installed channel
  - installed version/code
  - stable update.json version/code
  - GitHub pre-release asset policy
  - auto-switch state
  - status-only mode

## Runtime evidence carried forward

Runtime PASS is already recorded for:

```text
mustang / Android 17 / CP2A.260605.012 / outdoor-extended / polling mod / ZRAM 100p
```

Observed after reboot on test.1:

```text
P:🟢 mod | T:🟢 outdoor-ext | Z:🟢 100p | Action: settings/debug
```

## Test focus

Recommended runtime test for this build:

```text
mustang / CP2A.260605.012 / outdoor-extended / polling mod / ZRAM 100p
```

Check:

- manager status remains green
- Advanced > `Update Ch` shows stable/test policy clearly
- stable `update.json` remains `1.5.1-universal.1`
- matrix remains `PROFILE_MATRIX_VERIFY_PASS count=83`

## Scope honesty

This build does not add runtime-proven claims for frankel, blazer or rango.

It also does not make `1.5.2` stable. Stable update.json remains on `1.5.1-universal.1`.
