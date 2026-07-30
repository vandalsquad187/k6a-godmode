# Changelog – k6a-godmode

## v2.11 – GPU-Bugfix + Kernel-Synergie

### Neuer Kernel: BadazzKernel mit k6a-Optimierungen
- **CONFIG_MSM_PERFORMANCE=y** → `lmh_disable()`-Writes auf `msm_performance/parameters/` wirken endlich
- **CONFIG_CPU_FREQ_TIMES=y** → `time_in_state` für CPU-Frequenzstatistiken verfügbar
- **CONFIG_PSI=y** → `/proc/pressure/cpu|memory|io` für Last-Erkennung
- **GPU thermal floor Bugfix** → Lokale statics in `_adjust_pwrlevel()` entfernt, sysfs-Writes wirken jetzt

### Modul-Seite: Korrigierte sysfs-Pfade
- CPU Cooling Floor: `/sys/kernel/k6a_thermal/` (vorher falsch: `thermal_floor/`)
- GPU thermal floor: `/sys/kernel/k6a_gpu_thermal/thermal_floor/` (vorher falsch: `gpu_thermal_floor/`)
- `gpu_thermal_floor_levels` als combined File mit 3 space-sep Werten (vorher 5 Einzel-Nodes)
- God-Mode-ON: Gaming-Werte (85/90/95°C CPU, 0 1 2 + 75/90°C GPU)
- God-Mode-OFF: Default-Restore (80/90/92°C, 5 4 3 + 70/85°C)

### addkernel.txt
- Bauplan für Kernel-Optimierungen unter `/storage/emulated/0/Download/`
- 6 Punkte: 3x defconfig + 1x Bugfix + Modul-Seite + Build-Reihenfolge

---

## v2.5.5 – Stale-Lock-Fix (PID-Recycling)

### Problem
Nach Kernel-Update / Reboot blieb der Controller tot:
- Lock-Datei mit alter PID `3298` blieb erhalten
- `kill -0 3298` traf zu (PID wurde von Android an anderen Prozess vergeben)
- Controller dachte "läuft schon" → `exit 1`
- `rmdir` im trap schlug fehl (pid-File noch im Dir) → Lock blieb ewig

### Fix
- **`_startup()`**: Verifiziert via `grep -q "k6a-controller" /proc/$pid/cmdline` ob der Prozess wirklich unser Controller ist
- **Stale-Lock-Meldung**: Zeigt an, welchem Prozess der PID gehört
- **trap**: `rm -rf "$LOCKDIR"` statt `rmdir` (löscht auch nicht-leere Dirs)

### v2.5.4 – SchedTune Boost + GPU force_no_nap

### GPU-Adaptive Safety-Clamp
- `gpu_adaptive()`: max_freq wird nie unter devfreq/min_freq gesetzt
- Statt hardgecodedem min_allowed=355M → dynamisch via devfreq/min_freq

### GPU Gaming optimiert
- `throttling=1` (Kernel-Throttle aktiv)
- `force_bus_on=0` (Bus Power Collapse erlaubt)
- `bus_split=1` (Bus-Splitting aktiv)
- `polling_interval=20` (weniger CPU-Last durch Gov)
- `max_freq=650000000` (explizit statt $GPU_MAX_FREQ)

### Changelog + Module-Icons
- CHANGELOG.md aktualisiert mit allen v2.5.x Einträgen
- icon1.png + background.png im Repo (für KSU Manager)

---

## v2.5.2 – GPU-Konflikte gelöst

### force_clk_on=1 (Fix: GPU Power-Collapse Freezes)
- GPU force_clk_on=1 – verhindert Power-Collapse der GPU-Clock
- Behebt Framedrops (50→30fps nach 1h CODM) durch Adreno-Treiber-Konflikt
- GPU `min_pwrlevel=4` (355 MHz Floor)
- GPU `devfreq/min_freq=355M` (doppelte Absicherung)

### Blackscreens behoben
- `lmh_disable` + `thermal_disable` in `_god_on()` nur noch bei `_THP=1`
- Bei `_THP=0` bleiben Kernel-Thermal-Safeguards aktiv → keine Blackscreens
- K6Analyze-Logs bestätigt: kein Crash, kein Watchdog, kein Overheating (max 68.7°C)

### PID-Recycling-Fix
- `_startup()`: `kill -0` + `/proc/$op/comm` Check auf `k6a-controller|sh`
- service.sh: `while true` Restart entfernt → einmaliger `nohup ... &`

---

## v2.5.1 – Blackscreen-Fix: Thermal nur bei THP=1
- `lmh_disable` und `thermal_disable` nur noch bei `_THP=1`
- Bei `_THP=0` (default) bleibt Kernel-Thermal intakt
- Verhindert Blackscreens durch Zerstörung des Kernel-Thermal ohne Modul-Cooldown

---

## v2.5 – Thermal-Tamed (data-driven) 🔥

### Analyse-basierte Optimierung
Nach 57 Min CODM Battle Royale mit K6Analyze:
- GPU 800 MHz Boost nur 4x getriggert (0.2% der Zeit)
- GPU Throttle auf 267 MHz bei Gold >80C (das eigentliche Problem)
- Gold CPU erreicht 83.2C, GPU bleibt bei 57-60C kuhl

### GPU adaptive (355/650 MHz – ohne 800er Boost)
- 800 MHz Boost entfernt (kein Performance-Verlust, spart Hitze)
- GPU max: 650 MHz fur Gaming, 355 MHz fur Idle
- Wattlos: thermal_pwrlevel Watchdog bei >4 (267 MHz) unter Last

### GPU minimum 355 MHz
- gpu_gaming(): min_freq=355 statt 267 MHz
- gpu_cooldown() Level 4: min=355 statt 267 MHz
- Kein abrupter Throttle auf 267 MHz mehr moglich

### _THP fruher aktiv (78C statt 85C)
- thermal_cooking_thresh=78 (default in settings.conf)
- _THP greift ab 78C mit GPU Level 2 (565 MHz)
- Bei 80C+ Level 3 (430 MHz) – verhindert den 267 MHz Throttle-Crash

### K4Analyze – Diagnose-Modul (Begleitmodul)
- Separates Modul: /data/adb/modules/K4Analyze/
- Echtzeit-Logging aller CPU/GPU/Temp/Battery-Werte
- Anomalie-Erkennung (CPU FREEZE, GPU Throttle, Temp Peaks)
- Report-Generator fur Session-Analyse
- WebUI Dashboard (2 Kacheln/Zeile, 16px Font)

---

## v2.4 – Auslieferungszustand

### Kernel v4.2.6 (vandalsquad187)
- vbat/BCL per DT disabled – CPU FREEZE eliminiert
- Cooling-Floor dynamisch – CPU nie unter 1,5 GHz beim Gaming
- libperfmgr-Sentinel silent drop – dmesg sauber

### GPU adaptive (650-800 MHz)
- gpu_busy_percentage live: <30% = 355 | 30-65% = 650 | >65% = 800

### CODM Priority + Selbstheilung + schedutil 500/20000

---

## v2.3 – Cleanup
- thermal_bcl_disable entfernt, Watchdog entschlackt

## v2.2 – Stabilitat
- GPU 650 MHz, Cooling-Reset alle 10s, _TRIP_SAFE

## v2.1 – Root-Cause
- CPU FREEZE durch vbat identifiziert

## v2.0 – Initial
- Basis-Features, God-Mode, Thermal-Protect
