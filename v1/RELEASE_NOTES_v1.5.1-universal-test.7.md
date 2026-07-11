# v1.5.1-universal-test.7

Prerelease test for Pixel 10 Thermal & Memory Control.

## What changed

- Keeps Test6 runtime and Action UX behavior.
- Aligns Advanced pTune status with compat-check output.
- Splits pTune risk into `Bad version` and `Runtime block`.
- Keeps pTune override blocked for known-bad versionCode 200.
- Stable `update.json` remains on `1.5-universal.1`.

## Verify target

- Manager card stays value-coupled.
- Advanced pTune status no longer contradicts compat-check.
- Compat-check reports `PTUNE_KNOWN_BAD_VERSION` and `PTUNE_KNOWN_BAD_RUNTIME`.
