# Pixel 10 thermal VIRTUAL-SKIN map: rango

- Source factory image: `/storage/emulated/0/Download/pixel10_a17_factory_dump_work_cp21.260330.011/_downloads/rango_beta-cp21.260330.011-factory-37e096a2.zip`
- Source SHA-256: `37e096a22d27839b9ce2b0018ec603ecf44788c1ada4957d149e7cfff2a0922d`
- Status: evidence only; beta/pending until live device-owner verify.
- Safety: no cross-device value reuse by this dump script.

## thermal_info_config.json

- SHA-256: `2ffde3bcf7007cd5b7b5c2330bc2ce27776d275398eecaf8745081b01983e5f1`
- VIRTUAL-SKIN entry count: `33`

### $

- Names: `VIRTUAL-SKIN`, `VIRTUAL-SKIN-BOTTOM-SPEAKER`, `VIRTUAL-SKIN-CLOSE`, `VIRTUAL-SKIN-CLOSE-SUB-0`, `VIRTUAL-SKIN-CLOSE-SUB-1`, `VIRTUAL-SKIN-CLOSE-SUB-2`, `VIRTUAL-SKIN-CLOSE-SUB-3`, `VIRTUAL-SKIN-CLOSE-SUB-4`, `VIRTUAL-SKIN-CPU-HIGH`, `VIRTUAL-SKIN-CPU-LIGHT-ODPM`, `VIRTUAL-SKIN-CPU-MID`, `VIRTUAL-SKIN-CPU-ODPM`, `VIRTUAL-SKIN-HINT`, `VIRTUAL-SKIN-INNER-DISPLAY`, `VIRTUAL-SKIN-LEGACY`, `VIRTUAL-SKIN-LEGACY-SHUTDOWN`, `VIRTUAL-SKIN-MODEL`, `VIRTUAL-SKIN-MODEL-UPDATED`, `VIRTUAL-SKIN-MODEL-UPPER-CLAMPED`, `VIRTUAL-SKIN-OPEN`, `VIRTUAL-SKIN-OPEN-SUB-0`, `VIRTUAL-SKIN-OPEN-SUB-1`, `VIRTUAL-SKIN-OPEN-SUB-2`, `VIRTUAL-SKIN-OPEN-SUB-3`, `VIRTUAL-SKIN-OPEN-SUB-4`, `VIRTUAL-SKIN-OUTER-DISPLAY`, `VIRTUAL-SKIN-OUTER-DISPLAY-LEGACY`, `VIRTUAL-SKIN-SOC`, `VIRTUAL-SKIN-SPEAKER-CLOSE`, `VIRTUAL-SKIN-SPEAKER-LEGACY`, `VIRTUAL-SKIN-SPEAKER-OPEN`, `VIRTUAL-SKIN-TOP-SPEAKER`

```json
{
  "CoolingDevices": [],
  "Include": [
    "thermal_info_config_throttling.json",
    "thermal_info_config_charge.json",
    "thermal_info_config_stats.json",
    "thermal_info_config_vt.json"
  ],
  "PowerRails": [
    {
      "Coefficient": [
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0
      ],
      "Combination": [
        "S1M_VDD_AMB",
        "S2M_VDD_CPU2",
        "S3M_VDD_CPU1",
        "S4M_VDD_CPU",
        "S7M_VDD_TPU",
        "S8M_LLDO2",
        "S11M_VDD_CPU_M",
        "S12M_VDD_CPU1_M",
        "VSYS_PWR_WLAN_BT",
        "S2S_VDD_GPU",
        "S4S_VDD2H_MEM",
        "S7S_MLDO",
        "S8S_VDD_GMC",
        "VSYS_PWR_RFFE",
        "VSYS_PWR_MODEM",
        "VSYS_PWR_DISP_INNER",
        "VSYS_PWR_DISP_OUTER"
      ],
      "Formula": "WEIGHTED_AVG",
      "Name": "PARTIAL_SYSTEM_POWER",
      "PowerSampleCount": 5,
      "PowerSampleDelay": 7000,
      "VirtualRails": true
    }
  ],
  "Sensors": [
    {
      "Coefficient": [
        0.26,
        0.118,
        0.016,
        0.076,
        0.265,
        0.09,
        0.096,
        0.07,
        0.009
      ],
      "Combination": [
        "charging_therm",
        "rfpa_therm",
        "quiet_therm",
        "usb_pwr_therm",
        "inner_disp_therm",
        "flash_therm",
        "outer_disp_therm",
        "north_therm",
        "soc_therm"
      ],
      "Formula": "WEIGHTED_AVG",
      "Hidden": true,
      "Multiplier": 0.001,
      "Name": "VIRTUAL-SKIN-OPEN-SUB-0",
      "Offset": 155.0,
      "Type": "UNKNOWN",
      "VirtualSensor": true
    },
    {
      "Coefficient": [
        0.115,
        0.245,
        0.068,
        0.047,
        0.061,
        0.069,
        0.12,
        0.27,
        0.004
      ],
      "Combination": [
        "charging_therm",
        "rfpa_therm",
        "quiet_therm",
        "usb_pwr_therm",
        "inner_disp_therm",
        "flash_therm",
        "outer_disp_therm",
        "north_therm",
        "soc_therm"
      ],
      "Formula": "WEIGHTED_AVG",
      "Hidden": true,
      "Multiplier": 0.001,
      "Name": "VIRTUAL-SKIN-OPEN-SUB-1",
      "Offset": 213.0,
      "Type": "UNKNOWN",
      "VirtualSensor": true
    },
    {
      "Coefficient": [
        0.055,
        0.269,
        0.125,
        0.252,
        0.102,
        0.007,
        0.031,
        0.155,
        0.003
      ],
      "Combination": [
        "charging_therm",
        "rfpa_therm",
        "quiet_therm",
        "usb_pwr_therm",
        "inner_disp_therm",
        "flash_therm",
        "outer_disp_therm",
        "north_therm",
        "soc_therm"
      ],
      "Formula": "WEIGHTED_AVG",
      "Hidden": true,
      "Multiplier": 0.001,
      "Name": "VIRTUAL-SKIN-OPEN-SUB-2",
      "Offset": 9.0,
      "Type": "UNKNOWN",
      "VirtualSensor": true
    },
    {
      "Coefficient": [
        0.002,
        0.014,
        0.011,
        0.326,
        0.26,
        0.094,
        0.031,
        0.166,
        0.095
      ],
      "Combination": [
        "charging_therm",
        "rfpa_therm",
        "quiet_therm",
        "usb_pwr_therm",
        "inner_disp_therm",
        "flash_therm",
        "outer_disp_therm",
        "north_therm",
        "soc_therm"
      ],
      "Formula": "WEIGHTED_AVG",
      "Hidden": true,
      "Multiplier": 0.001,
      "Name": "VIRTUAL-SKIN-OPEN-SUB-3",
      "Offset": 353.0,
      "Type": "UNKNOWN",
      "VirtualSensor": true
    },
    {
      "Coefficient": [
        0.02,
        0.052,
        0.141,
        0.051,
        0.088,
        0.321,
        0.166,
        0.061,
        0.1
      ],
      "Combination": [
        "charging_therm",
        "rfpa_therm",
        "quiet_therm",
        "usb_pwr_therm",
        "inner_disp_therm",
        "flash_therm",
        "outer_disp_therm",
        "north_therm",
        "soc_therm"
      ],
      "Formula": "WEIGHTED_AVG",
      "Hidden": true,
      "Multiplier": 0.001,
      "Name": "VIRTUAL-SKIN-OPEN-SUB-4",
      "Offset": 216.0,
      "Type": "UNKNOWN",
      "VirtualSensor": true
    },
    {
      "Coefficient": [
        1.0,
        1.0,
        1.0,
        1.0,
        1.0
      ],
      "Combination": [
        "VIRTUAL-SKIN-OPEN-SUB-0",
        "VIRTUAL-SKIN-OPEN-SUB-1",
        "VIRTUAL-SKIN-OPEN-SUB-2",
        "VIRTUAL-SKIN-OPEN-SUB-3",
        "VIRTUAL-SKIN-OPEN-SUB-4"
      ],
      "Formula": "MAXIMUM",
      "Hidden": true,
      "Multiplier": 0.001,
      "Name": "VIRTUAL-SKIN-OPEN",
      "OffsetThresholds": [
        49000,
        50000
      ],
      "OffsetValues": [
        500,
        1000
      ],
      "Type": "UNKNOWN",
      "Version": "25.07.18",
      "VirtualSensor": true
    },
    {
      "Coefficient": [
        0.041,
        0.195,
        0.008,
        0.013,
        0.026,
        0.033,
        0.246,
        0.163,
        0.275
      ],
      "Combination": [
        "soc_therm",
        "rfpa_therm",
        "quiet_therm",
        "charging_therm",
        "inner_disp_therm",
        "flash_therm",
        "outer_disp_therm",
        "north_therm",
        "usb_pwr_therm"
      ],
      "Formula": "WEIGHTED_AVG",
      "Hidden": true,
      "Multiplier": 0.001,
      "Name": "VIRTUAL-SKIN-CLOSE-SUB-0",
      "Offset": 351.0,
      "Type": "UNKNOWN",
      "VirtualSensor": true
    },
    {
      "Coefficient": [
        0.003,
        0.237,
        0.082,
        0.032,
        0.037,
        0.106,
        0.123,
        0.146,
        0.234
      ],
      "Combination": [
        "soc_therm",
        "rfpa_therm",
        "quiet_therm",
        "charging_therm",
        "inner_disp_therm",
        "flash_therm",
        "outer_disp_therm",
        "north_therm",
        "usb_pwr_therm"
      ],
      "Formula": "WEIGHTED_AVG",
      "Hidden": true,
      "Multiplier": 0.001,
      "Name": "VIRTUAL-SKIN-CLOSE-SUB-1",
      "Offset": 17.0,
      "Type": "UNKNOWN",
      "VirtualSensor": true
    },
    {
      "Coefficient": [
        0.035,
        0.006,
        0.091,
        0.004,
        0.19,
        0.043,
        0.549,
        0.028,
        0.064
      ],
      "Combination": [
        "soc_therm",
        "rfpa_therm",
        "quiet_therm",
        "charging_therm",
        "inner_disp_therm",
        "flash_therm",
        "outer_disp_therm",
        "north_therm",
        "usb_pwr_therm"
      ],
      "Formula": "WEIGHTED_AVG",
      "Hidden": true,
      "Multiplier": 0.001,
      "Name": "VIRTUAL-SKIN-CLOSE-SUB-2",
      "Offset": 38.0,
      "Type": "UNKNOWN",
      "VirtualSensor": true
    },
    {
      "Coefficient": [
        0.074,
        0.03,
        0.086,
        0.002,
        0.016,
        0.19,
        0.213,
        0.217,
        0.173
      ],
      "Combination": [
        "soc_therm",
        "rfpa_therm",
        "quiet_therm",
        "charging_therm",
        "inner_disp_therm",
        "flash_therm",
        "outer_disp_therm",
        "north_therm",
        "usb_pwr_therm"
      ],
      "Formula": "WEIGHTED_AVG",
      "Hidden": true,
      "Multiplier": 0.001,
      "Name": "VIRTUAL-SKIN-CLOSE-SUB-3",
      "Offset": 56.0,
      "Type": "UNKNOWN",
      "VirtualSensor": true
    },
    {
      "Coefficient": [
        0.012,
        0.087,
        0.002,
        0.037,
        0.172,
        0.299,
        0.26,
        0.004,
        0.127
      ],
      "Combination": [
        "soc_therm",
        "rfpa_therm",
        "quiet_therm",
        "charging_therm",
        "inner_disp_therm",
        "flash_therm",
        "outer_disp_therm",
        "north_therm",
        "usb_pwr_therm"
      ],
      "Formula": "WEIGHTED_AVG",
      "Hidden": true,
      "Multiplier": 0.001,
      "Name": "VIRTUAL-SKIN-CLOSE-SUB-4",
      "Offset": 180.0,
      "Type": "UNKNOWN",
      "VirtualSensor": true
    },
    {
      "Coefficient": [
        1.0,
        1.0,
        1.0,
        1.0,
        1.0
      ],
      "Combination": [
        "VIRTUAL-SKIN-CLOSE-SUB-0",
        "VIRTUAL-SKIN-CLOSE-SUB-1",
        "VIRTUAL-SKIN-CLOSE-SUB-2",
        "VIRTUAL-SKIN-CLOSE-SUB-3",
        "VIRTUAL-SKIN-CLOSE-SUB-4"
      ],
      "Formula": "MAXIMUM",
      "Hidden": true,
      "Multiplier": 0.001,
      "Name": "VIRTUAL-SKIN-CLOSE",
      "Type": "UNKNOWN",
      "Version": "25.07.18",
      "VirtualSensor": true
    },
    "...len=38"
  ]
}
```

### $.Sensors[0]

- Names: `VIRTUAL-SKIN-OPEN-SUB-0`

```json
{
  "Coefficient": [
    0.26,
    0.118,
    0.016,
    0.076,
    0.265,
    0.09,
    0.096,
    0.07,
    0.009
  ],
  "Combination": [
    "charging_therm",
    "rfpa_therm",
    "quiet_therm",
    "usb_pwr_therm",
    "inner_disp_therm",
    "flash_therm",
    "outer_disp_therm",
    "north_therm",
    "soc_therm"
  ],
  "Formula": "WEIGHTED_AVG",
  "Hidden": true,
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-OPEN-SUB-0",
  "Offset": 155.0,
  "Type": "UNKNOWN",
  "VirtualSensor": true
}
```

### $.Sensors[1]

- Names: `VIRTUAL-SKIN-OPEN-SUB-1`

```json
{
  "Coefficient": [
    0.115,
    0.245,
    0.068,
    0.047,
    0.061,
    0.069,
    0.12,
    0.27,
    0.004
  ],
  "Combination": [
    "charging_therm",
    "rfpa_therm",
    "quiet_therm",
    "usb_pwr_therm",
    "inner_disp_therm",
    "flash_therm",
    "outer_disp_therm",
    "north_therm",
    "soc_therm"
  ],
  "Formula": "WEIGHTED_AVG",
  "Hidden": true,
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-OPEN-SUB-1",
  "Offset": 213.0,
  "Type": "UNKNOWN",
  "VirtualSensor": true
}
```

### $.Sensors[2]

- Names: `VIRTUAL-SKIN-OPEN-SUB-2`

```json
{
  "Coefficient": [
    0.055,
    0.269,
    0.125,
    0.252,
    0.102,
    0.007,
    0.031,
    0.155,
    0.003
  ],
  "Combination": [
    "charging_therm",
    "rfpa_therm",
    "quiet_therm",
    "usb_pwr_therm",
    "inner_disp_therm",
    "flash_therm",
    "outer_disp_therm",
    "north_therm",
    "soc_therm"
  ],
  "Formula": "WEIGHTED_AVG",
  "Hidden": true,
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-OPEN-SUB-2",
  "Offset": 9.0,
  "Type": "UNKNOWN",
  "VirtualSensor": true
}
```

### $.Sensors[3]

- Names: `VIRTUAL-SKIN-OPEN-SUB-3`

```json
{
  "Coefficient": [
    0.002,
    0.014,
    0.011,
    0.326,
    0.26,
    0.094,
    0.031,
    0.166,
    0.095
  ],
  "Combination": [
    "charging_therm",
    "rfpa_therm",
    "quiet_therm",
    "usb_pwr_therm",
    "inner_disp_therm",
    "flash_therm",
    "outer_disp_therm",
    "north_therm",
    "soc_therm"
  ],
  "Formula": "WEIGHTED_AVG",
  "Hidden": true,
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-OPEN-SUB-3",
  "Offset": 353.0,
  "Type": "UNKNOWN",
  "VirtualSensor": true
}
```

### $.Sensors[4]

- Names: `VIRTUAL-SKIN-OPEN-SUB-4`

```json
{
  "Coefficient": [
    0.02,
    0.052,
    0.141,
    0.051,
    0.088,
    0.321,
    0.166,
    0.061,
    0.1
  ],
  "Combination": [
    "charging_therm",
    "rfpa_therm",
    "quiet_therm",
    "usb_pwr_therm",
    "inner_disp_therm",
    "flash_therm",
    "outer_disp_therm",
    "north_therm",
    "soc_therm"
  ],
  "Formula": "WEIGHTED_AVG",
  "Hidden": true,
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-OPEN-SUB-4",
  "Offset": 216.0,
  "Type": "UNKNOWN",
  "VirtualSensor": true
}
```

### $.Sensors[5]

- Names: `VIRTUAL-SKIN-OPEN`, `VIRTUAL-SKIN-OPEN-SUB-0`, `VIRTUAL-SKIN-OPEN-SUB-1`, `VIRTUAL-SKIN-OPEN-SUB-2`, `VIRTUAL-SKIN-OPEN-SUB-3`, `VIRTUAL-SKIN-OPEN-SUB-4`

```json
{
  "Coefficient": [
    1.0,
    1.0,
    1.0,
    1.0,
    1.0
  ],
  "Combination": [
    "VIRTUAL-SKIN-OPEN-SUB-0",
    "VIRTUAL-SKIN-OPEN-SUB-1",
    "VIRTUAL-SKIN-OPEN-SUB-2",
    "VIRTUAL-SKIN-OPEN-SUB-3",
    "VIRTUAL-SKIN-OPEN-SUB-4"
  ],
  "Formula": "MAXIMUM",
  "Hidden": true,
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-OPEN",
  "OffsetThresholds": [
    49000,
    50000
  ],
  "OffsetValues": [
    500,
    1000
  ],
  "Type": "UNKNOWN",
  "Version": "25.07.18",
  "VirtualSensor": true
}
```

### $.Sensors[6]

- Names: `VIRTUAL-SKIN-CLOSE-SUB-0`

```json
{
  "Coefficient": [
    0.041,
    0.195,
    0.008,
    0.013,
    0.026,
    0.033,
    0.246,
    0.163,
    0.275
  ],
  "Combination": [
    "soc_therm",
    "rfpa_therm",
    "quiet_therm",
    "charging_therm",
    "inner_disp_therm",
    "flash_therm",
    "outer_disp_therm",
    "north_therm",
    "usb_pwr_therm"
  ],
  "Formula": "WEIGHTED_AVG",
  "Hidden": true,
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-CLOSE-SUB-0",
  "Offset": 351.0,
  "Type": "UNKNOWN",
  "VirtualSensor": true
}
```

### $.Sensors[7]

- Names: `VIRTUAL-SKIN-CLOSE-SUB-1`

```json
{
  "Coefficient": [
    0.003,
    0.237,
    0.082,
    0.032,
    0.037,
    0.106,
    0.123,
    0.146,
    0.234
  ],
  "Combination": [
    "soc_therm",
    "rfpa_therm",
    "quiet_therm",
    "charging_therm",
    "inner_disp_therm",
    "flash_therm",
    "outer_disp_therm",
    "north_therm",
    "usb_pwr_therm"
  ],
  "Formula": "WEIGHTED_AVG",
  "Hidden": true,
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-CLOSE-SUB-1",
  "Offset": 17.0,
  "Type": "UNKNOWN",
  "VirtualSensor": true
}
```

### $.Sensors[8]

- Names: `VIRTUAL-SKIN-CLOSE-SUB-2`

```json
{
  "Coefficient": [
    0.035,
    0.006,
    0.091,
    0.004,
    0.19,
    0.043,
    0.549,
    0.028,
    0.064
  ],
  "Combination": [
    "soc_therm",
    "rfpa_therm",
    "quiet_therm",
    "charging_therm",
    "inner_disp_therm",
    "flash_therm",
    "outer_disp_therm",
    "north_therm",
    "usb_pwr_therm"
  ],
  "Formula": "WEIGHTED_AVG",
  "Hidden": true,
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-CLOSE-SUB-2",
  "Offset": 38.0,
  "Type": "UNKNOWN",
  "VirtualSensor": true
}
```

### $.Sensors[9]

- Names: `VIRTUAL-SKIN-CLOSE-SUB-3`

```json
{
  "Coefficient": [
    0.074,
    0.03,
    0.086,
    0.002,
    0.016,
    0.19,
    0.213,
    0.217,
    0.173
  ],
  "Combination": [
    "soc_therm",
    "rfpa_therm",
    "quiet_therm",
    "charging_therm",
    "inner_disp_therm",
    "flash_therm",
    "outer_disp_therm",
    "north_therm",
    "usb_pwr_therm"
  ],
  "Formula": "WEIGHTED_AVG",
  "Hidden": true,
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-CLOSE-SUB-3",
  "Offset": 56.0,
  "Type": "UNKNOWN",
  "VirtualSensor": true
}
```

### $.Sensors[10]

- Names: `VIRTUAL-SKIN-CLOSE-SUB-4`

```json
{
  "Coefficient": [
    0.012,
    0.087,
    0.002,
    0.037,
    0.172,
    0.299,
    0.26,
    0.004,
    0.127
  ],
  "Combination": [
    "soc_therm",
    "rfpa_therm",
    "quiet_therm",
    "charging_therm",
    "inner_disp_therm",
    "flash_therm",
    "outer_disp_therm",
    "north_therm",
    "usb_pwr_therm"
  ],
  "Formula": "WEIGHTED_AVG",
  "Hidden": true,
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-CLOSE-SUB-4",
  "Offset": 180.0,
  "Type": "UNKNOWN",
  "VirtualSensor": true
}
```

### $.Sensors[11]

- Names: `VIRTUAL-SKIN-CLOSE`, `VIRTUAL-SKIN-CLOSE-SUB-0`, `VIRTUAL-SKIN-CLOSE-SUB-1`, `VIRTUAL-SKIN-CLOSE-SUB-2`, `VIRTUAL-SKIN-CLOSE-SUB-3`, `VIRTUAL-SKIN-CLOSE-SUB-4`

```json
{
  "Coefficient": [
    1.0,
    1.0,
    1.0,
    1.0,
    1.0
  ],
  "Combination": [
    "VIRTUAL-SKIN-CLOSE-SUB-0",
    "VIRTUAL-SKIN-CLOSE-SUB-1",
    "VIRTUAL-SKIN-CLOSE-SUB-2",
    "VIRTUAL-SKIN-CLOSE-SUB-3",
    "VIRTUAL-SKIN-CLOSE-SUB-4"
  ],
  "Formula": "MAXIMUM",
  "Hidden": true,
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-CLOSE",
  "Type": "UNKNOWN",
  "Version": "25.07.18",
  "VirtualSensor": true
}
```

### $.Sensors[12]

- Names: `VIRTUAL-SKIN-CLOSE`, `VIRTUAL-SKIN-LEGACY`, `VIRTUAL-SKIN-OPEN`

```json
{
  "Coefficient": [
    "OPEN_WEIGHT",
    "CLOSE_WEIGHT"
  ],
  "CoefficientType": [
    "SENSOR",
    "SENSOR"
  ],
  "Combination": [
    "VIRTUAL-SKIN-OPEN",
    "VIRTUAL-SKIN-CLOSE"
  ],
  "Formula": "WEIGHTED_AVG",
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-LEGACY",
  "Type": "UNKNOWN",
  "Version": "25.07.18",
  "VirtualSensor": true
}
```

### $.Sensors[13]

- Names: `VIRTUAL-SKIN-LEGACY`, `VIRTUAL-SKIN-MODEL`

```json
{
  "BackupSensor": "VIRTUAL-SKIN-LEGACY",
  "Combination": [
    "charging_therm",
    "inner_disp_therm",
    "outer_disp_therm",
    "flash_therm",
    "north_therm",
    "quiet_therm",
    "rfpa_therm",
    "soc_therm",
    "usb_pwr_therm"
  ],
  "Formula": "USE_ML_MODEL",
  "ModelPath": "vt_estimation_model.tflite",
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-MODEL",
  "OffsetThresholds": [
    39000,
    40000
  ],
  "OffsetValues": [
    250,
    500
  ],
  "PreviousSampleCount": 3,
  "TimeResolution": 7000,
  "Type": "UNKNOWN",
  "Version": "25.07.17",
  "VirtualSensor": true
}
```

### $.Sensors[14]

- Names: `VIRTUAL-SKIN-MODEL`, `VIRTUAL-SKIN-MODEL-UPPER-CLAMPED`

```json
{
  "Coefficient": [
    1.0,
    1.0
  ],
  "Combination": [
    "56500",
    "VIRTUAL-SKIN-MODEL"
  ],
  "CombinationType": [
    "CONSTANT",
    "SENSOR"
  ],
  "Formula": "MINIMUM",
  "Hidden": true,
  "Multiplier": 1,
  "Name": "VIRTUAL-SKIN-MODEL-UPPER-CLAMPED",
  "Type": "UNKNOWN",
  "VirtualSensor": true
}
```

### $.Sensors[15]

- Names: `VIRTUAL-SKIN-LEGACY`, `VIRTUAL-SKIN-LEGACY-SHUTDOWN`

```json
{
  "Coefficient": [
    56500
  ],
  "Combination": [
    "VIRTUAL-SKIN-LEGACY"
  ],
  "Formula": "COUNT_THRESHOLD",
  "Hidden": true,
  "Multiplier": 1.0,
  "Name": "VIRTUAL-SKIN-LEGACY-SHUTDOWN",
  "Type": "UNKNOWN",
  "VirtualSensor": true
}
```

### $.Sensors[16]

- Names: `VIRTUAL-SKIN`, `VIRTUAL-SKIN-LEGACY`, `VIRTUAL-SKIN-LEGACY-SHUTDOWN`, `VIRTUAL-SKIN-MODEL-UPDATED`
- PollingDelay: `300000`
- PassiveDelay: `7000`

```json
{
  "BindedCdevInfo": [
    {
      "CdevRequest": "aurora",
      "LimitInfo": [
        0,
        0,
        0,
        0,
        0,
        15,
        15
      ]
    }
  ],
  "Coefficient": [
    1.0,
    "VIRTUAL-SKIN-LEGACY-SHUTDOWN"
  ],
  "CoefficientType": [
    "CONSTANT",
    "SENSOR"
  ],
  "Combination": [
    "VIRTUAL-SKIN-MODEL-UPDATED",
    "VIRTUAL-SKIN-LEGACY"
  ],
  "Formula": "MAXIMUM",
  "HotHysteresis": [
    0.0,
    1.9,
    1.9,
    1.9,
    1.4,
    1.9,
    1.9
  ],
  "HotThreshold": [
    "NAN",
    39.0,
    43.0,
    45.0,
    46.5,
    53.0,
    56.5
  ],
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN",
  "PassiveDelay": 7000,
  "PollingDelay": 300000,
  "SendCallback": true,
  "TriggerSensor": [
    "soc_therm",
    "rfpa_therm",
    "quiet_therm",
    "usb_pwr_therm",
    "inner_disp_therm",
    "flash_therm",
    "outer_disp_therm",
    "north_therm"
  ],
  "Type": "SKIN",
  "VirtualSensor": true
}
```

### $.Sensors[17]

- Names: `VIRTUAL-SKIN`, `VIRTUAL-SKIN-HINT`
- PollingDelay: `300000`
- PassiveDelay: `7000`

```json
{
  "Coefficient": [
    1.0
  ],
  "Combination": [
    "VIRTUAL-SKIN"
  ],
  "Formula": "MAXIMUM",
  "Hidden": true,
  "HotHysteresis": [
    0.0,
    1.9,
    1.9,
    1.9,
    1.4,
    1.9,
    1.9
  ],
  "HotThreshold": [
    "NAN",
    37.0,
    43.0,
    45.0,
    46.5,
    53.0,
    56.5
  ],
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-HINT",
  "PassiveDelay": 7000,
  "PollingDelay": 300000,
  "SendPowerHint": true,
  "TriggerSensor": [
    "soc_therm",
    "rfpa_therm",
    "quiet_therm",
    "usb_pwr_therm",
    "inner_disp_therm",
    "flash_therm",
    "outer_disp_therm",
    "north_therm"
  ],
  "Type": "UNKNOWN",
  "VirtualSensor": true
}
```

### $.Sensors[18]

- Names: `VIRTUAL-SKIN`, `VIRTUAL-SKIN-CPU-LIGHT-ODPM`
- PollingDelay: `300000`
- PassiveDelay: `7000`

```json
{
  "BindedCdevInfo": [
    {
      "BindedPowerRail": "S4M_VDD_CPU",
      "CdevCeilingFrequency": [
        2438400,
        1632000,
        1632000,
        1632000,
        1632000,
        1632000,
        1632000
      ],
      "CdevRequest": "cpufreq-cpu0",
      "CdevWeightForPID": [
        1,
        1,
        1,
        1,
        1,
        1,
        1
      ],
      "MaxReleaseStep": 1,
      "MaxThrottleStep": 1
    },
    {
      "BindedPowerRail": "S3M_VDD_CPU1",
      "CdevCeilingFrequency": [
        3052000,
        1785000,
        1785000,
        1785000,
        1785000,
        1785000,
        1785000
      ],
      "CdevRequest": "cpufreq-cpu2",
      "CdevWeightForPID": [
        1,
        1,
        1,
        1,
        1,
        1,
        1
      ],
      "MaxReleaseStep": 1,
      "MaxThrottleStep": 1
    },
    {
      "BindedPowerRail": "S2M_VDD_CPU2",
      "CdevCeiling": [
        0,
        10,
        10,
        10,
        10,
        10,
        10
      ],
      "CdevRequest": "big_and_big_mid",
      "CdevWeightForPID": [
        1,
        1,
        1,
        1,
        1,
        1,
        1
      ],
      "MaxReleaseStep": 1,
      "MaxThrottleStep": 1
    }
  ],
  "Coefficient": [
    1.0
  ],
  "Combination": [
    "VIRTUAL-SKIN"
  ],
  "Formula": "MAXIMUM",
  "Hidden": true,
  "HotHysteresis": [
    0.0,
    0.0,
    1.9,
    0.0,
    0.0,
    0.0,
    0.0
  ],
  "HotThreshold": [
    "NAN",
    37.0,
    39.0,
    "NAN",
    "NAN",
    "NAN",
    "NAN"
  ],
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-CPU-LIGHT-ODPM",
  "PIDInfo": {
    "I_Cutoff": [
      "NAN",
      "NAN",
      2,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "I_Max": [
      "NAN",
      "NAN",
      2933,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "K_D": [
      "NAN",
      "NAN",
      0,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "K_I": [
      "NAN",
      "NAN",
      5,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "K_Po": [
      "NAN",
      "NAN",
      400,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "K_Pu": [
      "NAN",
      "NAN",
      400,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "MaxAllocPower": [
      "NAN",
      "NAN",
      6133,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "MinAllocPower": [
      "NAN",
      "NAN",
      1066,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "S_Power": [
      "NAN",
      "NAN",
      1066,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ]
  },
  "PassiveDelay": 7000,
  "PollingDelay": 300000,
  "Profile": [
    {
      "BindedCdevInfo": [
        {
          "BindedPowerRail": "S4M_VDD_CPU",
          "CdevRequest": "cpufreq-cpu0",
          "Disabled": true,
          "MaxReleaseStep": 1
        },
        {
          "BindedPowerRail": "S3M_VDD_CPU1",
          "CdevRequest": "cpufreq-cpu2",
          "Disabled": true,
          "MaxReleaseStep": 1
        },
        {
          "BindedPowerRail": "S2M_VDD_CPU2",
          "CdevRequest": "big_and_big_mid",
          "Disabled": true,
          "MaxReleaseStep": 1
        }
      ],
      "Mode": "game"
    }
  ],
  "TriggerSensor": [
    "soc_therm",
    "rfpa_therm",
    "quiet_therm",
    "usb_pwr_therm",
    "inner_disp_therm",
    "flash_therm",
    "outer_disp_therm",
    "north_therm"
  ],
  "Type": "UNKNOWN",
  "VirtualSensor": true
}
```

### $.Sensors[19]

- Names: `VIRTUAL-SKIN`, `VIRTUAL-SKIN-CPU-MID`
- PollingDelay: `300000`
- PassiveDelay: `7000`

```json
{
  "BindedCdevInfo": [
    {
      "CdevCeilingFrequency": [
        2438400,
        1190400,
        1190400,
        1190400,
        1190400,
        1190400,
        1190400
      ],
      "CdevRequest": "thermal-uclamp-0",
      "CdevWeightForPID": [
        0.145,
        0.145,
        0.145,
        0.145,
        0.145,
        0.145,
        0.145
      ],
      "MaxReleaseStep": 2,
      "MaxThrottleStep": 2
    },
    {
      "CdevCeilingFrequency": [
        3052000,
        1267200,
        1267200,
        1267200,
        1267200,
        1267200,
        1267200
      ],
      "CdevRequest": "thermal-uclamp-2",
      "CdevWeightForPID": [
        0.56,
        0.56,
        0.56,
        0.56,
        0.56,
        0.56,
        0.56
      ],
      "MaxReleaseStep": 2,
      "MaxThrottleStep": 2
    },
    {
      "CdevCeilingFrequency": [
        3052000,
        1267200,
        1267200,
        1267200,
        1267200,
        1267200,
        1267200
      ],
      "CdevRequest": "thermal-uclamp-5",
      "CdevWeightForPID": [
        0.4,
        0.4,
        0.4,
        0.4,
        0.4,
        0.4,
        0.4
      ],
      "MaxReleaseStep": 2,
      "MaxThrottleStep": 2
    },
    {
      "CdevCeilingFrequency": [
        4012000,
        1152000,
        1152000,
        1152000,
        1152000,
        1152000,
        1152000
      ],
      "CdevRequest": "thermal-uclamp-7",
      "CdevWeightForPID": [
        0.44,
        0.44,
        0.44,
        0.44,
        0.44,
        0.44,
        0.44
      ],
      "MaxReleaseStep": 2,
      "MaxThrottleStep": 2
    }
  ],
  "Coefficient": [
    1.0
  ],
  "Combination": [
    "VIRTUAL-SKIN"
  ],
  "Formula": "MAXIMUM",
  "Hidden": true,
  "HotHysteresis": [
    0.0,
    0.0,
    1.9,
    0.0,
    0.0,
    0.0,
    0.0
  ],
  "HotThreshold": [
    "NAN",
    39.0,
    41.0,
    "NAN",
    "NAN",
    "NAN",
    "NAN"
  ],
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-CPU-MID",
  "PIDInfo": {
    "I_Cutoff": [
      "NAN",
      "NAN",
      4,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "I_Default_Pct": 10,
    "I_Max": [
      "NAN",
      "NAN",
      2150,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "K_D": [
      "NAN",
      "NAN",
      0,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "K_I": [
      "NAN",
      "NAN",
      5,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "K_Po": [
      "NAN",
      "NAN",
      400,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "K_Pu": [
      "NAN",
      "NAN",
      400,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "MaxAllocPower": [
      "NAN",
      "NAN",
      2850,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "MinAllocPower": [
      "NAN",
      "NAN",
      0,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "S_Power": [
      "NAN",
      "NAN",
      700,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ]
  },
  "PassiveDelay": 7000,
  "PollingDelay": 300000,
  "Profile": [
    {
      "BindedCdevInfo": [
        {
          "CdevRequest": "thermal-uclamp-0",
          "Disabled": true,
          "MaxReleaseStep": 1
        },
        {
          "CdevRequest": "thermal-uclamp-2",
          "Disabled": true,
          "MaxReleaseStep": 1
        },
        {
          "CdevRequest": "thermal-uclamp-5",
          "Disabled": true,
          "MaxReleaseStep": 1
        },
        {
          "CdevRequest": "thermal-uclamp-7",
          "Disabled": true,
          "MaxReleaseStep": 1
        }
      ],
      "Mode": "game"
    },
    {
      "BindedCdevInfo": [
        {
          "CdevRequest": "thermal-uclamp-0",
          "Disabled": true,
          "MaxReleaseStep": 1
        },
        {
          "CdevRequest": "thermal-uclamp-2",
          "Disabled": true,
          "MaxReleaseStep": 1
        },
        {
          "CdevRequest": "thermal-uclamp-5",
          "Disabled": true,
          "MaxReleaseStep": 1
        },
        {
          "CdevRequest": "thermal-uclamp-7",
          "Disabled": true,
          "MaxReleaseStep": 1
        }
      ],
      "Mode": "camera"
    }
  ],
  "TriggerSensor": [
    "soc_therm",
    "rfpa_therm",
    "quiet_therm",
    "usb_pwr_therm",
    "inner_disp_therm",
    "flash_therm",
    "outer_disp_therm",
    "north_therm"
  ],
  "Type": "UNKNOWN",
  "VirtualSensor": true
}
```

### $.Sensors[20]

- Names: `VIRTUAL-SKIN`, `VIRTUAL-SKIN-CPU-ODPM`
- PollingDelay: `300000`
- PassiveDelay: `7000`

```json
{
  "BindedCdevInfo": [
    {
      "BindedPowerRail": "S4M_VDD_CPU",
      "CdevCeilingFrequency": [
        2246000,
        729000,
        729000,
        729000,
        729000,
        729000,
        729000
      ],
      "CdevRequest": "cpufreq-cpu0",
      "CdevWeightForPID": [
        1,
        1,
        1,
        1,
        1,
        1,
        1
      ],
      "MaxReleaseStep": 2,
      "MaxThrottleStep": 2
    },
    {
      "BindedPowerRail": "S3M_VDD_CPU1",
      "CdevCeilingFrequency": [
        3052000,
        729600,
        729600,
        729600,
        729600,
        729600,
        729600
      ],
      "CdevRequest": "cpufreq-cpu2",
      "CdevWeightForPID": [
        1,
        1,
        1,
        1,
        1,
        1,
        1
      ],
      "MaxReleaseStep": 2,
      "MaxThrottleStep": 2
    },
    {
      "BindedPowerRail": "S2M_VDD_CPU2",
      "CdevCeiling": [
        0,
        20,
        20,
        20,
        20,
        20,
        10
      ],
      "CdevRequest": "big_and_big_mid",
      "CdevWeightForPID": [
        1,
        1,
        1,
        1,
        1,
        1,
        1
      ],
      "MaxReleaseStep": 1,
      "MaxThrottleStep": 1
    }
  ],
  "Coefficient": [
    1.0
  ],
  "Combination": [
    "VIRTUAL-SKIN"
  ],
  "Formula": "MAXIMUM",
  "Hidden": true,
  "HotHysteresis": [
    0.0,
    0.0,
    1.9,
    0.0,
    0.0,
    0.0,
    0.0
  ],
  "HotThreshold": [
    "NAN",
    39.0,
    41.0,
    "NAN",
    "NAN",
    "NAN",
    "NAN"
  ],
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-CPU-ODPM",
  "PIDInfo": {
    "I_Cutoff": [
      "NAN",
      "NAN",
      2,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "I_Default": 500,
    "I_Max": [
      "NAN",
      "NAN",
      2000,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "K_D": [
      "NAN",
      "NAN",
      0,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "K_I": [
      "NAN",
      "NAN",
      5,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "K_Po": [
      "NAN",
      "NAN",
      1000,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "K_Pu": [
      "NAN",
      "NAN",
      1000,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "MaxAllocPower": [
      "NAN",
      "NAN",
      3800,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "MinAllocPower": [
      "NAN",
      "NAN",
      800,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "S_Power": [
      "NAN",
      "NAN",
      800,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ]
  },
  "PassiveDelay": 7000,
  "PollingDelay": 300000,
  "Profile": [
    {
      "BindedCdevInfo": [
        {
          "BindedPowerRail": "S4M_VDD_CPU",
          "CdevRequest": "cpufreq-cpu0",
          "Disabled": true,
          "MaxReleaseStep": 1
        },
        {
          "BindedPowerRail": "S3M_VDD_CPU1",
          "CdevRequest": "cpufreq-cpu2",
          "Disabled": true,
          "MaxReleaseStep": 1
        },
        {
          "BindedPowerRail": "S2M_VDD_CPU2",
          "CdevRequest": "big_and_big_mid",
          "Disabled": true,
          "MaxReleaseStep": 1
        }
      ],
      "Mode": "game"
    },
    {
      "BindedCdevInfo": [
        {
          "BindedPowerRail": "S4M_VDD_CPU",
          "CdevRequest": "cpufreq-cpu0",
          "Disabled": true,
          "MaxReleaseStep": 1
        },
        {
          "BindedPowerRail": "S3M_VDD_CPU1",
          "CdevRequest": "cpufreq-cpu2",
          "Disabled": true,
          "MaxReleaseStep": 1
        },
        {
          "BindedPowerRail": "S2M_VDD_CPU2",
          "CdevRequest": "big_and_big_mid",
          "Disabled": true,
          "MaxReleaseStep": 1
        }
      ],
      "Mode": "camera"
    }
  ],
  "TriggerSensor": [
    "soc_therm",
    "rfpa_therm",
    "quiet_therm",
    "usb_pwr_therm",
    "inner_disp_therm",
    "flash_therm",
    "outer_disp_therm",
    "north_therm"
  ],
  "Type": "UNKNOWN",
  "VirtualSensor": true
}
```

### $.Sensors[21]

- Names: `VIRTUAL-SKIN`, `VIRTUAL-SKIN-CPU-HIGH`
- PollingDelay: `300000`
- PassiveDelay: `7000`

```json
{
  "BindedCdevInfo": [
    {
      "CdevCeilingFrequency": [
        2438400,
        729600,
        729600,
        729600,
        729600,
        729600,
        729600
      ],
      "CdevRequest": "thermal-uclamp-0",
      "CdevWeightForPID": [
        0.093,
        0.093,
        0.093,
        0.093,
        0.093,
        0.093,
        0.093
      ],
      "MaxReleaseStep": 2,
      "MaxThrottleStep": 2
    },
    {
      "CdevCeilingFrequency": [
        3052000,
        729600,
        729600,
        729600,
        729600,
        729600,
        729600
      ],
      "CdevRequest": "thermal-uclamp-2",
      "CdevWeightForPID": [
        0.285,
        0.285,
        0.285,
        0.285,
        0.285,
        0.285,
        0.285
      ],
      "MaxReleaseStep": 2,
      "MaxThrottleStep": 2
    },
    {
      "CdevCeilingFrequency": [
        3052000,
        729600,
        729600,
        729600,
        729600,
        729600,
        729600
      ],
      "CdevRequest": "thermal-uclamp-5",
      "CdevWeightForPID": [
        0.217,
        0.217,
        0.217,
        0.217,
        0.217,
        0.217,
        0.217
      ],
      "MaxReleaseStep": 2,
      "MaxThrottleStep": 2
    },
    {
      "CdevCeilingFrequency": [
        4012000,
        883200,
        883200,
        883200,
        883200,
        883200,
        883200
      ],
      "CdevRequest": "thermal-uclamp-7",
      "CdevWeightForPID": [
        0.261,
        0.261,
        0.261,
        0.261,
        0.261,
        0.261,
        0.261
      ],
      "MaxReleaseStep": 2,
      "MaxThrottleStep": 2
    }
  ],
  "Coefficient": [
    1.0
  ],
  "Combination": [
    "VIRTUAL-SKIN"
  ],
  "Formula": "MAXIMUM",
  "Hidden": true,
  "HotHysteresis": [
    0.0,
    0.0,
    1.9,
    0.0,
    0.0,
    0.0,
    0.0
  ],
  "HotThreshold": [
    "NAN",
    41.0,
    43.0,
    "NAN",
    "NAN",
    "NAN",
    "NAN"
  ],
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-CPU-HIGH",
  "PIDInfo": {
    "I_Cutoff": [
      "NAN",
      "NAN",
      4,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "I_Max": [
      "NAN",
      "NAN",
      1000,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "K_D": [
      "NAN",
      "NAN",
      0,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "K_I": [
      "NAN",
      "NAN",
      5,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "K_Po": [
      "NAN",
      "NAN",
      400,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "K_Pu": [
      "NAN",
      "NAN",
      400,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "MaxAllocPower": [
      "NAN",
      "NAN",
      1600,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "MinAllocPower": [
      "NAN",
      "NAN",
      0,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "S_Power": [
      "NAN",
      "NAN",
      600,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ]
  },
  "PassiveDelay": 7000,
  "PollingDelay": 300000,
  "Profile": [
    {
      "BindedCdevInfo": [
        {
          "CdevRequest": "thermal-uclamp-0",
          "Disabled": true,
          "MaxReleaseStep": 1
        },
        {
          "CdevRequest": "thermal-uclamp-2",
          "Disabled": true,
          "MaxReleaseStep": 1
        },
        {
          "CdevRequest": "thermal-uclamp-5",
          "Disabled": true,
          "MaxReleaseStep": 1
        },
        {
          "CdevRequest": "thermal-uclamp-7",
          "Disabled": true,
          "MaxReleaseStep": 1
        }
      ],
      "Mode": "game"
    },
    {
      "BindedCdevInfo": [
        {
          "CdevRequest": "thermal-uclamp-0",
          "Disabled": true,
          "MaxReleaseStep": 1
        },
        {
          "CdevRequest": "thermal-uclamp-2",
          "Disabled": true,
          "MaxReleaseStep": 1
        },
        {
          "CdevRequest": "thermal-uclamp-5",
          "Disabled": true,
          "MaxReleaseStep": 1
        },
        {
          "CdevRequest": "thermal-uclamp-7",
          "Disabled": true,
          "MaxReleaseStep": 1
        }
      ],
      "Mode": "camera"
    }
  ],
  "TriggerSensor": [
    "soc_therm",
    "rfpa_therm",
    "quiet_therm",
    "usb_pwr_therm",
    "inner_disp_therm",
    "flash_therm",
    "outer_disp_therm",
    "north_therm"
  ],
  "Type": "UNKNOWN",
  "VirtualSensor": true
}
```

### $.Sensors[22]

- Names: `VIRTUAL-SKIN`, `VIRTUAL-SKIN-SOC`
- PollingDelay: `300000`
- PassiveDelay: `7000`

```json
{
  "BindedCdevInfo": [
    {
      "BindedPowerRail": "S4M_VDD_CPU",
      "CdevCeilingFrequency": [
        2438400,
        1632000,
        1632000,
        729600,
        729600,
        729600,
        268800
      ],
      "CdevRequest": "cpufreq-cpu0",
      "CdevWeightForPID": [
        1,
        1,
        1,
        1,
        1,
        1,
        1
      ],
      "LimitInfoFrequency": [
        2438400,
        2438400,
        2438400,
        2438400,
        2438400,
        2438400,
        268800
      ],
      "MaxReleaseStep": 1,
      "MaxThrottleStep": 1
    },
    {
      "BindedPowerRail": "S3M_VDD_CPU1",
      "CdevCeilingFrequency": [
        3052000,
        1785600,
        1785600,
        1267200,
        729600,
        729600,
        307200
      ],
      "CdevRequest": "cpufreq-cpu2",
      "CdevWeightForPID": [
        1,
        1,
        1,
        1,
        1,
        1,
        1
      ],
      "LimitInfoFrequency": [
        3052000,
        3052000,
        3052000,
        3052000,
        3052000,
        3052000,
        307200
      ],
      "MaxReleaseStep": 1,
      "MaxThrottleStep": 1
    },
    {
      "BindedPowerRail": "S2M_VDD_CPU2",
      "CdevCeiling": [
        0,
        22,
        22,
        22,
        22,
        22,
        22
      ],
      "CdevRequest": "big_and_big_mid",
      "CdevWeightForPID": [
        0.65,
        0.65,
        0.65,
        0.65,
        0.65,
        0.65,
        0.65
      ],
      "LimitInfo": [
        0,
        0,
        0,
        0,
        0,
        0,
        22
      ],
      "MaxReleaseStep": 1,
      "MaxThrottleStep": 1
    },
    {
      "BindedPowerRail": "S2S_VDD_GPU",
      "CdevCeilingFrequency": [
        1094000000,
        435000000,
        435000000,
        435000000,
        198000000,
        198000000,
        198000000
      ],
      "CdevRequest": "gpu",
      "CdevWeightForPID": [
        1,
        1,
        1,
        1,
        1,
        1,
        1
      ],
      "LimitInfoFrequency": [
        1094000000,
        1094000000,
        1094000000,
        1094000000,
        1094000000,
        1094000000,
        198000000
      ],
      "MaxReleaseStep": 1,
      "MaxThrottleStep": 1
    },
    {
      "BindedPowerRail": "S7M_VDD_TPU",
      "CdevCeiling": [
        0,
        13,
        13,
        13,
        13,
        14,
        15
      ],
      "CdevRequest": "tpu",
      "CdevWeightForPID": [
        1,
        1,
        1,
        1,
        1,
        1,
        1
      ],
      "LimitInfo": [
        0,
        0,
        0,
        0,
        0,
        0,
        15
      ],
      "MaxReleaseStep": 1,
      "MaxThrottleStep": 1
    }
  ],
  "Coefficient": [
    1.0
  ],
  "Combination": [
    "VIRTUAL-SKIN"
  ],
  "Formula": "MAXIMUM",
  "Hidden": true,
  "HotHysteresis": [
    0.0,
    0.0,
    1.9,
    1.9,
    1.9,
    1.4,
    1.9
  ],
  "HotThreshold": [
    "NAN",
    37.0,
    39.0,
    41.0,
    45.0,
    46.5,
    52.0
  ],
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-SOC",
  "PIDInfo": {
    "I_Cutoff": [
      "NAN",
      "NAN",
      "NAN",
      "NAN",
      8,
      "NAN",
      "NAN"
    ],
    "I_Max": [
      "NAN",
      "NAN",
      "NAN",
      "NAN",
      3120,
      "NAN",
      "NAN"
    ],
    "I_Trend": 0.75,
    "K_D": [
      "NAN",
      "NAN",
      "NAN",
      "NAN",
      0,
      "NAN",
      "NAN"
    ],
    "K_I": [
      "NAN",
      "NAN",
      "NAN",
      "NAN",
      5,
      "NAN",
      "NAN"
    ],
    "K_Po": [
      "NAN",
      "NAN",
      "NAN",
      "NAN",
      300,
      "NAN",
      "NAN"
    ],
    "K_Pu": [
      "NAN",
      "NAN",
      "NAN",
      "NAN",
      300,
      "NAN",
      "NAN"
    ],
    "MaxAllocPower": [
      "NAN",
      "NAN",
      "NAN",
      "NAN",
      4680,
      "NAN",
      "NAN"
    ],
    "MinAllocPower": [
      "NAN",
      "NAN",
      "NAN",
      "NAN",
      960,
      "NAN",
      "NAN"
    ],
    "S_Power": [
      "NAN",
      "NAN",
      "NAN",
      "NAN",
      960,
      "NAN",
      "NAN"
    ]
  },
  "PassiveDelay": 7000,
  "PollingDelay": 300000,
  "ThermalSampleCount": 5,
  "TriggerSensor": [
    "soc_therm",
    "rfpa_therm",
    "quiet_therm",
    "usb_pwr_therm",
    "inner_disp_therm",
    "flash_therm",
    "outer_disp_therm",
    "north_therm"
  ],
  "Type": "UNKNOWN",
  "VirtualSensor": true
}
```

### $.Sensors[23]

- Names: `VIRTUAL-SKIN-INNER-DISPLAY`, `VIRTUAL-SKIN-OPEN`
- PollingDelay: `300000`
- PassiveDelay: `7000`

```json
{
  "Coefficient": [
    1.0
  ],
  "Combination": [
    "VIRTUAL-SKIN-OPEN"
  ],
  "Formula": "MAXIMUM",
  "HotHysteresis": [
    0.0,
    1.9,
    1.9,
    1.9,
    1.4,
    1.9,
    1.9
  ],
  "HotThreshold": [
    "NAN",
    39.0,
    43.0,
    45.0,
    46.5,
    53.0,
    56.5
  ],
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-INNER-DISPLAY",
  "PassiveDelay": 7000,
  "PollingDelay": 300000,
  "SendCallback": true,
  "TriggerSensor": [
    "soc_therm",
    "rfpa_therm",
    "quiet_therm",
    "usb_pwr_therm",
    "inner_disp_therm",
    "flash_therm",
    "outer_disp_therm",
    "north_therm"
  ],
  "Type": "DISPLAY",
  "Version": "24.11.13",
  "VirtualSensor": true
}
```

### $.Sensors[24]

- Names: `VIRTUAL-SKIN-OUTER-DISPLAY-LEGACY`

```json
{
  "Coefficient": [
    0.071,
    0.013,
    0.23,
    0.098,
    0.023,
    0.069,
    0.337,
    0.009,
    0.23
  ],
  "Combination": [
    "soc_therm",
    "rfpa_therm",
    "quiet_therm",
    "charging_therm",
    "inner_disp_therm",
    "flash_therm",
    "outer_disp_therm",
    "north_therm",
    "usb_pwr_therm"
  ],
  "Formula": "WEIGHTED_AVG",
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-OUTER-DISPLAY-LEGACY",
  "Offset": 95.0,
  "TriggerSensor": [
    "outer_disp_therm"
  ],
  "Type": "UNKNOWN",
  "Version": "25.08.11",
  "VirtualSensor": true
}
```

### $.Sensors[25]

- Names: `VIRTUAL-SKIN-OUTER-DISPLAY`, `VIRTUAL-SKIN-OUTER-DISPLAY-LEGACY`
- PollingDelay: `300000`
- PassiveDelay: `7000`

```json
{
  "BackupSensor": "VIRTUAL-SKIN-OUTER-DISPLAY-LEGACY",
  "Combination": [
    "charging_therm",
    "inner_disp_therm",
    "outer_disp_therm",
    "flash_therm",
    "north_therm",
    "quiet_therm",
    "rfpa_therm",
    "soc_therm",
    "usb_pwr_therm"
  ],
  "Formula": "USE_ML_MODEL",
  "HotHysteresis": [
    0.0,
    1.9,
    1.9,
    1.9,
    1.4,
    1.9,
    1.9
  ],
  "HotThreshold": [
    "NAN",
    39.0,
    43.0,
    45.0,
    46.5,
    53.0,
    56.5
  ],
  "ModelPath": "vt_estimation_model_display.tflite",
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-OUTER-DISPLAY",
  "PassiveDelay": 7000,
  "PollingDelay": 300000,
  "PreviousSampleCount": 3,
  "SendCallback": true,
  "TimeResolution": 7000,
  "TriggerSensor": [
    "outer_disp_therm"
  ],
  "Type": "DISPLAY",
  "Version": "25.08.11",
  "VirtualSensor": true
}
```

### $.Sensors[31]

- Names: `VIRTUAL-SKIN-SPEAKER-OPEN`

```json
{
  "Coefficient": [
    0.372,
    0.205,
    0.052,
    0.305,
    0.101,
    0.113,
    0.064,
    0.115,
    0.087
  ],
  "Combination": [
    "soc_therm",
    "rfpa_therm",
    "quiet_therm",
    "usb_pwr_therm",
    "inner_disp_therm",
    "flash_therm",
    "outer_disp_therm",
    "north_therm",
    "charging_therm"
  ],
  "Formula": "WEIGHTED_AVG",
  "Hidden": true,
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-SPEAKER-OPEN",
  "Offset": -10967.0,
  "Type": "UNKNOWN",
  "Version": "24.10.29",
  "VirtualSensor": true
}
```

### $.Sensors[32]

- Names: `VIRTUAL-SKIN-SPEAKER-CLOSE`

```json
{
  "Coefficient": [
    0.059,
    0.1,
    0.119,
    0.394,
    0.093,
    0.028,
    0.146,
    0.052,
    0.209
  ],
  "Combination": [
    "soc_therm",
    "rfpa_therm",
    "quiet_therm",
    "usb_pwr_therm",
    "inner_disp_therm",
    "flash_therm",
    "outer_disp_therm",
    "north_therm",
    "charging_therm"
  ],
  "Formula": "WEIGHTED_AVG",
  "Hidden": true,
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-SPEAKER-CLOSE",
  "Offset": -3839.0,
  "Type": "UNKNOWN",
  "Version": "24.10.29",
  "VirtualSensor": true
}
```

### $.Sensors[33]

- Names: `VIRTUAL-SKIN-SPEAKER-CLOSE`, `VIRTUAL-SKIN-SPEAKER-LEGACY`, `VIRTUAL-SKIN-SPEAKER-OPEN`

```json
{
  "Coefficient": [
    "OPEN_WEIGHT",
    "CLOSE_WEIGHT"
  ],
  "CoefficientType": [
    "SENSOR",
    "SENSOR"
  ],
  "Combination": [
    "VIRTUAL-SKIN-SPEAKER-OPEN",
    "VIRTUAL-SKIN-SPEAKER-CLOSE"
  ],
  "Formula": "WEIGHTED_AVG",
  "Hidden": true,
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-SPEAKER-LEGACY",
  "Type": "UNKNOWN",
  "Version": "24.10.29",
  "VirtualSensor": true
}
```

### $.Sensors[34]

- Names: `VIRTUAL-SKIN-SPEAKER-LEGACY`, `VIRTUAL-SKIN-TOP-SPEAKER`
- PollingDelay: `300000`
- PassiveDelay: `7000`

```json
{
  "BackupSensor": "VIRTUAL-SKIN-SPEAKER-LEGACY",
  "Combination": [
    "charging_therm",
    "inner_disp_therm",
    "outer_disp_therm",
    "flash_therm",
    "north_therm",
    "quiet_therm",
    "rfpa_therm",
    "soc_therm",
    "usb_pwr_therm"
  ],
  "Formula": "USE_ML_MODEL",
  "HotHysteresis": [
    0.0,
    1.9,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0
  ],
  "HotThreshold": [
    "NAN",
    37.0,
    "NAN",
    "NAN",
    "NAN",
    "NAN",
    "NAN"
  ],
  "ModelPath": "vt_estimation_model_top_spk.tflite",
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-TOP-SPEAKER",
  "PassiveDelay": 7000,
  "PollingDelay": 300000,
  "PreviousSampleCount": 3,
  "SendCallback": true,
  "TimeResolution": 7000,
  "TriggerSensor": [
    "soc_therm"
  ],
  "Type": "UNKNOWN",
  "Version": "25.03.21",
  "VirtualSensor": true
}
```

### $.Sensors[35]

- Names: `VIRTUAL-SKIN-BOTTOM-SPEAKER`, `VIRTUAL-SKIN-SPEAKER-LEGACY`
- PollingDelay: `300000`
- PassiveDelay: `7000`

```json
{
  "BackupSensor": "VIRTUAL-SKIN-SPEAKER-LEGACY",
  "Combination": [
    "charging_therm",
    "inner_disp_therm",
    "outer_disp_therm",
    "flash_therm",
    "north_therm",
    "quiet_therm",
    "rfpa_therm",
    "soc_therm",
    "usb_pwr_therm"
  ],
  "Formula": "USE_ML_MODEL",
  "HotHysteresis": [
    0.0,
    1.9,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0
  ],
  "HotThreshold": [
    "NAN",
    37.0,
    "NAN",
    "NAN",
    "NAN",
    "NAN",
    "NAN"
  ],
  "ModelPath": "vt_estimation_model_bottom_spk.tflite",
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-BOTTOM-SPEAKER",
  "PassiveDelay": 7000,
  "PollingDelay": 300000,
  "PreviousSampleCount": 3,
  "SendCallback": true,
  "TimeResolution": 7000,
  "TriggerSensor": [
    "soc_therm"
  ],
  "Type": "UNKNOWN",
  "Version": "25.03.21",
  "VirtualSensor": true
}
```

### $.Sensors[37]

- Names: `VIRTUAL-SKIN`
- PollingDelay: `300000`
- PassiveDelay: `7000`

```json
{
  "Coefficient": [
    1.0
  ],
  "Combination": [
    "VIRTUAL-SKIN"
  ],
  "Formula": "MAXIMUM",
  "HotHysteresis": [
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    1.9,
    0.0
  ],
  "HotThreshold": [
    "NAN",
    "NAN",
    "NAN",
    "NAN",
    "NAN",
    55.0,
    "NAN"
  ],
  "Multiplier": 0.001,
  "Name": "cellular-emergency",
  "PassiveDelay": 7000,
  "PollingDelay": 300000,
  "SendCallback": true,
  "TriggerSensor": [
    "soc_therm",
    "rfpa_therm",
    "quiet_therm",
    "usb_pwr_therm",
    "inner_disp_therm",
    "flash_therm",
    "outer_disp_therm",
    "north_therm"
  ],
  "Type": "POWER_AMPLIFIER",
  "VirtualSensor": true
}
```

## thermal_info_config_charge.json

- SHA-256: `2b40f6b414a288cf21bd2d833f6b78d73e9a5145d26527999ca36f59c264725c`
- VIRTUAL-SKIN entry count: `15`

### $

- Names: `VIRTUAL-SKIN-CHARGE-CLOSE`, `VIRTUAL-SKIN-CHARGE-CLOSE-SUB-0`, `VIRTUAL-SKIN-CHARGE-CLOSE-SUB-1`, `VIRTUAL-SKIN-CHARGE-CLOSE-SUB-2`, `VIRTUAL-SKIN-CHARGE-LEGACY`, `VIRTUAL-SKIN-CHARGE-OPEN`, `VIRTUAL-SKIN-CHARGE-OPEN-SUB-0`, `VIRTUAL-SKIN-CHARGE-OPEN-SUB-1`, `VIRTUAL-SKIN-CHARGE-OPEN-SUB-2`, `VIRTUAL-SKIN-CHARGE-PERSIST`, `VIRTUAL-SKIN-CHARGE-WIRED`, `VIRTUAL-SKIN-CHARGE-WLC-CLOSE`, `VIRTUAL-SKIN-CHARGE-WLC-LEGACY`, `VIRTUAL-SKIN-CHARGE-WLC-OPEN`

```json
{
  "CoolingDevices": [
    {
      "Name": "chg_mdis",
      "Type": "BATTERY"
    },
    {
      "Name": "usbc-port",
      "Type": "BATTERY"
    }
  ],
  "PowerRails": [
    {
      "Coefficient": [
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0
      ],
      "Combination": [
        "S1M_VDD_AMB",
        "S2M_VDD_CPU2",
        "S3M_VDD_CPU1",
        "S4M_VDD_CPU",
        "S7M_VDD_TPU",
        "S8M_LLDO2",
        "S11M_VDD_CPU_M",
        "S12M_VDD_CPU1_M",
        "VSYS_PWR_WLAN_BT",
        "S2S_VDD_GPU",
        "S4S_VDD2H_MEM",
        "S7S_MLDO",
        "S8S_VDD_GMC",
        "VSYS_PWR_RFFE",
        "VSYS_PWR_MODEM",
        "VSYS_PWR_DISP_INNER",
        "VSYS_PWR_DISP_OUTER"
      ],
      "Formula": "WEIGHTED_AVG",
      "Name": "PARTIAL_SYSTEM_POWER",
      "PowerSampleCount": 5,
      "PowerSampleDelay": 7000,
      "VirtualRails": true
    }
  ],
  "Sensors": [
    {
      "HotHysteresis": [
        0.0,
        2.9,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0
      ],
      "HotThreshold": [
        "NAN",
        33.5,
        "NAN",
        "NAN",
        "NAN",
        "NAN",
        "NAN"
      ],
      "Multiplier": 0.001,
      "Name": "north_therm",
      "PassiveDelay": 7000,
      "PollingDelay": 300000,
      "Type": "UNKNOWN"
    },
    {
      "HotThreshold": [
        "NAN",
        "NAN",
        "NAN",
        "NAN",
        "NAN",
        "NAN",
        "NAN"
      ],
      "Multiplier": 0.001,
      "Name": "charging_therm",
      "Type": "UNKNOWN"
    },
    {
      "HotHysteresis": [
        0.0,
        2.9,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0
      ],
      "HotThreshold": [
        "NAN",
        32.3,
        "NAN",
        "NAN",
        "NAN",
        "NAN",
        "NAN"
      ],
      "Multiplier": 0.001,
      "Name": "inner_disp_therm",
      "PassiveDelay": 7000,
      "PollingDelay": 300000,
      "Type": "UNKNOWN"
    },
    {
      "HotHysteresis": [
        0.0,
        2.9,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0
      ],
      "HotThreshold": [
        "NAN",
        31.7,
        "NAN",
        "NAN",
        "NAN",
        "NAN",
        "NAN"
      ],
      "Multiplier": 0.001,
      "Name": "outer_disp_therm",
      "PassiveDelay": 7000,
      "PollingDelay": 300000,
      "Type": "UNKNOWN"
    },
    {
      "HotHysteresis": [
        0.0,
        2.9,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0
      ],
      "HotThreshold": [
        "NAN",
        33.1,
        "NAN",
        "NAN",
        "NAN",
        "NAN",
        "NAN"
      ],
      "Multiplier": 0.001,
      "Name": "flash_therm",
      "PassiveDelay": 7000,
      "PollingDelay": 300000,
      "Type": "UNKNOWN"
    },
    {
      "HotHysteresis": [
        0.0,
        2.9,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0
      ],
      "HotThreshold": [
        "NAN",
        31.7,
        "NAN",
        "NAN",
        "NAN",
        "NAN",
        "NAN"
      ],
      "Multiplier": 0.001,
      "Name": "rfpa_therm",
      "PassiveDelay": 7000,
      "PollingDelay": 300000,
      "Type": "UNKNOWN"
    },
    {
      "HotHysteresis": [
        0.0,
        2.9,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0
      ],
      "HotThreshold": [
        "NAN",
        31.7,
        "NAN",
        "NAN",
        "NAN",
        "NAN",
        "NAN"
      ],
      "Multiplier": 0.001,
      "Name": "soc_therm",
      "PassiveDelay": 7000,
      "PollingDelay": 300000,
      "Type": "UNKNOWN"
    },
    {
      "HotHysteresis": [
        0.0,
        2.9,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0
      ],
      "HotThreshold": [
        "NAN",
        33.8,
        "NAN",
        "NAN",
        "NAN",
        "NAN",
        "NAN"
      ],
      "Multiplier": 0.001,
      "Name": "quiet_therm",
      "PassiveDelay": 7000,
      "PollingDelay": 300000,
      "Type": "UNKNOWN"
    },
    {
      "HotHysteresis": [
        0.0,
        2.9,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0
      ],
      "HotThreshold": [
        "NAN",
        30.6,
        "NAN",
        "NAN",
        "NAN",
        "NAN",
        "NAN"
      ],
      "Multiplier": 0.001,
      "Name": "usb_pwr_therm",
      "PassiveDelay": 7000,
      "PollingDelay": 300000,
      "Type": "UNKNOWN"
    },
    {
      "HotThreshold": [
        "NAN",
        "NAN",
        "NAN",
        "NAN",
        "NAN",
        "NAN",
        "60.0"
      ],
      "Multiplier": 0.001,
      "Name": "battery",
      "Type": "BATTERY"
    },
    {
      "Multiplier": 1,
      "Name": "thb_hda",
      "Type": "UNKNOWN"
    },
    {
      "Coefficient": [
        1,
        -51
      ],
      "Combination": [
        "thb_hda",
        "thb_hda"
      ],
      "Formula": "COUNT_THRESHOLD",
      "Hidden": true,
      "Multiplier": 1,
      "Name": "WLC_CHECK",
      "Type": "UNKNOWN",
      "VirtualSensor": true
    },
    "...len=33"
  ]
}
```

### $.Sensors[17]

- Names: `VIRTUAL-SKIN-CHARGE-OPEN-SUB-0`

```json
{
  "Coefficient": [
    0.038,
    0.008,
    0.015,
    0.256,
    0.232,
    0.137,
    0.266,
    0.048
  ],
  "Combination": [
    "soc_therm",
    "rfpa_therm",
    "quiet_therm",
    "charging_therm",
    "inner_disp_therm",
    "flash_therm",
    "outer_disp_therm",
    "north_therm"
  ],
  "Formula": "WEIGHTED_AVG",
  "Hidden": true,
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-CHARGE-OPEN-SUB-0",
  "Offset": 182.0,
  "Type": "UNKNOWN",
  "VirtualSensor": true
}
```

### $.Sensors[18]

- Names: `VIRTUAL-SKIN-CHARGE-OPEN-SUB-1`

```json
{
  "Coefficient": [
    0.162,
    0.078,
    0.056,
    0.171,
    0.07,
    0.106,
    0.342,
    0.015
  ],
  "Combination": [
    "soc_therm",
    "rfpa_therm",
    "quiet_therm",
    "charging_therm",
    "inner_disp_therm",
    "flash_therm",
    "outer_disp_therm",
    "north_therm"
  ],
  "Formula": "WEIGHTED_AVG",
  "Hidden": true,
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-CHARGE-OPEN-SUB-1",
  "Offset": 235.0,
  "Type": "UNKNOWN",
  "VirtualSensor": true
}
```

### $.Sensors[19]

- Names: `VIRTUAL-SKIN-CHARGE-OPEN-SUB-2`

```json
{
  "Coefficient": [
    0.033,
    0.04,
    0.23,
    0.065,
    0.205,
    0.022,
    0.114,
    0.289
  ],
  "Combination": [
    "soc_therm",
    "rfpa_therm",
    "quiet_therm",
    "charging_therm",
    "inner_disp_therm",
    "flash_therm",
    "outer_disp_therm",
    "north_therm"
  ],
  "Formula": "WEIGHTED_AVG",
  "Hidden": true,
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-CHARGE-OPEN-SUB-2",
  "Offset": -739.0,
  "Type": "UNKNOWN",
  "VirtualSensor": true
}
```

### $.Sensors[20]

- Names: `VIRTUAL-SKIN-CHARGE-OPEN`, `VIRTUAL-SKIN-CHARGE-OPEN-SUB-0`, `VIRTUAL-SKIN-CHARGE-OPEN-SUB-1`, `VIRTUAL-SKIN-CHARGE-OPEN-SUB-2`

```json
{
  "Coefficient": [
    1.0,
    1.0,
    1.0
  ],
  "Combination": [
    "VIRTUAL-SKIN-CHARGE-OPEN-SUB-0",
    "VIRTUAL-SKIN-CHARGE-OPEN-SUB-1",
    "VIRTUAL-SKIN-CHARGE-OPEN-SUB-2"
  ],
  "Formula": "MAXIMUM",
  "Hidden": true,
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-CHARGE-OPEN",
  "Type": "UNKNOWN",
  "Version": "24.11.29",
  "VirtualSensor": true
}
```

### $.Sensors[21]

- Names: `VIRTUAL-SKIN-CHARGE-CLOSE-SUB-0`

```json
{
  "Coefficient": [
    0.011,
    0.063,
    0.03,
    0.24,
    0.019,
    0.252,
    0.277,
    0.109
  ],
  "Combination": [
    "soc_therm",
    "rfpa_therm",
    "quiet_therm",
    "charging_therm",
    "inner_disp_therm",
    "flash_therm",
    "outer_disp_therm",
    "north_therm"
  ],
  "Formula": "WEIGHTED_AVG",
  "Hidden": true,
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-CHARGE-CLOSE-SUB-0",
  "Offset": -195.0,
  "Type": "UNKNOWN",
  "VirtualSensor": true
}
```

### $.Sensors[22]

- Names: `VIRTUAL-SKIN-CHARGE-CLOSE-SUB-1`

```json
{
  "Coefficient": [
    0.19,
    0.0,
    0.019,
    0.087,
    0.006,
    0.312,
    0.303,
    0.083
  ],
  "Combination": [
    "soc_therm",
    "rfpa_therm",
    "quiet_therm",
    "charging_therm",
    "inner_disp_therm",
    "flash_therm",
    "outer_disp_therm",
    "north_therm"
  ],
  "Formula": "WEIGHTED_AVG",
  "Hidden": true,
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-CHARGE-CLOSE-SUB-1",
  "Offset": -130.0,
  "Type": "UNKNOWN",
  "VirtualSensor": true
}
```

### $.Sensors[23]

- Names: `VIRTUAL-SKIN-CHARGE-CLOSE-SUB-2`

```json
{
  "Coefficient": [
    0.187,
    0.2,
    0.059,
    0.036,
    0.031,
    0.242,
    0.013,
    0.231
  ],
  "Combination": [
    "soc_therm",
    "rfpa_therm",
    "quiet_therm",
    "charging_therm",
    "inner_disp_therm",
    "flash_therm",
    "outer_disp_therm",
    "north_therm"
  ],
  "Formula": "WEIGHTED_AVG",
  "Hidden": true,
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-CHARGE-CLOSE-SUB-2",
  "Offset": -2116.0,
  "Type": "UNKNOWN",
  "VirtualSensor": true
}
```

### $.Sensors[24]

- Names: `VIRTUAL-SKIN-CHARGE-CLOSE`, `VIRTUAL-SKIN-CHARGE-CLOSE-SUB-0`, `VIRTUAL-SKIN-CHARGE-CLOSE-SUB-1`, `VIRTUAL-SKIN-CHARGE-CLOSE-SUB-2`

```json
{
  "Coefficient": [
    1.0,
    1.0,
    1.0
  ],
  "Combination": [
    "VIRTUAL-SKIN-CHARGE-CLOSE-SUB-0",
    "VIRTUAL-SKIN-CHARGE-CLOSE-SUB-1",
    "VIRTUAL-SKIN-CHARGE-CLOSE-SUB-2"
  ],
  "Formula": "MAXIMUM",
  "Hidden": true,
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-CHARGE-CLOSE",
  "Type": "UNKNOWN",
  "Version": "24.11.29",
  "VirtualSensor": true
}
```

### $.Sensors[25]

- Names: `VIRTUAL-SKIN-CHARGE-CLOSE`, `VIRTUAL-SKIN-CHARGE-LEGACY`, `VIRTUAL-SKIN-CHARGE-OPEN`

```json
{
  "Coefficient": [
    "OPEN_WEIGHT",
    "CLOSE_WEIGHT"
  ],
  "CoefficientType": [
    "SENSOR",
    "SENSOR"
  ],
  "Combination": [
    "VIRTUAL-SKIN-CHARGE-OPEN",
    "VIRTUAL-SKIN-CHARGE-CLOSE"
  ],
  "Formula": "WEIGHTED_AVG",
  "Hidden": true,
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-CHARGE-LEGACY",
  "Type": "UNKNOWN",
  "Version": "24.11.29",
  "VirtualSensor": true
}
```

### $.Sensors[26]

- Names: `VIRTUAL-SKIN-CHARGE-LEGACY`, `VIRTUAL-SKIN-CHARGE-WIRED`
- PollingDelay: `300000`
- PassiveDelay: `7000`

```json
{
  "BindedCdevInfo": [
    {
      "CdevCeiling": [
        0,
        25,
        25,
        25,
        26,
        26,
        26
      ],
      "CdevRequest": "chg_mdis",
      "CdevWeightForPID": [
        1,
        1,
        1,
        1,
        1,
        1,
        1
      ],
      "LimitInfo": [
        0,
        0,
        1,
        1,
        1,
        26,
        26
      ],
      "MaxReleaseStep": 1,
      "MaxThrottleStep": 1
    }
  ],
  "Coefficient": [
    "NO_WLC"
  ],
  "CoefficientType": [
    "SENSOR"
  ],
  "Combination": [
    "VIRTUAL-SKIN-CHARGE-LEGACY"
  ],
  "ExcludedPowerInfo": [
    {
      "PowerRail": "PARTIAL_SYSTEM_POWER",
      "PowerWeight": [
        0.12,
        0.12,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0
      ]
    }
  ],
  "Formula": "MAXIMUM",
  "HotHysteresis": [
    0.0,
    0.0,
    1.9,
    1.9,
    1.9,
    1.4,
    1.9
  ],
  "HotThreshold": [
    "NAN",
    34.0,
    38.0,
    41.0,
    45.0,
    46.5,
    56.5
  ],
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-CHARGE-WIRED",
  "Offset": 1000.0,
  "PIDInfo": {
    "I_Cutoff": [
      "NAN",
      "NAN",
      4,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "I_Max": [
      "NAN",
      "NAN",
      2521,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "I_Trend": 0.03,
    "K_D": [
      "NAN",
      "NAN",
      0,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "K_I": [
      "NAN",
      "NAN",
      149,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "K_Po": [
      "NAN",
      "NAN",
      360,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "K_Pu": [
      "NAN",
      "NAN",
      0,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "MaxAllocPower": [
      "NAN",
      "NAN",
      3746,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "MinAllocPower": [
      "NAN",
      "NAN",
      0,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "S_Power": [
      "NAN",
      "NAN",
      3746,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ]
  },
  "PassiveDelay": 7000,
  "PollingDelay": 300000,
  "ThermalSampleCount": 16,
  "TriggerSensor": [
    "soc_therm"
  ],
  "Type": "UNKNOWN",
  "Version": "25.06.05",
  "VirtualSensor": true
}
```

### $.Sensors[27]

- Names: `VIRTUAL-SKIN-CHARGE-WLC-OPEN`

```json
{
  "Coefficient": [
    0.016,
    0.331,
    0.291,
    0.182,
    0.019,
    0.079,
    0.006,
    0.074
  ],
  "Combination": [
    "soc_therm",
    "rfpa_therm",
    "quiet_therm",
    "charging_therm",
    "inner_disp_therm",
    "flash_therm",
    "outer_disp_therm",
    "north_therm"
  ],
  "Formula": "WEIGHTED_AVG",
  "Hidden": true,
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-CHARGE-WLC-OPEN",
  "Offset": -39.0,
  "Type": "UNKNOWN",
  "Version": "24.11.29",
  "VirtualSensor": true
}
```

### $.Sensors[28]

- Names: `VIRTUAL-SKIN-CHARGE-WLC-CLOSE`

```json
{
  "Coefficient": [
    0.24,
    0.02,
    0.194,
    0.247,
    0.03,
    0.254,
    0.001,
    0.013
  ],
  "Combination": [
    "soc_therm",
    "rfpa_therm",
    "quiet_therm",
    "charging_therm",
    "inner_disp_therm",
    "flash_therm",
    "outer_disp_therm",
    "north_therm"
  ],
  "Formula": "WEIGHTED_AVG",
  "Hidden": true,
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-CHARGE-WLC-CLOSE",
  "Offset": -339.0,
  "Type": "UNKNOWN",
  "Version": "24.11.29",
  "VirtualSensor": true
}
```

### $.Sensors[29]

- Names: `VIRTUAL-SKIN-CHARGE-WLC-CLOSE`, `VIRTUAL-SKIN-CHARGE-WLC-LEGACY`, `VIRTUAL-SKIN-CHARGE-WLC-OPEN`

```json
{
  "Coefficient": [
    "OPEN_WEIGHT",
    "CLOSE_WEIGHT"
  ],
  "CoefficientType": [
    "SENSOR",
    "SENSOR"
  ],
  "Combination": [
    "VIRTUAL-SKIN-CHARGE-WLC-OPEN",
    "VIRTUAL-SKIN-CHARGE-WLC-CLOSE"
  ],
  "Formula": "WEIGHTED_AVG",
  "Hidden": true,
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-CHARGE-WLC-LEGACY",
  "Type": "UNKNOWN",
  "Version": "24.11.29",
  "VirtualSensor": true
}
```

### $.Sensors[30]

- Names: `VIRTUAL-SKIN-CHARGE-LEGACY`, `VIRTUAL-SKIN-CHARGE-PERSIST`, `VIRTUAL-SKIN-CHARGE-WLC-LEGACY`
- PollingDelay: `300000`
- PassiveDelay: `7000`

```json
{
  "BindedCdevInfo": [
    {
      "CdevCeiling": [
        0,
        25,
        25,
        26,
        26,
        26,
        26
      ],
      "CdevRequest": "chg_mdis",
      "CdevWeightForPID": [
        1,
        1,
        1,
        1,
        1,
        1,
        1
      ],
      "LimitInfo": [
        0,
        0,
        1,
        1,
        26,
        26,
        26
      ]
    }
  ],
  "Coefficient": [
    "IS_WLC",
    "NO_WLC"
  ],
  "CoefficientType": [
    "SENSOR",
    "SENSOR"
  ],
  "Combination": [
    "VIRTUAL-SKIN-CHARGE-WLC-LEGACY",
    "VIRTUAL-SKIN-CHARGE-LEGACY"
  ],
  "Formula": "WEIGHTED_AVG",
  "HotHysteresis": [
    0.0,
    0.0,
    1.9,
    1.9,
    1.4,
    1.9,
    1.9
  ],
  "HotThreshold": [
    "NaN",
    37.0,
    41.0,
    45.0,
    46.5,
    51.0,
    56.5
  ],
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-CHARGE-PERSIST",
  "Offset": 1000.0,
  "PIDInfo": {
    "I_Cutoff": [
      "NaN",
      "NaN",
      4,
      "NaN",
      "NaN",
      "NaN",
      "NaN"
    ],
    "I_Max": [
      "NaN",
      "NaN",
      2072,
      "NaN",
      "NaN",
      "NaN",
      "NaN"
    ],
    "I_Trend": 0,
    "K_D": [
      "NaN",
      "NaN",
      0,
      "NaN",
      "NaN",
      "NaN",
      "NaN"
    ],
    "K_Io": [
      "NaN",
      "NaN",
      149,
      "NaN",
      "NaN",
      "NaN",
      "NaN"
    ],
    "K_Iu": [
      "NaN",
      "NaN",
      25,
      "NaN",
      "NaN",
      "NaN",
      "NaN"
    ],
    "K_Po": [
      "NaN",
      "NaN",
      518,
      "NaN",
      "NaN",
      "NaN",
      "NaN"
    ],
    "K_Pu": [
      "NaN",
      "NaN",
      103,
      "NaN",
      "NaN",
      "NaN",
      "NaN"
    ],
    "MaxAllocPower": [
      "NaN",
      "NaN",
      3710,
      "NaN",
      "NaN",
      "NaN",
      "NaN"
    ],
    "MinAllocPower": [
      "NaN",
      "NaN",
      0,
      "NaN",
      "NaN",
      "NaN",
      "NaN"
    ],
    "S_Power": [
      "NaN",
      "NaN",
      3297,
      "NaN",
      "NaN",
      "NaN",
      "NaN"
    ]
  },
  "PassiveDelay": 7000,
  "PollingDelay": 300000,
  "ThermalSampleCount": 16,
  "TriggerSensor": [
    "soc_therm"
  ],
  "Type": "UNKNOWN",
  "Version": "25.06.05",
  "VirtualSensor": true
}
```

## thermal_info_config_throttling.json

- SHA-256: `8660dbc231f6b821c989e18dd73b942de636ae4e2edc9734cf560eb0d05a02ec`
- VIRTUAL-SKIN entry count: `10`

### $

- Names: `VIRTUAL-SKIN`, `VIRTUAL-SKIN-CPU-HIGH`, `VIRTUAL-SKIN-CPU-LIGHT-ODPM`, `VIRTUAL-SKIN-CPU-MID`, `VIRTUAL-SKIN-CPU-ODPM`, `VIRTUAL-SKIN-EQ`, `VIRTUAL-SKIN-HINT`, `VIRTUAL-SKIN-SOC`, `VIRTUAL-SKIN-SOC-EXTREME`

```json
{
  "CoolingDevices": [
    {
      "Multiplier": 0.001,
      "Name": "cpufreq-cpu0",
      "PowerCap": true,
      "ScalingAvailableFrequenciesPath": "/sys/devices/system/cpu/cpufreq/policy0/scaling_available_frequencies",
      "Type": "CPU"
    },
    {
      "Multiplier": 0.001,
      "Name": "cpufreq-cpu2",
      "PowerCap": true,
      "ScalingAvailableFrequenciesPath": "/sys/devices/system/cpu/cpufreq/policy2/scaling_available_frequencies",
      "Type": "CPU"
    },
    {
      "Multiplier": 0.001,
      "Name": "big_and_big_mid",
      "PowerCap": true,
      "Type": "CPU"
    },
    {
      "Name": "thermal-uclamp-0",
      "ScalingAvailableFrequenciesPath": "/sys/devices/system/cpu/cpufreq/policy0/scaling_available_frequencies",
      "Type": "CPU",
      "WritePath": "/dev/thermal/cdev-by-name/thermal-uclamp-0/cur_state"
    },
    {
      "Name": "thermal-uclamp-2",
      "ScalingAvailableFrequenciesPath": "/sys/devices/system/cpu/cpufreq/policy2/scaling_available_frequencies",
      "Type": "CPU",
      "WritePath": "/dev/thermal/cdev-by-name/thermal-uclamp-2/cur_state"
    },
    {
      "Name": "thermal-uclamp-5",
      "ScalingAvailableFrequenciesPath": "/sys/devices/system/cpu/cpufreq/policy5/scaling_available_frequencies",
      "Type": "CPU",
      "WritePath": "/dev/thermal/cdev-by-name/thermal-uclamp-5/cur_state"
    },
    {
      "Name": "thermal-uclamp-7",
      "ScalingAvailableFrequenciesPath": "/sys/devices/system/cpu/cpufreq/policy7/scaling_available_frequencies",
      "Type": "CPU",
      "WritePath": "/dev/thermal/cdev-by-name/thermal-uclamp-7/cur_state"
    },
    {
      "Multiplier": 0.001,
      "Name": "gpu",
      "PowerCap": true,
      "ScalingAvailableFrequenciesPath": "/sys/devices/platform/34f00000.gpu0/devfreq/34f00000.gpu0/available_frequencies",
      "Type": "GPU"
    },
    {
      "Multiplier": 0.001,
      "Name": "tpu",
      "PowerCap": true,
      "Type": "NPU"
    },
    {
      "Multiplier": 0.001,
      "Name": "aurora",
      "PowerCap": true,
      "Type": "NPU"
    }
  ],
  "Include": [
    "thermal_info_config_bg_tasks_throttling.json"
  ],
  "LogInfo": {
    "ExcludedPowerRailsLog": [
      "VSYS_PWR_VBATT"
    ]
  },
  "PowerRails": [
    {
      "Name": "S4M_VDD_CPU",
      "PowerSampleCount": 1,
      "PowerSampleDelay": 7000
    },
    {
      "Name": "S3M_VDD_CPU1",
      "PowerSampleCount": 1,
      "PowerSampleDelay": 7000
    },
    {
      "Name": "S2M_VDD_CPU2",
      "PowerSampleCount": 1,
      "PowerSampleDelay": 7000
    },
    {
      "Name": "S2S_VDD_GPU",
      "PowerSampleCount": 1,
      "PowerSampleDelay": 7000
    },
    {
      "Name": "S7M_VDD_TPU",
      "PowerSampleCount": 1,
      "PowerSampleDelay": 7000
    },
    {
      "Name": "S8S_VDD_GMC",
      "PowerSampleCount": 1,
      "PowerSampleDelay": 7000
    },
    {
      "Coefficient": [
        1.0,
        1.0,
        1.0
      ],
      "Combination": [
        "S2M_VDD_CPU2",
        "S3M_VDD_CPU1",
        "S4M_VDD_CPU"
      ],
      "Formula": "WEIGHTED_AVG",
      "Name": "VIRTUAL_CPU_POWER",
      "PowerSampleCount": 1,
      "PowerSampleDelay": 7000,
      "VirtualRails": true
    },
    {
      "Coefficient": [
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0
      ],
      "Combination": [
        "S1M_VDD_AMB",
        "S2M_VDD_CPU2",
        "S3M_VDD_CPU1",
        "S4M_VDD_CPU",
        "S7M_VDD_TPU",
        "S8M_LLDO2",
        "S9M_VDD_TPU_M",
        "S11M_VDD_CPU_M",
        "S12M_VDD_CPU1_M",
        "VSYS_PWR_WLAN_BT",
        "S2S_VDD_GPU",
        "S4S_VDD2H_MEM",
        "S7S_MLDO",
        "S8S_VDD_GMC",
        "VSYS_PWR_RFFE",
        "VSYS_PWR_MODEM",
        "VSYS_PWR_DISP_G1",
        "VSYS_PWR_DISP_G2"
      ],
      "Formula": "WEIGHTED_AVG",
      "Name": "PARTIAL_SYSTEM_POWER",
      "PowerSampleCount": 5,
      "PowerSampleDelay": 7000,
      "VirtualRails": true
    }
  ],
  "Sensors": [
    {
      "HotThreshold": [
        "NAN",
        "NAN",
        "NAN",
        "NAN",
        "NAN",
        "NAN",
        "60.0"
      ],
      "Multiplier": 0.001,
      "Name": "battery",
      "Type": "BATTERY"
    },
    {
      "Multiplier": 0.001,
      "Name": "LITTLE",
      "Type": "CPU"
    },
    {
      "Multiplier": 0.001,
      "Name": "MID",
      "Type": "CPU"
    },
    {
      "Multiplier": 0.001,
      "Name": "BIG_MID",
      "Type": "CPU"
    },
    {
      "Multiplier": 0.001,
      "Name": "BIG",
      "Type": "CPU"
    },
    {
      "Multiplier": 0.001,
      "Name": "GPU",
      "Type": "GPU"
    },
    {
      "Multiplier": 0.001,
      "Name": "TPU",
      "Type": "NPU"
    },
    {
      "BindedCdevInfo": [
        {
          "CdevRequest": "aurora",
          "LimitInfo": [
            0,
            0,
            0,
            0,
            0,
            15,
            15
          ]
        }
      ],
      "Coefficient": [
        1.0
      ],
      "Combination": [
        "VIRTUAL-SKIN-EQ"
      ],
      "Formula": "MAXIMUM",
      "HotHysteresis": [
        0.0,
        1.9,
        1.9,
        1.9,
        1.4,
        1.9,
        1.9
      ],
      "HotThreshold": [
        "NAN",
        39,
        43,
        45,
        46.5,
        52,
        55.0
      ],
      "Multiplier": 0.001,
      "Name": "VIRTUAL-SKIN",
      "PassiveDelay": 7000,
      "PollingDelay": 300000,
      "SendCallback": true,
      "TriggerSensor": [
        "north_therm",
        "charging_therm",
        "disp0_therm"
      ],
      "Type": "SKIN",
      "Version": "0.1",
      "VirtualSensor": true
    },
    {
      "Coefficient": [
        1.0
      ],
      "Combination": [
        "VIRTUAL-SKIN"
      ],
      "Formula": "MAXIMUM",
      "Hidden": true,
      "HotHysteresis": [
        0.0,
        1.9,
        1.9,
        1.9,
        1.4,
        1.9,
        1.9
      ],
      "HotThreshold": [
        "NAN",
        37.0,
        43.0,
        45.0,
        46.5,
        52.0,
        55.0
      ],
      "Multiplier": 0.001,
      "Name": "VIRTUAL-SKIN-HINT",
      "PassiveDelay": 7000,
      "PollingDelay": 300000,
      "SendPowerHint": true,
      "TriggerSensor": [
        "north_therm",
        "charging_therm",
        "disp0_therm"
      ],
      "Type": "UNKNOWN",
      "VirtualSensor": true
    },
    {
      "BindedCdevInfo": [
        {
          "BindedPowerRail": "S4M_VDD_CPU",
          "CdevCeilingFrequency": [
            2246000,
            1632000,
            1632000,
            1632000,
            1632000,
            1632000,
            1632000
          ],
          "CdevRequest": "cpufreq-cpu0",
          "CdevWeightForPID": [
            1,
            1,
            1,
            1,
            1,
            1,
            1
          ],
          "MaxReleaseStep": 1,
          "MaxThrottleStep": 1
        },
        {
          "BindedPowerRail": "S3M_VDD_CPU1",
          "CdevCeilingFrequency": [
            3052000,
            1785000,
            1785000,
            1785000,
            1785000,
            1785000,
            1785000
          ],
          "CdevRequest": "cpufreq-cpu2",
          "CdevWeightForPID": [
            1,
            1,
            1,
            1,
            1,
            1,
            1
          ],
          "MaxReleaseStep": 1,
          "MaxThrottleStep": 1
        },
        {
          "BindedPowerRail": "S2M_VDD_CPU2",
          "CdevCeiling": [
            0,
            10,
            10,
            10,
            10,
            10,
            10
          ],
          "CdevRequest": "big_and_big_mid",
          "CdevWeightForPID": [
            1,
            1,
            1,
            1,
            1,
            1,
            1
          ],
          "MaxReleaseStep": 1,
          "MaxThrottleStep": 1
        }
      ],
      "Coefficient": [
        1.0
      ],
      "Combination": [
        "VIRTUAL-SKIN"
      ],
      "Formula": "MAXIMUM",
      "Hidden": true,
      "HotHysteresis": [
        0.0,
        0.0,
        1.9,
        0.0,
        0.0,
        0.0,
        0.0
      ],
      "HotThreshold": [
        "NAN",
        37.0,
        39.0,
        "NAN",
        "NAN",
        "NAN",
        "NAN"
      ],
      "Multiplier": 0.001,
      "Name": "VIRTUAL-SKIN-CPU-LIGHT-ODPM",
      "PIDInfo": {
        "I_Cutoff": [
          "NAN",
          "NAN",
          2,
          "NAN",
          "NAN",
          "NAN",
          "NAN"
        ],
        "I_Max": [
          "NAN",
          "NAN",
          2933,
          "NAN",
          "NAN",
          "NAN",
          "NAN"
        ],
        "K_D": [
          "NAN",
          "NAN",
          0,
          "NAN",
          "NAN",
          "NAN",
          "NAN"
        ],
        "K_I": [
          "NAN",
          "NAN",
          5,
          "NAN",
          "NAN",
          "NAN",
          "NAN"
        ],
        "K_Po": [
          "NAN",
          "NAN",
          400,
          "NAN",
          "NAN",
          "NAN",
          "NAN"
        ],
        "K_Pu": [
          "NAN",
          "NAN",
          400,
          "NAN",
          "NAN",
          "NAN",
          "NAN"
        ],
        "MaxAllocPower": [
          "NAN",
          "NAN",
          6133,
          "NAN",
          "NAN",
          "NAN",
          "NAN"
        ],
        "MinAllocPower": [
          "NAN",
          "NAN",
          1066,
          "NAN",
          "NAN",
          "NAN",
          "NAN"
        ],
        "S_Power": [
          "NAN",
          "NAN",
          1066,
          "NAN",
          "NAN",
          "NAN",
          "NAN"
        ]
      },
      "PassiveDelay": 7000,
      "PollingDelay": 300000,
      "Profile": [
        {
          "BindedCdevInfo": [
            {
              "BindedPowerRail": "S4M_VDD_CPU",
              "CdevRequest": "cpufreq-cpu0",
              "Disabled": true,
              "MaxReleaseStep": 1
            },
            {
              "BindedPowerRail": "S3M_VDD_CPU1",
              "CdevRequest": "cpufreq-cpu2",
              "Disabled": true,
              "MaxReleaseStep": 1
            },
            {
              "BindedPowerRail": "S2M_VDD_CPU2",
              "CdevRequest": "big_and_big_mid",
              "Disabled": true,
              "MaxReleaseStep": 1
            }
          ],
          "Mode": "game"
        }
      ],
      "TriggerSensor": [
        "north_therm",
        "charging_therm",
        "disp0_therm"
      ],
      "Type": "UNKNOWN",
      "VirtualSensor": true
    },
    {
      "BindedCdevInfo": [
        {
          "CdevCeilingFrequency": [
            2246000,
            1190000,
            1190000,
            1190000,
            1190000,
            1190000,
            1190000
          ],
          "CdevRequest": "thermal-uclamp-0",
          "CdevWeightForPID": [
            0.145,
            0.145,
            0.145,
            0.145,
            0.145,
            0.145,
            0.145
          ],
          "MaxReleaseStep": 2,
          "MaxThrottleStep": 2
        },
        {
          "CdevCeilingFrequency": [
            3052000,
            1267200,
            1267200,
            1267200,
            1267200,
            1267200,
            1267200
          ],
          "CdevRequest": "thermal-uclamp-2",
          "CdevWeightForPID": [
            0.56,
            0.56,
            0.56,
            0.56,
            0.56,
            0.56,
            0.56
          ],
          "MaxReleaseStep": 2,
          "MaxThrottleStep": 2
        },
        {
          "CdevCeilingFrequency": [
            3052000,
            1075200,
            1075200,
            1075200,
            1075200,
            1075200,
            1075200
          ],
          "CdevRequest": "thermal-uclamp-5",
          "CdevWeightForPID": [
            0.4,
            0.4,
            0.4,
            0.4,
            0.4,
            0.4,
            0.4
          ],
          "MaxReleaseStep": 2,
          "MaxThrottleStep": 2
        },
        {
          "CdevCeilingFrequency": [
            3782000,
            1152000,
            1152000,
            1152000,
            1152000,
            1152000,
            1152000
          ],
          "CdevRequest": "thermal-uclamp-7",
          "CdevWeightForPID": [
            0.44,
            0.44,
            0.44,
            0.44,
            0.44,
            0.44,
            0.44
          ],
          "MaxReleaseStep": 2,
          "MaxThrottleStep": 2
        }
      ],
      "Coefficient": [
        1.0
      ],
      "Combination": [
        "VIRTUAL-SKIN"
      ],
      "Formula": "MAXIMUM",
      "Hidden": true,
      "HotHysteresis": [
        0.0,
        0.0,
        1.9,
        0.0,
        0.0,
        0.0,
        0.0
      ],
      "HotThreshold": [
        "NAN",
        39.0,
        41.0,
        "NAN",
        "NAN",
        "NAN",
        "NAN"
      ],
      "Multiplier": 0.001,
      "Name": "VIRTUAL-SKIN-CPU-MID",
      "PIDInfo": {
        "I_Cutoff": [
          "NAN",
          "NAN",
          4,
          "NAN",
          "NAN",
          "NAN",
          "NAN"
        ],
        "I_Default_Pct": 10,
        "I_Max": [
          "NAN",
          "NAN",
          2150,
          "NAN",
          "NAN",
          "NAN",
          "NAN"
        ],
        "K_D": [
          "NAN",
          "NAN",
          0,
          "NAN",
          "NAN",
          "NAN",
          "NAN"
        ],
        "K_I": [
          "NAN",
          "NAN",
          5,
          "NAN",
          "NAN",
          "NAN",
          "NAN"
        ],
        "K_Po": [
          "NAN",
          "NAN",
          400,
          "NAN",
          "NAN",
          "NAN",
          "NAN"
        ],
        "K_Pu": [
          "NAN",
          "NAN",
          400,
          "NAN",
          "NAN",
          "NAN",
          "NAN"
        ],
        "MaxAllocPower": [
          "NAN",
          "NAN",
          2850,
          "NAN",
          "NAN",
          "NAN",
          "NAN"
        ],
        "MinAllocPower": [
          "NAN",
          "NAN",
          0,
          "NAN",
          "NAN",
          "NAN",
          "NAN"
        ],
        "S_Power": [
          "NAN",
          "NAN",
          700,
          "NAN",
          "NAN",
          "NAN",
          "NAN"
        ]
      },
      "PassiveDelay": 7000,
      "PollingDelay": 300000,
      "Profile": [
        {
          "BindedCdevInfo": [
            {
              "CdevRequest": "thermal-uclamp-0",
              "Disabled": true,
              "MaxReleaseStep": 1
            },
            {
              "CdevRequest": "thermal-uclamp-2",
              "Disabled": true,
              "MaxReleaseStep": 1
            },
            {
              "CdevRequest": "thermal-uclamp-5",
              "Disabled": true,
              "MaxReleaseStep": 1
            },
            {
              "CdevRequest": "thermal-uclamp-7",
              "Disabled": true,
              "MaxReleaseStep": 1
            }
          ],
          "Mode": "game"
        },
        {
          "BindedCdevInfo": [
            {
              "CdevRequest": "thermal-uclamp-0",
              "Disabled": true,
              "MaxReleaseStep": 1
            },
            {
              "CdevRequest": "thermal-uclamp-2",
              "Disabled": true,
              "MaxReleaseStep": 1
            },
            {
              "CdevRequest": "thermal-uclamp-5",
              "Disabled": true,
              "MaxReleaseStep": 1
            },
            {
              "CdevRequest": "thermal-uclamp-7",
              "Disabled": true,
              "MaxReleaseStep": 1
            }
          ],
          "Mode": "camera"
        }
      ],
      "TriggerSensor": [
        "north_therm",
        "charging_therm",
        "disp0_therm"
      ],
      "Type": "UNKNOWN",
      "VirtualSensor": true
    },
    {
      "BindedCdevInfo": [
        {
          "BindedPowerRail": "S4M_VDD_CPU",
          "CdevCeilingFrequency": [
            2246000,
            729000,
            729000,
            729000,
            729000,
            729000,
            729000
          ],
          "CdevRequest": "cpufreq-cpu0",
          "CdevWeightForPID": [
            1,
            1,
            1,
            1,
            1,
            1,
            1
          ],
          "MaxReleaseStep": 2,
          "MaxThrottleStep": 2
        },
        {
          "BindedPowerRail": "S3M_VDD_CPU1",
          "CdevCeilingFrequency": [
            3052000,
            729600,
            729600,
            729600,
            729600,
            729600,
            729600
          ],
          "CdevRequest": "cpufreq-cpu2",
          "CdevWeightForPID": [
            1,
            1,
            1,
            1,
            1,
            1,
            1
          ],
          "MaxReleaseStep": 2,
          "MaxThrottleStep": 2
        },
        {
          "BindedPowerRail": "S2M_VDD_CPU2",
          "CdevCeiling": [
            0,
            20,
            20,
            20,
            20,
            20,
            10
          ],
          "CdevRequest": "big_and_big_mid",
          "CdevWeightForPID": [
            1,
            1,
            1,
            1,
            1,
            1,
            1
          ],
          "MaxReleaseStep": 1,
          "MaxThrottleStep": 1
        }
      ],
      "Coefficient": [
        1.0
      ],
      "Combination": [
        "VIRTUAL-SKIN"
      ],
      "Formula": "MAXIMUM",
      "Hidden": true,
      "HotHysteresis": [
        0.0,
        0.0,
        1.9,
        0.0,
        0.0,
        0.0,
        0.0
      ],
      "HotThreshold": [
        "NAN",
        39.0,
        41.0,
        "NAN",
        "NAN",
        "NAN",
        "NAN"
      ],
      "Multiplier": 0.001,
      "Name": "VIRTUAL-SKIN-CPU-ODPM",
      "PIDInfo": {
        "I_Cutoff": [
          "NAN",
          "NAN",
          2,
          "NAN",
          "NAN",
          "NAN",
          "NAN"
        ],
        "I_Default": 500,
        "I_Max": [
          "NAN",
          "NAN",
          2000,
          "NAN",
          "NAN",
          "NAN",
          "NAN"
        ],
        "K_D": [
          "NAN",
          "NAN",
          0,
          "NAN",
          "NAN",
          "NAN",
          "NAN"
        ],
        "K_I": [
          "NAN",
          "NAN",
          5,
          "NAN",
          "NAN",
          "NAN",
          "NAN"
        ],
        "K_Po": [
          "NAN",
          "NAN",
          1000,
          "NAN",
          "NAN",
          "NAN",
          "NAN"
        ],
        "K_Pu": [
          "NAN",
          "NAN",
          1000,
          "NAN",
          "NAN",
          "NAN",
          "NAN"
        ],
        "MaxAllocPower": [
          "NAN",
          "NAN",
          3800,
          "NAN",
          "NAN",
          "NAN",
          "NAN"
        ],
        "MinAllocPower": [
          "NAN",
          "NAN",
          800,
          "NAN",
          "NAN",
          "NAN",
          "NAN"
        ],
        "S_Power": [
          "NAN",
          "NAN",
          800,
          "NAN",
          "NAN",
          "NAN",
          "NAN"
        ]
      },
      "PassiveDelay": 7000,
      "PollingDelay": 300000,
      "Profile": [
        {
          "BindedCdevInfo": [
            {
              "BindedPowerRail": "S4M_VDD_CPU",
              "CdevRequest": "cpufreq-cpu0",
              "Disabled": true,
              "MaxReleaseStep": 1
            },
            {
              "BindedPowerRail": "S3M_VDD_CPU1",
              "CdevRequest": "cpufreq-cpu2",
              "Disabled": true,
              "MaxReleaseStep": 1
            },
            {
              "BindedPowerRail": "S2M_VDD_CPU2",
              "CdevRequest": "big_and_big_mid",
              "Disabled": true,
              "MaxReleaseStep": 1
            }
          ],
          "Mode": "game"
        },
        {
          "BindedCdevInfo": [
            {
              "BindedPowerRail": "S4M_VDD_CPU",
              "CdevRequest": "cpufreq-cpu0",
              "Disabled": true,
              "MaxReleaseStep": 1
            },
            {
              "BindedPowerRail": "S3M_VDD_CPU1",
              "CdevRequest": "cpufreq-cpu2",
              "Disabled": true,
              "MaxReleaseStep": 1
            },
            {
              "BindedPowerRail": "S2M_VDD_CPU2",
              "CdevRequest": "big_and_big_mid",
              "Disabled": true,
              "MaxReleaseStep": 1
            }
          ],
          "Mode": "camera"
        }
      ],
      "TriggerSensor": [
        "north_therm",
        "charging_therm",
        "disp0_therm"
      ],
      "Type": "UNKNOWN",
      "VirtualSensor": true
    },
    "...len=19"
  ]
}
```

### $.Sensors[7]

- Names: `VIRTUAL-SKIN`, `VIRTUAL-SKIN-EQ`
- PollingDelay: `300000`
- PassiveDelay: `7000`

```json
{
  "BindedCdevInfo": [
    {
      "CdevRequest": "aurora",
      "LimitInfo": [
        0,
        0,
        0,
        0,
        0,
        15,
        15
      ]
    }
  ],
  "Coefficient": [
    1.0
  ],
  "Combination": [
    "VIRTUAL-SKIN-EQ"
  ],
  "Formula": "MAXIMUM",
  "HotHysteresis": [
    0.0,
    1.9,
    1.9,
    1.9,
    1.4,
    1.9,
    1.9
  ],
  "HotThreshold": [
    "NAN",
    39,
    43,
    45,
    46.5,
    52,
    55.0
  ],
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN",
  "PassiveDelay": 7000,
  "PollingDelay": 300000,
  "SendCallback": true,
  "TriggerSensor": [
    "north_therm",
    "charging_therm",
    "disp0_therm"
  ],
  "Type": "SKIN",
  "Version": "0.1",
  "VirtualSensor": true
}
```

### $.Sensors[8]

- Names: `VIRTUAL-SKIN`, `VIRTUAL-SKIN-HINT`
- PollingDelay: `300000`
- PassiveDelay: `7000`

```json
{
  "Coefficient": [
    1.0
  ],
  "Combination": [
    "VIRTUAL-SKIN"
  ],
  "Formula": "MAXIMUM",
  "Hidden": true,
  "HotHysteresis": [
    0.0,
    1.9,
    1.9,
    1.9,
    1.4,
    1.9,
    1.9
  ],
  "HotThreshold": [
    "NAN",
    37.0,
    43.0,
    45.0,
    46.5,
    52.0,
    55.0
  ],
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-HINT",
  "PassiveDelay": 7000,
  "PollingDelay": 300000,
  "SendPowerHint": true,
  "TriggerSensor": [
    "north_therm",
    "charging_therm",
    "disp0_therm"
  ],
  "Type": "UNKNOWN",
  "VirtualSensor": true
}
```

### $.Sensors[9]

- Names: `VIRTUAL-SKIN`, `VIRTUAL-SKIN-CPU-LIGHT-ODPM`
- PollingDelay: `300000`
- PassiveDelay: `7000`

```json
{
  "BindedCdevInfo": [
    {
      "BindedPowerRail": "S4M_VDD_CPU",
      "CdevCeilingFrequency": [
        2246000,
        1632000,
        1632000,
        1632000,
        1632000,
        1632000,
        1632000
      ],
      "CdevRequest": "cpufreq-cpu0",
      "CdevWeightForPID": [
        1,
        1,
        1,
        1,
        1,
        1,
        1
      ],
      "MaxReleaseStep": 1,
      "MaxThrottleStep": 1
    },
    {
      "BindedPowerRail": "S3M_VDD_CPU1",
      "CdevCeilingFrequency": [
        3052000,
        1785000,
        1785000,
        1785000,
        1785000,
        1785000,
        1785000
      ],
      "CdevRequest": "cpufreq-cpu2",
      "CdevWeightForPID": [
        1,
        1,
        1,
        1,
        1,
        1,
        1
      ],
      "MaxReleaseStep": 1,
      "MaxThrottleStep": 1
    },
    {
      "BindedPowerRail": "S2M_VDD_CPU2",
      "CdevCeiling": [
        0,
        10,
        10,
        10,
        10,
        10,
        10
      ],
      "CdevRequest": "big_and_big_mid",
      "CdevWeightForPID": [
        1,
        1,
        1,
        1,
        1,
        1,
        1
      ],
      "MaxReleaseStep": 1,
      "MaxThrottleStep": 1
    }
  ],
  "Coefficient": [
    1.0
  ],
  "Combination": [
    "VIRTUAL-SKIN"
  ],
  "Formula": "MAXIMUM",
  "Hidden": true,
  "HotHysteresis": [
    0.0,
    0.0,
    1.9,
    0.0,
    0.0,
    0.0,
    0.0
  ],
  "HotThreshold": [
    "NAN",
    37.0,
    39.0,
    "NAN",
    "NAN",
    "NAN",
    "NAN"
  ],
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-CPU-LIGHT-ODPM",
  "PIDInfo": {
    "I_Cutoff": [
      "NAN",
      "NAN",
      2,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "I_Max": [
      "NAN",
      "NAN",
      2933,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "K_D": [
      "NAN",
      "NAN",
      0,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "K_I": [
      "NAN",
      "NAN",
      5,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "K_Po": [
      "NAN",
      "NAN",
      400,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "K_Pu": [
      "NAN",
      "NAN",
      400,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "MaxAllocPower": [
      "NAN",
      "NAN",
      6133,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "MinAllocPower": [
      "NAN",
      "NAN",
      1066,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "S_Power": [
      "NAN",
      "NAN",
      1066,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ]
  },
  "PassiveDelay": 7000,
  "PollingDelay": 300000,
  "Profile": [
    {
      "BindedCdevInfo": [
        {
          "BindedPowerRail": "S4M_VDD_CPU",
          "CdevRequest": "cpufreq-cpu0",
          "Disabled": true,
          "MaxReleaseStep": 1
        },
        {
          "BindedPowerRail": "S3M_VDD_CPU1",
          "CdevRequest": "cpufreq-cpu2",
          "Disabled": true,
          "MaxReleaseStep": 1
        },
        {
          "BindedPowerRail": "S2M_VDD_CPU2",
          "CdevRequest": "big_and_big_mid",
          "Disabled": true,
          "MaxReleaseStep": 1
        }
      ],
      "Mode": "game"
    }
  ],
  "TriggerSensor": [
    "north_therm",
    "charging_therm",
    "disp0_therm"
  ],
  "Type": "UNKNOWN",
  "VirtualSensor": true
}
```

### $.Sensors[10]

- Names: `VIRTUAL-SKIN`, `VIRTUAL-SKIN-CPU-MID`
- PollingDelay: `300000`
- PassiveDelay: `7000`

```json
{
  "BindedCdevInfo": [
    {
      "CdevCeilingFrequency": [
        2246000,
        1190000,
        1190000,
        1190000,
        1190000,
        1190000,
        1190000
      ],
      "CdevRequest": "thermal-uclamp-0",
      "CdevWeightForPID": [
        0.145,
        0.145,
        0.145,
        0.145,
        0.145,
        0.145,
        0.145
      ],
      "MaxReleaseStep": 2,
      "MaxThrottleStep": 2
    },
    {
      "CdevCeilingFrequency": [
        3052000,
        1267200,
        1267200,
        1267200,
        1267200,
        1267200,
        1267200
      ],
      "CdevRequest": "thermal-uclamp-2",
      "CdevWeightForPID": [
        0.56,
        0.56,
        0.56,
        0.56,
        0.56,
        0.56,
        0.56
      ],
      "MaxReleaseStep": 2,
      "MaxThrottleStep": 2
    },
    {
      "CdevCeilingFrequency": [
        3052000,
        1075200,
        1075200,
        1075200,
        1075200,
        1075200,
        1075200
      ],
      "CdevRequest": "thermal-uclamp-5",
      "CdevWeightForPID": [
        0.4,
        0.4,
        0.4,
        0.4,
        0.4,
        0.4,
        0.4
      ],
      "MaxReleaseStep": 2,
      "MaxThrottleStep": 2
    },
    {
      "CdevCeilingFrequency": [
        3782000,
        1152000,
        1152000,
        1152000,
        1152000,
        1152000,
        1152000
      ],
      "CdevRequest": "thermal-uclamp-7",
      "CdevWeightForPID": [
        0.44,
        0.44,
        0.44,
        0.44,
        0.44,
        0.44,
        0.44
      ],
      "MaxReleaseStep": 2,
      "MaxThrottleStep": 2
    }
  ],
  "Coefficient": [
    1.0
  ],
  "Combination": [
    "VIRTUAL-SKIN"
  ],
  "Formula": "MAXIMUM",
  "Hidden": true,
  "HotHysteresis": [
    0.0,
    0.0,
    1.9,
    0.0,
    0.0,
    0.0,
    0.0
  ],
  "HotThreshold": [
    "NAN",
    39.0,
    41.0,
    "NAN",
    "NAN",
    "NAN",
    "NAN"
  ],
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-CPU-MID",
  "PIDInfo": {
    "I_Cutoff": [
      "NAN",
      "NAN",
      4,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "I_Default_Pct": 10,
    "I_Max": [
      "NAN",
      "NAN",
      2150,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "K_D": [
      "NAN",
      "NAN",
      0,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "K_I": [
      "NAN",
      "NAN",
      5,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "K_Po": [
      "NAN",
      "NAN",
      400,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "K_Pu": [
      "NAN",
      "NAN",
      400,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "MaxAllocPower": [
      "NAN",
      "NAN",
      2850,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "MinAllocPower": [
      "NAN",
      "NAN",
      0,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "S_Power": [
      "NAN",
      "NAN",
      700,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ]
  },
  "PassiveDelay": 7000,
  "PollingDelay": 300000,
  "Profile": [
    {
      "BindedCdevInfo": [
        {
          "CdevRequest": "thermal-uclamp-0",
          "Disabled": true,
          "MaxReleaseStep": 1
        },
        {
          "CdevRequest": "thermal-uclamp-2",
          "Disabled": true,
          "MaxReleaseStep": 1
        },
        {
          "CdevRequest": "thermal-uclamp-5",
          "Disabled": true,
          "MaxReleaseStep": 1
        },
        {
          "CdevRequest": "thermal-uclamp-7",
          "Disabled": true,
          "MaxReleaseStep": 1
        }
      ],
      "Mode": "game"
    },
    {
      "BindedCdevInfo": [
        {
          "CdevRequest": "thermal-uclamp-0",
          "Disabled": true,
          "MaxReleaseStep": 1
        },
        {
          "CdevRequest": "thermal-uclamp-2",
          "Disabled": true,
          "MaxReleaseStep": 1
        },
        {
          "CdevRequest": "thermal-uclamp-5",
          "Disabled": true,
          "MaxReleaseStep": 1
        },
        {
          "CdevRequest": "thermal-uclamp-7",
          "Disabled": true,
          "MaxReleaseStep": 1
        }
      ],
      "Mode": "camera"
    }
  ],
  "TriggerSensor": [
    "north_therm",
    "charging_therm",
    "disp0_therm"
  ],
  "Type": "UNKNOWN",
  "VirtualSensor": true
}
```

### $.Sensors[11]

- Names: `VIRTUAL-SKIN`, `VIRTUAL-SKIN-CPU-ODPM`
- PollingDelay: `300000`
- PassiveDelay: `7000`

```json
{
  "BindedCdevInfo": [
    {
      "BindedPowerRail": "S4M_VDD_CPU",
      "CdevCeilingFrequency": [
        2246000,
        729000,
        729000,
        729000,
        729000,
        729000,
        729000
      ],
      "CdevRequest": "cpufreq-cpu0",
      "CdevWeightForPID": [
        1,
        1,
        1,
        1,
        1,
        1,
        1
      ],
      "MaxReleaseStep": 2,
      "MaxThrottleStep": 2
    },
    {
      "BindedPowerRail": "S3M_VDD_CPU1",
      "CdevCeilingFrequency": [
        3052000,
        729600,
        729600,
        729600,
        729600,
        729600,
        729600
      ],
      "CdevRequest": "cpufreq-cpu2",
      "CdevWeightForPID": [
        1,
        1,
        1,
        1,
        1,
        1,
        1
      ],
      "MaxReleaseStep": 2,
      "MaxThrottleStep": 2
    },
    {
      "BindedPowerRail": "S2M_VDD_CPU2",
      "CdevCeiling": [
        0,
        20,
        20,
        20,
        20,
        20,
        10
      ],
      "CdevRequest": "big_and_big_mid",
      "CdevWeightForPID": [
        1,
        1,
        1,
        1,
        1,
        1,
        1
      ],
      "MaxReleaseStep": 1,
      "MaxThrottleStep": 1
    }
  ],
  "Coefficient": [
    1.0
  ],
  "Combination": [
    "VIRTUAL-SKIN"
  ],
  "Formula": "MAXIMUM",
  "Hidden": true,
  "HotHysteresis": [
    0.0,
    0.0,
    1.9,
    0.0,
    0.0,
    0.0,
    0.0
  ],
  "HotThreshold": [
    "NAN",
    39.0,
    41.0,
    "NAN",
    "NAN",
    "NAN",
    "NAN"
  ],
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-CPU-ODPM",
  "PIDInfo": {
    "I_Cutoff": [
      "NAN",
      "NAN",
      2,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "I_Default": 500,
    "I_Max": [
      "NAN",
      "NAN",
      2000,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "K_D": [
      "NAN",
      "NAN",
      0,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "K_I": [
      "NAN",
      "NAN",
      5,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "K_Po": [
      "NAN",
      "NAN",
      1000,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "K_Pu": [
      "NAN",
      "NAN",
      1000,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "MaxAllocPower": [
      "NAN",
      "NAN",
      3800,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "MinAllocPower": [
      "NAN",
      "NAN",
      800,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "S_Power": [
      "NAN",
      "NAN",
      800,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ]
  },
  "PassiveDelay": 7000,
  "PollingDelay": 300000,
  "Profile": [
    {
      "BindedCdevInfo": [
        {
          "BindedPowerRail": "S4M_VDD_CPU",
          "CdevRequest": "cpufreq-cpu0",
          "Disabled": true,
          "MaxReleaseStep": 1
        },
        {
          "BindedPowerRail": "S3M_VDD_CPU1",
          "CdevRequest": "cpufreq-cpu2",
          "Disabled": true,
          "MaxReleaseStep": 1
        },
        {
          "BindedPowerRail": "S2M_VDD_CPU2",
          "CdevRequest": "big_and_big_mid",
          "Disabled": true,
          "MaxReleaseStep": 1
        }
      ],
      "Mode": "game"
    },
    {
      "BindedCdevInfo": [
        {
          "BindedPowerRail": "S4M_VDD_CPU",
          "CdevRequest": "cpufreq-cpu0",
          "Disabled": true,
          "MaxReleaseStep": 1
        },
        {
          "BindedPowerRail": "S3M_VDD_CPU1",
          "CdevRequest": "cpufreq-cpu2",
          "Disabled": true,
          "MaxReleaseStep": 1
        },
        {
          "BindedPowerRail": "S2M_VDD_CPU2",
          "CdevRequest": "big_and_big_mid",
          "Disabled": true,
          "MaxReleaseStep": 1
        }
      ],
      "Mode": "camera"
    }
  ],
  "TriggerSensor": [
    "north_therm",
    "charging_therm",
    "disp0_therm"
  ],
  "Type": "UNKNOWN",
  "VirtualSensor": true
}
```

### $.Sensors[12]

- Names: `VIRTUAL-SKIN`, `VIRTUAL-SKIN-CPU-HIGH`
- PollingDelay: `300000`
- PassiveDelay: `7000`

```json
{
  "BindedCdevInfo": [
    {
      "CdevCeilingFrequency": [
        2246000,
        729000,
        729000,
        729000,
        729000,
        729000,
        729000
      ],
      "CdevRequest": "thermal-uclamp-0",
      "CdevWeightForPID": [
        0.093,
        0.093,
        0.093,
        0.093,
        0.093,
        0.093,
        0.093
      ],
      "MaxReleaseStep": 2,
      "MaxThrottleStep": 2
    },
    {
      "CdevCeilingFrequency": [
        3052000,
        729600,
        729600,
        729600,
        729600,
        729600,
        729600
      ],
      "CdevRequest": "thermal-uclamp-2",
      "CdevWeightForPID": [
        0.285,
        0.285,
        0.285,
        0.285,
        0.285,
        0.285,
        0.285
      ],
      "MaxReleaseStep": 2,
      "MaxThrottleStep": 2
    },
    {
      "CdevCeilingFrequency": [
        3052000,
        729600,
        729600,
        729600,
        729600,
        729600,
        729600
      ],
      "CdevRequest": "thermal-uclamp-5",
      "CdevWeightForPID": [
        0.217,
        0.217,
        0.217,
        0.217,
        0.217,
        0.217,
        0.217
      ],
      "MaxReleaseStep": 2,
      "MaxThrottleStep": 2
    },
    {
      "CdevCeilingFrequency": [
        3782000,
        883000,
        883000,
        883000,
        883000,
        883000,
        883000
      ],
      "CdevRequest": "thermal-uclamp-7",
      "CdevWeightForPID": [
        0.261,
        0.261,
        0.261,
        0.261,
        0.261,
        0.261,
        0.261
      ],
      "MaxReleaseStep": 2,
      "MaxThrottleStep": 2
    }
  ],
  "Coefficient": [
    1.0
  ],
  "Combination": [
    "VIRTUAL-SKIN"
  ],
  "Formula": "MAXIMUM",
  "Hidden": true,
  "HotHysteresis": [
    0.0,
    0.0,
    1.9,
    0.0,
    0.0,
    0.0,
    0.0
  ],
  "HotThreshold": [
    "NAN",
    41.0,
    43.0,
    "NAN",
    "NAN",
    "NAN",
    "NAN"
  ],
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-CPU-HIGH",
  "PIDInfo": {
    "I_Cutoff": [
      "NAN",
      "NAN",
      4,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "I_Max": [
      "NAN",
      "NAN",
      1000,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "K_D": [
      "NAN",
      "NAN",
      0,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "K_I": [
      "NAN",
      "NAN",
      5,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "K_Po": [
      "NAN",
      "NAN",
      400,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "K_Pu": [
      "NAN",
      "NAN",
      400,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "MaxAllocPower": [
      "NAN",
      "NAN",
      1600,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "MinAllocPower": [
      "NAN",
      "NAN",
      0,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "S_Power": [
      "NAN",
      "NAN",
      600,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ]
  },
  "PassiveDelay": 7000,
  "PollingDelay": 300000,
  "Profile": [
    {
      "BindedCdevInfo": [
        {
          "CdevRequest": "thermal-uclamp-0",
          "Disabled": true,
          "MaxReleaseStep": 1
        },
        {
          "CdevRequest": "thermal-uclamp-2",
          "Disabled": true,
          "MaxReleaseStep": 1
        },
        {
          "CdevRequest": "thermal-uclamp-5",
          "Disabled": true,
          "MaxReleaseStep": 1
        },
        {
          "CdevRequest": "thermal-uclamp-7",
          "Disabled": true,
          "MaxReleaseStep": 1
        }
      ],
      "Mode": "game"
    },
    {
      "BindedCdevInfo": [
        {
          "CdevRequest": "thermal-uclamp-0",
          "Disabled": true,
          "MaxReleaseStep": 1
        },
        {
          "CdevRequest": "thermal-uclamp-2",
          "Disabled": true,
          "MaxReleaseStep": 1
        },
        {
          "CdevRequest": "thermal-uclamp-5",
          "Disabled": true,
          "MaxReleaseStep": 1
        },
        {
          "CdevRequest": "thermal-uclamp-7",
          "Disabled": true,
          "MaxReleaseStep": 1
        }
      ],
      "Mode": "camera"
    }
  ],
  "TriggerSensor": [
    "north_therm",
    "charging_therm",
    "disp0_therm"
  ],
  "Type": "UNKNOWN",
  "VirtualSensor": true
}
```

### $.Sensors[13]

- Names: `VIRTUAL-SKIN`, `VIRTUAL-SKIN-SOC`
- PollingDelay: `300000`
- PassiveDelay: `7000`

```json
{
  "BindedCdevInfo": [
    {
      "BindedPowerRail": "S4M_VDD_CPU",
      "CdevCeilingFrequency": [
        2246000,
        1632000,
        1632000,
        729000,
        729000,
        729000,
        268000
      ],
      "CdevRequest": "cpufreq-cpu0",
      "CdevWeightForPID": [
        1,
        1,
        1,
        1,
        1,
        1,
        1
      ],
      "LimitInfoFrequency": [
        2246000,
        2246000,
        2246000,
        2246000,
        2246000,
        2246000,
        268000
      ],
      "MaxReleaseStep": 1,
      "MaxThrottleStep": 1
    },
    {
      "BindedPowerRail": "S3M_VDD_CPU1",
      "CdevCeilingFrequency": [
        3052000,
        1785600,
        1785600,
        1267200,
        729600,
        729600,
        307200
      ],
      "CdevRequest": "cpufreq-cpu2",
      "CdevWeightForPID": [
        1,
        1,
        1,
        1,
        1,
        1,
        1
      ],
      "LimitInfoFrequency": [
        3052000,
        3052000,
        3052000,
        3052000,
        3052000,
        3052000,
        307200
      ],
      "MaxReleaseStep": 1,
      "MaxThrottleStep": 1
    },
    {
      "BindedPowerRail": "S2M_VDD_CPU2",
      "CdevCeiling": [
        0,
        22,
        22,
        22,
        22,
        22,
        22
      ],
      "CdevRequest": "big_and_big_mid",
      "CdevWeightForPID": [
        0.65,
        0.65,
        0.65,
        0.65,
        0.65,
        0.65,
        0.65
      ],
      "LimitInfo": [
        0,
        0,
        0,
        0,
        0,
        0,
        22
      ],
      "MaxReleaseStep": 1,
      "MaxThrottleStep": 1
    },
    {
      "BindedPowerRail": "S2S_VDD_GPU",
      "CdevCeilingFrequency": [
        1094000000,
        435000000,
        435000000,
        435000000,
        198000000,
        198000000,
        198000000
      ],
      "CdevRequest": "gpu",
      "CdevWeightForPID": [
        1,
        1,
        1,
        1,
        1,
        1,
        1
      ],
      "LimitInfoFrequency": [
        1094000000,
        1094000000,
        1094000000,
        1094000000,
        1094000000,
        1094000000,
        198000000
      ],
      "MaxReleaseStep": 1,
      "MaxThrottleStep": 1
    },
    {
      "BindedPowerRail": "S7M_VDD_TPU",
      "CdevCeiling": [
        0,
        13,
        13,
        13,
        13,
        14,
        15
      ],
      "CdevRequest": "tpu",
      "CdevWeightForPID": [
        1,
        1,
        1,
        1,
        1,
        1,
        1
      ],
      "LimitInfo": [
        0,
        0,
        0,
        0,
        0,
        0,
        15
      ],
      "MaxReleaseStep": 1,
      "MaxThrottleStep": 1
    }
  ],
  "Coefficient": [
    1.0
  ],
  "Combination": [
    "VIRTUAL-SKIN"
  ],
  "Formula": "MAXIMUM",
  "Hidden": true,
  "HotHysteresis": [
    0.0,
    0.0,
    1.9,
    1.9,
    1.9,
    1.4,
    1.9
  ],
  "HotThreshold": [
    "NAN",
    37.0,
    39.0,
    41.0,
    45.0,
    46.5,
    52.0
  ],
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-SOC",
  "PIDInfo": {
    "I_Cutoff": [
      "NAN",
      "NAN",
      "NAN",
      "NAN",
      8,
      "NAN",
      "NAN"
    ],
    "I_Max": [
      "NAN",
      "NAN",
      "NAN",
      "NAN",
      3120,
      "NAN",
      "NAN"
    ],
    "K_D": [
      "NAN",
      "NAN",
      "NAN",
      "NAN",
      0,
      "NAN",
      "NAN"
    ],
    "K_I": [
      "NAN",
      "NAN",
      "NAN",
      "NAN",
      5,
      "NAN",
      "NAN"
    ],
    "K_Po": [
      "NAN",
      "NAN",
      "NAN",
      "NAN",
      300,
      "NAN",
      "NAN"
    ],
    "K_Pu": [
      "NAN",
      "NAN",
      "NAN",
      "NAN",
      300,
      "NAN",
      "NAN"
    ],
    "MaxAllocPower": [
      "NAN",
      "NAN",
      "NAN",
      "NAN",
      4680,
      "NAN",
      "NAN"
    ],
    "MinAllocPower": [
      "NAN",
      "NAN",
      "NAN",
      "NAN",
      960,
      "NAN",
      "NAN"
    ],
    "S_Power": [
      "NAN",
      "NAN",
      "NAN",
      "NAN",
      960,
      "NAN",
      "NAN"
    ]
  },
  "PassiveDelay": 7000,
  "PollingDelay": 300000,
  "TriggerSensor": [
    "north_therm",
    "charging_therm",
    "disp0_therm"
  ],
  "Type": "UNKNOWN",
  "VirtualSensor": true
}
```

### $.Sensors[15]

- Names: `VIRTUAL-SKIN`

```json
{
  "Coefficient": [
    46000,
    3000,
    4000
  ],
  "Combination": [
    "VIRTUAL-SKIN",
    "PARTIAL_SYSTEM_POWER",
    "PARTIAL_SYSTEM_POWER"
  ],
  "CombinationType": [
    "SENSOR",
    "ODPM",
    "ODPM"
  ],
  "CountThresholdHysteresis": [
    1000.0,
    0.0,
    0.0
  ],
  "Formula": "COUNT_THRESHOLD",
  "Hidden": true,
  "Multiplier": 1,
  "Name": "EXTREME_POWER_VSKIN",
  "Type": "UNKNOWN",
  "VirtualSensor": true
}
```

### $.Sensors[18]

- Names: `VIRTUAL-SKIN`, `VIRTUAL-SKIN-SOC-EXTREME`
- PollingDelay: `300000`
- PassiveDelay: `7000`

```json
{
  "BindedCdevInfo": [
    {
      "BindedPowerRail": "S4M_VDD_CPU",
      "CdevCeilingFrequency": [
        2246000,
        1632000,
        1632000,
        729000,
        268000,
        268000,
        268000
      ],
      "CdevRequest": "cpufreq-cpu0",
      "CdevWeightForPID": [
        1,
        1,
        1,
        1,
        1,
        1,
        1
      ],
      "MaxReleaseStep": 1,
      "MaxThrottleStep": 1
    },
    {
      "BindedPowerRail": "S3M_VDD_CPU1",
      "CdevCeilingFrequency": [
        3052000,
        1785600,
        1785600,
        729600,
        307200,
        307200,
        307200
      ],
      "CdevRequest": "cpufreq-cpu2",
      "CdevWeightForPID": [
        1,
        1,
        1,
        1,
        1,
        1,
        1
      ],
      "MaxReleaseStep": 1,
      "MaxThrottleStep": 1
    },
    {
      "BindedPowerRail": "S2M_VDD_CPU2",
      "CdevCeiling": [
        0,
        22,
        22,
        22,
        22,
        22,
        22
      ],
      "CdevRequest": "big_and_big_mid",
      "CdevWeightForPID": [
        1,
        1,
        1,
        1,
        1,
        1,
        1
      ],
      "MaxReleaseStep": 1,
      "MaxThrottleStep": 1
    },
    {
      "BindedPowerRail": "S2S_VDD_GPU",
      "CdevCeilingFrequency": [
        1094000000,
        435000000,
        435000000,
        198000000,
        198000000,
        198000000,
        198000000
      ],
      "CdevRequest": "gpu",
      "CdevWeightForPID": [
        1,
        1,
        1,
        1,
        1,
        1,
        1
      ],
      "MaxReleaseStep": 1,
      "MaxThrottleStep": 1
    },
    {
      "BindedPowerRail": "S7M_VDD_TPU",
      "CdevCeiling": [
        0,
        15,
        15,
        15,
        15,
        15,
        15
      ],
      "CdevRequest": "tpu",
      "CdevWeightForPID": [
        1,
        1,
        1,
        1,
        1,
        1,
        1
      ],
      "MaxReleaseStep": 1,
      "MaxThrottleStep": 1
    }
  ],
  "Coefficient": [
    "EXTREME_THROTTLE"
  ],
  "CoefficientType": [
    "SENSOR"
  ],
  "Combination": [
    "VIRTUAL-SKIN"
  ],
  "Formula": "MAXIMUM",
  "Hidden": true,
  "HotHysteresis": [
    0.0,
    0.0,
    0.0,
    0.0,
    0.9,
    0.0,
    0.0
  ],
  "HotThreshold": [
    "NAN",
    "NAN",
    "NAN",
    45.0,
    46.0,
    "NAN",
    "NAN"
  ],
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-SOC-EXTREME",
  "PIDInfo": {
    "I_Cutoff": [
      "NAN",
      "NAN",
      "NAN",
      "NAN",
      2,
      "NAN",
      "NAN"
    ],
    "I_Max": [
      "NAN",
      "NAN",
      "NAN",
      "NAN",
      1200,
      "NAN",
      "NAN"
    ],
    "K_D": [
      "NAN",
      "NAN",
      "NAN",
      "NAN",
      0,
      "NAN",
      "NAN"
    ],
    "K_I": [
      "NAN",
      "NAN",
      "NAN",
      "NAN",
      5,
      "NAN",
      "NAN"
    ],
    "K_Po": [
      "NAN",
      "NAN",
      "NAN",
      "NAN",
      300,
      "NAN",
      "NAN"
    ],
    "K_Pu": [
      "NAN",
      "NAN",
      "NAN",
      "NAN",
      300,
      "NAN",
      "NAN"
    ],
    "MaxAllocPower": [
      "NAN",
      "NAN",
      "NAN",
      "NAN",
      1800,
      "NAN",
      "NAN"
    ],
    "MinAllocPower": [
      "NAN",
      "NAN",
      "NAN",
      "NAN",
      600,
      "NAN",
      "NAN"
    ],
    "S_Power": [
      "NAN",
      "NAN",
      "NAN",
      "NAN",
      600,
      "NAN",
      "NAN"
    ]
  },
  "PassiveDelay": 7000,
  "PollingDelay": 300000,
  "TriggerSensor": [
    "VIRTUAL-SKIN"
  ],
  "Type": "UNKNOWN",
  "VirtualSensor": true
}
```
