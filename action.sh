#!/system/bin/sh
MODDIR=${0%/*}
if [ -s "$MODDIR/tools/action-dashboard.sh" ]; then
  sh "$MODDIR/tools/action-dashboard.sh"
elif [ -s "$MODDIR/tools/menu/zram-menu.sh" ]; then
  sh "$MODDIR/tools/menu/zram-menu.sh" action
else
  echo "Action helpers missing."
  exit 1
fi
