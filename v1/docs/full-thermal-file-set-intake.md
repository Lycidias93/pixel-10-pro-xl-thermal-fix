# Full thermal file set intake

Status: vNext planning and guard layer.

Source trigger:

Harish reported that the July Android 17 stable thermal set contains additional thermal_info_config JSON files beyond the three core files currently used by the module.

Important correction from uploaded ZIP inspection:

- PollingDelay values are 300000 in the supplied files, not 30000.
- vt and wingboard files have no PollingDelay and must stay stock unless separately proven.

Full thermal set:

- thermal_info_config.json
- thermal_info_config_charge.json
- thermal_info_config_throttling.json
- thermal_info_config_aa_throttling.json
- thermal_info_config_bg_tasks_throttling.json
- thermal_info_config_earlywarnings.json
- thermal_info_config_lpm.json
- thermal_info_config_stats.json
- thermal_info_config_vt.json
- thermal_info_config_wingboard.json

Patch policy:

Patch PollingDelay only in files that actually contain PollingDelay.

Patch candidates:

- thermal_info_config.json
- thermal_info_config_aa_throttling.json
- thermal_info_config_bg_tasks_throttling.json
- thermal_info_config_charge.json
- thermal_info_config_earlywarnings.json
- thermal_info_config_lpm.json
- thermal_info_config_stats.json
- thermal_info_config_throttling.json

Stock-only unless separately proven:

- thermal_info_config_vt.json
- thermal_info_config_wingboard.json

SSD2 working root:

Marker: FACTORY_IMAGE_SSD2_CANONICAL_20260710

Use /ssd2/pixel-thermal-factory as the only active source for full thermal set intake, manifests, reports and factory extracts.

Guardrails:

- Do not import Harish ZIP files as stock-exact.
- Official factory or OTA extraction is required for stock-exact classification.
- Keep stable update.json unchanged.
- Do not claim runtime support before install plus reboot evidence.
