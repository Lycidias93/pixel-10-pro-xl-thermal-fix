#!/system/bin/sh
# Pixel 10 A17 Test9 full profile matrix helper.

profile_matrix_base() {
  _device="${1:-}"
  _build="${2:-}"
  case "$_build" in
    CP2A.*|cp2a.*) _family="cp2a"; _buildid="cp2a260605012" ;;
    CP21.*|cp21.*) _family="cp21"; _buildid="cp21260330011" ;;
    CP31.*|cp31.*) _family="cp31"; _buildid="cp31260608007" ;;
    *) return 1 ;;
  esac
  case "$_device" in
    frankel|blazer|mustang|rango) ;;
    *) return 1 ;;
  esac
  printf "%s\n" "${_device}-android17-${_family}-${_buildid}"
}

profile_matrix_variant() {
  _base="${1:-}"
  _variant="${2:-base}"
  case "$_variant" in
    base|stock|"") printf "%s\n" "$_base" ;;
    outdoor-safe|outdoor-plus|outdoor-extended) printf "%s-%s\n" "$_base" "$_variant" ;;
    *) return 1 ;;
  esac
}
