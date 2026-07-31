# V1 static profile line — end of life

Dynamic V2 is the active source architecture.

## Current-tree policy

Static profile payloads have been removed from the current `main` tree because V2 does not consume them for admission, materialization, validation, or packaging.

The removal does not delete history:

- V1 tags remain available;
- published V1 release assets remain available;
- Git history retains the former profile snapshots;
- the stable update channel remains on its published package until a separate explicit release decision.

## Active model

Dynamic V2 reads the device's own three controlled stock Thermal files, validates their structure, creates a constrained local overlay, and verifies the active runtime result.

## Rollback

Source-tree cleanup does not remove historical packages. Reverting the V2 source promotion or installing a historical release remains possible through normal Git and release history.
