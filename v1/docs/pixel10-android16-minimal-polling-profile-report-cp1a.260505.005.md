# Pixel 10 Android 16 minimal polling profile report (`CP1A.260505.005`)

Status: source profile import only. No release ZIP, no update.json change.

Policy:
- Use factory thermal JSON as source basis.
- Set only listed VIRTUAL-SKIN `PollingDelay` / `PollingDelayMs` fields to `5000`.
- Do not port existing non-polling Blazer deltas.
- Keep Mustang stable profile unchanged.

## Devices

| Device | Codename | VIRTUAL-SKIN total | Changed counts | Skipped counts |
|---|---|---:|---|---|
| Pixel 10 | `frankel` | 44 | thermal_info_config.json:1, thermal_info_config_charge.json:2, thermal_info_config_throttling.json:8 | thermal_info_config.json:1, thermal_info_config_charge.json:0, thermal_info_config_throttling.json:0 |
| Pixel 10 Pro | `blazer` | 43 | thermal_info_config.json:1, thermal_info_config_charge.json:2, thermal_info_config_throttling.json:8 | thermal_info_config.json:1, thermal_info_config_charge.json:0, thermal_info_config_throttling.json:0 |
| Pixel 10 Pro Fold | `rango` | 60 | thermal_info_config.json:0, thermal_info_config_charge.json:2, thermal_info_config_throttling.json:8 | thermal_info_config.json:11, thermal_info_config_charge.json:0, thermal_info_config_throttling.json:0 |

## Release guard

- New/updated `frankel`, `blazer`, and `rango` profiles remain beta/pending.
- Stable update channel remains unchanged.
- A later release build must verify ZIP structure and keep `update.json` unchanged until assets exist.
