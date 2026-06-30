# Pixel 10 Thermal & Memory Control

**Magisk module for Pixel 10-series thermal profiles and optional ZRAM 100p.**

Stable **1.5-universal.1** promotes the verified Test25–Test29 chain: cleaner install flow, safer profile selection, Outdoor Extended, Use-last, ZRAM 100p, and read-only profile layout auditing.

[Download latest release](https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/releases/latest) · [Telegram](https://t.me/lycidias93) · [Issues](https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/issues) · [Release notes](RELEASE_NOTES_v1.5-universal.1.md) · [Changelog](CHANGELOG.md) · [Credits](CREDITS.md)

---

## What this module does

This module installs guarded Pixel 10 thermal and memory overlays through Magisk. It does **not** replace Android thermal management; the stock thermal HAL remains in control while selected profile inputs are changed for supported device/build combinations.

Main functions:

- **Thermal polling:** preserves the verified polling-mod path for supported Pixel 10 thermal configs. In daily use, this aims for more consistent thermal sensor/update behavior during longer load, charging, navigation, camera use, or outdoor use.
- **Throttling profiles:** applies guarded `thermal_info_config*.json` profile overlays, including the verified **Outdoor Extended** path. This can make sustained load feel less abrupt by using tested profile variants, without disabling thermal safety.
- **ZRAM 100p:** optional boot/runtime memory profile for the verified ZRAM 100p path. This can help multitasking under memory pressure and reduce app reloads in daily use.
- **Compatibility guard:** activates only when device/build/profile evidence matches the supported matrix. This reduces the risk of applying the wrong thermal profile to an unknown build.

It is **not** an overclock, benchmark unlock, FPS tweak, or thermal safety bypass.

---

## Stable 1.5 highlights

| Area | Stable 1.5 |
|---|---|
| Install UX | Use-last flow reuses previous choices without repeated menus |
| Safety | Fresh-default fallback when no saved settings exist |
| Thermal | Outdoor Extended verified and promoted |
| Memory | Optional ZRAM 100p boot/runtime path verified |
| Compatibility | Known-bad pTune guard preserved |
| Refactor | Thermal/ZRAM helper cleanup promoted to stable |
| Profiles | Harish / Codecity001 profile-layout mapping audit added as read-only helper/docs |

---

## Compatibility

| Device / build | Status |
|---|---|
| Pixel 10 Pro XL `mustang` / Android 17 `CP2A.260605.012` | Verified |
| Pixel 10 Pro `blazer` / Android 17 stable | Community verified |
| Pixel 10 Pro XL `mustang` / Android 17 CP31 beta path | Community verified |
| Pixel 10 `frankel` / Pixel 10 Pro Fold `rango` | Profiles included, live verification still useful |
| Unknown devices or builds | Blocked until compatibility evidence exists |

A PASS on one Pixel 10 model does **not** automatically verify every other codename.

---

## Install

### Requirements

- Supported Pixel 10-series device/build.
- Magisk is the recommended install path.
- Keep a working rollback path before flashing.
- Do not force unsupported devices or builds.
- Reboot and verify after install/update.

### Install/update

1. Download the latest ZIP from [Releases](https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/releases/latest).
2. Install it in Magisk.
3. Choose the desired install options.
4. Reboot.
5. Run the compatibility check.

Stable update channel: [update.json](update.json)

```sh
su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/compat-check.sh
```

Expected healthy markers:

```text
MODULE_OVERLAY_READY=yes
ACTIVE_VENDOR_MATCH=yes
SAFE_TO_REBOOT=yes
```

For a full debug package:

```sh
su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/collect-debug.sh
```

Online debug command for Termux / shells with `curl`, using the latest helper from main:

```sh
cd /sdcard/Download
curl -fsSLO https://raw.githubusercontent.com/Lycidias93/pixel-10-pro-xl-thermal-fix/main/tools/collect-debug.sh
su -c "sh -n /sdcard/Download/collect-debug.sh && sh /sdcard/Download/collect-debug.sh"
```

Generated output:

```text
/sdcard/Download/pixel_thermal_debug_*.zip
```

Review generated output before posting it publicly.

Do not post raw tokens, private hostnames, private IPs, MAC addresses, personal paths, or unrelated logs.

When reporting issues, include:

- device and codename
- Android version, build ID, incremental and fingerprint
- root solution and version
- module version and install/update path
- compat-check result
- debug ZIP, plus the Magisk install log or install screenshot when relevant

For Magisk module-state or toggle issues:

```sh
cd /sdcard/Download
curl -fsSLO https://raw.githubusercontent.com/Lycidias93/pixel-10-pro-xl-thermal-fix/main/tools/pixel_thermal_toggle_debug.sh
su -c "sh -n /sdcard/Download/pixel_thermal_toggle_debug.sh && sh /sdcard/Download/pixel_thermal_toggle_debug.sh"
```

Generated module-state output:

```text
/sdcard/Download/pixel_thermal_toggle_debug_*.txt
```

This helper is read-only; it does not delete, disable, enable, mount, or patch anything.

---

## Install options

| Option | Meaning |
|---|---|
| **Use last settings** | Reuses the previous thermal/ZRAM choices |
| **Fresh defaults** | Safe fallback when no saved settings exist |
| **Outdoor Extended** | Verified 1.5 thermal profile path |
| **Polling mod** | Preserved verified polling behavior |
| **pTune Override** | OFF by default |
| **ZRAM 100p** | Optional memory profile, verified in 1.5 |

---

## Safety notes

Stable 1.5 intentionally does **not** include:

- TensorConservative sysfs/procfs writes
- direct profile resolver layout switching
- unsupported device/build activation
- thermal safety disablement
- blind Android 17 support using unrelated files

The module prefers guarded activation over risky auto-detection.

Advanced compatibility:

- **pTune:** advanced/experimental. pTune Override stays OFF by default and requires an explicit risk acknowledgement.
- **KernelSU-Next / mountify:** community-tested paths exist, but verify `ACTIVE_VENDOR_MATCH=yes` after reboot.
- **Unknown root or mount backends:** collect debug evidence before reporting; do not force unsupported profiles.

---

## Verified Stable 1.5 runtime

- Pixel 10 Pro XL / `mustang`
- Android 17 `CP2A.260605.012`
- Incremental `15430684`
- Outdoor Extended
- Polling mod
- pTune Override OFF
- ZRAM 100p runtime PASS
- Thermal tombstone index empty or absent

Artifact:

```text
pixel-10-thermal-memory-control-1.5-universal.1.zip
SHA256: 225013f7e51cb29b1ceebb1460f6f5125c134518ae900c2587f4416c2b6f057f
```

---

## Rollback / emergency disable

Normal rollback: disable or remove the module in Magisk, then reboot.

Emergency disable from a root shell:

```sh
su -c "touch /data/adb/modules/pixel-10-pro-xl-thermal-fix/disable"
su -c "reboot"
```

If mount behavior is the suspected issue:

```sh
su -c "touch /data/adb/modules/pixel-10-pro-xl-thermal-fix/skip_mount"
su -c "reboot"
```

---

## Project files

| File | Purpose |
|---|---|
| [RELEASE_NOTES_v1.5-universal.1.md](RELEASE_NOTES_v1.5-universal.1.md) | Stable 1.5 release summary |
| [CHANGELOG.md](CHANGELOG.md) | Full change history |
| [CREDITS.md](CREDITS.md) | Credits and acknowledgements |
| [VERIFY_MUSTANG.md](VERIFY_MUSTANG.md) | Mustang verification notes |
| [docs/test29_profile_layout_mapping.md](docs/test29_profile_layout_mapping.md) | Profile-layout mapping audit notes |

---

## Credits

Created by **Lycidias93**, based on earlier work by **marx161**.

Stable 1.5 includes testing, feedback, and reference work from **Harish / Codecity001**, **JoshuaDoes**, **Allen Chang**, **Jiggs**, **maicol07**, and the existing project acknowledgements.

See [CREDITS.md](CREDITS.md) for the detailed list.

---

## License

See [LICENSE](LICENSE).
