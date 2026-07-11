# v1.5.2-universal-test.3

Status: pre-release test build.

This build adds the guarded Magisk update-path channel switch.

## Included since test.2

- Adds `update-prerelease.json`.
- Adds `tools/update-channel-switch.sh`.
- Adds `tools/update-channel-verify.sh`.
- Advanced > `Update Ch` now supports:
  - `Use Stable`
  - `Use Test`
  - `Back`
- The switch only changes the `updateJson=` path in active `module.prop`.
- It does not download ZIP files.
- It does not install anything.
- Stable `update.json` remains pinned to `1.5.1-universal.1`.

## Channel policy

Stable channel:

```text
updateJson=https://raw.githubusercontent.com/Lycidias93/pixel-10-pro-xl-thermal-fix/main/update.json
```

Test/pre-release channel:

```text
updateJson=https://raw.githubusercontent.com/Lycidias93/pixel-10-pro-xl-thermal-fix/main/update-prerelease.json
```

## Runtime evidence carried forward

Runtime PASS is already recorded for:

```text
mustang / Android 17 / CP2A.260605.012 / outdoor-extended / polling mod / ZRAM 100p
```

## Scope honesty

This build does not add runtime-proven claims for frankel, blazer or rango.

It also does not make `1.5.2` stable.
