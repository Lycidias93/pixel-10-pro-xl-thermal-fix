# Verify Pixel 10 Pro XL Thermal Polling Fix

## Target

- Device: Pixel 10 Pro XL
- Codename: `mustang`
- Android: 16
- Build: `CP1A.260505.005/15081906`

## v1.3-mustang.3 expected scope

Only this module overlay should exist:

```text
system/vendor/etc/thermal_info_config_throttling.json
```

Removed from active module scope:

```text
system/vendor/etc/thermal_info_config.json
system/vendor/etc/thermal_info_config_charge.json
```

Only one semantic value is expected to differ from live stock:

```text
VIRTUAL-SKIN-CPU-LIGHT-ODPM
PollingDelay: 300000 -> 5000
```

## Runtime success criteria

```text
disable=absent
skip_mount=absent
pending_boot=absent or missing
fail_count=absent or missing
last_boot_ok=present
PollingDelay=5000 for VIRTUAL-SKIN-CPU-LIGHT-ODPM
AshLooper loops=0
no new android.hardware.thermal-service.pixel tombstones
```

## Failure criteria

```text
/vendor/bin/hw/android.hardware.thermal-service.pixel
Abort message: ThermalHAL could not be initialized properly.
```

If that appears again with v1.3-mustang.3 active, this target sensor overlay is not safe on the current build.


## v1.3-mustang.4 - Pixel 10 Pro XL VIRTUAL-SKIN CPU ODPM bisect

Adds exactly one additional live-stock thermal throttling overlay change on top of v1.3-mustang.3:

- VIRTUAL-SKIN-CPU-LIGHT-ODPM: PollingDelay 300000ms -> 5000ms
- VIRTUAL-SKIN-CPU-ODPM: PollingDelay 300000ms -> 5000ms

No base thermal overlay and no charge overlay are included. AshLooper remains the primary bootloop protection.


## v1.3-mustang.5 - CPU-MID bisect

Adds VIRTUAL-SKIN-CPU-MID to the verified v1.3-mustang.4 baseline. Active target sensors:

- VIRTUAL-SKIN-CPU-LIGHT-ODPM: PollingDelay 300000ms -> 5000ms
- VIRTUAL-SKIN-CPU-ODPM: PollingDelay 300000ms -> 5000ms
- VIRTUAL-SKIN-CPU-MID: PollingDelay 300000ms -> 5000ms

No base thermal overlay and no charge overlay are included. AshLooper remains the primary bootloop protection.


## v1.3-mustang.6 - CPU-HIGH bisect

Adds VIRTUAL-SKIN-CPU-HIGH to the verified v1.3-mustang.5 baseline. Active target sensors:

- VIRTUAL-SKIN-CPU-LIGHT-ODPM: PollingDelay 300000ms -> 5000ms
- VIRTUAL-SKIN-CPU-ODPM: PollingDelay 300000ms -> 5000ms
- VIRTUAL-SKIN-CPU-MID: PollingDelay 300000ms -> 5000ms
- VIRTUAL-SKIN-CPU-HIGH: PollingDelay 300000ms -> 5000ms

No base thermal overlay and no charge overlay are included. AshLooper remains the primary bootloop protection.


## v1.3-mustang.7 - VIRTUAL-SKIN bisect

Adds the generic VIRTUAL-SKIN sensor to the verified v1.3-mustang.6 baseline. Active target sensors:

- VIRTUAL-SKIN: PollingDelay 300000ms -> 5000ms
- VIRTUAL-SKIN-CPU-LIGHT-ODPM: PollingDelay 300000ms -> 5000ms
- VIRTUAL-SKIN-CPU-ODPM: PollingDelay 300000ms -> 5000ms
- VIRTUAL-SKIN-CPU-MID: PollingDelay 300000ms -> 5000ms
- VIRTUAL-SKIN-CPU-HIGH: PollingDelay 300000ms -> 5000ms

No base thermal overlay and no charge overlay are included. AshLooper remains the primary bootloop protection.


## v1.3-mustang.8 - VIRTUAL-SKIN-HINT bisect

Adds VIRTUAL-SKIN-HINT to the verified v1.3-mustang.7 baseline. Active target sensors:

- VIRTUAL-SKIN: PollingDelay 300000ms -> 5000ms
- VIRTUAL-SKIN-HINT: PollingDelay 300000ms -> 5000ms
- VIRTUAL-SKIN-CPU-LIGHT-ODPM: PollingDelay 300000ms -> 5000ms
- VIRTUAL-SKIN-CPU-ODPM: PollingDelay 300000ms -> 5000ms
- VIRTUAL-SKIN-CPU-MID: PollingDelay 300000ms -> 5000ms
- VIRTUAL-SKIN-CPU-HIGH: PollingDelay 300000ms -> 5000ms

No base thermal overlay and no charge overlay are included. AshLooper remains the primary bootloop protection.


## v1.3-mustang.9 - VIRTUAL-SKIN-SOC bisect

Adds VIRTUAL-SKIN-SOC to the verified v1.3-mustang.8 baseline. Active target sensors:

- VIRTUAL-SKIN: PollingDelay 300000ms -> 5000ms
- VIRTUAL-SKIN-HINT: PollingDelay 300000ms -> 5000ms
- VIRTUAL-SKIN-CPU-LIGHT-ODPM: PollingDelay 300000ms -> 5000ms
- VIRTUAL-SKIN-CPU-ODPM: PollingDelay 300000ms -> 5000ms
- VIRTUAL-SKIN-CPU-MID: PollingDelay 300000ms -> 5000ms
- VIRTUAL-SKIN-CPU-HIGH: PollingDelay 300000ms -> 5000ms
- VIRTUAL-SKIN-SOC: PollingDelay 300000ms -> 5000ms

No base thermal overlay and no charge overlay are included. AshLooper remains the primary bootloop protection.


## v1.3-mustang.10 - VIRTUAL-SKIN-SOC-EXTREME bisect

Adds VIRTUAL-SKIN-SOC-EXTREME to the verified v1.3-mustang.9 baseline. Active target sensors:

- VIRTUAL-SKIN: PollingDelay 300000ms -> 5000ms
- VIRTUAL-SKIN-HINT: PollingDelay 300000ms -> 5000ms
- VIRTUAL-SKIN-CPU-LIGHT-ODPM: PollingDelay 300000ms -> 5000ms
- VIRTUAL-SKIN-CPU-ODPM: PollingDelay 300000ms -> 5000ms
- VIRTUAL-SKIN-CPU-MID: PollingDelay 300000ms -> 5000ms
- VIRTUAL-SKIN-CPU-HIGH: PollingDelay 300000ms -> 5000ms
- VIRTUAL-SKIN-SOC: PollingDelay 300000ms -> 5000ms
- VIRTUAL-SKIN-SOC-EXTREME: PollingDelay 300000ms -> 5000ms

No base thermal overlay and no charge overlay are included. AshLooper remains the primary bootloop protection.


## v1.3-mustang.11 - base VIRTUAL-SKIN-SPEAKER bisect

Adds one base thermal config sensor to the verified v1.3-mustang.10 throttling baseline:

- thermal_info_config.json / VIRTUAL-SKIN-SPEAKER: PollingDelay 300000ms -> 5000ms

The module keeps all eight throttling-only VIRTUAL-SKIN targets from v1.3-mustang.10 and does not add thermal_info_config_charge.json. VIRTUAL-SKIN entries with absent/null PollingDelay are intentionally left untouched. AshLooper remains the primary bootloop protection.


## v1.3-mustang.12 - charge VIRTUAL-SKIN-CHARGE-WIRED/PERSIST bisect

Adds both remaining true 300000ms charge thermal config sensors to the verified v1.3-mustang.11 baseline:

- thermal_info_config_charge.json / VIRTUAL-SKIN-CHARGE-WIRED: PollingDelay 300000ms -> 5000ms
- thermal_info_config_charge.json / VIRTUAL-SKIN-CHARGE-PERSIST: PollingDelay 300000ms -> 5000ms

The module keeps all eight throttling-only VIRTUAL-SKIN targets and the base VIRTUAL-SKIN-SPEAKER target. VIRTUAL-SKIN entries with absent/null PollingDelay are intentionally left untouched. AshLooper remains the primary bootloop protection.


## v1.3-mustang.13 - stable Mustang release

Stable cleanup release after verified v1.3-mustang.12 runtime testing. Runtime thermal scope is unchanged from v1.3-mustang.12:

- thermal_info_config_throttling.json: all eight verified VIRTUAL-SKIN* PollingDelay targets set to 5000ms
- thermal_info_config.json: VIRTUAL-SKIN-SPEAKER set to 5000ms
- thermal_info_config_charge.json: VIRTUAL-SKIN-CHARGE-WIRED and VIRTUAL-SKIN-CHARGE-PERSIST set to 5000ms

This release only corrects stale installer wording and finalizes stable documentation. Entries with absent/null PollingDelay remain untouched.


## v1.3-mustang.15 verify notes

`v1.3-mustang.15` is a tooling/support release. Runtime thermal scope is unchanged from `v1.3-mustang.14`.

Additional expected checks:

```text
debug_report_default_out_dir=/storage/emulated/0/Download
debug_report_manifest=present
debug_report_sanitizer_status=pass
zip_sha256_asset=present
```
