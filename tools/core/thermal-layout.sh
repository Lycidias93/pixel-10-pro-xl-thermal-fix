#!/system/bin/sh
# Dynamic controlled-file layout detector for Pixel Thermal vNext.
# Exactly three controlled files are admitted: base + charge + one runtime-family file.

thermal_layout_file_allowed() {
  case "${1:-}" in
    thermal_info_config.json|thermal_info_config_charge.json|thermal_info_config_throttling.json|thermal_info_config_lpm.json) return 0 ;;
    *) return 1 ;;
  esac
}

thermal_layout_polling_count() {
  _tl_file="$1"
  [ -r "$_tl_file" ] || { printf '%s\n' 0; return 0; }
  grep -Eo '"PollingDelay"[[:space:]]*:[[:space:]]*[0-9]+' "$_tl_file" 2>/dev/null | wc -l | tr -d ' '
}

thermal_layout_set() {
  _tl_third="$1"
  case "$_tl_third" in
    thermal_info_config_throttling.json) THERMAL_LAYOUT_FAMILY=base_charge_throttling ;;
    thermal_info_config_lpm.json) THERMAL_LAYOUT_FAMILY=base_charge_lpm ;;
    *) return 1 ;;
  esac
  THERMAL_LAYOUT_THIRD="$_tl_third"
  THERMAL_LAYOUT_COUNT=3
  THERMAL_LAYOUT_FILES="thermal_info_config.json thermal_info_config_charge.json $_tl_third"
  THERMAL_LAYOUT_FILES_CSV="thermal_info_config.json,thermal_info_config_charge.json,$_tl_third"
  return 0
}

thermal_layout_device_family() {
  case "${1:-unknown}" in
    mustang|blazer|frankel|rango) printf '%s\n' pixel10_g5 ;;
    tokay|caiman|komodo|comet|tegu|stallion) printf '%s\n' tensor_g4_vnext ;;
    *) printf '%s\n' unknown ;;
  esac
}

thermal_layout_detect() {
  _tl_dir="$1"
  _tl_device="${2:-${THERMAL_DEVICE:-$(getprop ro.product.device 2>/dev/null || true)}}"
  [ -n "$_tl_device" ] || _tl_device=unknown
  _tl_family="$(thermal_layout_device_family "$_tl_device")"
  THERMAL_LAYOUT_FAMILY=unsupported
  THERMAL_LAYOUT_THIRD=none
  THERMAL_LAYOUT_COUNT=0
  THERMAL_LAYOUT_FILES=
  THERMAL_LAYOUT_FILES_CSV=none

  [ -s "$_tl_dir/thermal_info_config.json" ] || return 1
  [ -s "$_tl_dir/thermal_info_config_charge.json" ] || return 1

  _tl_t=no
  _tl_l=no
  [ -s "$_tl_dir/thermal_info_config_throttling.json" ] && _tl_t=yes
  [ -s "$_tl_dir/thermal_info_config_lpm.json" ] && _tl_l=yes

  case "$_tl_family" in
    pixel10_g5)
      [ "$_tl_t" = yes ] || return 1
      thermal_layout_set thermal_info_config_throttling.json
      return
    ;;
    tensor_g4_vnext)
      if [ "$_tl_l" = yes ]; then
        _tl_lc="$(thermal_layout_polling_count "$_tl_dir/thermal_info_config_lpm.json")"
        if [ "$_tl_lc" -gt 0 ] 2>/dev/null || [ "$_tl_t" = no ]; then
          thermal_layout_set thermal_info_config_lpm.json
          return
        fi
      fi
      if [ "$_tl_t" = yes ]; then
        thermal_layout_set thermal_info_config_throttling.json
        return
      fi
      return 1
    ;;
  esac

  case "$_tl_t:$_tl_l" in
    yes:no) thermal_layout_set thermal_info_config_throttling.json ;;
    no:yes) thermal_layout_set thermal_info_config_lpm.json ;;
    yes:yes)
      _tl_tc="$(thermal_layout_polling_count "$_tl_dir/thermal_info_config_throttling.json")"
      _tl_lc="$(thermal_layout_polling_count "$_tl_dir/thermal_info_config_lpm.json")"
      case "$_tl_tc:$_tl_lc" in
        0:0) return 2 ;;
        0:*) thermal_layout_set thermal_info_config_lpm.json ;;
        *:0) thermal_layout_set thermal_info_config_throttling.json ;;
        *) return 2 ;;
      esac
    ;;
    *) return 1 ;;
  esac
}

thermal_layout_from_manifest() {
  _tl_manifest="$1"
  [ -s "$_tl_manifest" ] || return 1
  _tl_rows=0
  _tl_base=0
  _tl_charge=0
  _tl_throttling=0
  _tl_lpm=0
  _tl_tab="$(printf '\t')"
  while IFS="$_tl_tab" read -r _tl_name _tl_rest; do
    [ "$_tl_name" = file ] && continue
    [ -n "$_tl_name" ] || continue
    thermal_layout_file_allowed "$_tl_name" || return 1
    _tl_rows=$((_tl_rows + 1))
    case "$_tl_name" in
      thermal_info_config.json) _tl_base=$((_tl_base + 1)) ;;
      thermal_info_config_charge.json) _tl_charge=$((_tl_charge + 1)) ;;
      thermal_info_config_throttling.json) _tl_throttling=$((_tl_throttling + 1)) ;;
      thermal_info_config_lpm.json) _tl_lpm=$((_tl_lpm + 1)) ;;
    esac
  done < "$_tl_manifest"
  [ "$_tl_rows" -eq 3 ] 2>/dev/null || return 1
  [ "$_tl_base" -eq 1 ] 2>/dev/null || return 1
  [ "$_tl_charge" -eq 1 ] 2>/dev/null || return 1
  if [ "$_tl_throttling" -eq 1 ] 2>/dev/null && [ "$_tl_lpm" -eq 0 ] 2>/dev/null; then
    thermal_layout_set thermal_info_config_throttling.json
  elif [ "$_tl_throttling" -eq 0 ] 2>/dev/null && [ "$_tl_lpm" -eq 1 ] 2>/dev/null; then
    thermal_layout_set thermal_info_config_lpm.json
  else
    return 1
  fi
}

thermal_layout_write_env() {
  _tl_out="$1"
  _tl_device="${2:-unknown}"
  _tl_build="${3:-unknown}"
  [ "${THERMAL_LAYOUT_COUNT:-0}" -eq 3 ] 2>/dev/null || return 1
  _tl_tmp="${_tl_out}.tmp.$$"
  mkdir -p "${_tl_out%/*}" 2>/dev/null || return 1
  {
    printf '%s\n' 'schema=pixel-thermal-layout-v1'
    printf '%s\n' "family=$THERMAL_LAYOUT_FAMILY"
    printf '%s\n' "count=$THERMAL_LAYOUT_COUNT"
    printf '%s\n' "third=$THERMAL_LAYOUT_THIRD"
    printf '%s\n' "files_csv=$THERMAL_LAYOUT_FILES_CSV"
    printf '%s\n' "device=$_tl_device"
    printf '%s\n' "build_id=$_tl_build"
  } > "$_tl_tmp" || return 1
  chmod 0600 "$_tl_tmp" 2>/dev/null || true
  mv "$_tl_tmp" "$_tl_out"
}

thermal_layout_load_env() {
  _tl_env="$1"
  [ -r "$_tl_env" ] || return 1
  _tl_family="$(sed -n 's/^family=//p' "$_tl_env" | tail -n 1)"
  _tl_third="$(sed -n 's/^third=//p' "$_tl_env" | tail -n 1)"
  case "$_tl_family:$_tl_third" in
    base_charge_throttling:thermal_info_config_throttling.json|base_charge_lpm:thermal_info_config_lpm.json)
      thermal_layout_set "$_tl_third"
    ;;
    *) return 1 ;;
  esac
}
