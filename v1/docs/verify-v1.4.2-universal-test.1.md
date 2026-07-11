# Verify v1.4.2-universal-test.1

Pre-release verification notes.

## Scope

- Android 16 only.
- Android 17 is explicitly blocked until separate factory evidence/profile files exist.
- Mustang remains the only stable/live-verified profile.
- Frankel, Blazer, and Rango are beta/pending live verification.
- No service-time bind mount.
- No live runtime text patching.
- `update.json` remains on stable `v1.4.1-universal.1`.

## Required install markers

```text
module_version=1.4.2-universal-test.1
module_version_code=1014201
android_guard=android16_pass
fingerprint_android_guard=fingerprint_android16_pass
profile_source_android=16
profile_source_build=CP1A.260505.005
profile_materialized=yes
active_overlay_dir=system/vendor/etc
expected_thermal_files=3
bind_mount_model=no
live_runtime_text_patch_model=no
```

## Device profile states

```text
mustang=verified
frankel=beta_pending_live_verification
blazer=beta_pending_live_verification
rango=beta_pending_live_verification
```

## Must not happen

```text
android=17 accepted
update.json changed
module install without active profile materialization
runtime bind mount
runtime text patching
```

<!-- MUSTANG_POST_REBOOT_PASS_20260602_START -->
## Mustang post-reboot PASS

Verified after flash and reboot on Mustang / Pixel 10 Pro XL.

```text
module_version=1.4.2-universal-test.1
module_version_code=1014201
device=mustang
profile=mustang
profile_state=verified
build_state=verified_build
android_guard=android16_pass
fingerprint_android_guard=fingerprint_android16_pass
profile_source_android=16
profile_source_build=CP1A.260505.005
profile_materialized=yes
active_overlay_dir=system/vendor/etc
bind_mount_model=no
live_runtime_text_patch_model=no
```

Result: `PASS`.
<!-- MUSTANG_POST_REBOOT_PASS_20260602_END -->
