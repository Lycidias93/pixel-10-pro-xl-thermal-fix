# Release reboot verify policy

Status: mandatory workflow rule.

A release or pre-release is not complete until the exact published ZIP has been installed and verified after reboot.

Required sequence:

1. Build and verify ZIP.
2. Publish tag/release or pre-release.
3. Install the exact published ZIP.
4. Reboot.
5. Verify active module path `/data/adb/modules/pixel-10-pro-xl-thermal-fix`.
6. Verify version and versionCode.
7. Verify manager P/T/Z status.
8. Verify `PROFILE_MATRIX_VERIFY_PASS count=83`.
9. Verify ZRAM runtime proof when ZRAM is enabled.
10. Verify Stable/Test update-channel switching when the release changes update-channel behavior.
11. Record evidence before marking release done.

Minimum evidence:

```text
module_active_no_disable_remove_skip_mount
version=<released version>
versionCode=<released code>
PROFILE_MATRIX_VERIFY_PASS count=83
manager status P/T/Z
```

For channel-switch releases:

```text
RESULT: UPDATE_CHANNEL_SWITCH_VERIFY_DONE
No ZIP download
stable update.json unchanged
```

Baseline test device for this workstream:

```text
mustang / CP2A.260605.012
```

This policy does not add runtime-proven claims for untested devices.
