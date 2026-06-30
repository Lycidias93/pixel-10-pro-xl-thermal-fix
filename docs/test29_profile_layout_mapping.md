# Test29 Profile Layout Mapping Audit

Test29 integrates the Harish / Codecity001 profile layout concept as a safe read-only mapping slice.

Credit: Harish / Codecity001 provided the profile layout refactor concept and mockup reference. This implementation is reworked against current Test28 main and does not cherry-pick the older mockup commit directly.

## Scope

- Add a read-only mapping helper for the proposed profile tree.
- Preserve Test28 Use last settings behavior.
- Preserve Test27 install thermal overlay helper boundaries.
- Do not move profile directories in this slice.
- Do not switch runtime resolver behavior in this slice.

## Proposed layout

`profiles/device/family/variant/system/vendor/etc`

Examples:

- `profiles/mustang/cp2a/base/system/vendor/etc`
- `profiles/mustang/cp2a/outdoor-safe/system/vendor/etc`
- `profiles/mustang/cp2a/outdoor-plus/system/vendor/etc`
- `profiles/mustang/cp2a/outdoor-extended/system/vendor/etc`

## Legacy variant guard

The old `outdoor-g4-adapted` and `outdoor-g4-adapted-plus` profiles must not be silently collapsed into `base`.
They are mapped as preserved legacy variants until a later runtime resolver migration explicitly decides their fate.

## TensorConservative research decision

Do not add TensorConservative sysfs/procfs writes in Test29.

Blocked ideas:

- 4 GiB ZRAM reset
- thermal safety disable
- cpuset load balance disable
- conservative governor switch

Research-only candidates:

- vm.swappiness
- vfs_cache_pressure
- watermark_scale_factor
- gro_option
- pcie_aspm

## Status

This is an audit and mapping helper only. It performs no writes to `/sys`, `/proc`, Magisk module runtime state, routes, DNS, or thermal runtime paths.
