#!/system/bin/sh
MODDIR=${0%/*}
if [ -s "$MODDIR/tools/zram-menu.sh" ]; then
  sh "$MODDIR/tools/zram-menu.sh" action
else
  echo "ZRAM menu helper missing."
  exit 1
fi
