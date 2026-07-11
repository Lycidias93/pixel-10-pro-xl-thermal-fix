# CP31.260618.005 profile aliases

Status: implemented for vNext 1.5.2
Scope: CP31 profile-name hygiene alias implementation

## Purpose

Stable 1.5.1 established `CP31.260618.005` as the real QPR1 Beta 6 factory basis for the G5 Pixel 10 family.

The existing CP31 profile directories used legacy compatibility names containing `cp31260608007`. vNext adds `cp31260618005` aliases while keeping the legacy names.

## Policy

- Do not hard-rename existing legacy CP31 directories.
- Keep `cp31260608007` as compatibility aliases.
- Add `cp31260618005` as current CP31.260618.005 aliases.
- Do not claim runtime-proven status for frankel, blazer or rango without device runtime logs.
- Stable runtime wording remains mustang-only until more devices have runtime evidence.

## Alias table

| Legacy compatibility source | Current CP31.260618.005 alias |
|---|---|
| `blazer-android17-cp31-cp31260608007` | `blazer-android17-cp31-cp31260618005` |
| `blazer-android17-cp31-cp31260608007-outdoor-extended` | `blazer-android17-cp31-cp31260618005-outdoor-extended` |
| `blazer-android17-cp31-cp31260608007-outdoor-plus` | `blazer-android17-cp31-cp31260618005-outdoor-plus` |
| `blazer-android17-cp31-cp31260608007-outdoor-safe` | `blazer-android17-cp31-cp31260618005-outdoor-safe` |
| `frankel-android17-cp31-cp31260608007` | `frankel-android17-cp31-cp31260618005` |
| `frankel-android17-cp31-cp31260608007-outdoor-extended` | `frankel-android17-cp31-cp31260618005-outdoor-extended` |
| `frankel-android17-cp31-cp31260608007-outdoor-plus` | `frankel-android17-cp31-cp31260618005-outdoor-plus` |
| `frankel-android17-cp31-cp31260608007-outdoor-safe` | `frankel-android17-cp31-cp31260618005-outdoor-safe` |
| `mustang-android17-cp31-cp31260608007` | `mustang-android17-cp31-cp31260618005` |
| `mustang-android17-cp31-cp31260608007-outdoor-extended` | `mustang-android17-cp31-cp31260618005-outdoor-extended` |
| `mustang-android17-cp31-cp31260608007-outdoor-plus` | `mustang-android17-cp31-cp31260618005-outdoor-plus` |
| `mustang-android17-cp31-cp31260608007-outdoor-safe` | `mustang-android17-cp31-cp31260618005-outdoor-safe` |
| `rango-android17-cp31-cp31260608007` | `rango-android17-cp31-cp31260618005` |
| `rango-android17-cp31-cp31260608007-outdoor-extended` | `rango-android17-cp31-cp31260618005-outdoor-extended` |
| `rango-android17-cp31-cp31260608007-outdoor-plus` | `rango-android17-cp31-cp31260618005-outdoor-plus` |
| `rango-android17-cp31-cp31260608007-outdoor-safe` | `rango-android17-cp31-cp31260618005-outdoor-safe` |

## Verification

Run from repo root:

```text
sh tools/cp31-260618005-alias-verify.sh .
sh tools/cp31-profile-name-hygiene-audit.sh .
sh tools/profile-matrix-verify.sh
```

Expected alias marker:

```text
RESULT: CP31_260618005_ALIAS_VERIFY_DONE
```

Expected profile matrix count after aliases:

```text
PROFILE_MATRIX_VERIFY_PASS count=83
```

## Runtime claim guard

These aliases are naming and selection hygiene. They do not add runtime PASS claims for frankel, blazer or rango.

Stable 1.5.1 remains:

- Runtime-proven on **mustang**.
- Factory-basis covered for all G5 Pixel 10 devices.
- Runtime feedback still needed for **frankel**, **blazer**, and **rango**.
