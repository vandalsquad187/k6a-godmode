# k6a-godmode v2.4

GPU-adaptives God-Mode für **SM7150 (sweet/sweet2)** mit **v4.2.6 Kernel** – entwickelt und optimiert für CODM Battle Royale.

## Voraussetzung

**Kernel v4.2.6+ (vandalsquad187)** mit folgenden Patches:

| Patch | Beschreibung |
|-------|-------------|
| vbat/BCL per DT disabled | pm6150.dtsi: status=disabled fuer alle pm6150-bcl und pm6150-vbat Zonen. CPU FREEZE durch low_limits_cap-Governor eliminiert. |
| Cooling-Floor dynamisch | cpu_cooling.c: max_state temperaturabhaengig. Unter 75 Grad nie unter 1,5 GHz Gold, bei >90 Grad volle Kuehlung. |
| libperfmgr silent drop | cpufreq.c: bei min > max wird der Write ignoriert statt -EINVAL (kein dmesg-Spam). |

Ohne diese Kernel-Patches arbeitet das Modul ineffizient (CPU FREEZE, Yo-Yo).

## Features

### GPU adaptiv (355/650/800 MHz)
- gpu_busy_percentage live ausgewertet - alle 5s
- unter 30% Last: 355 MHz (Idle, Looten)
- 30-65% Last: 650 MHz (normales Gaming)
- ueber 65% Last: 800 MHz (Kampf, Boost)

### CPU & Scheduler
- Cooling-Floor im Kernel (nie unter 1,5 GHz beim Gaming)
- schedutil up_rate_limit_us = 500 (schnelles Hochtakten)
- schedutil down_rate_limit_us = 20000 (Frequenz halten)
- taskset auf Gold-Kerne (RenderThread, GLThread, UnityMain)
- CHRT FIFO-Prioritaet fuer Render-Threads

### CODM Priority
- renice -n -10 direkt auf CODM-Prozess
- oom_adj = -17 verhindert Kill bei Memory Pressure

### Thermal
- Trip-Temperaturen auf 95 Grad angehoben (ausser Safe-Zonen)
- _TRIP_SAFE schuetzt Battery, Touch, Charger, BMS
- 55 Grad Guard fuer quiet_therm-step
- _THP drosselt GPU bei >85 Grad (optional, ueber WebUI)

### Selbstheilung
- service.sh mit while true-Loop
- Controller crasht - automatischer Neustart nach 5s

### Sonstiges
- Wakelock Blocker
- LRU-GEN Enabler
- Netzwerk-Tuning (wlan power_save off)
- fstrim alle 10s
- Kernel-Fallback fuer Temp-Sensoren

## Installation

1. Kernel v4.2.6+ flashen
2. Modul per KernelSU / Magisk installieren
3. Neustart
4. WebUI oeffnen (KernelSU App - Modul - k6a-godmode)
5. k6a enable

## WebUI Toggles

| Button | Funktion |
|--------|----------|
| God-Mode | Aktiviert alle Gaming-Tweaks |
| Thermal Protect | GPU-Drossel bei >85 Grad (optional) |
| GPU | GPU-Tuning an/aus |
| Sched | Scheduler-Tuning an/aus |
| IO | I/O-Scheduler + read_ahead |
| VM | VM-Parameter |
| IRQ | IRQ-Affinitaet |
| Net | Netzwerk-Tuning |
| Props | System-Properties |

## Dateistruktur

```
/data/adb/modules/k6a_tune/
  bin/
    k6a-controller      Haupt-Loop (Watchdog, GPU-adaptive)
    k6a-lib.sh          Library (GPU, CPU, Thermal, Sched)
  config/
    settings.conf       Toggle-Konfiguration
    god_mode            God-Mode State (0/1)
    thermal_protect     Thermal-Protect State (0/1)
  webroot/
    index.html          WebUI
  service.sh            Boot-Script (Selbstheilung)
  module.prop           Magisk-Metadaten
  CHANGELOG.md
```

## Changelog

Siehe CHANGELOG.md

## Credits

- BadazZ89 - Modul-Entwicklung
- vandalsquad187 - Kernel v4.2.6
- WeAreRavenS - Inspiration

## Lizenz

MIT
