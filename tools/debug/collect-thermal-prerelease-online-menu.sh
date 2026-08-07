#!/data/data/com.termux/files/usr/bin/sh
# Interactive Termux launcher for the read-only online Thermal debug collector.
set -u

ENGINE_COMMIT="ea8f34a70e0a045b6444f7960b94cbdcec6d9f59"
ENGINE_BLOB="bd63fb145c8cac450e5c1b8aa95c81fa5d7c0de7"
ENGINE_URL="https://raw.githubusercontent.com/Lycidias93/pixel-10-pro-xl-thermal-fix/$ENGINE_COMMIT/tools/debug/collect-thermal-prerelease-online.sh"
ENGINE_PATH="${TMPDIR:-/data/data/com.termux/files/usr/tmp}/collect-thermal-online.sh"

choose() {
  _prompt="$1"
  _default="$2"
  shift 2
  while :; do
    printf '\n%s\n' "$_prompt"
    _number=1
    for _value in "$@"; do
      printf '  %s) %s\n' "$_number" "$_value"
      _number=$((_number + 1))
    done
    printf 'Select [%s]: ' "$_default"
    IFS= read -r _answer || _answer=""
    [ -n "$_answer" ] || _answer="$_default"
    _number=1
    for _value in "$@"; do
      if [ "$_answer" = "$_number" ] || [ "$_answer" = "$_value" ]; then
        CHOICE="$_value"
        return 0
      fi
      _number=$((_number + 1))
    done
    printf '%s\n' 'Invalid selection.'
  done
}

download_engine() {
  rm -f "$ENGINE_PATH" 2>/dev/null || true
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$ENGINE_URL" -o "$ENGINE_PATH"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$ENGINE_PATH" "$ENGINE_URL"
  else
    printf '%s\n' 'FAILED: curl_or_wget_missing'
    return 1
  fi
}

verify_engine() {
  _size="$(wc -c < "$ENGINE_PATH" | tr -d ' ')"
  _blob="$( (printf 'blob %s\0' "$_size"; cat "$ENGINE_PATH") | sha1sum | awk '{print $1}')"
  [ "$_blob" = "$ENGINE_BLOB" ] || {
    printf 'FAILED: collector_integrity_mismatch expected=%s actual=%s\n' "$ENGINE_BLOB" "$_blob"
    return 1
  }
}

printf '%s\n' 'Pixel Thermal online debug collector'
printf '%s\n' 'The collector is read-only and does not enable or modify Thermal/Polling.'
choose 'Collection mode' 1 support runtime
mode="$CHOICE"

if [ "$mode" = support ]; then
  printf '%s\n' 'Support mode: privacy-reduced platform/layout inventory; no logcat or dmesg.'
else
  printf '%s\n' 'Runtime mode: adds filtered system/root logs for boot or runtime failures.'
fi

printf '\nDownloading verified collector into the private Termux temp directory...\n'
download_engine || exit 4
verify_engine || exit 5
chmod 0700 "$ENGINE_PATH"
printf '%s\n' 'Grant root when prompted.'
su -c "sh '$ENGINE_PATH' '$mode'"
