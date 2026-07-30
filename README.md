<div align="center">
  <img src="assets/logo.png" alt="Badazz89" width="120"/>
  <h1>k6a-godmode v2.10</h1>
  <p>Unified Gaming-Mode für SM7150 – optimiert für BadazzKernel</p>
  <p>
    <img src="https://img.shields.io/badge/Version-2.10-green?style=flat-square">
    <img src="https://img.shields.io/badge/Kernel-BadazzKernel%204.14.369-blue?style=flat-square">
    <img src="https://img.shields.io/badge/API-Magisk%20%7C%20KSU%20%7C%20APatch-orange?style=flat-square">
  </p>
</div>

---

# k6a-godmode v2.10

Unified Gaming-Mode für **SM7150 (sweet/sweet2)** — Thermal-Profile, Cooldown-Hysterese, Thresholds-UI, Atomic Write, Watchdog.

## Voraussetzung

**BadazzKernel** (empfohlen) oder jeder SM7150-Kernel ab v4.14.369:

| Patch | Beschreibung |
|-------|-------------|
| vbat/BCL per DT disabled | CPU FREEZE eliminiert |
| Cooling-Floor dynamisch | CPU nie unter 1,5 GHz beim Gaming |
| libperfmgr silent drop | Kein dmesg-Spam bei min>max |

Ohne diese Patches arbeitet das Modul ineffizient (CPU FREEZE, Yo-Yo).

## Features

### Unified Governor (v2.8)
- `gpu_adaptive()` + `_do_cooldown()` verschmolzen – eine Stelle regelt GPU
- **Cooldown-Hysterese**: 10s Mindestzeit pro Stufe (L4→L3→L2→active) – kein Pendeln
- GPU-Watchdog: reset bei stuck pwrlevel > 4
- GPU-Adaptive: volle Leistung bei busy>70% + temp<75°C

### Thermal-Protect (THP)
- 4 Cooldown-Stufen L2/L3/L4 mit konfigurierbaren Schwellen
- Alle Grenzen via WebUI-Slider live anpassbar
- Android-Notification bei L3/L4 (via Notification-Channel)
- God-Mode OFF restored originale Trip-Temperaturen

### Controller-Watchdog (v2.7)
- `service.sh` startet Controller in `while true`-Loop
- Automatischer Restart nach 6s bei Crash
- Crash-Zähler mit 30s Backoff bei >3 Crushes

### CPU & Scheduler
- schedutil up_rate_limit_us=500 / down_rate_limit_us=20000
- taskset auf Gold-Kerne (RenderThread, GLThread, UnityMain)
- CHRT FIFO-Priorität für Render-Threads
- Cooldown-Gold-Max pro Stufe konfigurierbar

### GPU
- 8 Pwrlevel (825/800/650/565/430/355/267/180 MHz)
- gpu_gaming(): force_clk_on=1, throttling=1, bus_split=1
- gpu_cooldown(): pro Stufe konfigurierbar (L2=565/L3=430/L4=355 MHz)
- Atomic Write: data.txt via Tempfile + mv – kein Toggle-Blinken

### WebUI
- **Home-Tab**: Live-Thermal-State, Temp, CPU/GPU MHz, RAM, Bat
- **Settings-Tab**: 11 Threshold-Slider (Temps + GPU/Gold max)
- **Thermal-Profile**: 1-Klick-Buttons 🔥 Badazz / 🎮 Gaming / 🔋 Battery in der Thresholds-Card
- **Console-Tab**: CPU/GPU Boost, Governor-Wechsel, Log, Debug
- **revertTune()**: Setzt alle Sub-Toggles zurück auf Default
- Accent-Farbe wählbar, Fullscreen, Ripple-Effekt

### Sonstiges
- Wakelock Blocker (Boeffla)
- LRU-Gen Enabler
- WiFi-Boost (bbr/cubic)
- fstrim alle 10s
- Kernel-Fallback für Temp-Sensoren
- Stale-Lock-Erkennung mit PID-Verifikation

## Installation

1. BadazzKernel flashen
2. Modul per KernelSU / Magisk / APatch installieren
3. Neustart
4. WebUI öffnen (KernelSU App → Modul → k6a-godmode)
5. God-Mode aktivieren

## WebUI Toggles

| Button | Funktion |
|--------|----------|
| God-Mode | Aktiviert alle Gaming-Tweaks |
| Thermal Protect | Cooldown-Stufen L2/L3/L4 |
| WiFi Boost | TCP bbr/cubic |
| GPU | GPU-Tuning (governor, freq, force_clk_on) |
| Sched | Scheduler-Tuning (schedutil, taskset) |
| IO | I/O-Scheduler + read_ahead |
| VM | VM-Parameter (swappiness, dirty_ratio) |
| IRQ | IRQ-Affinität auf Gold-Kerne |
| Net | Netzwerk-Tuning (buffers, backlog) |
| Props | System-Properties (render, sf, gpu) |

## Dateistruktur

```
/data/adb/modules/k6a_tune/
  bin/
    k6a-controller      Haupt-Loop (Unified Governor, Watchdog)
    k6a-lib.sh          Library (GPU, CPU, Thermal, Sched, Props)
  config/
    settings.conf       Alle Toggle + Threshold-Konfiguration
    god_mode            God-Mode State (0/1)
    thermal_protect     Thermal-Protect State (0/1)
  webroot/
    index.html          WebUI (Home/Console/Settings)
    data.txt            Live-Daten (polled alle 2s)
    log.txt             Letzte 30 Log-Zeilen
  run/
    lock/               Lock-Directory mit PID
    crash_count         Crash-Zähler für Backoff
    thermal_state       Aktueller _TSTATE für gpu_adaptive
  service.sh            Boot-Script (Watchdog-Loop)
  module.prop           Magisk-Metadaten
  CHANGELOG.md
```

## Changelog

Siehe [CHANGELOG.md](CHANGELOG.md)

## Credits

- BadazZ89 – Modul-& Kernel Entwicklung
- vandalsquad187 – [BadazzKernel](https://github.com/vandalsquad187/BadazzKernel)

## Lizenz

MIT
