# Pixel 10 Thermal & Memory Control

**Magisk module for Pixel 10-series thermal profiles, dynamic manager status, Action settings, and optional ZRAM 100p.**

Stable **1.5.1-universal.1** promotes the verified Test7 dynamic manager Ampel/Action dashboard line on top of Stable 1.5: P/T/Z status with active values, Settings/Debug/Advanced menus, pTune status consistency, profile-matrix verification, and ZRAM 100p runtime proof.

[Download latest release](https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/releases/latest) · [Telegram](https://t.me/lycidias93) · [Issues](https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/issues) · [Release notes](RELEASE_NOTES_v1.5.1-universal.1.md) · [Changelog](CHANGELOG.md) · [Credits](CREDITS.md)

---

## Current pre-release alpha channel

- Current public pre-release: **1.5.2-universal-v2-alpha.1**.
- V2 dynamically reads the exact build's stock thermal files and materializes a validated overlay.
- Only the three critical files are controlled: base, charge and throttling.
- Mustang / Android 17 / CP2A.260705.006 is runtime verified with Stock Thermal, Polling Mod, 22 active 5000 values, pTune disabled and module ZRAM disabled.
- Blazer / Android 17 stable is community runtime PASS, confirmed by Harish / Codecity001. Exact build-ID and debug-bundle capture remain evidence-hardening follow-up and do not revoke the PASS.
- frankel, rango and Canary/ZP remain alpha validation targets; an exact supported build and a working recovery path are required.
- Test ZRAM 100p separately only after the base thermal reboot and runtime checks are green.
- Stable channel remains **1.5.1-universal.1** and stable update.json is unchanged.
- Alpha users may opt into the V2 test update channel through Action > Advanced > Update Channel.
- Living validation status and Beta gate: [V2 Alpha validation plan](docs/v2-alpha-validation-plan.md).

## What this module does

This module installs guarded Pixel 10 thermal and memory overlays through Magisk. It does **not** replace Android thermal management; the stock thermal HAL remains in control while selected profile inputs are changed for supported device/build combinations.

Main functions:

- **Thermal polling:** preserves the verified polling-mod path for supported Pixel 10 thermal configs. In daily use, this aims for more consistent thermal sensor/update behavior during longer load, charging, navigation, camera use, or outdoor use.
- **Throttling profiles:** applies guarded `thermal_info_config*.json` profile overlays, including the verified **Outdoor Extended** path. This can make sustained load feel less abrupt by using tested profile variants, without disabling thermal safety.
- **ZRAM 100p:** optional boot/runtime memory profile for the verified ZRAM 100p path. This can help multitasking under memory pressure and reduce app reloads in daily use.
- **Compatibility guard:** activates only when device/build/profile evidence matches the supported matrix. This reduces the risk of applying the wrong thermal profile to an unknown build.

It is **not** an overclock, benchmark unlock, FPS tweak, or thermal safety bypass.

---

## Stable 1.5.1 highlights

| Area | Stable 1.5.1 |
|---|---|
| Install UX | Use-last flow plus Action dashboard for Status, Settings, Debug ZIP, Advanced and Exit |
| Safety | Fresh-default fallback, pTune status consistency, and known-bad version/runtime split |
| Thermal | Outdoor Extended verified and promoted |
| Memory | Optional ZRAM 100p boot/runtime path verified |
| Compatibility | Profile Matrix PASS count 67 and dynamic thermal overlay checks |
| Refactor | Thermal/ZRAM helper cleanup plus manager status/action helpers promoted to stable |
| Profiles | Harish / Codecity001 profile-layout mapping audit plus Allen Chang Beta 1/QPR1 feedback preserved |

---

## Runtime and factory-basis status

Stable 1.5.1 remains intentionally honest:

- Runtime-proven on **mustang**.
- Factory-basis covered for all G5 Pixel 10 devices.
- Runtime feedback is still needed for **frankel**, **blazer**, and **rango**.

Runtime PASS:

- `mustang / CP2A.260605.012 / outdoor-extended / polling mod / ZRAM 100p`
- `mustang / CP31.260618.005 / outdoor-plus / polling mod / ZRAM 100p`

Factory-basis PASS:

- `frankel / CP31.260618.005`
- `blazer / CP31.260618.005`
- `mustang / CP31.260618.005`
- `rango / CP31.260618.005`

`CP31.260618.005` is the current QPR1 Beta 6 factory basis for frankel, blazer, mustang and rango.

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

## Manager status and Action dashboard

`1.5.1-universal.1` adds a verified status line for module managers:

```text
P:🟢 mod | T:🟢 outdoor-ext | Z:🟢 100p | Action: settings/debug
```

The status is refreshed after boot and whenever the module Action is opened. If the manager caches module descriptions, reopen or refresh the manager after using Action.

The Action button opens an extended terminal dashboard with Status, Settings for Polling/Thermal/ZRAM, Debug ZIP creation, Advanced pTune status/override guards, and Exit.

Action menu quick guide:

- Navigation: Vol+ cycles, Vol- selects, 30s timeout keeps the shown choice.

- Status: refreshes P, T, Z and manager description.
- Settings > Polling: Mod values or Stock values; rematerializes the thermal overlay.
- Settings > Thermal: Stock, Outdoor Safe, Outdoor Plus, or Outdoor Ext; reboot recommended.
- Settings > ZRAM: Enabled or Disabled; disabling needs reboot.
- Debug > Debug ZIP: creates a report in Download.
- Debug > Boot Crash Archive: creates a boot-crash evidence archive.
- Debug > Bootguard: shows Bootguard and last-good diff.
- Debug > Clear Counters: resets Bootguard counters only; disable state is preserved.
- Advanced > Update Channel: switches the Magisk update path only; no ZIP download.
- Advanced > pTune Status or pTune OFF or pTune ON: inspect or explicitly allow pTune coexistence risk.


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

Stable 1.5.1 intentionally does **not** include:

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

## Outdoor profile temperature deltas

The Outdoor profiles are staged thermal profile deltas, not thermal-safety bypass modes.

For the current mustang CP2A profile set:

| Variant | VIRTUAL-SKIN thresholds | Delta vs base | VIRTUAL-SKIN-HINT thresholds | Delta vs base |
|---|---:|---:|---:|---:|
| Base | 39 / 43 / 45 / 46.5 / 52 / 55 C | baseline | 37 / 43 / 45 / 46.5 / 52 / 55 C | baseline |
| outdoor-safe | 40 / 44 / 46 / 47.5 / 53 / 56 C | +1 C each | 38 / 44 / 46 / 47.5 / 53 / 56 C | +1 C each |
| outdoor-plus | 41 / 45 / 47 / 48.5 / 54 / 57 C | +2 C each | 39 / 45 / 47 / 48.5 / 54 / 57 C | +2 C each |
| outdoor-extended | 42 / 46 / 48 / 49.5 / 55 / 58 C | +3 C each | 40 / 46 / 48 / 49.5 / 55 / 58 C | +3 C each |

Short version: safe = base +1 C, plus = base +2 C, extended = base +3 C for the main VIRTUAL-SKIN and VIRTUAL-SKIN-HINT threshold rows.

Outdoor Extended is not always better. It is the strongest outdoor delta and should stay limited to tested device/build combinations. For unknown builds, Stock or Safe fallback should be used until anchors and runtime behavior are verified.

These modes do not disable core thermal safety.

## 1.5.2-universal-test.7 Canary diagnostic

- Adds a guarded diagnostic path for Canary/ZP builds.
- On Canary/ZP, install is debug-only: no thermal overlay, no Outdoor profile, no ZRAM fstab.
- Creates /sdcard/Download/pixel_thermal_canary_diagnostic_*.tgz during install.
- Normal supported non-Canary builds keep the existing test.6 behavior.
