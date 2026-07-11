#!/system/bin/sh
# Pixel 10 A17 nested profile matrix helper.

profile_matrix_base() {
  _device="${1:-}"
  _build="${2:-}"
  case "$_device" in
    frankel|blazer|mustang|rango) ;;
    *) return 1 ;;
  esac
  case "$_build" in
    CP2A.*|cp2a.*) printf "%s\n" "$_device/17/stable/cp2a-260605012/base" ;;
    CP21.*|cp21.*) printf "%s\n" "$_device/17/cp21/cp21260330011/base" ;;
    CP31.*|cp31.*) printf "%s\n" "$_device/17/cp31/cp31260618005/base" ;;
    *) return 1 ;;
  esac
}

profile_matrix_variant() {
  _base="${1:-}"
  _variant="${2:-base}"
  case "$_variant" in
    base|stock|"") printf "%s\n" "$_base" ;;
    outdoor-safe|outdoor-plus|outdoor-extended|outdoor-g4-adapted|outdoor-g4-adapted-plus)
      case "$_base" in
        */17/stable/cp2a-260605012/base)
          _device="${_base%%/*}"
          case "$_variant" in
            outdoor-g4-adapted|outdoor-g4-adapted-plus) printf "%s\n" "$_device/17/stable/cp2a-260605012/$_variant" ;;
            *) printf "%s\n" "$_device/17/cp2a/cp2a260605012/$_variant" ;;
          esac
        ;;
        */base) printf "%s\n" "${_base%/base}/$_variant" ;;
        *) printf "%s\n" "$_base-$_variant" ;;
      esac
    ;;
    *) return 1 ;;
  esac
}
