# Changelog – k6a-godmode

## v2.4 – Auslieferungszustand 🏆

### Kernel v4.2.6 (vandalsquad187)
- **vbat/BCL per DT disabled** – CPU FREEZE eliminiert
- **Cooling-Floor dynamisch** – CPU nie unter 1,5 GHz beim Gaming, Sicherheit bei >90°C
- **libperfmgr-Sentinel silent drop** – dmesg sauber

### GPU adaptiv (650–800 MHz)
- gpu_busy_percentage live ausgewertet
- < 30% → 355 MHz (idle/Looten)
- 30–65% → 650 MHz (normales Gaming)
- > 65% → 800 MHz (Kampf/Boost)

### CODM Priority
- renice -n -10 für CODM-Prozess
- oom_adj = -17 verhindert Kill mitten im Match

### Selbstheilung
- service.sh mit while true-Loop
- Controller crasht → automatischer Neustart nach 5s

### schedutil Fine-Tuning
- up_rate_limit_us 2000 → 500 (schnelleres Hochtakten)
- down_rate_limit_us 10000 → 20000 (Frequenz länger halten)

### Watchdog entschlackt
- Cooling-Reset + CPU-FREEZE-ReApply entfernt (überflüssig durch Kernel-Floor)
- thermal_bcl_disable komplett raus (Zonen per DT tot)

---

## v2.3 – Cleanup

- thermal_bcl_disable() entfernt (vbat/BCL per DT deaktiviert)
- Cooling-Reset + CPU-FREEZE aus Watchdog entfernt
- One-shot Reset in thermal_disable() bleibt

---

## v2.2 – Stabilität

- GPU-Limit 650 MHz (später 750 MHz)
- Cooling-Reset alle 10s im Watchdog (Yo-Yo-Fix)
- _TRIP_SAFE + 55°C-Guard für quiet_therm
- Temp-Sensor-Pfade fixiert (zone26/24)

---

## v2.1 – Root-Cause

- CPU FREEZE durch vbat-Zonen identifiziert
- thermal_bcl_disable implementiert
- thermal_cooling_reset für cpufreq-cdevs

---

## v2.0 – Initial

- Basis-Features: CPU/GPU/Sched/IO/VM/IRQ/Net/Props
- God-Mode Toggle
- Thermal-Protect (85°C Schwelle)
- Wakelock Blocker
- LRU-GEN Enabler
