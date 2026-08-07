#!/system/bin/sh
# This path is populated from the 2.0.1 legacy implementation during vNext branch preparation.
exec sh "${0%/*}/patch-thermal-validated.sh" "$@"
