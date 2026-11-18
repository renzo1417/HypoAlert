# HypoAlert (Symptom-Based Nocturnal Hypoglycemia Guardian)

> **Non-Invasive Nocturnal Hypoglycemia Symptom Detection for HarmonyOS NEXT & Huawei Health**  
> Measures real physiological symptom changes (`ΔHR`, `HRV RMSSD/SDNN`, `8–12 Hz` wrist tremor, and motion gating) with Phase 1–3 calibration and safety guardrails—never fabricating blood glucose numbers from watch sensors.

---

## Clinical Architecture (Phases 1 → 3)

### 1. One-Time Setup (Before Night 1)
The user provides **age**, **years with Type 1 diabetes**, and **body response type**:
- **Adrenergic:** reacts to lows with a fast heart rate and shaking.
- **Bradycardic / Blunted:** has a quieter or flat pulse response to lows.

### 2. Every Night's Safety Rules (Identical Across All Phases)
- **First 75 minutes (`15 × 5-min` sedentary slots):** silent baseline warm-up so the watch learns what normal sleep looks like tonight.
- **After 75 minutes:** checks every **5 minutes** only while sedentary (motion-gated when moving/awake).
- **Persistence Filter (no single 5-minute spike can alert on its own):**
  - **Adrenergic:** `3` elevated checks in a row (`~15 min`)
  - **Bradycardic / Blunted:** `2` elevated checks in a row (`~10 min`)
- **Cooldown & Cap:** `30-minute` cooldown between alerts, max `2` alerts per night.

### 3. Progressive Calibration (What "High" Means)
- **Phase 1 (Days 1–7 — Safe Warm-Up):** Fixed formula (`score >= 3.7`). Gentle buzz + *"Possible low — please check"* alert; user logs finger-prick blood sugar checks.
- **Phase 2 (Days 8+ — Personal Cutoff):** After 7 nights with `>= 3` buzz-linked finger-pricks, replaces `3.7` with the user's quiet-night 95th-percentile threshold (`>= 3.7`).
- **Phase 3 (Weeks 2–3+ — Smart 1D-CNN):** Unlocks once finger-pricks prove `>= 1` real low (`< 70 mg/dL`) and `>= 10` normal nights (`70+ mg/dL`). Runs a causal 60-minute (`L = 12`) 1D-CNN (`DualHead_multitask_smoothap`, `498` inference params / `0.49 KB int8` / `122 µs` Cortex-M33), with optional `A2` personal adaptation of the last 9 weights.

---

## Project Structure

```text
Huawei/
├── AppScope/
├── entry/src/main/ets/
│   ├── models/
│   │   ├── VitalsModel.ets            # Symptom engine (4 signals + motion gate + Phase 1-3 safety rules)
│   │   └── HistoryModel.ets           # Multi-night peak risk, finger-prick checks & Phase 1-3 gate tracking
│   ├── watch/
│   │   ├── WatchPage.ets              # Circular 466×466 wearable controller
│   │   └── components/                # WatchMonitorView, WatchHistoryView, WatchSettingsView, WatchAlertView
│   ├── phone/
│   │   ├── PhonePage.ets              # Companion 3-tab phone controller (Monitor, History, Guardian)
│   │   ├── views/                     # MonitorView (with finger-prick check-in), TrendsView, FamilyView
│   │   └── components/                # PhoneHeroCard, PhoneMetricGrid, DemoSheet, PhoneTopBar
│   └── services/                      # AlertService (@ohos.vibrator), DeviceConnectionManager
├── health-companion-demo/             # Interactive Huawei Health Companion + Watch Mirror web demo UI
│   ├── index.html
│   ├── styles.css
│   └── app.js
└── ai/
    └── dsp_hypoglycemia_pipeline.py   # Reference motion-gating, within-night baseline & Phase 1 score script
```

---

## Testing & Verification

### HarmonyOS Build & Unit Tests
```bash
hvigorw assembleHap --no-daemon
hvigorw test --no-daemon
```

### Huawei Health Companion Demo (Browser)
Open `health-companion-demo/index.html` in any modern browser (or run `python3 -m http.server 8080` in `health-companion-demo/`) to interact with the **Huawei Health Companion UI** and **Live Circular Watch Mirror** side by side.

---

## Planned Next Phase (Huawei Cloud)
- **Huawei Cloud ECS, RDS, DCS for Redis, SMN, OBS/ModelArts** for real-time telemetry sync, persistent calibration history, caregiver SMS dispatch, and hosted Visual Demo URL.
