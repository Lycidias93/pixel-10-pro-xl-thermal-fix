# Boot crash debug collection

Status: vNext guard layer.

`tools/boot-crash-log-collect.sh` collects focused evidence for boot-crash reports:

- module paths and flags
- module props, install-state, health.log and bootguard.log
- pTune presence
- active thermal mounts
- ZRAM state
- logcat all buffers tail
- crash buffer tail
- thermal/Magisk filtered logcat
- pstore / ramoops / last_kmsg when readable
- matching tombstones

Output:

```text
/sdcard/Download/pixel_thermal_boot_crash_*.tgz
```

Ask reporters to send:

```text
pixel_thermal_debug_*.zip
pixel_thermal_boot_crash_*.tgz
Magisk install log
device/build/Magisk version
whether the device boots with the module disabled
```

Logs can contain device identifiers and should be reviewed before public posting.

## Action menu

The Action menu exposes debug ZIP export and boot-crash archive export without adding a WebUI.
