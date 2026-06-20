#!/system/bin/sh
MODDIR=${0%/*}
mkdir -p "$MODDIR/run" "$MODDIR/config"
chmod 755 "$MODDIR/bin/k6a-controller" "$MODDIR/bin/k6a-lib.sh" 2>/dev/null
[ -f "$MODDIR/config/god_mode" ] || printf '0' > "$MODDIR/config/god_mode"
[ -f "$MODDIR/config/thermal_protect" ] || printf '1' > "$MODDIR/config/thermal_protect"
chmod 644 "$MODDIR/config/god_mode" "$MODDIR/config/thermal_protect" 2>/dev/null
