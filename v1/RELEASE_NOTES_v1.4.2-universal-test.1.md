# Pixel 10 Thermal Polling Fix 1.4.2-universal-test.1

Pre-release for Android 16 Pixel 10-series profile expansion.

## Highlights

- Adds Android 16-only install/profile guard.
- Adds install-time selection for `frankel`, `blazer`, and `rango`.
- Keeps `mustang` as the only stable/live-verified profile.
- Marks `frankel`, `blazer`, and `rango` as beta/pending live verification.
- Blocks Android 17 until separate factory evidence/profile files exist.
- Keeps `update.json` on stable `v1.4.1-universal.1`.

## Device states

| Device | Codename | State |
|---|---|---|
| Pixel 10 Pro XL | `mustang` | stable/live verified |
| Pixel 10 | `frankel` | beta/pending |
| Pixel 10 Pro | `blazer` | beta/pending |
| Pixel 10 Pro Fold | `rango` | beta/pending |

## Non-scope

- No Android 17 support.
- No stable update-channel promotion.
- No runtime text patching.
- No bind-mount model.
