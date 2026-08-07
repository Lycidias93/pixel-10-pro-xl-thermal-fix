#!/system/bin/sh
# Legacy Dynamic V2 validated patcher retained for the Pixel 10 throttling-file family.
exec sh "${0%/*}/patch-thermal-validated-legacy-core.sh" "$@"
