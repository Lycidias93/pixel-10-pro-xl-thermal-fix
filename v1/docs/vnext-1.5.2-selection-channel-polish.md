# vNext 1.5.2 selector and channel polish

Status: implemented
Scope: low-complexity vNext additions before `1.5.2-universal-test.1`

## Purpose

This change finishes the low-risk parts that make sense before the first 1.5.2 test build.

Implemented:

- CP31.260618.005 selection now prefers the current `cp31260618005` aliases.
- Legacy `cp31260608007` profile directories remain compatibility fallback data.
- Auto-profile metadata now names `CP31.260618.005` as the CP31 source build.
- Auto-profile install-state update-channel metadata is no longer stuck on the old 1.4.9 label.
- Advanced menu gets status-only update-channel visibility.
- Selection verification is available through `tools/cp31-260618005-selection-verify.sh`.

Not implemented here:

- Stock-file import pipeline.
- Runtime claims for frankel, blazer or rango.
- Stable release.
- Automatic update-channel switching.

## Selection rule

`tools/profile-matrix-test9.sh` maps CP31 devices to:

```text
<device>-android17-cp31-cp31260618005
```

for:

- frankel
- blazer
- mustang
- rango

The old `cp31260608007` paths are kept as compatibility profile names.

## Advanced menu

The Advanced menu now includes:

```text
Update Ch
```

This is status-only and prints:

- Channel
- Version
- VersionCode
- update.json presence/version when available
- Mode: status only

It does not change update channels.

## Guard

Run from repo root:

```text
sh tools/cp31-260618005-selection-verify.sh .
```

Expected final marker:

```text
RESULT: CP31_260618005_SELECTION_VERIFY_DONE
```

## Stable honesty

Stable 1.5.1 and vNext test wording remain honest:

- Runtime-proven on **mustang**.
- Factory-basis covered for all G5 Pixel 10 devices.
- Runtime feedback still needed for **frankel**, **blazer**, and **rango**.
