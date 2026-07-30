#!/system/bin/sh
MODDIR=${0%/*}
chmod 755 "$MODDIR/bin"/*.sh "$MODDIR/bin/k6a-controller" 2>/dev/null
mkdir -p "$MODDIR/run" 2>/dev/null

boot_delay=15
[ -f "$MODDIR/config/settings.conf" ] && boot_delay=$(grep "^boot_delay=" "$MODDIR/config/settings.conf" | cut -d= -f2)
sleep "$boot_delay"

# Watchdog: restart controller if it crashes
while true; do
    nohup "$MODDIR/bin/k6a-controller" "$MODDIR" >/dev/null 2>&1 &
    wait
    sleep 6
done &
