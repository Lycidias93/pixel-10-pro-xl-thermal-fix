# Dynamic Thermal Patching System (v2) - Implementation Plan & Task List

This document outlines the design, proposed modifications, and step-by-step task list for transitioning the module to a dynamic patching system. All development and staging for v2 will occur inside the `v2/` directory.

---

## 1. Objectives

1. **On-Device Dynamic Patching**: Eliminate the `profiles/` directory and instead copy the device's own stock `/vendor/etc/thermal_info_config*.json` files during installation (and OTA upgrades), dynamically modifying them.
2. **Simplified Version Control**: Use a centralized `supported_versions.json` file for compatibility checks during install and boot.
3. **Robust Scripting**: Use POSIX-compliant `awk`/`sed` to perform the search and replace operations safely on the device.
4. **ZRAM Retention**: Keep the ZRAM 100% overlay and configuration flow but clean up any profile dependencies.

---

## 2. Dynamic Patching Logic

The target edits to stock device thermal configs are:
* **Polling Delay**:
  - Locate `PollingDelay` keys across all three JSON configurations (`thermal_info_config.json`, `thermal_info_config_charge.json`, `thermal_info_config_throttling.json`) and change value `300000` to `5000`.
* **Outdoor Temperature Offsets**:
  - For `outdoor-safe` (+1°C), `outdoor-plus` (+2°C), and `outdoor-extended` (+3°C) profiles:
  - Locate `VIRTUAL-SKIN` and `VIRTUAL-SKIN-HINT` sensors in `thermal_info_config_throttling.json`.
  - Shift all numeric entries in their `HotThreshold` array by the selected offset.

---

## 3. Detailed Task List

Use the following checklist to track progress during development of v2.

### Phase 1: Configuration & Patching Core
- [ ] **Task 1.1**: Create `v2/supported_versions.json` mapping devices (`mustang`, `blazer`, `frankel`, `rango`), Android versions (`16`, `17`), and verified builds.
- [ ] **Task 1.2**: Write `v2/tools/patch-thermal.sh` (or helper function) to patch JSON files using `awk`.
- [ ] **Task 1.3**: Validate `patch-thermal.sh` locally on stock original JSONs to ensure it produces syntactically correct JSON matching baseline targets (delta 0, +1, +2, +3).

### Phase 2: Installer Porting
- [ ] **Task 2.1**: Create `v2/customize.sh` using the new dynamic validation flow and central `supported_versions.json`.
- [ ] **Task 2.2**: Port `tools/install-options-menu.sh` and `tools/thermal-outdoor-menu.sh` into `v2/tools/`, removing static directory checks and mapping everything to the dynamic compiler.
- [ ] **Task 2.3**: Adapt `tools/install-thermal-overlay.sh` to extract stock configurations, run `patch-thermal.sh`, and place them in the overlay structure.
- [ ] **Task 2.4**: Copy ZRAM setup helper `tools/install-zram.sh` and templates to `v2/tools/`, stripping out legacy directory structure links.

### Phase 3: Runtime & Boot Logic Porting
- [ ] **Task 3.1**: Port `post-fs-data.sh` and `service.sh` to `v2/`.
- [ ] **Task 3.2**: Port `tools/auto-profile-switch.sh` to `v2/tools/` and update it to dynamically run `patch-thermal.sh` on OTA build changes.
- [ ] **Task 3.3**: Copy debug/health collectors (`collect-debug.sh`, `status-lib.sh`, etc.) to `v2/tools/` and update references to v2 structures.

### Phase 4: Verification & Final Switch
- [ ] **Task 4.1**: Create a flashable zip structure test from `v2/` and verify menu cycle operation in recovery or the Magisk app.
- [ ] **Task 4.2**: Verify runtime configuration generation on device (validate that `/vendor/etc/` overrides are correct after boot).
- [ ] **Task 4.3**: Remove legacy files (`profiles/`, `originals/`, old matrix scripts) and promote `v2/` files to the root level.
