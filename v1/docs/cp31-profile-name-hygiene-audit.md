# CP31 profile-name hygiene audit

Status: audit complete
Scope: vNext 1.5.2 Workstream 1
Base: Stable 1.5.1 final plus vNext verify evidence scope helper

## Purpose

This audit documents the current CP31 profile naming state before any alias or rename work.

Stable 1.5.1 is already final and remains honest:

- Runtime-proven on **mustang**.
- Factory-basis covered for all G5 Pixel 10 devices.
- Runtime feedback is still needed for **frankel**, **blazer**, and **rango**.

`CP31.260618.005` is the real QPR1 Beta 6 factory basis for the G5 Pixel 10 family.

## Finding

The current profile matrix still contains CP31 profile directory names with `cp31260608007`.

These names are now compatibility/legacy profile names and must not be described as the current QPR1 factory basis.

The audit tool classifies CP31 profile names as:

- `compat_legacy_cp31260608007_name`
- `current_cp31260618005_name`
- `generic_cp31_name`

## Decision

Do not hard-rename existing CP31 profile directories in vNext 1.5.2 without exact stock-file hash basis and install-selection regression testing.

Preferred next step:

1. Add explicit `cp31260618005` aliases for G5 devices.
2. Keep legacy `cp31260608007` names as compatibility aliases.
3. Ensure profile selection prefers exact/current aliases when the device build is `CP31.260618.005`.
4. Keep all runtime claims device-specific and evidence-based.

## Acceptance criteria for alias work

- Existing installs remain compatible.
- Profile Matrix remains green.
- Older CP31.260608.007 profile names are compatibility names only, not the current factory basis.
- `CP31.260618.005` aliases exist for frankel, blazer, mustang and rango.
- Exact/current aliases have three thermal files each.
- No runtime support claim is added for frankel, blazer or rango without logs.
- Runtime-proven wording remains mustang-only until more devices are tested.

## Tool

Run from repo root:

```text
sh tools/cp31-profile-name-hygiene-audit.sh .
```

Expected final marker:

```text
RESULT: CP31_PROFILE_NAME_HYGIENE_AUDIT_DONE
```

## Next step

Proceed with a low-risk alias implementation branch only after this audit is merged.

Suggested next branch:

```text
vnext/cp31-260618005-profile-aliases
```


## Alias implementation status

Implemented in vNext by adding `cp31260618005` aliases while keeping legacy `cp31260608007` compatibility names.
