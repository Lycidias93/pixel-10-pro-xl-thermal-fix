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

# The supported-version manifest is immutable for the lifetime of each helper
# process. Cache its structural validation so platform/build probes do not
# repeat the character-by-character JSON scan, wc and grep sequence.
THERMAL_SUPPORTED_VALIDATE_CACHE_FILE=
THERMAL_SUPPORTED_VALIDATE_CACHE_SIZE=
THERMAL_SUPPORTED_VALIDATE_CACHE_RESULT=1
THERMAL_SUPPORTED_PROBE_CACHE_KEY=
THERMAL_SUPPORTED_DEVICE_OK=0
THERMAL_SUPPORTED_ANDROID_OK=0
THERMAL_SUPPORTED_BUILD_OK=0

thermal_supported_validate_file() {
  _file="$1"
  [ -s "$_file" ] || return 1
  _size="$(wc -c < "$_file" 2>/dev/null | tr -d ' ')"
  case "$_size" in ''|*[!0-9]*) return 1 ;; esac

  if [ "$_file" = "$THERMAL_SUPPORTED_VALIDATE_CACHE_FILE" ] &&
     [ "$_size" = "$THERMAL_SUPPORTED_VALIDATE_CACHE_SIZE" ]; then
    return "$THERMAL_SUPPORTED_VALIDATE_CACHE_RESULT"
  fi

  _result=0
  [ "$_size" -ge 100 ] 2>/dev/null || _result=1
  [ "$_size" -le 262144 ] 2>/dev/null || _result=1
  if [ "$_result" -eq 0 ]; then
    thermal_json_tolerant_validate "$_file" || _result=1
  fi
  if [ "$_result" -eq 0 ]; then
    grep -q '"supported_devices"[[:space:]]*:' "$_file" || _result=1
    grep -q '"supported_android_versions"[[:space:]]*:' "$_file" || _result=1
    grep -q '"verified_builds"[[:space:]]*:' "$_file" || _result=1
  fi

  THERMAL_SUPPORTED_VALIDATE_CACHE_FILE="$_file"
  THERMAL_SUPPORTED_VALIDATE_CACHE_SIZE="$_size"
  THERMAL_SUPPORTED_VALIDATE_CACHE_RESULT="$_result"
  return "$_result"
}

thermal_supported_probe() {
  _file="$1"
  _device="$2"
  _android="$3"
  _build="${4:-unknown}"
  _key="$_file|$_device|$_android|$_build"

  if [ "$_key" = "$THERMAL_SUPPORTED_PROBE_CACHE_KEY" ]; then
    [ "$THERMAL_SUPPORTED_DEVICE_OK" = 1 ] &&
      [ "$THERMAL_SUPPORTED_ANDROID_OK" = 1 ]
    return
  fi

  THERMAL_SUPPORTED_DEVICE_OK=0
  THERMAL_SUPPORTED_ANDROID_OK=0
  THERMAL_SUPPORTED_BUILD_OK=0
  thermal_supported_validate_file "$_file" || {
    THERMAL_SUPPORTED_PROBE_CACHE_KEY="$_key"
    return 1
  }

  _probe="$(awk -v dev="$_device" -v android="$_android" -v bid="$_build" '
    index($0, "\"supported_devices\"") && index($0, "{") {
      in_devices=1
      next
    }
    in_devices {
      if (index($0, "}") > 0) {
        in_devices=0
      } else if (index($0, "\"" dev "\"") > 0 && index($0, ":") > 0) {
        device_ok=1
      }
      next
    }

    index($0, "\"supported_android_versions\"") && index($0, "[") {
      in_android_list=1
    }
    in_android_list {
      if (index($0, "\"" android "\"") > 0) android_ok=1
      if (index($0, "]") > 0) in_android_list=0
      next
    }

    index($0, "\"verified_builds\"") && index($0, "{") {
      in_verified=1
      next
    }
    in_verified && !in_verified_device &&
      index($0, "\"" dev "\"") && index($0, "{") {
        in_verified_device=1
        next
      }
    in_verified_device && !in_verified_android &&
      index($0, "\"" android "\"") && index($0, "[") {
        in_verified_android=1
        next
      }
    in_verified_android {
      if (index($0, "\"" bid "\"") > 0) build_ok=1
      if (index($0, "]") > 0) in_verified_android=0
      next
    }
    in_verified_device && !in_verified_android && index($0, "}") {
      in_verified_device=0
    }
    END {
      printf "%d:%d:%d\n", device_ok + 0, android_ok + 0, build_ok + 0
    }
  ' "$_file" 2>/dev/null)" || _probe="0:0:0"

  THERMAL_SUPPORTED_DEVICE_OK="${_probe%%:*}"
  _rest="${_probe#*:}"
  THERMAL_SUPPORTED_ANDROID_OK="${_rest%%:*}"
  THERMAL_SUPPORTED_BUILD_OK="${_rest##*:}"
  THERMAL_SUPPORTED_PROBE_CACHE_KEY="$_key"

  [ "$THERMAL_SUPPORTED_DEVICE_OK" = 1 ] &&
    [ "$THERMAL_SUPPORTED_ANDROID_OK" = 1 ]
}

thermal_supported_device_check() {
  _file="$1"
  _device="$2"
  thermal_supported_probe "$_file" "$_device" "__none__" "__none__" || true
  [ "$THERMAL_SUPPORTED_DEVICE_OK" = 1 ]
}

thermal_supported_android_check() {
  _file="$1"
  _android="$2"
  thermal_supported_probe "$_file" "__none__" "$_android" "__none__" || true
  [ "$THERMAL_SUPPORTED_ANDROID_OK" = 1 ]
}

thermal_supported_platform_check() {
  _file="$1"
  _device="$2"
  _android="$3"
  thermal_supported_probe "$_file" "$_device" "$_android" "__none__"
}

thermal_exact_build_check() {
  _file="$1"
  _device="$2"
  _android="$3"
  _build="$4"
  thermal_supported_probe "$_file" "$_device" "$_android" "$_build" || return 1
  [ "$THERMAL_SUPPORTED_BUILD_OK" = 1 ]
}

# Backward-compatible activation API. In Dynamic V2, "supported" means the
# device/Android platform is supported. Exact build IDs are evidence only.
thermal_supported_check() {
  _file="$1"
  _device="$2"
  _android="$3"
  _build="${4:-unknown}"
  THERMAL_BUILD_EVIDENCE=unverified
  if ! thermal_supported_probe "$_file" "$_device" "$_android" "$_build"; then
    THERMAL_BUILD_EVIDENCE=unsupported_platform
    return 1
  fi
  if [ "$THERMAL_SUPPORTED_BUILD_OK" = 1 ]; then
    THERMAL_BUILD_EVIDENCE=verified
  fi
  return 0
}

thermal_build_evidence_state() {
  _file="$1"
  _device="$2"
  _android="$3"
  _build="$4"
  if ! thermal_supported_probe "$_file" "$_device" "$_android" "$_build"; then
    printf '%s\n' unsupported_platform
  elif [ "$THERMAL_SUPPORTED_BUILD_OK" = 1 ]; then
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
