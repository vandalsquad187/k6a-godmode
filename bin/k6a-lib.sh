#!/system/bin/sh
# k6a-lib.sh  v2.2 — BALANCED (kernel-aligned)
# SM7150 | Silver 0-5 (1516MHz) | Gold 6-7 (1804MHz)

unalias r 2>/dev/null || true

GPU=/sys/class/kgsl/kgsl-3d0
P0=/sys/devices/system/cpu/cpufreq/policy0
P6=/sys/devices/system/cpu/cpufreq/policy6

CS_TOP=/dev/cpuset/top-app
CS_FG=/dev/cpuset/foreground
CS_BG=/dev/cpuset/background
CS_SYS=/dev/cpuset/system-background
CS_RESTRICT=/dev/cpuset/restricted

CODM_PKG=com.activision.callofduty.shooter
_TRIP_CACHE=$MODDIR/run/trip_cache
_TRIP_SAFE="touch|tsp|conn_therm|charger_therm|battery|bms|qcom-bms|xo_therm|pa_therm|pm6150|pm6150l|bcl|vbat|pmic"

FEATURE_HOTPLUG=0
FEATURE_LRU_GEN=0
FEATURE_BOEFFLA=0
FEATURE_WAKELOCK=0
FEATURE_SCHED_CASS=0
FEATURE_UCLAMP=0
FEATURE_THERMAL_WRITABLE=0

log()  { printf '[%s] [INFO] %s\n' "$(date '+%H:%M:%S')" "$1" >> "${LOG_FILE:-/dev/null}" 2>/dev/null; }
warn() { printf '[%s] [WARN] %s\n' "$(date '+%H:%M:%S')" "$1" >> "${LOG_FILE:-/dev/null}" 2>/dev/null; }
err()  { printf '[%s] [ERROR] %s\n' "$(date '+%H:%M:%S')" "$1" >> "${LOG_FILE:-/dev/null}" 2>/dev/null; }
dbg()  { [ "${CFG_DEBUG:-0}" = "1" ] && printf '[%s] [DBG] %s\n' "$(date '+%H:%M:%S')" "$1" >> "${LOG_FILE:-/dev/null}" 2>/dev/null; }

w() {
    local node="$1" val="$2"
    [ -f "$node" ] || return 1
    case "$node" in
        */devfreq/max_freq|*/devfreq/min_freq)
            [ "${val:-0}" -gt "${GPU_MAX_FREQ:-800000000}" ] 2>/dev/null && { dbg "GPU freq blocked: ${val} > ${GPU_MAX_FREQ} at $node"; return 1; } ;;
    esac
    case "$node" in
        */scaling_min_freq)
            local max_freq
            max_freq=$(cat "${node/scaling_min_freq/scaling_max_freq}" 2>/dev/null)
            [ -n "$max_freq" ] && [ "${val:-0}" -gt "${max_freq:-0}" ] 2>/dev/null && { printf '%s' "$val" > "${node/scaling_min_freq/scaling_max_freq}" 2>/dev/null; sleep 0.05; dbg "CPU min>max: raised max to ${val}Hz"; } ;;
    esac
    printf '%s' "$val" > "$node" 2>/dev/null
}

r() { cat "$1" 2>/dev/null || echo "0"; }

detect_kernel_features() {
    FEATURE_HOTPLUG=0; FEATURE_LRU_GEN=0; FEATURE_BOEFFLA=0
    FEATURE_WAKELOCK=0; FEATURE_SCHED_CASS=0; FEATURE_UCLAMP=0; FEATURE_THERMAL_WRITABLE=0
    [ -f /sys/devices/system/cpu/cpu0/online ] && FEATURE_HOTPLUG=1
    [ -d /sys/kernel/mm/lru_gen ] && FEATURE_LRU_GEN=1
    [ -f /sys/module/boeffla_wl_blocker/parameters/wl_blocker ] && FEATURE_BOEFFLA=1
    [ -f /sys/power/wake_lock ] && FEATURE_WAKELOCK=1
    grep -q "sched_cass" /proc/sched_debug 2>/dev/null && FEATURE_SCHED_CASS=1
    [ -f /dev/cpuset/top-app/uclamp.min ] && FEATURE_UCLAMP=1
    [ -d /sys/devices/virtual/thermal/thermal_zone0 ] && FEATURE_THERMAL_WRITABLE=1
    gpu_detect_max_freq
    log "Features: hotplug=$FEATURE_HOTPLUG lru=$FEATURE_LRU_GEN boeffla=$FEATURE_BOEFFLA uclamp=$FEATURE_UCLAMP thermal_w=$FEATURE_THERMAL_WRITABLE"
}

GPU_DRIVER_INSTALLED=0
gpu_detect_max_freq() {
    [ -f "$GPU/gpu_available_frequencies" ] || return
    local freqs avail max=0
    freqs=$(r "$GPU/gpu_available_frequencies")
    for avail in $freqs; do
        [ "${avail:-0}" -gt "$max" ] 2>/dev/null && max=$avail
    done
    GPU_MAX_FREQ=$max
    GPU_AVAIL_FREQS=$freqs
    dbg "GPU max freq: ${GPU_MAX_FREQ}Hz"
}

# ── CPU ─────────────────────────────────────────────────────────────────────
cpu_set() {
    local gov="$1" smin="$2" smax="$3" gmin="$4" gmax="$5"
    w "$P0/scaling_max_freq" "$smax"
    w "$P6/scaling_max_freq" "$gmax"
    sleep 0.1
    for _r in 0 1 2; do
        w "$P0/scaling_min_freq" "$smin"
        [ "$(r "$P0/scaling_min_freq")" -ge "$smin" ] 2>/dev/null && break
        w "$P0/scaling_max_freq" "$smax"; sleep 0.05
    done
    for _r in 0 1 2; do
        w "$P6/scaling_min_freq" "$gmin"
        [ "$(r "$P6/scaling_min_freq")" -ge "$gmin" ] 2>/dev/null && break
        w "$P6/scaling_max_freq" "$gmax"; sleep 0.05
    done
    w "$P0/scaling_governor" "$gov"
    w "$P6/scaling_governor" "$gov"
}

cpu_gaming() {
    cpu_set schedutil 768000 1516800 1036800 1804800
    dbg "CPU BALANCED: Silver 768-1516 Gold 1036-1804 schedutil"
    # CPU_BOOST: Touch-Input boost für sofortige Gold-Max
    [ -f /sys/module/cpu_boost/parameters/input_boost_freq ] && echo "0:1516800 6:1804800" > /sys/module/cpu_boost/parameters/input_boost_freq 2>/dev/null
    [ -f /sys/module/cpu_boost/parameters/input_boost_ms ] && echo "2000" > /sys/module/cpu_boost/parameters/input_boost_ms 2>/dev/null
}
# ── GPU ─────────────────────────────────────────────────────────────────────
gpu_gaming() {
    w $GPU/devfreq/governor        msm-adreno-tz
    w $GPU/force_clk_on            0
    w $GPU/force_bus_on            0
    w $GPU/bus_split               1
    w $GPU/thermal_pwrlevel        0
    w $GPU/max_pwrlevel            0
    w $GPU/min_pwrlevel            "$(echo "$GPU_AVAIL_FREQS" | awk '{n=split($0,a); for(i=1;i<=n;i++) if(a[i]==750000000||a[i]==650000000){print i-1; exit}} {print n-2}')"
    w $GPU/devfreq/max_freq        "650000000"
    w $GPU/devfreq/min_freq        "267000000"
    w $GPU/devfreq/polling_interval 20
    w $GPU/pwrscale                1
    printf '%s' "1" > "$GPU/throttling" 2>/dev/null || true
    dbg "GPU BALANCED: min 267MHz max ${GPU_MAX_FREQ}Hz throttling=1"
}

gpu_cooldown() {
    local level="$1"
    w $GPU/thermal_pwrlevel "$level"
    case "$level" in
        4) w $GPU/devfreq/max_freq "355000000"; w $GPU/devfreq/min_freq "267000000" ;;
        3) w $GPU/devfreq/max_freq "430000000"; w $GPU/devfreq/min_freq "342000000" ;;
        2) w $GPU/devfreq/max_freq "565000000"; w $GPU/devfreq/min_freq "430000000" ;;
        *) w $GPU/devfreq/max_freq "$GPU_MAX_FREQ"; w $GPU/devfreq/min_freq "267000000" ;;
    esac
    w $GPU/force_clk_on 1; w $GPU/force_bus_on 1
    printf '%s' "0" > "$GPU/throttling" 2>/dev/null || true
    dbg "GPU cooldown level=$level"
}

# ── CPU Hotplug ─────────────────────────────────────────────────────────────
cpu_hotplug_online_all() {
    [ "$FEATURE_HOTPLUG" = "0" ] && return 0
    local c
    for c in 0 1 2 3 4 5 6 7; do
        [ -f /sys/devices/system/cpu/cpu${c}/online ] || continue
        printf '%s' "1" > /sys/devices/system/cpu/cpu${c}/online 2>/dev/null || true
    done
}

# ── Thermal ─────────────────────────────────────────────────────────────────
thermal_trips_raise() {
    local target_temp="${1:-95000}"
    rm -f "$_TRIP_CACHE" 2>/dev/null
    local zone type tfile val
    for zone in /sys/devices/virtual/thermal/thermal_zone*/; do
        [ -d "$zone" ] || continue
        type=$(r "${zone}type")
        [ -z "$type" ] && continue
        echo "$type" | grep -Eqi "$_TRIP_SAFE" && continue
        for trip in 0 1 2 3 4 5 6 7 8 9 10 11; do
            tfile="${zone}trip_point_${trip}_temp"
            [ -f "$tfile" ] || continue
            val=$(r "$tfile")
            [ "${val:-0}" -lt 55000 ] && continue
            [ "${val:-0}" -lt "$target_temp" ] || continue
            printf '%s:%s:%s\n' "${zone##*/}" "$trip" "$val" >> "$_TRIP_CACHE"
            printf '%s' "$target_temp" > "$tfile" 2>/dev/null || true
        done
    done
    local count=0
    [ -f "$_TRIP_CACHE" ] && count=$(wc -l < "$_TRIP_CACHE" 2>/dev/null || echo 0)
    dbg "Thermal trips raised to $(( target_temp / 1000 ))°C, $count cached"
}

thermal_trips_restore() {
    [ -f "$_TRIP_CACHE" ] || return 0
    local zone trip val tfile
    while IFS=: read -r zone trip val 2>/dev/null; do
        [ -z "$zone" ] && continue
        tfile="/sys/devices/virtual/thermal/${zone}/trip_point_${trip}_temp"
        [ -f "$tfile" ] && printf '%s' "$val" > "$tfile" 2>/dev/null || true
    done < "$_TRIP_CACHE"
    rm -f "$_TRIP_CACHE" 2>/dev/null
    dbg "Thermal trips restored"
}

thermal_cooling_reset() {
    local _cd
    for _cd in /sys/devices/virtual/thermal/cooling_device*/; do
        case "$(cat "${_cd}type" 2>/dev/null)" in
            thermal-cpufreq-*)
                printf 0 > "${_cd}cur_state" 2>/dev/null || true
                ;;
        esac
    done
    dbg "Cooling devices reset"
}


thermal_cpu_temp() {
    local t
    t=$(r "$TZ_GOLD")
    [ -n "$t" ] && [ "$t" -gt -27400 ] 2>/dev/null && echo $(( t / 1000 )) && return
    t=$(r "$TZ_SILVER")
    [ -n "$t" ] && [ "$t" -gt -27400 ] 2>/dev/null && echo $(( t / 1000 )) && return
    [ -n "$TZ_FALLBACK" ] && t=$(r "$TZ_FALLBACK") && [ -n "$t" ] && echo $(( t / 1000 )) && return
    echo 95
}

_cache_thermal_zones() {
    TZ_GOLD=""; TZ_SILVER=""; TZ_FALLBACK=""
    local zone type
    for zone in /sys/devices/virtual/thermal/thermal_zone*/; do
        [ -d "$zone" ] || continue
        type=$(r "${zone}type")
        case "$type" in
            *cpu-1-0*|*gold*|*cpu6*|*cpu7*) [ -z "$TZ_GOLD" ] && TZ_GOLD="${zone}temp" ;;
            *cpuss-0*|*silver*|*cpu0*|*cpu1*|*cpu2*|*cpu3*|*cpu4*|*cpu5*) [ -z "$TZ_SILVER" ] && TZ_SILVER="${zone}temp" ;;
        esac
    done
    [ -f /sys/devices/virtual/thermal/thermal_zone0/temp ] && TZ_FALLBACK=/sys/devices/virtual/thermal/thermal_zone0/temp
    [ -z "$TZ_GOLD" ] && TZ_GOLD="$TZ_FALLBACK"
    [ -z "$TZ_SILVER" ] && TZ_SILVER="$TZ_FALLBACK"
    log "Thermal zones: Gold=$TZ_GOLD Silver=$TZ_SILVER"
}

# ── Scheduler ───────────────────────────────────────────────────────────────
sched_gaming() {
    echo "0-7" > "$CS_TOP/cpus"      2>/dev/null || true
    echo "0-7" > "$CS_FG/cpus"       2>/dev/null || true
    echo "0-3" > "$CS_SYS/cpus"      2>/dev/null || true
    echo "0-3" > "$CS_BG/cpus"       2>/dev/null || true
    echo "2-3" > "$CS_RESTRICT/cpus" 2>/dev/null || true
    [ "$FEATURE_UCLAMP" = "1" ] && {
        w "$CS_TOP/uclamp.min" 0; w "$CS_TOP/uclamp.max" 80
        w "$CS_TOP/uclamp.boosted" 0; w "$CS_TOP/uclamp.latency_sensitive" 0
        w "$CS_FG/uclamp.min"  0; w "$CS_FG/uclamp.max" 80
    }
    w /proc/sys/kernel/sched_upmigrate        80
    w /proc/sys/kernel/sched_downmigrate      60
    w /proc/sys/kernel/sched_energy_aware     1
    w /proc/sys/kernel/sched_boost            0
    w "$P0/schedutil/up_rate_limit_us"    500
    w "$P0/schedutil/down_rate_limit_us"  20000
    w "$P6/schedutil/up_rate_limit_us"    500
    w "$P6/schedutil/down_rate_limit_us"  20000
    w "$P0/schedutil/hispeed_load"        80
    w "$P0/schedutil/hispeed_freq"        1516800
    w "$P6/schedutil/hispeed_load"        80
    w "$P6/schedutil/hispeed_freq"        1804800
    w "$P0/schedutil/pl"                  0
    w "$P6/schedutil/pl"                  0
    dbg "Sched BALANCED: EAS=1 sched_boost=0 uclamp top=0-80 up_rate=2000 hispeed=80 pl=0"
}

# ── IO ──────────────────────────────────────────────────────────────────────
io_gaming() {
    local blk
    for blk in /sys/block/sd* /sys/block/mmcblk* /sys/block/dm-*; do
        [ -d "$blk/queue" ] || continue
        w "$blk/queue/scheduler"     deadline
        w "$blk/queue/read_ahead_kb" 128
        w "$blk/queue/nr_requests"   64
        w "$blk/queue/iostats"       0
        w "$blk/queue/add_random"    0
    done
}

# ── VM ──────────────────────────────────────────────────────────────────────
vm_gaming() {
    w /proc/sys/vm/swappiness              30
    w /proc/sys/vm/vfs_cache_pressure      50
    w /proc/sys/vm/dirty_ratio              15
    w /proc/sys/vm/dirty_background_ratio    5
    w /proc/sys/vm/dirty_expire_centisecs 3000
    w /proc/sys/vm/dirty_writeback_centisecs 500
    w /proc/sys/vm/extra_free_kbytes       8192
    w /proc/sys/vm/watermark_scale_factor    10
    w /proc/sys/vm/min_free_kbytes         8192
    w /proc/sys/vm/page-cluster              0
    dbg "VM BALANCED: dirty_expire=3000 dirty_ratio=15 watermark=10 min_free=8M"
}

vm_zram_reset() {
    swapoff /dev/block/zram0 2>/dev/null || true
    printf '%s' "1" > /sys/block/zram0/reset 2>/dev/null || true
    printf '%s' "3221225472" > /sys/block/zram0/disksize 2>/dev/null || true
    mkswap /dev/block/zram0 2>/dev/null
    swapon -p 0 /dev/block/zram0 2>/dev/null || true
}

# ── LRU_GEN ─────────────────────────────────────────────────────────────────
lru_gen_enable() {
    [ "$FEATURE_LRU_GEN" = "0" ] && return 0
    printf '%s' "1" > /sys/kernel/mm/lru_gen/enabled 2>/dev/null || true
}

# ── Boeffla Wakelock ─────────────────────────────────────────────────────────
wakelock_block() {
    [ "$FEATURE_BOEFFLA" = "0" ] && return 0
    for wl in "*PowerManagerService*" "*NfcService*" "*GMS*" "*SyncLoop*"; do
        printf '%s' "$wl" > /sys/module/boeffla_wl_blocker/parameters/wl_blocker 2>/dev/null || true
    done
    log "Wakelock Blocker: aktiv"
}

# ── IRQ ─────────────────────────────────────────────────────────────────────
apply_irq_affinity() {
    local touch_irq ufs_irq
    touch_irq=$(grep -l "GTX9896\|touch\|fts\|novatek" /proc/irq/*/actions 2>/dev/null | head -1 | grep -o '[0-9]\+')
    [ -n "$touch_irq" ] && printf '%s' "40" > /proc/irq/${touch_irq}/smp_affinity 2>/dev/null || true
    ufs_irq=$(grep -l "ufshcd\|ufs" /proc/irq/*/actions 2>/dev/null | head -1 | grep -o '[0-9]\+')
    [ -n "$ufs_irq" ] && printf '%s' "02" > /proc/irq/${ufs_irq}/smp_affinity 2>/dev/null || true
    local dir name
    for dir in /proc/irq/*/; do
        [ -f "${dir}smp_affinity" ] || continue
        name=$(r "${dir}actions")
        echo "$name" | grep -Eqi "wlan|rmnet|gsi|^ipa" && printf '%s' "04" > "${dir}smp_affinity" 2>/dev/null || true
    done
    dbg "IRQ affinity: Touch→cpu4 UFS→cpu1 Net→cpu2"
}

# ── LMH ─────────────────────────────────────────────────────────────────────
lmh_disable() {
    [ -d /sys/kernel/lmh_dcvs ] || { dbg "LMH DCVS not available (v4.2.5+)"; return 0; }
    local node
    for node in /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq; do
        [ -f "$node" ] || continue
        local max; max=$(r "${node%/scaling_max_freq}/scaling_max_freq")
        [ -n "$max" ] && [ "$max" -lt 1000000 ] 2>/dev/null && {
            local policy; policy=$(echo "$node" | grep -o 'policy[0-9]')
            [ -n "$policy" ] && w "/sys/devices/system/cpu/cpufreq/${policy}/scaling_max_freq" 1804800
        }
    done
    for node in /sys/module/msm_performance/parameters/*; do
        [ -f "$node" ] || continue
        case "$(basename "$node")" in *limit*|*thermal*|*dcvs*) printf '%s' "0" > "$node" 2>/dev/null || true ;; esac
    done
    w "$P6/scaling_max_freq" 1804800
    # schedutil rate limits: schnelleres Hochtakten für Gaming
    echo 500 > "/sys/devices/system/cpu/cpufreq/policy6/schedutil/up_rate_limit_us" 2>/dev/null || true
    echo 20000 > "/sys/devices/system/cpu/cpufreq/policy6/schedutil/down_rate_limit_us" 2>/dev/null || true
    echo 500 > "/sys/devices/system/cpu/cpufreq/policy0/schedutil/up_rate_limit_us" 2>/dev/null || true
    echo 20000 > "/sys/devices/system/cpu/cpufreq/policy0/schedutil/down_rate_limit_us" 2>/dev/null || true
}

# ── Network ─────────────────────────────────────────────────────────────────
net_gaming() {
    local iface
    iface=$(ip route show default 2>/dev/null | grep -o "dev [^ ]*" | head -1 | cut -d' ' -f2)
    w /proc/sys/net/ipv4/tcp_congestion_control cubic
    w /proc/sys/net/ipv4/tcp_sack               1
    w /proc/sys/net/ipv4/tcp_dsack              1
    w /proc/sys/net/ipv4/tcp_low_latency        0
    w /proc/sys/net/ipv4/tcp_retries2           8
    w /proc/sys/net/core/rmem_max               524288
    w /proc/sys/net/core/wmem_max               524288
    w /proc/sys/net/ipv4/tcp_rmem               "4096 131072 524288"
    w /proc/sys/net/ipv4/tcp_wmem               "4096 16384 524288"
    for iface in $(ip link show up 2>/dev/null | grep -o "wlan[0-9]*"); do
        iw dev "$iface" set power_save off 2>/dev/null || true
    done
    [ "${CFG_NET_QOS:-0}" = "1" ] && net_qos_apply "$iface"
    dbg "Net BALANCED: cubic low_latency=0 retries=8 512K buffers"
}

net_qos_apply() {
    local iface="$1"
    [ -z "$iface" ] && return 0
    tc qdisc del dev "$iface" root 2>/dev/null || true
    tc qdisc add dev "$iface" root handle 1: htb default 30 2>/dev/null || true
    tc class add dev "$iface" parent 1: classid 1:1 htb rate 1000mbit ceil 1000mbit 2>/dev/null || true
    tc class add dev "$iface" parent 1:1 classid 1:10 htb rate 800mbit ceil 1000mbit prio 1 2>/dev/null || true
    tc class add dev "$iface" parent 1:1 classid 1:20 htb rate 150mbit ceil 500mbit prio 2 2>/dev/null || true
    tc class add dev "$iface" parent 1:1 classid 1:30 htb rate 50mbit ceil 200mbit prio 3 2>/dev/null || true
    tc filter add dev "$iface" parent 1: protocol ip u32 match ip dport 3074 0xffff flowid 1:10 2>/dev/null || true
    tc filter add dev "$iface" parent 1: protocol ip u32 match ip sport 3074 0xffff flowid 1:10 2>/dev/null || true
    dbg "QoS HTB on $iface"
}

# ── Thread Pinning ──────────────────────────────────────────────────────────
tune_gaming() {
    local pkg="${1:-$CODM_PKG}"
    local main_pid
    main_pid=$(pidof "$pkg" 2>/dev/null | awk '{print $1}')
    [ -z "$main_pid" ] && return 0
    local tid tname render_mask worker_mask
    render_mask="0xc0"; worker_mask="0x3f"
    [ "${CFG_CPU_HOTPLUG:-0}" = "1" ] && render_mask="0xf0" && worker_mask="0xf0"
    for tid in /proc/"$main_pid"/task/*/; do
        tid="${tid%/}"; tid="${tid##*/}"
        [ -f "/proc/$main_pid/task/$tid/comm" ] || continue
        tname=$(cat "/proc/$main_pid/task/$tid/comm" 2>/dev/null)
        case "$tname" in
            *RenderThread*|*UnityMain*|*GLThread*) taskset -p $render_mask "$tid" >/dev/null 2>&1; chrt -f -p 1 "$tid" 2>/dev/null || true ;;
            *AudioMixer*|*AudioTrack*) taskset -p 0x3f "$tid" >/dev/null 2>&1; chrt -f -p 1 "$tid" 2>/dev/null || true ;;
        esac
    done
    local ap; ap=$(pidof audioserver 2>/dev/null | awk '{print $1}')
    renice -n -10 "$main_pid" 2>/dev/null || true
    echo -17 > "/proc/$main_pid/oom_adj" 2>/dev/null || true
    [ -n "$ap" ] && taskset -p 0x3f "$ap" >/dev/null 2>&1
}

# ── Props ───────────────────────────────────────────────────────────────────
props_gaming() {
    setprop debug.sf.disable_backpressure             1 2>/dev/null || true
    setprop debug.sf.enable_gl_backpressure           0 2>/dev/null || true
    setprop persist.sys.game_mode                      1 2>/dev/null || true
    setprop persist.sys.vulkan.perf_mode               1 2>/dev/null || true
    setprop persist.vendor.qti.games.gt.fps           120 2>/dev/null || true
}

# ── Cache / RAM ─────────────────────────────────────────────────────────────
clean_cache() {
    sync
    printf '%s' "3" > /proc/sys/vm/drop_caches 2>/dev/null || true
    printf '%s' "0" > /proc/sys/vm/drop_caches 2>/dev/null || true
    date +%s > "$MODDIR/config/cache_last_cleaned" 2>/dev/null || true
}

clean_ram() {
}
    sync
    printf '%s' "3" > /proc/sys/vm/drop_caches 2>/dev/null || true
    printf '%s' "1" > /proc/sys/vm/compact_memory 2>/dev/null || true
    printf '%s' "0" > /proc/sys/vm/drop_caches 2>/dev/null || true

thermal_disable() {
    thermal_trips_raise
    thermal_cooling_reset
    log "Thermal: trips raised"
}

# ── GPU Adaptive ─────────────────────────────────────────────────────────────
gpu_adaptive() {
    local busy max_freq
    busy=$(cat /sys/class/kgsl/kgsl-3d0/gpu_busy_percentage 2>/dev/null || echo 0)
    busy=${busy%\%}
    case "$busy" in
        ''|*[!0-9]*) busy=0 ;;
    esac
    if   [ "$busy" -lt 30 ] 2>/dev/null; then
        max_freq=355000000
    elif [ "$busy" -lt 65 ] 2>/dev/null; then
        max_freq=650000000
    else
        max_freq=800000000
    fi
    local cur; cur=$(cat /sys/class/kgsl/kgsl-3d0/devfreq/max_freq 2>/dev/null || echo 0)
    [ "$cur" != "$max_freq" ] && w /sys/class/kgsl/kgsl-3d0/devfreq/max_freq "$max_freq"
    dbg "GPU adaptive: busy=${busy}% → max_freq=${max_freq}Hz"
}
