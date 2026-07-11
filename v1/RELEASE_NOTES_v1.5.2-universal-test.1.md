# v1.5.2-universal-test.1

Status: pre-release test build.

This is the first vNext 1.5.2 test build after Stable 1.5.1.

## Included in this test build

- CP31.260618.005 profile aliases for frankel, blazer, mustang and rango.
- CP31.260618.005 selection now prefers the `cp31260618005` alias profiles.
- Legacy `cp31260608007` profile directories remain compatibility fallback data.
- Profile matrix expands from 67 to 83 profiles.
- Installer-vs-runtime verify evidence scope helper.
- CP31 profile-name hygiene audit helper.
- CP31.260618.005 alias verify helper.
- CP31.260618.005 selection verify helper.
- Advanced menu status-only update channel view.
- Runtime claims remain honest and device-specific.

## Runtime/factory-basis honesty

Stable/vNext wording remains:

- Runtime-proven on **mustang**.
- Factory-basis covered for all G5 Pixel 10 devices.
- Runtime feedback is still needed for **frankel**, **blazer**, and **rango**.

## Not included yet

- Stock-file import pipeline.
- Runtime support claim for frankel, blazer or rango.
- Stable 1.5.2 release.
- Stable update.json bump.
- Automatic update-channel switching.

## Test focus

Recommended first runtime test:

- `mustang / CP31.260618.005 / outdoor-plus / polling mod / ZRAM 100p`

Also verify:

- `tools/cp31-260618005-selection-verify.sh`
- `tools/cp31-260618005-alias-verify.sh`
- `tools/verify-evidence-scope.sh`
- `PROFILE_MATRIX_VERIFY_PASS count=83`
- Manager Advanced menu: `Update Ch`

## Install notes

This is a GitHub pre-release test asset. Stable `update.json` remains on `1.5.1-universal.1`.

## Runtime evidence update

Runtime PASS has been recorded for:

```text
mustang / Android 17 / CP2A.260605.012 / outdoor-extended / polling mod / ZRAM 100p
```

Observed after reboot:

```text
P:🟢 mod | T:🟢 outdoor-ext | Z:🟢 100p | Action: settings/debug
```

The active CP2A profile is expected for this device/build:

```text
mustang-android17-cp2a-cp2a260605012-outdoor-extended
```

CP31.260618.005 selection and alias verification remain included and PASS, but CP31 runtime on-device still needs a CP31 runtime log.

See:

```text
docs/v1.5.2-test1-runtime-mustang-cp2a.md
```
