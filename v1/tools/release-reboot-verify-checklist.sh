#!/usr/bin/env sh
set -eu
version="${1:-}"
code="${2:-}"
printf '%s\n' "== release reboot verify checklist =="
[ -n "$version" ] && printf '%s\n' "version=$version"
[ -n "$code" ] && printf '%s\n' "versionCode=$code"
cat <<'EOF'
required_after_release:
- install exact published ZIP
- reboot
- verify active module path
- verify no disable/remove/skip_mount active
- verify module.prop version/versionCode
- verify manager P/T/Z status
- verify PROFILE_MATRIX_VERIFY_PASS count=83
- verify ZRAM runtime proof when enabled
- verify update-channel switch when touched by release
- record evidence before marking release done
RESULT: RELEASE_REBOOT_VERIFY_CHECKLIST_DONE
EOF
