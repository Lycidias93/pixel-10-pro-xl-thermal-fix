# 1.5.2-universal-test.4

Pre-release test build.

## Changes since 1.5.2-universal-test.3

- Adds Bootguard v2 self-only threshold guard.
- Adds `pending_boot`, `fail_count`, `disabled_reason` and `last_good.env` guard evidence.
- Adds Action-menu Debug submenu with Debug ZIP export, Boot-Crash TGZ export, Bootguard status and counter clear.
- Adds last-good differential helper.
- Keeps WebUI out of scope until after stable.
- Keeps stable `update.json` unchanged.

## Runtime status

This release requires install + reboot + runtime verify before it can be marked done.

Current required post-release checks:

- install exact published ZIP
- reboot
- verify active module path
- verify no `disable`, `remove` or `skip_mount` marker blocks active runtime
- verify `module.prop` version/versionCode
- verify manager P/T/Z status
- verify `PROFILE_MATRIX_VERIFY_PASS count=83`
- verify ZRAM runtime proof when enabled
- record evidence before marking release done

## Safety note

If boot issues occur, keep the module disabled and export debug evidence through the Action menu or by running:

```text
su -c 'sh /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/collect-debug.sh'
su -c 'sh /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/boot-crash-log-collect.sh'
```

## Runtime verification

Runtime PASS has been recorded on `mustang / CP2A.260605.012`.

```text
RESULT: PIXEL_THERMAL_152_TEST4_RUNTIME_PASS device=mustang build=CP2A.260605.012 version=1.5.2-universal-test.4 profile=mustang-android17-cp2a-cp2a260605012-outdoor-extended polling=mod thermal=outdoor-ext zram=100p bootguard=pass fail_count=0 matrix_count=83 reboot=safe
```

Bootguard v2 updated `last_good.env`, kept `fail_count=0`, and did not create `disable`, `remove` or `skip_mount` markers.

Runtime feedback is still needed for `frankel`, `blazer` and `rango`.

## Credits

- Codecity001 - contributor. https://github.com/Codecity001
