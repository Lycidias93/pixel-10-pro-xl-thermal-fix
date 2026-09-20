#!/system/bin/sh
set -u

src="${1:-}"
dst="${2:-}"
[ -n "$src" ] && [ -r "$src" ] && [ -n "$dst" ] || exit 1
size="$(wc -c < "$src" 2>/dev/null | tr -d ' ')"
case "$size" in ''|*[!0-9]*) exit 1 ;; esac
[ "$size" -le 1048576 ] || exit 1

tmp="$dst.tmp.$$"
: > "$tmp" || exit 1
while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in
    NTFY_ENABLED=*|NTFY_PRIORITY=*|NTFY_TAGS=*)
      printf '%s\n' "$line" >> "$tmp" || exit 1
      ;;
    NTFY_*=*)
      key="${line%%=*}"
      printf '%s=<redacted>\n' "$key" >> "$tmp" || exit 1
      ;;
    *)
      printf '%s\n' "$line" >> "$tmp" || exit 1
      ;;
  esac
done < "$src"
chmod 0600 "$tmp" 2>/dev/null || true
mv "$tmp" "$dst"
