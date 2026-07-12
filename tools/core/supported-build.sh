#!/system/bin/sh
# Shared supported_versions.json guard and immutable-commit refresh helper.

thermal_json_tolerant_validate() {
  _ts_file="$1"
  [ -s "$_ts_file" ] || return 1
  awk '
    BEGIN {
      braces = 0
      brackets = 0
      in_string = 0
      escaped = 0
      first = ""
      last = ""
      bad = 0
    }
    {
      line = $0
      for (i = 1; i <= length(line); i++) {
        c = substr(line, i, 1)
        if (c !~ /[[:space:]]/) {
          if (first == "") first = c
          last = c
        }
        if (in_string) {
          if (escaped) {
            escaped = 0
          } else if (c == "\\") {
            escaped = 1
          } else if (c == "\"") {
            in_string = 0
          }
          continue
        }
        if (c == "\"") {
          in_string = 1
          continue
        }
        if (c == "{") braces++
        else if (c == "}") {
          braces--
          if (braces < 0) bad = 1
        } else if (c == "[") brackets++
        else if (c == "]") {
          brackets--
          if (brackets < 0) bad = 1
        }
      }
    }
    END {
      if (bad || in_string || escaped || braces != 0 || brackets != 0) exit 1
      if (first != "{" || last != "}") exit 1
    }
  ' "$_ts_file"
}

thermal_supported_validate_file() {
  _ts_file="$1"
  [ -s "$_ts_file" ] || return 1
  _ts_size="$(wc -c < "$_ts_file" 2>/dev/null | tr -d ' ')"
  case "$_ts_size" in
    ''|*[!0-9]*) return 1 ;;
  esac
  [ "$_ts_size" -ge 100 ] 2>/dev/null || return 1
  [ "$_ts_size" -le 262144 ] 2>/dev/null || return 1
  thermal_json_tolerant_validate "$_ts_file" || return 1
  grep -q '"supported_devices"[[:space:]]*:' "$_ts_file" || return 1
  grep -q '"supported_android_versions"[[:space:]]*:' "$_ts_file" || return 1
  grep -q '"verified_builds"[[:space:]]*:' "$_ts_file" || return 1
  grep -q '"mustang"[[:space:]]*:' "$_ts_file" || return 1
  grep -q '"blazer"[[:space:]]*:' "$_ts_file" || return 1
  grep -q '"frankel"[[:space:]]*:' "$_ts_file" || return 1
  grep -q '"rango"[[:space:]]*:' "$_ts_file" || return 1
  return 0
}

thermal_supported_check() {
  _ts_file="$1"
  _ts_device="$2"
  _ts_android="$3"
  _ts_build="$4"
  thermal_supported_validate_file "$_ts_file" || return 1
  awk -v dev="$_ts_device" -v android="$_ts_android" -v bid="$_ts_build" '
    BEGIN {
      in_verified = 0
      found_dev = 0
      found_android = 0
      supported = 0
    }
    index($0, "\"verified_builds\"") && index($0, "{") {
      in_verified = 1
      next
    }
    !in_verified { next }
    index($0, "\"" dev "\"") && index($0, "{") {
      found_dev = 1
      next
    }
    found_dev && index($0, "\"" android "\"") && index($0, "[") {
      found_android = 1
      next
    }
    found_android && index($0, "]") {
      found_android = 0
      next
    }
    found_dev && !found_android && index($0, "}") {
      found_dev = 0
      next
    }
    found_dev && found_android && index($0, "\"" bid "\"") {
      supported = 1
      exit
    }
    END {
      if (supported) exit 0
      exit 1
    }
  ' "$_ts_file"
}

thermal_download_url() {
  _ts_url="$1"
  _ts_dest="$2"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL --connect-timeout 5 --max-time 15 "$_ts_url" -o "$_ts_dest"
    return $?
  fi
  if command -v wget >/dev/null 2>&1; then
    wget -T 15 -t 1 "$_ts_url" -O "$_ts_dest"
    return $?
  fi
  if [ -x /data/adb/magisk/busybox ]; then
    /data/adb/magisk/busybox wget -T 15 -t 1 "$_ts_url" -O "$_ts_dest"
    return $?
  fi
  return 1
}

thermal_supported_refresh_for_current() {
  _ts_moddir="$1"
  _ts_device="$2"
  _ts_android="$3"
  _ts_build="$4"
  _ts_id="${5:-pixel-10-pro-xl-thermal-fix}"
  _ts_tmp_root="${THERMAL_SUPPORTED_TMP_ROOT:-/data/local/tmp}"
  _ts_work="$_ts_tmp_root/.pixel-thermal-supported.$$"
  _ts_api="$_ts_work.commit.json"
  _ts_json="$_ts_work.supported.json"
  _ts_target="$_ts_moddir/supported_versions.json"
  _ts_target_tmp="$_ts_moddir/.supported_versions.json.$$"
  _ts_state_dir="/data/adb/$_ts_id"
  _ts_state_tmp="$_ts_state_dir/.supported_versions.remote.env.$$"
  _ts_state="$_ts_state_dir/supported_versions.remote.env"

  rm -f "$_ts_api" "$_ts_json" "$_ts_target_tmp" "$_ts_state_tmp"
  thermal_download_url \
    "https://api.github.com/repos/Lycidias93/pixel-10-pro-xl-thermal-fix/commits/v2" \
    "$_ts_api" || return 1

  _ts_commit="$(sed -n 's/^[[:space:]]*"sha":[[:space:]]*"\([0-9a-fA-F][0-9a-fA-F]*\)".*/\1/p' "$_ts_api" | head -n 1)"
  case "$_ts_commit" in
   ????????????????????????????????????????) ;;
    *) rm -f "$_ts_api" "$_ts_json"; return 1 ;;
  esac
  case "$_ts_commit" in *[!0-9a-fA-F]*) rm -f "$_ts_api" "$_ts_json"; return 1 ;; esac

  thermal_download_url \
    "https://raw.githubusercontent.com/Lycidias93/pixel-10-pro-xl-thermal-fix/$_ts_commit/supported_versions.json" \
    "$_ts_json" || {
      rm -f "$_ts_api" "$_ts_json"
      return 1
    }

  thermal_supported_validate_file "$_ts_json" || {
    rm -f "$_ts_api" "$_ts_json"
    return 1
  }
  thermal_supported_check "$_ts_json" "$_ts_device" "$_ts_android" "$_ts_build" || {
    rm -f "$_ts_api" "$_ts_json"
    return 1
  }

  _ts_sha="$(sha256sum "$_ts_json" 2>/dev/null | awk '{print $1}')"
  case "$_ts_sha" in
   ????????????????????????????????????????????????????????????????) ;;
    *) rm -f "$_ts_api" "$_ts_json"; return 1 ;;
  esac

  cp -fp "$_ts_json" "$_ts_target_tmp" || {
    rm -f "$_ts_api" "$_ts_json" "$_ts_target_tmp"
    return 1
  }
  thermal_supported_validate_file "$_ts_target_tmp" || {
    rm -f "$_ts_api" "$_ts_json" "$_ts_target_tmp"
    return 1
  }
  mv "$_ts_target_tmp" "$_ts_target" || {
    rm -f "$_ts_api" "$_ts_json" "$_ts_target_tmp"
    return 1
  }
  chmod 0644 "$_ts_target" 2>/dev/null || true

  mkdir -p "$_ts_state_dir" 2>/dev/null || true
  {
    printf '%s\n' "repository=Lycidias93/pixel-10-pro-xl-thermal-fix"
    printf '%s\n' "branch=v2"
    printf '%s\n' "commit=$_ts_commit"
    printf '%s\n' "sha256=$_ts_sha"
    printf '%s\n' "device=$_ts_device"
    printf '%s\n' "android=$_ts_android"
    printf '%s\n' "build_id=$_ts_build"
    printf '%s\n' "updated_at=$(date -Is 2>/dev/null || date)"
  } > "$_ts_state_tmp"
  mv "$_ts_state_tmp" "$_ts_state" 2>/dev/null || true
  chmod 0600 "$_ts_state" 2>/dev/null || true

  rm -f "$_ts_api" "$_ts_json"
  printf '%s\n' "SUPPORTED_REFRESH=pass"
  printf '%s\n' "SUPPORTED_REFRESH_COMMIT=$_ts_commit"
  printf '%s\n' "SUPPORTED_REFRESH_SHA256=$_ts_sha"
  return 0
}
