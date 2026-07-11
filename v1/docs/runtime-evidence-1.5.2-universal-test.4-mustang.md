# Runtime evidence: 1.5.2-universal-test.4 on mustang

Status: PASS.

## Release identity

- Version: `1.5.2-universal-test.4`
- Version code: `1016204`
- Tag: `v1.5.2-universal-test.4`
- Main: `1e49979`
- Full SHA: `1e49979ecd4a32dafd582f8ab2f5a6462c987a54`
- ZIP SHA256: `4bb82104d5276a73a1d6bb08ebb97ad83e597dc03387087bede360eb1641e453`
- ZIP size: `1113170` bytes

## Device

- Device: `mustang`
- Model: `Pixel 10 Pro XL`
- Build ID: `CP2A.260605.012`
- Incremental: `15430684`
- Android: `17`
- SDK: `37`

## Runtime result

```text
RESULT: PIXEL_THERMAL_152_TEST4_RUNTIME_PASS device=mustang build=CP2A.260605.012 version=1.5.2-universal-test.4 profile=mustang-android17-cp2a-cp2a260605012-outdoor-extended polling=mod thermal=outdoor-ext zram=100p bootguard=pass fail_count=0 matrix_count=83 reboot=safe
```

## Runtime proof summary

- Active module version: `1.5.2-universal-test.4`
- Active module versionCode: `1016204`
- Manager description: `P:🟢 mod | T:🟢 outdoor-ext | Z:🟢 100p | Action: settings/debug`
- Active blocker markers: `disable`, `remove`, `skip_mount` absent
- Bootguard v2: `boot_success last_good_updated fail_count=0`
- Bootguard fail count: `0`
- Profile: `mustang-android17-cp2a-cp2a260605012-outdoor-extended`
- Thermal polling: `mod`
- Thermal profile: `outdoor-extended`
- ZRAM: `100p`, `/dev/block/zram0` active
- ZRAM disksize: `16323969024`
- Runtime evidence scope: PASS
- Profile matrix: `PROFILE_MATRIX_VERIFY_PASS count=83`
- UI guard: `UI_TEXT_GUARD_PASS max=44`
- Update channel guard: PASS
- Release reboot checklist: PASS

## Interpretation

`1.5.2-universal-test.4` is published, installed and reboot/runtime-verified on `mustang / CP2A.260605.012`.

Allen's prior bootloop report is not reproduced on this mustang runtime with Test4. This does not prove all devices are runtime-safe; frankel, blazer and rango still require independent runtime feedback.
