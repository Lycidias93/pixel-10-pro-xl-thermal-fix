# Pixel 10 Thermal & Memory Control

**Dynamic V2 Magisk module for guarded Pixel 10 thermal profiles, stock-derived runtime validation, optional ZRAM tuning, controlled LMKD experiments, Bootguard recovery, and an interactive Action dashboard.**

Dynamic V2 is the active source architecture on `main`.

[Latest stable](https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/releases/tag/v2.0.1) · [Latest prerelease](https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/releases/tag/v2.0.0-alpha.3-dev.21) · [All releases](https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/releases) · [Telegram](https://t.me/lycidias93) · [Issues](https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/issues) · [Release notes](release-notes/README.md) · [Changelog](CHANGELOG.md) · [Credits](CREDITS.md)

> [!IMPORTANT]
> **2.0.1 is the current stable release.** The August hotfix passed full post-reboot Bootguard/runtime verification on a Pixel 10 Pro XL (`mustang`) running Android 17 build `CP2A.260805.005` with KernelSU; August Canary was independently verified, and the July Stable Magisk regression remained green. Experimental Emerald Hill and LMKD controls remain opt-in.

## Current release

| Item | Value |
|---|---|
| Version | `2.0.1` |
| Version code | `1016241` |
| Release type | Stable Dynamic V2 hotfix, device-verified |
| Tag | `v2.0.1` |
| Asset | `pixel-10-thermal-memory-control-2.0.1.zip` |
| Asset size | `330935` bytes |
| SHA-256 | `6517cd106acd063e52596d4fc0f2e561cd019cdaa3712e930fcddaf746d4dbaa` |
| Device proof | `mustang / CP2A.260805.005 / Android 17 / KernelSU full post-reboot` |

2.0.1 keeps the full Dynamic V2 stable feature set and fixes independent Outdoor-delta validation for newer compact or multiline `HotThreshold` arrays. The August Stable KernelSU runtime proof confirms the active three-file Thermal overlay, Polling Mod at 22/22 values of `5000`, Bootguard full-pass behavior, and ZRAM 100%; the July Stable Magisk regression remained green.

The stable and test update paths remain independent. Selecting a channel changes only the active update metadata path; it does not download or flash a ZIP.

## What the module is designed to do

The module combines two guarded control areas:

1. **Thermal policy overlays** built from the device's own stock configuration.
2. **Optional memory controls** for ZRAM, Emerald Hill acceleration, and LMKD behavior.

The main goals are:

- keep monthly firmware compatibility without shipping a separate static profile for every build;
- change only explicitly admitted values in three stock thermal files;
- improve thermal-response timing and offer controlled Outdoor threshold profiles;
- provide optional compressed-memory headroom;
- make every risky memory option explicit, reversible, and evidence-backed;
- fail closed on unsupported platforms, invalid overlays, pTune conflicts, or unhealthy boots;
- avoid a permanent monitoring daemon or repeated background verification on unchanged normal boots.

## Supported platforms

### Devices

| Codename | Device |
|---|---|
| `mustang` | Pixel 10 Pro XL |
| `blazer` | Pixel 10 Pro |
| `frankel` | Pixel 10 |
| `rango` | Pixel 10 Pro Fold |

### Android

- Supported Android major version: **Android 17**
- Magisk remains a verified reference backend; the July Stable regression passed on Mustang.
- KernelSU is also device-verified on Mustang with August Stable full post-reboot Bootguard/runtime proof.
- KernelSU Next, SukiSU and APatch-style environments are detected, but they do not currently have the same device-proof coverage.
- Minimum installation battery: **15%**

### Build admission

Exact build IDs are evidence, not the only activation gate.

| Evidence state | Meaning |
|---|---|
| `exact_verified` | The device/build tuple already has exact repository evidence. |
| `dynamic_unverified` | The codename and Android version are supported; the module validates the device's local stock files before creating an overlay. |
| `unsupported_platform` | Unknown codename or unsupported Android version; Thermal remains disabled while optional ZRAM can remain available. |

A new monthly or Canary build on a supported device does not need a repository update merely to open Action. It must still pass local stock-structure, controlled-diff, manifest, exact-delta, and active-runtime validation.

<details>
<summary>Currently registered exact build IDs</summary>

- **Mustang:** `CP1A.260505.005`, `CP21.260330.011`, `CP2A.260605.012`, `CP2A.260705.006`, `CP31.260522.006`, `CP31.260618.005`
- **Blazer:** `CP1A.260505.005`, `CP21.260330.011`, `CP2A.260605.012`, `CP2A.260705.006`, `CP31.260522.006`, `CP31.260618.005`, `ZP11.260618.005`
- **Frankel:** `CP1A.260505.005`, `CP21.260330.011`, `CP2A.260605.012`, `CP2A.260705.006`, `CP31.260522.006`, `CP31.260618.005`, `ZP11.260618.005`
- **Rango:** `CP1A.260505.005`, `CP21.260330.011`, `CP2A.260605.012`, `CP2A.260705.006`, `CP31.260522.006`, `CP31.260618.005`

</details>

## Dynamic thermal architecture

The module reads and validates the device's own stock copies of:

- `thermal_info_config.json`
- `thermal_info_config_charge.json`
- `thermal_info_config_throttling.json`

It then:

1. captures source hashes and structural evidence;
2. creates a controlled overlay from those local stock files;
3. changes only admitted Polling and Outdoor targets;
4. independently verifies exact deltas and generated manifests;
5. promotes the validated result into the module overlay;
6. verifies the active `/vendor/etc` files after reboot;
7. records a last-good state for Bootguard.

The module does **not** replace the stock thermal HAL, remove emergency/shutdown protections, or globally disable Android thermal management.

### Firmware and platform transitions

When the Android build or platform tuple changes, the early boot path quarantines stale thermal overlays, recaptures current stock files, and rematerializes only after validation. A failed transition sets `skip_mount` or disables Thermal rather than mounting an overlay from the wrong firmware.

## Feature reference

### Polling Mode

| Mode | Operation | Goal and likely effect |
|---|---|---|
| Module values | Changes admitted `PollingDelay: 300000` values to `5000` in the three controlled files. | Evaluates relevant thermal policy more frequently and can react sooner to temperature changes. It may add a small amount of polling work. |
| Stock values | Preserves the stock polling values. | Maximum stock behavior and lowest module-added polling activity. |

Only the admitted `PollingDelay` entries are changed. Stock passive-delay behavior while throttling remains untouched.

### Thermal profiles

| Profile | Controlled Outdoor delta | Intended use | Trade-off |
|---|---:|---|---|
| Stock | `+0 °C` | Original device thresholds | Stock performance and temperature behavior |
| Outdoor Safe | `+1 °C` | Conservative extra headroom | Slightly more heat may be allowed before selected throttling |
| Outdoor Plus | `+2 °C` | Stronger sustained-performance bias | Higher surface temperature and battery use are possible |
| Outdoor Extended | `+3 °C` | Maximum admitted profile | Highest heat/performance trade-off in the current policy |

These deltas apply only to validated Outdoor target entries. Higher profiles may delay selected throttling responses, which can improve sustained performance or brightness at the cost of additional heat and power use. They do not intentionally change emergency, shutdown, USB, charging, speaker, or unrelated thermal limits.

### ZRAM 100%

ZRAM is optional but enabled by default in a fresh 2.0.1 install unless the user selects Disabled.

When enabled, the module configures:

- ZRAM target size `100p` / approximately total physical RAM;
- `lz77eh` compression when exposed by the platform;
- `vm.swappiness=100`;
- early property application and one postboot reapply;
- active-swap and non-zero-disksize verification.

The configured size is capacity, not pre-filled memory. The goal is to provide more compressed-memory headroom and reduce avoidable app reloads under pressure. Compression consumes CPU time, and very heavy memory pressure can still reduce responsiveness.

### Emerald Hill mode

Emerald Hill controls the devfreq path used by the ZRAM acceleration hardware.

| Mode | Behavior | Goal and impact |
|---|---|---|
| Adaptive | Leaves normal devfreq scaling active. | Recommended daily mode; balances compression performance, heat, and battery use. |
| **EXPERIMENTAL max lock** | Raises the minimum frequency to the maximum validated hardware OPP and verifies readback. | Can reduce compression latency under pressure, but higher heat and battery use are expected. |

The max lock is separate from normal ZRAM and is found under **Action → Advanced → Emerald Hill mode**. It is not a CPU or GPU overclock. Apply and restore events are recorded with boot ID, caller, physical node, original minimum, target, and readback. A failed apply restores adaptive operation.

### LMKD 1% reload

LMKD is Android's Low Memory Killer Daemon. The experimental option sets:

```text
ro.lmk.swap_free_low_percentage=1
```

2.0.1 uses Magisk system `resetprop` first for this one property, verifies readback, and falls back to `resetprop-rs` only when required. Normal ZRAM properties continue to use `resetprop-rs`.

After the write, the module:

1. prefers the targeted AOSP `lmkd.reinit` path;
2. verifies acknowledgement and service state;
3. uses a verified LMKD restart only as fallback;
4. records property writer, property before/after, method, PID, service state, boot ID, and result.

The goal is to make LMKD treat swap as critically low only below 1% free swap, roughly when ZRAM is 99% used. This can reduce kills caused by that specific swap-starvation threshold. It does **not** disable LMKD, and Android can still kill processes because of PSI pressure, thrashing, low memory, or other policies.

Requirements and boundaries:

- disabled by default;
- requires ZRAM 100%;
- requires explicit acknowledgement;
- works at boot and from Action;
- no separate permanent LMKD helper daemon;
- restore may require a reboot when the original property cannot be proven safely.

See the [AOSP LMKD documentation](https://source.android.com/docs/core/perf/lmkd) for the broader Android memory-management model.

### pTune conflict guard

pTune can touch overlapping thermal or memory controls. The default guard:

- detects installed or staged pTune modules;
- blocks the Thermal overlay when an active conflict exists;
- keeps ZRAM independently available where safe;
- exposes pTune status in Action;
- requires an explicit high-risk acknowledgement for coexistence;
- blocks known-bad pTune states from using the override.

The override is intentionally off by default. Enabling or disabling it requires reinstall/reflash so the mount decision is made during the guarded boot path.

### Bootguard

Bootguard evaluates the previous boot before mounting the current overlay and records a signed last-good state.

It can:

- detect a previous pending or incomplete boot;
- increment bounded failure counters;
- set `disable` and `skip_mount` after the configured threshold;
- preserve current stock behavior when validation fails;
- verify the active overlay and thermal service before marking success;
- escalate from the lightweight path back to full verification after any relevant change.

### Full and lightweight boots

A **full** verification runs after:

- first installation;
- module update;
- Android firmware/build change;
- configuration or overlay change;
- pending platform transition;
- previous pending boot;
- missing or invalid last-good evidence;
- debug or Canary mode.

An unchanged, previously verified normal boot uses the **fast** path:

- load selected settings;
- apply ZRAM, LMKD and Emerald Hill state;
- perform lightweight live readbacks;
- refresh the manager badges;
- exit.

There is no permanent module verification service. **Verbose Debug intentionally forces full verification on every boot.** Switch Debug Logging to Silent after testing to enable the unchanged-boot fast path.

### Automatic manager badges

The Magisk description is refreshed after boot and after Action changes:

```text
P:🟢 5000 | T:🟢 outdoor-ext | Z:🟢 100p | L:🟢 1pct-active
```

| Badge | Meaning |
|---|---|
| `P` | Polling mode and active value |
| `T` | Thermal profile |
| `Z` | ZRAM state |
| `L` | LMKD policy and reload state |

| Color | Meaning |
|---|---|
| 🟢 | Active and verified |
| 🟡 | Configured or validated but waiting for reboot/runtime confirmation |
| 🔴 | Failed, unsafe, unsupported, or disabled by a guard |
| ⚪ | Stock or off |

The compact `Z` badge shows ZRAM state, not the Emerald Hill submode. Check **Action → Advanced → Emerald Hill mode** for Adaptive versus max lock.

## Installation

### Requirements

- supported Pixel 10 device;
- Android 17;
- Magisk or a compatible module manager;
- at least 15% battery;
- a known way to disable modules from recovery or safe mode;
- no unreviewed active pTune conflict.

### Install steps

1. Download `pixel-10-thermal-memory-control-2.0.0.zip` from the [2.0.0 stable release](https://github.com/Lycidias93/pixel-10-pro-xl-thermal-fix/releases/tag/v2.0.0).
2. Verify the SHA-256 shown in [Current release](#current-release).
3. Install the ZIP from Magisk.
4. Use the volume-key menu:
   - **Volume Up:** next option
   - **Volume Down:** select
   - **30-second timeout:** keep the currently shown option
   - **Power key:** not used
5. Choose saved settings or fresh choices.
6. Review the final install summary.
7. Reboot.

### Fresh-install defaults

| Setting | Default |
|---|---|
| Polling | Module values |
| Thermal | Stock |
| ZRAM | Enabled |
| Emerald Hill | Adaptive |
| LMKD 1% reload | Disabled |
| pTune override | Off |
| Debug logging | Verbose |

Verbose Debug is useful for the first test cycle but causes full verification at every boot. For normal use, change it to Silent from **Action → Debug → Debug Logging**.

### First boot expectations

- The first boot after install/update should report `boot_verification_mode=full`.
- With Debug set to Silent and no settings/build changes, a later unchanged boot should report `boot_verification_mode=fast`.
- A changed build, changed config, transition, or failed readback automatically returns to full verification.

## Magisk Action dashboard

Open **Action** on the module card. The menu uses the same Volume Up/Volume Down controls.

### Settings

- **Polling Mode:** Module or stock values.
- **Thermal Profile:** Stock, Outdoor Safe, Outdoor Plus, or Outdoor Extended.
- **ZRAM 100%:** enable or disable the ZRAM layout and runtime properties.

Thermal and ZRAM layout changes are materialized safely and may require a reboot for the active vendor mount/layout guarantee.

### Debug

- **Status:** refresh and print detailed source, overlay, Polling, Thermal, ZRAM, LMKD, pTune and Bootguard state.
- **Collect ZIP:** create a bounded debug archive.
- **EH Event Log:** show recent Emerald Hill apply/restore evidence.
- **LMKD Reload Evidence:** show writer, method, PID, property and service proof.
- **Debug Logging:** toggle Silent or Verbose.

### Advanced

- **Emerald Hill mode:** Adaptive or experimental max lock.
- **LMKD 1% reload:** Stock or experimental 1%.
- **pTune Status:** detected path, enabled state, version and known-bad state.
- **pTune Override:** explicit coexistence risk control.
- **Update Channel:** Stable or Test metadata path.

The Action dashboard does not perform a network refresh during normal startup.

## Runtime verification

The easiest check is **Action → Debug → Status**.

A direct compatibility check is also available:

```sh
su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/bootguard/compat-check.sh
```

Healthy Thermal runtime markers include:

```text
DYNAMIC_MATERIALIZATION_VALID=yes
MODULE_OVERLAY_READY=yes
ACTIVE_VENDOR_MATCH=yes
ACTIVE_POLLING_VALID=yes
SAFE_TO_REBOOT=yes
```

For LMKD, **Action → Debug → LMKD Reload Evidence** should show:

```text
reload_result=success
property_after=1
property_writer=magisk_resetprop
lmkd_service_after=running
```

`property_writer=resetprop_rs_fallback` is also valid when the system writer is unavailable and the readback succeeds.

## Update channels

Use **Action → Advanced → Update Channel**.

- **Stable:** follows the separately maintained stable metadata.
- **Test:** follows public prereleases such as 2.0.0.
- Switching changes `updateJson` only.
- It does not download, install, or flash anything.
- Refresh Magisk's update check after switching.

A source commit does not automatically publish a release or move either channel. Tags, assets, and channel changes remain separate publication steps.

## Debugging and issue reports

Create a debug archive from Action or run:

```sh
su -c /data/adb/modules/pixel-10-pro-xl-thermal-fix/tools/bootguard/collect-debug.sh
```

The archive can include:

- device, Android and build identity;
- selected configuration;
- install state and validation manifests;
- active and generated thermal hashes;
- Bootguard and platform-transition state;
- ZRAM runtime state;
- Emerald Hill event evidence;
- LMKD property/reload evidence;
- pTune state;
- bounded current and previous-boot diagnostics.

Review the archive before posting it publicly.

A useful issue report includes:

- device model and codename;
- Android version, build ID and incremental;
- module version;
- fresh or remembered install choices;
- whether pTune is installed or active;
- whether Debug is Silent or Verbose;
- install autosave log;
- debug ZIP or relevant bounded evidence;
- exact reproduction steps and whether a reboot was involved.

## Recovery and rollback

### Normal rollback

1. Disable or remove the module in Magisk.
2. Reboot.

### Emergency disable

```sh
su -c 'touch /data/adb/modules/pixel-10-pro-xl-thermal-fix/disable'
su -c reboot
```

### Mount-only emergency bypass

```sh
su -c 'touch /data/adb/modules/pixel-10-pro-xl-thermal-fix/skip_mount'
su -c reboot
```

`disable` prevents the module from running. `skip_mount` keeps the module files available for diagnosis while preventing the overlay mount.

### Uninstall cleanup

Removing the module in Magisk and rebooting should remove:

- `/data/adb/modules/pixel-10-pro-xl-thermal-fix`
- `/data/adb/pixel-10-pro-xl-thermal-fix`

The module uninstaller explicitly removes its persistent data and guard state; the module manager removes the active module directory.

## What the module does not do

- It does not overclock the CPU or GPU.
- It does not replace the Pixel thermal HAL.
- It does not disable emergency or shutdown thermal protection.
- It does not remove all throttling.
- It does not disable LMKD or guarantee that apps will never be killed.
- It does not continuously verify the device in the background.
- It does not use a permanent screen-on, polling, LMKD, or Emerald Hill watcher.
- It does not silently allow an active pTune conflict.
- It does not apply a Thermal overlay to an unsupported device or Android major version.
- It does not treat a repository test as proof for every Pixel 10 model and firmware.

## Evidence boundaries

2.0.0 has detailed postboot evidence on Pixel 10 Pro XL (`mustang`) and external Pixel 10 Pro (`blazer`) testing. Platform support for `frankel` and `rango` is implemented, but each new device/build combination still benefits from fresh on-device evidence.

A green CI run proves repository behavior, packaging, fixtures, and static contracts. It does not replace installation, reboot, active-vendor, ZRAM, LMKD, pTune, or hardware evidence.

## Repository and development

- `main` is the canonical Dynamic V2 source.
- `v2` is retained as a protected rollback/reference branch.
- Documentation-only maintenance may use one short-lived branch.
- Non-trivial features are proven on test branches, reconstructed from the latest target branch into approximately one to four logical commits, and fully retested on that exact cleaned head before merge.
- Runtime, installation, boot, or hardware-dependent changes require fresh device verification after reconstruction.
- Flashable ZIPs are deterministic and exclude repository-only documentation, tests, fixtures, workflows, and nested archives.

See [Development and integration workflow](docs/DEVELOPMENT_WORKFLOW.md).

## Credits

Created and maintained by **Lycidias93**, based on earlier work by **marx161**.

Current Dynamic V2 development and testing includes major contributions and evidence from:

- **Harish / Codecity001**
- **Allen Chang**
- **JoshuaDoes / pTune**
- **marx161**
- community testers and existing project contributors

See [CREDITS.md](CREDITS.md) for detailed attribution.

## License

See [LICENSE](LICENSE).
