# V1 static profile line — end of active maintenance

The Dynamic V2 source line supersedes the static V1 profile model.

## Effective state

- `main` is the canonical Dynamic V2 source branch after the controlled promotion.
- `v2` remains protected during the transition and as a rollback/reference branch.
- Stable `update.json` remains on the last verified stable package until a separate explicit stable release decision.
- The public prerelease channel remains on the last published and verified prerelease until a separate release GO.

## Static profile policy

Files under `deprecated/profiles/` are retained as historical evidence only.

They are no longer:

- extracted for every monthly firmware;
- maintained as the activation source of truth;
- required for supported-build admission;
- packaged as the active Thermal source.

Dynamic V2 instead reads and validates the device's own three controlled stock Thermal files, creates a local constrained overlay, and verifies the active result.

## Rollback

Historical tags and release assets remain available. Promotion of source branches does not delete old releases or change an update channel.
