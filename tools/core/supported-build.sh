#!/system/bin/sh
# Dynamic V2 platform admission and exact-build evidence helper.
# Unknown build IDs are admitted locally when the Pixel 10 platform and
# generated stock-derived overlay pass structural validation.

thermal_json_tolerant_validate() {
  _file="$1"
  [ -s "$_file" ] || return 1
  awk '
    BEGIN { braces=0; brackets=0; in_string=0; escaped=0; bad=0; first=""; last="" }
    {
      line=$0
      for (i=1; i<=length(line); i++) {
        c=substr(line,i,1)
        if (c !~ /[[:space:]]/) {
          if (first=="") first=c
          last=c
        }
        if (in_string) {
          if (escaped) escaped=0
          else if (c=="\\") escaped=1
          else if (c=="\"") in_string=0
          continue
        }
        if (c=="\"") { in_string=1; continue }
        if (c=="{") braces++
        else if (c=="}") { braces--; if (braces<0) bad=1 }
        else if (c=="[") brackets++
        else if (c=="]") { brackets--; if (brackets<0) bad=1 }
      }
    }
    END {
      if (bad || in_string || escaped || braces != 0 || brackets != 0) exit 1
      if (first != "{" || last != "}") exit 1
    }
  ' "$_file"
}

thermal_supported_validate_file() {
  _file="$1"
  [ -s "$_file" ] || return 1
  _size="$(wc -c < "$_file" 2>/dev/null | tr -d ' ')"
  case "$_size" in ''|*[!0-9]*) return 1 ;; esac
  [ "$_size" -ge 100 ] 2>/dev/null || return 1
  [ "$_size" -le 262144 ] 2>/dev/null || return 1
  thermal_json_tolerant_validate "$_file" || return 1
  grep -q '"supported_devices"[[:space:]]*:' "$_file" || return 1
  grep -q '"supported_android_versions"[[:space:]]*:' "$_file" || return 1
  grep -q '"verified_builds"[[:space:]]*:' "$_file" || return 1
  return 0
}

thermal_supported_device_check() {
  _file="$1"
  _device="$2"
  thermal_supported_validate_file "$_file" || return 1
  awk -v dev="$_device" '
    index($0, "\"supported_devices\"") && index($0, "{") { in_devices=1; next }
    in_devices && index($0, "}") { exit(found ? 0 : 1) }
    in_devices && index($0, "\"" dev "\"") && index($0, ":") { found=1; exit 0 }
    END { if (!found) exit 1 }
  ' "$_file"
}

thermal_supported_android_check() {
  _file="$1"
  _android="$2"
  thermal_supported_validate_file "$_file" || return 1
  awk -v android="$_android" '
    index($0, "\"supported_android_versions\"") && index($0, "[") { in_android=1 }
    in_android && index($0, "\"" android "\"") { found=1; exit 0 }
    in_android && index($0, "]") { exit(found ? 0 : 1) }
    END { if (!found) exit 1 }
  ' "$_file"
}

thermal_supported_platform_check() {
  _file="$1"
  _device="$2"
  _android="$3"
  thermal_supported_device_check "$_file" "$_device" &&
    thermal_supported_android_check "$_file" "$_android"
}

thermal_exact_build_check() {
  _file="$1"
  _device="$2"
  _android="$3"
  _build="$4"
  thermal_supported_validate_file "$_file" || return 1
  awk -v dev="$_device" -v android="$_android" -v bid="$_build" '
    index($0, "\"verified_builds\"") && index($0, "{") { in_verified=1; next }
    !in_verified { next }
    index($0, "\"" dev "\"") && index($0, "{") { in_device=1; next }
    in_device && index($0, "\"" android "\"") && index($0, "[") { in_android=1; next }
    in_android && index($0, "\"" bid "\"") { found=1; exit 0 }
    in_android && index($0, "]") { in_android=0; next }
    in_device && !in_android && index($0, "}") { in_device=0; next }
    END { if (!found) exit 1 }
  ' "$_file"
}

# Backward-compatible activation API. In Dynamic V2, "supported" means the
# device/Android platform is supported. Exact build IDs are evidence only.
thermal_supported_check() {
  _file="$1"
  _device="$2"
  _android="$3"
  _build="${4:-unknown}"
  THERMAL_BUILD_EVIDENCE=unverified
  if ! thermal_supported_platform_check "$_file" "$_device" "$_android"; then
    THERMAL_BUILD_EVIDENCE=unsupported_platform
    return 1
  fi
  if thermal_exact_build_check "$_file" "$_device" "$_android" "$_build"; then
    THERMAL_BUILD_EVIDENCE=verified
  fi
  return 0
}

thermal_build_evidence_state() {
  _file="$1"
  _device="$2"
  _android="$3"
  _build="$4"
  if ! thermal_supported_platform_check "$_file" "$_device" "$_android"; then
    printf '%s\n' unsupported_platform
  elif thermal_exact_build_check "$_file" "$_device" "$_android" "$_build"; then
    printf '%s\n' exact_verified
  else
    printf '%s\n' dynamic_unverified
  fi
}

# Network refresh was removed. Dynamic admission is local and deterministic.
thermal_supported_refresh_for_current() {
  printf '%s\n' "SUPPORTED_REFRESH=removed_local_dynamic_admission"
  return 2
}
