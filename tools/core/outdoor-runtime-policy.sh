#!/system/bin/sh
# Runtime-evidence admission for non-stock Thermal profiles.
# Stock is always admitted. Unknown device/build tuples fail closed at delta 0.

# Android shell portability shim for the two legacy TSV header writes in
# patch-thermal.sh. The contents API representation used literal backslash-t
# sequences; only those exact headers are converted to real tab characters.
# All other printf calls are delegated byte-for-byte to the shell builtin.
case "${0##*/}" in
  patch-thermal.sh)
    printf() {
      if [ "$#" -eq 2 ] && [ "$1" = '%s\n' ]; then
        case "$2" in
          'file\tsha256\tbytes\tpolling_300000'|'file\tsource_sha256\toutput_sha256\tsource_polling_300000\treplacements\toutput_polling_300000\toutput_polling_5000\tallowed_diff')
            command printf '%b\n' "$2"
            return 0
          ;;
        esac
      fi
      command printf "$@"
    }
  ;;
esac

thermal_outdoor_profile_delta() {
  case "${1:-stock}" in
    stock) printf '%s\n' 0 ;;
    outdoor-safe) printf '%s\n' 1 ;;
    outdoor-plus) printf '%s\n' 2 ;;
    outdoor-extended) printf '%s\n' 3 ;;
    *) return 1 ;;
  esac
}

thermal_outdoor_profile_for_delta() {
  case "${1:-0}" in
    0) printf '%s\n' stock ;;
    1) printf '%s\n' outdoor-safe ;;
    2) printf '%s\n' outdoor-plus ;;
    3) printf '%s\n' outdoor-extended ;;
    *) return 1 ;;
  esac
}

thermal_outdoor_max_delta() {
  _device="${1:-unknown}"
  _android="${2:-unknown}"
  _build="${3:-unknown}"
  case "$_device:$_android:$_build" in
    mustang:17:CP2A.260705.006) printf '%s\n' 3 ;;
    mustang:17:ZP11.260618.005) printf '%s\n' 1 ;;
    *) printf '%s\n' 0 ;;
  esac
}

thermal_outdoor_policy_evidence() {
  _device="${1:-unknown}"
  _android="${2:-unknown}"
  _build="${3:-unknown}"
  case "$_device:$_android:$_build" in
    mustang:17:CP2A.260705.006) printf '%s\n' local_postboot_extended_pass_2026-07-26 ;;
    mustang:17:ZP11.260618.005) printf '%s\n' allen_clean_flash_safe_boots_plus_hangs_2026-07-26 ;;
    *) printf '%s\n' stock_only_no_nonstock_runtime_evidence ;;
  esac
}

thermal_outdoor_profile_admitted() {
  _profile="${1:-stock}"
  _device="${2:-unknown}"
  _android="${3:-unknown}"
  _build="${4:-unknown}"
  _requested="$(thermal_outdoor_profile_delta "$_profile")" || return 1
  _maximum="$(thermal_outdoor_max_delta "$_device" "$_android" "$_build")" || return 1
  [ "$_requested" -le "$_maximum" ]
}
