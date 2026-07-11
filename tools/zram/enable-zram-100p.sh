#!/system/bin/sh
CONFIG_DIR="/data/adb/pixel-10-pro-xl-thermal-fix"
CONFIG_FILE="$CONFIG_DIR/config.env"
MODDIR="${MODDIR:-/data/adb/modules/pixel-10-pro-xl-thermal-fix}"
mkdir -p "$CONFIG_DIR" 2>/dev/null || true
if [ -f "$CONFIG_FILE" ]; then
  grep -v -E '^(ENABLE_ZRAM_100P|ZRAM_RESTART_MMD|ZRAM_RISK_ACK)=' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" 2>/dev/null || true
  mv "$CONFIG_FILE.tmp" "$CONFIG_FILE" 2>/dev/null || true
fi
{
  echo 'ENABLE_ZRAM_100P=1'
  echo 'ZRAM_RESTART_MMD=1'
  echo 'ZRAM_RISK_ACK=explicit_user_enable'
} >> "$CONFIG_FILE"
export ENABLE_ZRAM_100P=1
export ZRAM_RESTART_MMD=1
export ZRAM_RISK_ACK=explicit_user_enable

echo "ZRAM 100p enabled in config. Applying once now and service.sh will re-apply after next boot."
sh "$MODDIR/tools/apply-zram-100p.sh" manual
