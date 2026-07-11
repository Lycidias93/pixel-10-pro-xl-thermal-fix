#!/usr/bin/env sh
set -eu

manifest="${1:-templates/stock-import-manifest.example.tsv}"

say() {
  printf '%s\n' "$*"
}

fail() {
  say "FAIL $1"
  exit "${2:-1}"
}

[ -s "$manifest" ] || fail "manifest_missing_or_empty path=$manifest" 10

header="$(sed -n '1p' "$manifest")"
expected="$(printf 'device\tbuild\tincremental\tsource_kind\tsource_path\trelative_path\tsha256\tbytes\tprofile_consumers\tclassification\tnotes')"
[ "$header" = "$expected" ] || fail "manifest_header_mismatch" 11

p1="$(printf '%s%s' 'g' 'hp_')"
p2="$(printf '%s%s' 'github_' 'pat_')"
p3="$(printf '%s%s' 'BEGIN OPENSSH ' 'PRIVATE KEY')"
p4="$(printf '%s%s' 'BEGIN RSA ' 'PRIVATE KEY')"
secret_pattern="$p1|$p2|$p3|$p4"
if grep -E "$secret_pattern" "$manifest" >/dev/null 2>&1; then
  fail "manifest_secret_pattern_present" 14
fi

tail -n +2 "$manifest" | while IFS="$(printf '\t')" read -r device build incremental source_kind source_path relative_path sha256 bytes consumers classification notes; do
  [ -n "${device:-}" ] || continue

  case "$device" in
    frankel|blazer|mustang|rango) ;;
    *) fail "bad_device value=$device" 15 ;;
  esac

  case "$build" in
    CP31.260618.005|CP2A.260605.012|CP21.260330.011) ;;
    *) fail "bad_build value=$build" 16 ;;
  esac

  case "$classification" in
    stock-exact|compatibility-derived|unknown) ;;
    *) fail "bad_classification value=$classification" 17 ;;
  esac

  case "$relative_path" in
    originals/*/CP31.260618.005/*|originals/*/CP2A.260605.012/*|originals/*/CP21.260330.011/*) ;;
    *) fail "bad_relative_path value=$relative_path" 18 ;;
  esac

  case "$sha256" in
    64_HEX_SHA256)
      say "WARN example_sha_placeholder device=$device relative_path=$relative_path"
    ;;
    *)
      if ! printf '%s' "$sha256" | grep -Eq '^[0-9a-f]{64}$'; then
        fail "bad_sha256 value=$sha256" 19
      fi
    ;;
  esac

  case "$bytes" in
    ''|*[!0-9]*) fail "bad_bytes value=$bytes" 20 ;;
    *) ;;
  esac

  say "PASS manifest_row device=$device build=$build classification=$classification relative_path=$relative_path"
done

entries="$(tail -n +2 "$manifest" | awk 'NF > 0 {count++} END {print count+0}')"
bad_sha="$(tail -n +2 "$manifest" | awk -F '\t' 'NF > 0 && $7 != "64_HEX_SHA256" && $7 !~ /^[0-9a-f]{64}$/ {count++} END {print count+0}')"
bad_class="$(tail -n +2 "$manifest" | awk -F '\t' 'NF > 0 && $10 !~ /^(stock-exact|compatibility-derived|unknown)$/ {count++} END {print count+0}')"

[ "$bad_sha" = "0" ] || fail "manifest_bad_sha_count=$bad_sha" 21
[ "$bad_class" = "0" ] || fail "manifest_bad_classification_count=$bad_class" 22

say "manifest_entries=$entries"
say "RESULT: STOCK_IMPORT_MANIFEST_VERIFY_DONE"
