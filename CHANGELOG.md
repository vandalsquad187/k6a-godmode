# Changelog – k6a-godmode

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
