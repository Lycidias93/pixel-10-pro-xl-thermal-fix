#!/system/bin/sh
# Runtime admission for non-stock Thermal profiles.
# Stock is always admitted. Supported Pixel 10 / Android platform tuples may
# request up to +3 C, but the local stock-derived materializer and validator
# remain the final fail-closed authority. Exact build IDs are evidence only.

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

thermal_outdoor_platform_supported() {
  _device="${1:-unknown}"
  _android="${2:-unknown}"
  case "$_device:$_android" in
    mustang:17|blazer:17|frankel:17|rango:17) return 0 ;;
    *) return 1 ;;
  esac
}

thermal_outdoor_max_delta() {
  _device="${1:-unknown}"
  _android="${2:-unknown}"
  _build="${3:-unknown}"
  if thermal_outdoor_platform_supported "$_device" "$_android"; then
    printf '%s\n' 3
  else
    printf '%s\n' 0
  fi
}

thermal_outdoor_policy_evidence() {
  _device="${1:-unknown}"
  _android="${2:-unknown}"
  _build="${3:-unknown}"
  case "$_device:$_android:$_build" in
    mustang:17:CP2A.260705.006) printf '%s\n' dev6_postboot_extended_12zones_84values_pass_2026-07-27 ;;
    mustang:17:ZP11.260618.005) printf '%s\n' allen_fix5_clean_flash_all_profiles_boot_2026-07-26 ;;
    blazer:17:CP2A.260705.006) printf '%s\n' harish_fix5_extended_13zones_91values_pass_2026-07-26 ;;
    *)
      if thermal_outdoor_platform_supported "$_device" "$_android"; then
        printf '%s\n' supported_platform_local_stock_validation_required
      else
        printf '%s\n' unsupported_platform_stock_only
      fi
    ;;
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
