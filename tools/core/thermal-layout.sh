#!/system/bin/sh
# Dynamic controlled-file layout detector for Pixel Thermal vNext.
# Legacy Pixel layouts use three files. Tensor G6 devices resolve a bounded,
# validated Include graph rooted at thermal_info_config.json.

THERMAL_LAYOUT_MAX_GRAPH_FILES=24

thermal_layout_file_allowed() {
  _name="${1:-}"
  case "$_name" in
    thermal_info_config*.json) ;;
    *) return 1 ;;
  esac
  case "$_name" in */*|*..*) return 1 ;; esac
  return 0
}

thermal_layout_polling_count() {
  _tl_file="$1"
  [ -r "$_tl_file" ] || { printf '%s\n' 0; return 0; }
  grep -Eo '"PollingDelay"[[:space:]]*:[[:space:]]*[0-9]+' "$_tl_file" 2>/dev/null | wc -l | tr -d ' '
}

thermal_layout_device_family() {
  case "${1:-unknown}" in
    mustang|blazer|frankel|rango) printf '%s\n' pixel10_g5 ;;
    tokay|caiman|komodo|comet|tegu|stallion) printf '%s\n' tensor_g4_vnext ;;
    cubs|grizzly|kodiak|yogi) printf '%s\n' tensor_g6_graph ;;
    *) printf '%s\n' unknown ;;
  esac
}

thermal_layout_is_g6_device() {
  case "${1:-unknown}" in cubs|grizzly|kodiak|yogi) return 0 ;; *) return 1 ;; esac
}

thermal_layout_polling_mode_admitted() {
  _device="${1:-unknown}"
  _mode="${2:-stock}"
  case "$_mode" in stock|mod) ;; *) return 1 ;; esac
  if thermal_layout_is_g6_device "$_device"; then
    [ "$_mode" = stock ]
  else
    return 0
  fi
}

thermal_layout_outdoor_policy() {
  if thermal_layout_is_g6_device "${1:-unknown}"; then
    printf '%s\n' g6_exact_virtual_skin
  else
    printf '%s\n' legacy_virtual_skin_family
  fi
}

thermal_layout_set_legacy() {
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

thermal_layout_normalize_include() {
  _raw="${1:-}"
  case "$_raw" in
    thermal_info_config*.json) _name="$_raw" ;;
    /vendor/etc/thermal_info_config*.json|vendor/etc/thermal_info_config*.json|/system/vendor/etc/thermal_info_config*.json|system/vendor/etc/thermal_info_config*.json)
      _name="${_raw##*/}"
    ;;
    *) return 1 ;;
  esac
  thermal_layout_file_allowed "$_name" || return 1
  printf '%s\n' "$_name"
}

thermal_layout_extract_includes() {
  _file="$1"
  awk '
    function emit_strings(text, token) {
      while (match(text, /"[^"]+"/)) {
        token = substr(text, RSTART + 1, RLENGTH - 2)
        print token
        text = substr(text, RSTART + RLENGTH)
      }
    }
    {
      line = $0
      if (!in_include && line ~ /"Include"[[:space:]]*:/) {
        sub(/^.*"Include"[[:space:]]*:[[:space:]]*/, "", line)
        if (line ~ /\[/) {
          sub(/^[^[]*\[/, "", line)
          if (line ~ /\]/) {
            sub(/\].*$/, "", line)
            emit_strings(line)
          } else {
            emit_strings(line)
            in_include = 1
          }
        } else {
          emit_strings(line)
        }
        next
      }
      if (in_include) {
        if (line ~ /\]/) {
          sub(/\].*$/, "", line)
          emit_strings(line)
          in_include = 0
        } else {
          emit_strings(line)
        }
      }
    }
  ' "$_file"
}

thermal_layout_detect_graph() {
  _dir="$1"
  THERMAL_LAYOUT_GRAPH_COUNT=0
  _pending="thermal_info_config.json|"
  _resolved=

  while [ -n "$_pending" ]; do
    _item="${_pending%% *}"
    if [ "$_item" = "$_pending" ]; then _pending=; else _pending="${_pending#* }"; fi
    _name="${_item%%|*}"
    _stack="${_item#*|}"

    thermal_layout_file_allowed "$_name" || return 1
    case ",$_stack," in *",$_name,"*) return 3 ;; esac
    case " $_resolved " in *" $_name "*) continue ;; esac
    [ -s "$_dir/$_name" ] || return 2

    _resolved="${_resolved:+$_resolved }$_name"
    THERMAL_LAYOUT_GRAPH_COUNT=$((THERMAL_LAYOUT_GRAPH_COUNT + 1))
    [ "$THERMAL_LAYOUT_GRAPH_COUNT" -le "$THERMAL_LAYOUT_MAX_GRAPH_FILES" ] 2>/dev/null || return 4

    _children=
    _includes="$(thermal_layout_extract_includes "$_dir/$_name")" || return 5
    if [ -n "$_includes" ]; then
      while IFS= read -r _raw; do
        [ -n "$_raw" ] || continue
        _child="$(thermal_layout_normalize_include "$_raw")" || return 6
        case ",${_stack:+$_stack,}$_name," in *",$_child,"*) return 3 ;; esac
        _children="${_children:+$_children }$_child|${_stack:+$_stack,}$_name"
      done <<EOF_INCLUDES
$_includes
EOF_INCLUDES
    fi
    [ -z "$_children" ] || _pending="${_pending:+$_pending }$_children"
  done

  [ "$THERMAL_LAYOUT_GRAPH_COUNT" -ge 3 ] 2>/dev/null || return 7
  THERMAL_LAYOUT_FAMILY=include_graph_g6
  THERMAL_LAYOUT_THIRD=none
  THERMAL_LAYOUT_COUNT="$THERMAL_LAYOUT_GRAPH_COUNT"
  THERMAL_LAYOUT_FILES="$_resolved"
  THERMAL_LAYOUT_FILES_CSV="$(printf '%s' "$_resolved" | tr ' ' ',')"
  return 0
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

  case "$_tl_family" in
    tensor_g6_graph)
      thermal_layout_detect_graph "$_tl_dir"
      return
    ;;
  esac

  [ -s "$_tl_dir/thermal_info_config_charge.json" ] || return 1
  _tl_t=no
  _tl_l=no
  [ -s "$_tl_dir/thermal_info_config_throttling.json" ] && _tl_t=yes
  [ -s "$_tl_dir/thermal_info_config_lpm.json" ] && _tl_l=yes

  case "$_tl_family" in
    pixel10_g5)
      [ "$_tl_t" = yes ] || return 1
      thermal_layout_set_legacy thermal_info_config_throttling.json
      return
    ;;
    tensor_g4_vnext)
      if [ "$_tl_l" = yes ]; then
        _tl_lc="$(thermal_layout_polling_count "$_tl_dir/thermal_info_config_lpm.json")"
        if [ "$_tl_lc" -gt 0 ] 2>/dev/null || [ "$_tl_t" = no ]; then
          thermal_layout_set_legacy thermal_info_config_lpm.json
          return
        fi
      fi
      if [ "$_tl_t" = yes ]; then
        thermal_layout_set_legacy thermal_info_config_throttling.json
        return
      fi
      return 1
    ;;
  esac

  case "$_tl_t:$_tl_l" in
    yes:no) thermal_layout_set_legacy thermal_info_config_throttling.json ;;
    no:yes) thermal_layout_set_legacy thermal_info_config_lpm.json ;;
    yes:yes)
      _tl_tc="$(thermal_layout_polling_count "$_tl_dir/thermal_info_config_throttling.json")"
      _tl_lc="$(thermal_layout_polling_count "$_tl_dir/thermal_info_config_lpm.json")"
      case "$_tl_tc:$_tl_lc" in
        0:0) return 2 ;;
        0:*) thermal_layout_set_legacy thermal_info_config_lpm.json ;;
        *:0) thermal_layout_set_legacy thermal_info_config_throttling.json ;;
        *) return 2 ;;
      esac
    ;;
    *) return 1 ;;
  esac
}

thermal_layout_manifest_matches() {
  _manifest="$1"
  [ -s "$_manifest" ] || return 1
  _rows=0
  _tab="$(printf '\t')"
  while IFS="$_tab" read -r _name _rest; do
    [ "$_name" = file ] && continue
    [ -n "$_name" ] || continue
    thermal_layout_file_allowed "$_name" || return 1
    case " $THERMAL_LAYOUT_FILES " in *" $_name "*) ;; *) return 1 ;; esac
    _rows=$((_rows + 1))
  done < "$_manifest"
  [ "$_rows" -eq "$THERMAL_LAYOUT_COUNT" ] 2>/dev/null || return 1
  for _name in $THERMAL_LAYOUT_FILES; do
    grep -Fq "$_name$_tab" "$_manifest" || return 1
  done
  return 0
}

thermal_layout_write_env() {
  _tl_out="$1"
  _tl_device="${2:-unknown}"
  _tl_build="${3:-unknown}"
  case "${THERMAL_LAYOUT_COUNT:-0}" in ''|*[!0-9]*) return 1 ;; esac
  [ "$THERMAL_LAYOUT_COUNT" -ge 3 ] 2>/dev/null || return 1
  [ -n "${THERMAL_LAYOUT_FILES:-}" ] || return 1
  _tl_tmp="${_tl_out}.tmp.$$"
  mkdir -p "${_tl_out%/*}" 2>/dev/null || return 1
  {
    printf '%s\n' 'schema=pixel-thermal-layout-v2'
    printf '%s\n' "family=$THERMAL_LAYOUT_FAMILY"
    printf '%s\n' "count=$THERMAL_LAYOUT_COUNT"
    printf '%s\n' "third=${THERMAL_LAYOUT_THIRD:-none}"
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
  _tl_schema="$(sed -n 's/^schema=//p' "$_tl_env" | tail -n 1)"
  _tl_family="$(sed -n 's/^family=//p' "$_tl_env" | tail -n 1)"
  _tl_count="$(sed -n 's/^count=//p' "$_tl_env" | tail -n 1)"
  _tl_third="$(sed -n 's/^third=//p' "$_tl_env" | tail -n 1)"
  _tl_csv="$(sed -n 's/^files_csv=//p' "$_tl_env" | tail -n 1)"
  case "$_tl_count" in ''|*[!0-9]*) return 1 ;; esac
  [ "$_tl_count" -ge 3 ] 2>/dev/null || return 1
  [ "$_tl_schema" = pixel-thermal-layout-v2 ] || return 1

  case "$_tl_family" in
    base_charge_throttling)
      [ "$_tl_count" -eq 3 ] 2>/dev/null || return 1
      [ "$_tl_third" = thermal_info_config_throttling.json ] || return 1
    ;;
    base_charge_lpm)
      [ "$_tl_count" -eq 3 ] 2>/dev/null || return 1
      [ "$_tl_third" = thermal_info_config_lpm.json ] || return 1
    ;;
    include_graph_g6)
      [ "$_tl_third" = none ] || return 1
      [ "$_tl_count" -le "$THERMAL_LAYOUT_MAX_GRAPH_FILES" ] 2>/dev/null || return 1
    ;;
    *) return 1 ;;
  esac

  _tl_files="$(printf '%s' "$_tl_csv" | tr ',' ' ')"
  _actual=0
  _has_root=0
  for _name in $_tl_files; do
    thermal_layout_file_allowed "$_name" || return 1
    [ "$_name" = thermal_info_config.json ] && _has_root=1
    _actual=$((_actual + 1))
  done
  [ "$_actual" -eq "$_tl_count" ] 2>/dev/null || return 1
  [ "$_has_root" -eq 1 ] || return 1

  THERMAL_LAYOUT_FAMILY="$_tl_family"
  THERMAL_LAYOUT_THIRD="$_tl_third"
  THERMAL_LAYOUT_COUNT="$_tl_count"
  THERMAL_LAYOUT_FILES="$_tl_files"
  THERMAL_LAYOUT_FILES_CSV="$_tl_csv"
  return 0
}
