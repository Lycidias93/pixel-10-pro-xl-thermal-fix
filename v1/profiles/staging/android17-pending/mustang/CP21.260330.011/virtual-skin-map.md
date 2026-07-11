# Pixel 10 thermal VIRTUAL-SKIN map: mustang

- Source factory image: `/storage/emulated/0/Download/pixel10_a17_factory_dump_work_cp21.260330.011/_downloads/mustang_beta-cp21.260330.011-factory-01cd72fc.zip`
- Source SHA-256: `01cd72fc5204d2295fa1833cc3b706727d32a589cfecb9e4ef7052525c0691d7`
- Status: evidence only; beta/pending until live device-owner verify.
- Safety: no cross-device value reuse by this dump script.

## thermal_info_config.json

- SHA-256: `9976306c6421447426f17464a12a3d058eee6e4c936e6a1db7dceb9280c0286d`
- VIRTUAL-SKIN entry count: `6`

### $

- Names: `VIRTUAL-SKIN`, `VIRTUAL-SKIN-PREDICTION-MODEL`, `VIRTUAL-SKIN-SPEAKER`, `VIRTUAL-SKIN-SPEAKER-SUB-0`, `VIRTUAL-SKIN-SPEAKER-SUB-1`

```json
{
  "Include": [
    "thermal_info_config_throttling.json",
    "thermal_info_config_charge.json",
    "thermal_info_config_stats.json",
    "thermal_info_config_earlywarnings.json"
  ],
  "Sensors": [
    {
      "Combination": [
        "north_therm",
        "flash_therm",
        "soc_therm",
        "rfpa_therm",
        "charging_therm",
        "disp0_therm",
        "usb_pwr_therm",
        "quiet_therm",
        "VIRTUAL-SKIN"
      ],
      "Formula": "USE_ML_MODEL",
      "ModelPath": "future_vt_prediction_model.tflite",
      "Multiplier": 0.001,
      "Name": "VIRTUAL-SKIN-PREDICTION-MODEL",
      "OutputLabelCount": 10,
      "PreviousSampleCount": 11,
      "SampleDuration": 7000,
      "SupportPrediction": true,
      "SupportUnderSampling": true,
      "TimeResolution": 7000,
      "Type": "UNKNOWN",
      "VirtualSensor": true
    },
    {
      "Coefficient": [
        0.047,
        0.046,
        0.076,
        0.492,
        0.018,
        0.291,
        0.007,
        0.022
      ],
      "Combination": [
        "rfpa_therm",
        "quiet_therm",
        "charging_therm",
        "usb_pwr_therm",
        "flash_therm",
        "disp0_therm",
        "north_therm",
        "soc_therm"
      ],
      "Formula": "WEIGHTED_AVG",
      "Hidden": true,
      "Multiplier": 0.001,
      "Name": "VIRTUAL-SKIN-SPEAKER-SUB-0",
      "Offset": 126.0,
      "Type": "UNKNOWN",
      "VirtualSensor": true
    },
    {
      "Coefficient": [
        0.024,
        0.028,
        0.016,
        0.347,
        0.343,
        0.2,
        0.02,
        0.023
      ],
      "Combination": [
        "rfpa_therm",
        "quiet_therm",
        "charging_therm",
        "usb_pwr_therm",
        "flash_therm",
        "disp0_therm",
        "north_therm",
        "soc_therm"
      ],
      "Formula": "WEIGHTED_AVG",
      "Hidden": true,
      "Multiplier": 0.001,
      "Name": "VIRTUAL-SKIN-SPEAKER-SUB-1",
      "Offset": 158.0,
      "Type": "UNKNOWN",
      "VirtualSensor": true
    },
    {
      "Coefficient": [
        1.0,
        1.0
      ],
      "Combination": [
        "VIRTUAL-SKIN-SPEAKER-SUB-0",
        "VIRTUAL-SKIN-SPEAKER-SUB-1"
      ],
      "Formula": "MAXIMUM",
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
      "Multiplier": 0.001,
      "Name": "VIRTUAL-SKIN-SPEAKER",
      "Offset": 1000.0,
      "PassiveDelay": 7000,
      "PollingDelay": 300000,
      "SendCallback": true,
      "TriggerSensor": [
        "north_therm",
        "flash_therm",
        "soc_therm",
        "rfpa_therm",
        "charging_therm",
        "disp0_therm"
      ],
      "Type": "UNKNOWN",
      "Version": "DVT",
      "VirtualSensor": true
    },
    {
      "Coefficient": [
        0.012
      ],
      "Combination": [
        "flash_therm"
      ],
      "Formula": "WEIGHTED_AVG",
      "Multiplier": 0.001,
      "Name": "VIRTUAL-BTS-WINDOW-PARTIAL",
      "Offset": 1155,
      "Type": "UNKNOWN",
      "VirtualSensor": true
    },
    {
      "Coefficient": [
        59000.0,
        54000.0,
        2000.0
      ],
      "Combination": [
        "usb_pwr_therm",
        "usb_pwr_therm",
        "USB-MINUS-CHARGING"
      ],
      "Formula": "COUNT_THRESHOLD",
      "HotHysteresis": [
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.9,
        0.0
      ],
      "HotThreshold": [
        "NaN",
        "NaN",
        "NaN",
        "NaN",
        "NaN",
        2.0,
        "NaN"
      ],
      "Name": "VIRTUAL-USB-UI",
      "PassiveDelay": 7000,
      "PollingDelay": 300000,
      "SendCallback": true,
      "TriggerSensor": "usb_pwr_therm",
      "Type": "USB_PORT",
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
        54.0,
        "NAN"
      ],
      "Multiplier": 0.001,
      "Name": "cellular-emergency",
      "PassiveDelay": 7000,
      "PollingDelay": 300000,
      "SendCallback": true,
      "TriggerSensor": [
        "north_therm",
        "charging_therm",
        "disp0_therm"
      ],
      "Type": "POWER_AMPLIFIER",
      "VirtualSensor": true
    }
  ]
}
```

### $.Sensors[0]

- Names: `VIRTUAL-SKIN`, `VIRTUAL-SKIN-PREDICTION-MODEL`

```json
{
  "Combination": [
    "north_therm",
    "flash_therm",
    "soc_therm",
    "rfpa_therm",
    "charging_therm",
    "disp0_therm",
    "usb_pwr_therm",
    "quiet_therm",
    "VIRTUAL-SKIN"
  ],
  "Formula": "USE_ML_MODEL",
  "ModelPath": "future_vt_prediction_model.tflite",
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-PREDICTION-MODEL",
  "OutputLabelCount": 10,
  "PreviousSampleCount": 11,
  "SampleDuration": 7000,
  "SupportPrediction": true,
  "SupportUnderSampling": true,
  "TimeResolution": 7000,
  "Type": "UNKNOWN",
  "VirtualSensor": true
}
```

### $.Sensors[1]

- Names: `VIRTUAL-SKIN-SPEAKER-SUB-0`

```json
{
  "Coefficient": [
    0.047,
    0.046,
    0.076,
    0.492,
    0.018,
    0.291,
    0.007,
    0.022
  ],
  "Combination": [
    "rfpa_therm",
    "quiet_therm",
    "charging_therm",
    "usb_pwr_therm",
    "flash_therm",
    "disp0_therm",
    "north_therm",
    "soc_therm"
  ],
  "Formula": "WEIGHTED_AVG",
  "Hidden": true,
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-SPEAKER-SUB-0",
  "Offset": 126.0,
  "Type": "UNKNOWN",
  "VirtualSensor": true
}
```

### $.Sensors[2]

- Names: `VIRTUAL-SKIN-SPEAKER-SUB-1`

```json
{
  "Coefficient": [
    0.024,
    0.028,
    0.016,
    0.347,
    0.343,
    0.2,
    0.02,
    0.023
  ],
  "Combination": [
    "rfpa_therm",
    "quiet_therm",
    "charging_therm",
    "usb_pwr_therm",
    "flash_therm",
    "disp0_therm",
    "north_therm",
    "soc_therm"
  ],
  "Formula": "WEIGHTED_AVG",
  "Hidden": true,
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-SPEAKER-SUB-1",
  "Offset": 158.0,
  "Type": "UNKNOWN",
  "VirtualSensor": true
}
```

### $.Sensors[3]

- Names: `VIRTUAL-SKIN-SPEAKER`, `VIRTUAL-SKIN-SPEAKER-SUB-0`, `VIRTUAL-SKIN-SPEAKER-SUB-1`
- PollingDelay: `300000`
- PassiveDelay: `7000`

```json
{
  "Coefficient": [
    1.0,
    1.0
  ],
  "Combination": [
    "VIRTUAL-SKIN-SPEAKER-SUB-0",
    "VIRTUAL-SKIN-SPEAKER-SUB-1"
  ],
  "Formula": "MAXIMUM",
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
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-SPEAKER",
  "Offset": 1000.0,
  "PassiveDelay": 7000,
  "PollingDelay": 300000,
  "SendCallback": true,
  "TriggerSensor": [
    "north_therm",
    "flash_therm",
    "soc_therm",
    "rfpa_therm",
    "charging_therm",
    "disp0_therm"
  ],
  "Type": "UNKNOWN",
  "Version": "DVT",
  "VirtualSensor": true
}
```

### $.Sensors[6]

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
    54.0,
    "NAN"
  ],
  "Multiplier": 0.001,
  "Name": "cellular-emergency",
  "PassiveDelay": 7000,
  "PollingDelay": 300000,
  "SendCallback": true,
  "TriggerSensor": [
    "north_therm",
    "charging_therm",
    "disp0_therm"
  ],
  "Type": "POWER_AMPLIFIER",
  "VirtualSensor": true
}
```

## thermal_info_config_charge.json

- SHA-256: `2d5d10a5ab2eae1443ea6200569c316cbf0109c407a16672386c0e0095bf8532`
- VIRTUAL-SKIN entry count: `14`

### $

- Names: `VIRTUAL-SKIN-CHARGE`, `VIRTUAL-SKIN-CHARGE-PERSIST`, `VIRTUAL-SKIN-CHARGE-WIRED`, `VIRTUAL-SKIN-EQ`, `VIRTUAL-SKIN-LEGACY`, `VIRTUAL-SKIN-MODEL`, `VIRTUAL-SKIN-SUB-0`, `VIRTUAL-SKIN-SUB-1`, `VIRTUAL-SKIN-SUB-2`, `VIRTUAL-SKIN-SUB-3`, `VIRTUAL-SKIN-SUB-4`, `VIRTUAL-SKIN-SUB-5`, `VIRTUAL-SKIN-SUB-6`, `VIRTUAL-SKIN-SUB-7`

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
  "Include": [
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
        32.1,
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
        32.1,
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
        48.4,
        "NAN",
        "NAN",
        "NAN",
        "NAN",
        "NAN"
      ],
      "Multiplier": 0.001,
      "Name": "charging_therm",
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
      "Name": "disp0_therm",
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
        31.7,
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
      "Coefficient": [
        0.01,
        0.042,
        0.022,
        0.351,
        0.004,
        0.401,
        0.143,
        0.035
      ],
      "Combination": [
        "rfpa_therm",
        "quiet_therm",
        "charging_therm",
        "usb_pwr_therm",
        "flash_therm",
        "disp0_therm",
        "north_therm",
        "soc_therm"
      ],
      "Formula": "WEIGHTED_AVG",
      "Hidden": true,
      "Multiplier": 0.001,
      "Name": "VIRTUAL-SKIN-SUB-0",
      "Offset": 855.0,
      "Type": "UNKNOWN",
      "VirtualSensor": true
    },
    {
      "Coefficient": [
        0.04,
        0.281,
        0.058,
        0.046,
        0.3,
        0.253,
        0.021,
        0.002
      ],
      "Combination": [
        "rfpa_therm",
        "quiet_therm",
        "charging_therm",
        "usb_pwr_therm",
        "flash_therm",
        "disp0_therm",
        "north_therm",
        "soc_therm"
      ],
      "Formula": "WEIGHTED_AVG",
      "Hidden": true,
      "Multiplier": 0.001,
      "Name": "VIRTUAL-SKIN-SUB-1",
      "Offset": 28.0,
      "Type": "UNKNOWN",
      "VirtualSensor": true
    },
    {
      "Coefficient": [
        0.029,
        0.123,
        0.021,
        0.254,
        0.329,
        0.048,
        0.197,
        0.001
      ],
      "Combination": [
        "rfpa_therm",
        "quiet_therm",
        "charging_therm",
        "usb_pwr_therm",
        "flash_therm",
        "disp0_therm",
        "north_therm",
        "soc_therm"
      ],
      "Formula": "WEIGHTED_AVG",
      "Hidden": true,
      "Multiplier": 0.001,
      "Name": "VIRTUAL-SKIN-SUB-2",
      "Offset": 404.0,
      "Type": "UNKNOWN",
      "VirtualSensor": true
    },
    "...len=27"
  ]
}
```

### $.Sensors[9]

- Names: `VIRTUAL-SKIN-SUB-0`

```json
{
  "Coefficient": [
    0.01,
    0.042,
    0.022,
    0.351,
    0.004,
    0.401,
    0.143,
    0.035
  ],
  "Combination": [
    "rfpa_therm",
    "quiet_therm",
    "charging_therm",
    "usb_pwr_therm",
    "flash_therm",
    "disp0_therm",
    "north_therm",
    "soc_therm"
  ],
  "Formula": "WEIGHTED_AVG",
  "Hidden": true,
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-SUB-0",
  "Offset": 855.0,
  "Type": "UNKNOWN",
  "VirtualSensor": true
}
```

### $.Sensors[10]

- Names: `VIRTUAL-SKIN-SUB-1`

```json
{
  "Coefficient": [
    0.04,
    0.281,
    0.058,
    0.046,
    0.3,
    0.253,
    0.021,
    0.002
  ],
  "Combination": [
    "rfpa_therm",
    "quiet_therm",
    "charging_therm",
    "usb_pwr_therm",
    "flash_therm",
    "disp0_therm",
    "north_therm",
    "soc_therm"
  ],
  "Formula": "WEIGHTED_AVG",
  "Hidden": true,
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-SUB-1",
  "Offset": 28.0,
  "Type": "UNKNOWN",
  "VirtualSensor": true
}
```

### $.Sensors[11]

- Names: `VIRTUAL-SKIN-SUB-2`

```json
{
  "Coefficient": [
    0.029,
    0.123,
    0.021,
    0.254,
    0.329,
    0.048,
    0.197,
    0.001
  ],
  "Combination": [
    "rfpa_therm",
    "quiet_therm",
    "charging_therm",
    "usb_pwr_therm",
    "flash_therm",
    "disp0_therm",
    "north_therm",
    "soc_therm"
  ],
  "Formula": "WEIGHTED_AVG",
  "Hidden": true,
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-SUB-2",
  "Offset": 404.0,
  "Type": "UNKNOWN",
  "VirtualSensor": true
}
```

### $.Sensors[12]

- Names: `VIRTUAL-SKIN-SUB-3`

```json
{
  "Coefficient": [
    0.123,
    0.007,
    0.006,
    0.26,
    0.308,
    0.014,
    0.254,
    0.029
  ],
  "Combination": [
    "rfpa_therm",
    "quiet_therm",
    "charging_therm",
    "usb_pwr_therm",
    "flash_therm",
    "disp0_therm",
    "north_therm",
    "soc_therm"
  ],
  "Formula": "WEIGHTED_AVG",
  "Hidden": true,
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-SUB-3",
  "Offset": 313.0,
  "Type": "UNKNOWN",
  "VirtualSensor": true
}
```

### $.Sensors[13]

- Names: `VIRTUAL-SKIN-SUB-4`

```json
{
  "Coefficient": [
    0.069,
    0.011,
    0.162,
    0.181,
    0.354,
    0.145,
    0.045,
    0.032
  ],
  "Combination": [
    "rfpa_therm",
    "quiet_therm",
    "charging_therm",
    "usb_pwr_therm",
    "flash_therm",
    "disp0_therm",
    "north_therm",
    "soc_therm"
  ],
  "Formula": "WEIGHTED_AVG",
  "Hidden": true,
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-SUB-4",
  "Offset": 61.0,
  "Type": "UNKNOWN",
  "VirtualSensor": true
}
```

### $.Sensors[14]

- Names: `VIRTUAL-SKIN-SUB-5`

```json
{
  "Coefficient": [
    0.24,
    0.028,
    0.002,
    0.242,
    0.254,
    0.098,
    0.134,
    0.001
  ],
  "Combination": [
    "rfpa_therm",
    "quiet_therm",
    "charging_therm",
    "usb_pwr_therm",
    "flash_therm",
    "disp0_therm",
    "north_therm",
    "soc_therm"
  ],
  "Formula": "WEIGHTED_AVG",
  "Hidden": true,
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-SUB-5",
  "Offset": 21.0,
  "Type": "UNKNOWN",
  "VirtualSensor": true
}
```

### $.Sensors[15]

- Names: `VIRTUAL-SKIN-SUB-6`

```json
{
  "Coefficient": [
    0.1,
    0.083,
    0.004,
    0.624,
    0.061,
    0.011,
    0.087,
    0.029
  ],
  "Combination": [
    "rfpa_therm",
    "quiet_therm",
    "charging_therm",
    "usb_pwr_therm",
    "flash_therm",
    "disp0_therm",
    "north_therm",
    "soc_therm"
  ],
  "Formula": "WEIGHTED_AVG",
  "Hidden": true,
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-SUB-6",
  "Offset": 552.0,
  "Type": "UNKNOWN",
  "VirtualSensor": true
}
```

### $.Sensors[16]

- Names: `VIRTUAL-SKIN-SUB-7`

```json
{
  "Coefficient": [
    0.008,
    0.026,
    0.013,
    0.121,
    0.317,
    0.192,
    0.321,
    0.002
  ],
  "Combination": [
    "rfpa_therm",
    "quiet_therm",
    "charging_therm",
    "usb_pwr_therm",
    "flash_therm",
    "disp0_therm",
    "north_therm",
    "soc_therm"
  ],
  "Formula": "WEIGHTED_AVG",
  "Hidden": true,
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-SUB-7",
  "Offset": 295.0,
  "Type": "UNKNOWN",
  "VirtualSensor": true
}
```

### $.Sensors[17]

- Names: `VIRTUAL-SKIN-LEGACY`, `VIRTUAL-SKIN-SUB-0`, `VIRTUAL-SKIN-SUB-1`, `VIRTUAL-SKIN-SUB-2`, `VIRTUAL-SKIN-SUB-3`, `VIRTUAL-SKIN-SUB-4`, `VIRTUAL-SKIN-SUB-5`, `VIRTUAL-SKIN-SUB-6`, `VIRTUAL-SKIN-SUB-7`

```json
{
  "Coefficient": [
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
    "VIRTUAL-SKIN-SUB-0",
    "VIRTUAL-SKIN-SUB-1",
    "VIRTUAL-SKIN-SUB-2",
    "VIRTUAL-SKIN-SUB-3",
    "VIRTUAL-SKIN-SUB-4",
    "VIRTUAL-SKIN-SUB-5",
    "VIRTUAL-SKIN-SUB-6",
    "VIRTUAL-SKIN-SUB-7"
  ],
  "Formula": "MAXIMUM",
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-LEGACY",
  "Type": "UNKNOWN",
  "Version": "DVT",
  "VirtualSensor": true
}
```

### $.Sensors[18]

- Names: `VIRTUAL-SKIN-LEGACY`, `VIRTUAL-SKIN-MODEL`

```json
{
  "BackupSensor": "VIRTUAL-SKIN-LEGACY",
  "Combination": [
    "charging_therm",
    "disp0_therm",
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
    48000,
    49000,
    50000
  ],
  "OffsetValues": [
    450,
    900,
    1350
  ],
  "PreviousSampleCount": 3,
  "TimeResolution": 7000,
  "Type": "UNKNOWN",
  "Version": "DVT",
  "VirtualSensor": true
}
```

### $.Sensors[19]

- Names: `VIRTUAL-SKIN-CHARGE`, `VIRTUAL-SKIN-EQ`

```json
{
  "Coefficient": [
    1.0
  ],
  "Combination": [
    "VIRTUAL-SKIN-EQ"
  ],
  "Formula": "MAXIMUM",
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-CHARGE",
  "Offset": 500.0,
  "TriggerSensor": [
    "north_therm",
    "charging_therm",
    "disp0_therm",
    "quiet_therm"
  ],
  "Type": "UNKNOWN",
  "Version": "DVT",
  "VirtualSensor": true
}
```

### $.Sensors[23]

- Names: `VIRTUAL-SKIN-CHARGE`, `VIRTUAL-SKIN-CHARGE-WIRED`
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
    "VIRTUAL-SKIN-CHARGE"
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
  "Formula": "WEIGHTED_AVG",
  "HotHysteresis": [
    0.0,
    0.0,
    3.9,
    2.9,
    3.9,
    1.9,
    1.9
  ],
  "HotThreshold": [
    "NAN",
    34.0,
    38.0,
    41.0,
    45.0,
    47.0,
    55.0
  ],
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-CHARGE-WIRED",
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
      1268,
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
      181,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "K_Pu": [
      "NAN",
      "NAN",
      304,
      "NAN",
      "NAN",
      "NAN",
      "NAN"
    ],
    "MaxAllocPower": [
      "NAN",
      "NAN",
      3710,
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
      2493,
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
    "north_therm",
    "charging_therm",
    "disp0_therm",
    "quiet_therm"
  ],
  "Type": "UNKNOWN",
  "VirtualSensor": true
}
```

### $.Sensors[24]

- Names: `VIRTUAL-SKIN-CHARGE`, `VIRTUAL-SKIN-CHARGE-PERSIST`
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
    1.0
  ],
  "Combination": [
    "VIRTUAL-SKIN-CHARGE"
  ],
  "Formula": "WEIGHTED_AVG",
  "HotHysteresis": [
    0.0,
    0.0,
    1.9,
    3.9,
    1.9,
    1.9,
    1.9
  ],
  "HotThreshold": [
    "NaN",
    37.0,
    41.0,
    45.0,
    47.0,
    51.0,
    55.0
  ],
  "Multiplier": 0.001,
  "Name": "VIRTUAL-SKIN-CHARGE-PERSIST",
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
      2115,
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
      93,
      "NaN",
      "NaN",
      "NaN",
      "NaN"
    ],
    "K_Pu": [
      "NaN",
      "NaN",
      500,
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
      1595,
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
    "north_therm",
    "charging_therm",
    "disp0_therm",
    "quiet_therm"
  ],
  "Type": "UNKNOWN",
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
