# Changelog – k6a-godmode

## v2.5.4 – SchedTune Boost + GPU force_no_nap

### SchedTune Boost (80)
- `schedtune.boost=80`: Top-App-Tasks bevorzugt auf Gold-Kernen
- `schedtune.prefer_high_cap=1`: Scheduler wählt schnellere (energiehungrige) Kerne
- Messbar höhere FPS in GPU-bound Szenarien (CODM Kampf)

### GPU force_no_nap=1
- GPU bleibt zwischen Frames aktiv, kein Nap-Idle
- Reduziert Latenz-Spitzen bei Lastwechseln

### GPU throttling=0
- Kernel-seitige GPU-Thermaldrosselung deaktiviert
- GPU hält volle Leistung bis zum _THP-Cooldown (default 78°C)

### mkdir-Lock (flock-Ersatz)
- `flock` via shell-Redirection (`} 9>...`) hielt Lock nicht über Funktionsgrenzen
- `mkdir` atomar + PID-basierte Stale-Erkennung
- SIGKILL-sicher: Lock stirbt mit Prozess (trap EXIT räumt auf)

### Bugfixes
- `_startup()` wurde definiert aber nie aufgerufen → fehlender Lock-Check
- `gpu_busy_percentage` enthielt Prozentzeichen → `0%%` in WebUI
- sed auf toybox scheiterte an `/`-Delimiter mit `.`-Wildcard
- `setTimeout(refreshData,500)` lag global → wurde nur einmal beim Seitenladen ausgeführt

---

## v2.5.3 – GPU-Clamp + Polling-Interval

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
