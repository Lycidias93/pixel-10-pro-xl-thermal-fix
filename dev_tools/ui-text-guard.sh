#!/system/bin/sh
set -eu
MAX="${1:-44}"
shift 2>/dev/null || true
rc=0
files="$*"
[ -n "$files" ] || files="customize.sh action.sh tools/action-dashboard.sh tools/install-options-menu.sh tools/install-thermal-overlay.sh tools/install-zram.sh tools/thermal-outdoor-menu.sh tools/zram-menu.sh tools/ptune-guard.sh tools/collect-debug.sh"

for f in $files; do
  [ -r "$f" ] || continue
  n=0
  while IFS= read -r line || [ -n "$line" ]; do
    n=$((n + 1))
    case "$line" in
      *'ui_print "'*|*'mc_msg "'*|*'msg "'*) ;;
      *) continue ;;
    esac
    text="${line#*\"}"
    text="${text%%\"*}"
    case "$text" in
      *'$'*|RESULT:*|"") continue ;;
    esac
    len=${#text}
    if [ "$len" -gt "$MAX" ]; then
      echo "FAIL ui_text_len file=$f line=$n len=$len text=$text"
      rc=1
    fi
  done < "$f"
done
if [ "$rc" = "0" ]; then
  echo "UI_TEXT_GUARD_PASS max=$MAX"
fi
exit "$rc"
