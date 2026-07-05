#!/system/bin/sh
MODDIR=${0%/*}
chmod 755 "$MODDIR/bin"/*.sh "$MODDIR/bin/k6a-controller" 2>/dev/null
