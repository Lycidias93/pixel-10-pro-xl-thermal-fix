#!/system/bin/sh
# Legacy compatibility path retained for the stable Pixel 10 throttling layout.
exec sh "${0%/*}/compat-check-legacy-core.sh" "$@"
