# Pixel 10 thermal profile (`frankel`)

- Source build: `CP1A.260505.005`
- Source basis: Google factory image thermal JSON evidence.
- Profile transform: minimal VIRTUAL-SKIN polling delay overlay.
- Profile state: `beta/pending` until live owner install and post-reboot verify.
- Factory image SHA-256: `7e12c8607a7af176ec7233f4df4609f2f2eae53e0ae818547b9aade07255d1d3`
- VIRTUAL-SKIN total from evidence: `44`
- Only allowed `PollingDelay` / `PollingDelayMs` fields are set to `5000`.
- No CPU cdev, PIDInfo, threshold, frequency, power-rail, or non-polling fields are changed.
- Do not infer runtime safety from another Pixel 10 device.

## Applied polling changes

### `thermal_info_config.json`

- `VIRTUAL-SKIN-SPEAKER` at `Sensors[11].PollingDelay`: `300000` -> `5000`

### `thermal_info_config_charge.json`

- `VIRTUAL-SKIN-CHARGE-WIRED` at `Sensors[20].PollingDelay`: `300000` -> `5000`
- `VIRTUAL-SKIN-CHARGE-PERSIST` at `Sensors[21].PollingDelay`: `300000` -> `5000`

### `thermal_info_config_throttling.json`

- `VIRTUAL-SKIN` at `Sensors[8].PollingDelay`: `300000` -> `5000`
- `VIRTUAL-SKIN-HINT` at `Sensors[9].PollingDelay`: `300000` -> `5000`
- `VIRTUAL-SKIN-CPU-LIGHT-ODPM` at `Sensors[10].PollingDelay`: `300000` -> `5000`
- `VIRTUAL-SKIN-CPU-MID` at `Sensors[11].PollingDelay`: `300000` -> `5000`
- `VIRTUAL-SKIN-CPU-ODPM` at `Sensors[12].PollingDelay`: `300000` -> `5000`
- `VIRTUAL-SKIN-CPU-HIGH` at `Sensors[13].PollingDelay`: `300000` -> `5000`
- `VIRTUAL-SKIN-SOC` at `Sensors[14].PollingDelay`: `300000` -> `5000`
- `VIRTUAL-SKIN-SOC-EXTREME` at `Sensors[19].PollingDelay`: `300000` -> `5000`

## Skipped VIRTUAL-SKIN polling candidates

These remained at factory values because they are outside the minimal allowlist.

### `thermal_info_config.json`

- `VIRTUAL-SKIN-CPU-LIGHT-ODPM` at `Sensors[14].PollingDelay` remains `300000`

### `thermal_info_config_charge.json`

- None.

### `thermal_info_config_throttling.json`

- None.

## Required live verify before stable support

- Magisk install log with selected profile.
- Pre-reboot staging check.
- Post-reboot overlay/mount check.
- Semantic sensor-value check.
- `fresh_thermalhal_tombstone=absent`.
