#!/system/bin/sh
set -eu
ROOT="${1:-profiles}"

map_one() {
  name="$1"
  device="${name%%-*}"
  family="unknown"
  variant="base"
  status="ok"
  note="mapped"

  case "$name" in
    *cp21*) family="cp21" ;;
    *cp2a*|*stable-cp2a*) family="cp2a" ;;
    *cp31*) family="cp31" ;;
    *android16*|*a16*) family="android16" ;;
    *) family="unknown"; status="needs_manual_review"; note="family_unknown" ;;
  esac

  case "$name" in
    *-outdoor-g4-adapted-plus) variant="outdoor-g4-adapted-plus"; status="legacy_variant_preserve"; note="do_not_map_to_base" ;;
    *-outdoor-g4-adapted) variant="outdoor-g4-adapted"; status="legacy_variant_preserve"; note="do_not_map_to_base" ;;
    *-outdoor-extended) variant="outdoor-extended" ;;
    *-outdoor-plus) variant="outdoor-plus" ;;
    *-outdoor-safe) variant="outdoor-safe" ;;
    *) variant="base" ;;
  esac

  printf "%s\t%s\t%s\t%s\n" "$name" "profiles/$device/$family/$variant/system/vendor/etc" "$status" "$note"
}

printf "%s\t%s\t%s\t%s\n" "source_profile" "proposed_profile_path" "status" "note"
find "$ROOT" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | while IFS= read -r d; do
  b="${d##*/}"
  map_one "$b"
done | sort
