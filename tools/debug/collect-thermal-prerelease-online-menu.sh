#!/data/data/com.termux/files/usr/bin/sh
# Interactive Termux launcher for the repo-only prerelease debug collector.
set -u

ENGINE_COMMIT="189be5c18381702e515b4136ceabfd2fe57f60d2"
ENGINE_BLOB="bdfbcd280de8bd83150c1777b08e5b677b434ab2"
ENGINE_URL="https://raw.githubusercontent.com/Lycidias93/pixel-10-pro-xl-thermal-fix/$ENGINE_COMMIT/tools/debug/collect-thermal-prerelease-online.sh"
ENGINE_PATH="${TMPDIR:-/data/data/com.termux/files/usr/tmp}/collect-thermal-prerelease-online.sh"

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

printf '%s\n' 'Pixel Thermal Alpha 3 Dev 6 debug collector'
choose 'Scenario' 6 clean-install action-switch boot-failure status-red install-failure unknown
scenario="$CHOICE"
choose 'Selected profile' 5 stock outdoor-safe outdoor-plus outdoor-extended unknown
selected="$CHOICE"
choose 'Previous profile' 6 none stock outdoor-safe outdoor-plus outdoor-extended unknown
previous="$CHOICE"
choose 'Install mode' 4 clean upgrade dirty unknown
mode="$CHOICE"

printf '\nCollecting: scenario=%s selected=%s previous=%s mode=%s\n' "$scenario" "$selected" "$previous" "$mode"
download_engine
verify_engine
chmod 0755 "$ENGINE_PATH"
su -c "sh '$ENGINE_PATH' '$scenario' '$selected' '$previous' '$mode'"
