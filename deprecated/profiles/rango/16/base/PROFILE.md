# Pixel 10 Pro Fold thermal profile (`rango`)

- Source build: `CP1A.260505.005`
- Source basis: Google factory image thermal JSON evidence.
- Profile transform: minimal VIRTUAL-SKIN polling delay overlay.
- Profile state: `beta/pending` until live owner install and post-reboot verify.
- Android scope: Android 16 only; Android 17 requires a separate factory evidence/profile set.
- Factory image SHA-256: `18bf79d917dfc411a062ada4494c573cb26ca4bcbca7c3f6ea4576e4fc883b37`
- VIRTUAL-SKIN total from evidence: `60`
- Only allowed `PollingDelay` / `PollingDelayMs` fields are set to `5000`.
- No CPU cdev, PIDInfo, threshold, frequency, power-rail, or non-polling fields are changed.
- Do not infer runtime safety from another Pixel 10 device.

## Applied polling changes

### `thermal_info_config.json`

- No allowed polling candidate found.

### `thermal_info_config_charge.json`

- `VIRTUAL-SKIN-CHARGE-WIRED` at `Sensors[26].PollingDelay`: `300000` -> `5000`
- `VIRTUAL-SKIN-CHARGE-PERSIST` at `Sensors[30].PollingDelay`: `300000` -> `5000`

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

- `VIRTUAL-SKIN` at `Sensors[16].PollingDelay` remains `300000`
- `VIRTUAL-SKIN-HINT` at `Sensors[17].PollingDelay` remains `300000`
- `VIRTUAL-SKIN-CPU-LIGHT-ODPM` at `Sensors[18].PollingDelay` remains `300000`
- `VIRTUAL-SKIN-CPU-MID` at `Sensors[19].PollingDelay` remains `300000`
- `VIRTUAL-SKIN-CPU-ODPM` at `Sensors[20].PollingDelay` remains `300000`
- `VIRTUAL-SKIN-CPU-HIGH` at `Sensors[21].PollingDelay` remains `300000`
- `VIRTUAL-SKIN-SOC` at `Sensors[22].PollingDelay` remains `300000`
- `VIRTUAL-SKIN-INNER-DISPLAY` at `Sensors[23].PollingDelay` remains `300000`
- `VIRTUAL-SKIN-OUTER-DISPLAY` at `Sensors[25].PollingDelay` remains `300000`
- `VIRTUAL-SKIN-TOP-SPEAKER` at `Sensors[34].PollingDelay` remains `300000`
- `VIRTUAL-SKIN-BOTTOM-SPEAKER` at `Sensors[35].PollingDelay` remains `300000`

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
