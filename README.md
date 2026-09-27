# HypoAlert (低血糖夜间守护系统)

> **Nocturnal Hypoglycemia Detection & Cross-Device Guardian for HarmonyOS NEXT**  
> Autonomous wearable vital-sign analysis paired with a light family companion dashboard.

---

## 📖 About The Project

**Nocturnal hypoglycemia** is one of the most dangerous complications of diabetes. During sleep, physiological counter-regulatory adrenaline responses are blunted, and patients frequently fail to awaken during precipitous glucose drops—leading to nocturnal seizures, loss of consciousness, or severe neuroglycopenia.

**HypoAlert** is a cross-device medical application developed in **ArkTS / ArkUI for HarmonyOS NEXT**. It bridges wearable physiological sensing on Huawei smartwatches with remote family oversight on smartphones:

1. **Huawei Watch (Autonomous Wearable)**:  
   Operates independently on the patient's wrist throughout the night. Fuses optical photoplethysmogram (**PPG**) heart rate variability, peripheral **skin temperature**, and inertial (**IMU**) micro-tremor power spectral density (**PSD**). If a critical drop is detected, it immediately activates local hardware haptics (`@ohos.vibrator`) and acoustic alerts—even if disconnected from the phone.
2. **Companion Phone (Light Family Dashboard)**:  
   Provides parents and caregivers with a light, non-alarmist family dashboard organized into **4 dedicated screens** with bottom tab navigation, emergency SMS dispatch via **Huawei Cloud SMN**, overnight trend curves, and real-time vital streams.
3. **Dynamic Device Router**:  
   The application entry point automatically identifies whether the host hardware is a **Phone** or a **Wearable** (with display aspect ratio fallbacks for DevEco Studio previewers), routing to the appropriate interface seamlessly.

---

## 🎨 Design System & Palette

HypoAlert follows a calm, tactile "Night Guardian" aesthetic designed to reassure families while providing instant clarity during crises:

| Role | Color | Hex Code | Purpose |
| :--- | :--- | :--- | :--- |
| **Page Surface** | Light Slate | `#EEF2F7` | Soft, daylight-neutral backdrop avoiding stark dark modes |
| **Cards** | Pure White | `#FFFFFF` | Rounded cards (radius 20–22, 1px `#E3E9F2` border, soft shadow) |
| **Primary Ink** | Navy Ink | `#0F1B2D` | High-contrast readable typography for values and titles |
| **Muted Ink** | Slate Grey | `#8A94A6` | Captions, units, and timestamps |
| **Primary Accent** | Cobalt Blue | `#2E86DE` | Primary actions, glucose tiles, and active navigation indicators |
| **Blush Accent** | Soft Rose | `#F6B8C1` | Restrained warmth: brand dot, night star, and family circle badge |
| **Normal** | Emerald Green | `#34C759` | Glucose ≥ 4.4 mmol/L, steady overnight status |
| **Warning** | Amber Yellow | `#FF9500` | Glucose 3.9–4.4 mmol/L, rising nocturnal restlessness |
| **Critical** | Urgent Crimson | `#FF3B30` | Glucose < 3.9 mmol/L, hardware alarm & SMN dispatch trigger |

---

## 📱 Architecture & Screen Overview

### 1. Phone Companion Dashboard (`entry/src/main/ets/phone/`)

- **Tab 1: Monitor (`MonitorView.ets`)**  
  - *Night Guardian Hero*: Blue-tinted card (`#DFE9FA`) with crescent moon & star graphics, 52sp glucose level, trend phrases, and heart/watch battery glass chips. Flips to high-contrast red (`#FF3B30`) with *"Call now"* and *"I'm with them"* buttons during crises.
  - *2×2 Physiological Grid*: Real-time Canvas PPG waveform (sparkline), tremor power spectral density (PSD) bars, guardian schedule window, and hypoglycemia risk index.
- **Tab 2: Overnight Trends (`TrendsView.ets`)**  
  - *8-Hour Sleep Curve*: 5-bar nocturnal glucose progression (12am, 2am, 4am, 6am, 8am) with dynamic threshold coloring.
  - *Chronological Sleep Events*: Timeline of bedtime settling, autonomous check-ins, and circadian stability notes.
- **Tab 3: Caregiver & Dispatch (`FamilyView.ets`)**  
  - *Thumb-Zone Call Button*: 56-high primary button that dynamically elevates urgency during emergencies.
  - *Huawei Cloud SMN Emergency Dispatch*: Automated toggle to send priority SMS messages to designated family contacts upon threshold breach.
  - *Activity Trail*: Chronological audit log with severity indicators (`crit`, `warn`, `ok`, `info`).
- **Tab 4: Clinical Simulation (`DemoView.ets`)**  
  - *3 Preset Scenarios*: **Stable 5.5** (steady), **Pre-Drop 4.2** (falling), and **Crisis 3.1** (emergency alarm + SMN SMS).
  - *Telemetry Diagnostics*: Live sensor readouts for Pulse (PPG), Tremor PSD, Skin Temperature, and HRV.
  - *SMN Payload Inspector*: JSON preview of the emergency message dispatched to Huawei Cloud SMN.

### 2. Wearable Engine (`entry/src/main/ets/watch/`)

- Optimized for circular/square smartwatches (466×466).
- Autonomous threshold detection engine running locally on the watch.
- Hardware vibration pulses via `@ohos.vibrator` and acoustic emergency buzzer (`AlertService.ets`).

---

## 🛠️ Project Structure

```text
HypoAlert/
├── AppScope/
│   ├── app.json5                       # Bundle metadata & application name
│   └── resources/                      # Application icons and assets
├── entry/
│   ├── src/
│   │   └── main/
│   │       ├── module.json5            # Module capabilities (phone & wearable permissions)
│   │       └── ets/
│   │           ├── entryability/       # HarmonyOS application lifecycle
│   │           ├── pages/
│   │           │   ├── Index.ets       # Device router (Wearable vs. Phone)
│   │           │   └── Phone.ets       # Phone direct entry & DevEco preview
│   │           ├── phone/
│   │           │   ├── PhonePage.ets   # Phone coordinator with bottom navigation
│   │           │   ├── views/          # 4 Dedicated Views (Monitor, Trends, Family, Demo)
│   │           │   ├── components/     # TopBar, HeroCard, MetricGrid, Overnight, etc.
│   │           │   │   └── tiles/      # GlucoseTile, RestlessTile, RiskTile, TonightTile
│   │           │   ├── models/         # Strongly-typed data models (AuditEntry, etc.)
│   │           │   └── utils/          # Risk formulas, PPG wave synthesis, sleep models
│   │           ├── watch/
│   │           │   ├── WatchPage.ets   # Wearable monitor and emergency handler
│   │           │   └── components/     # Wearable sub-views (Monitor, Alert, Settings)
│   │           └── services/
│   │               └── AlertService.ets# Singleton for haptic & audio hardware alerts
├── build-profile.json5                 # Target SDK version (6.0.1 / API 21)
├── hvigorfile.ts                       # Hvigor build engine script
└── .gitignore                          # Exclusions for build artifacts, caches & keys
```

---

## 🚀 Getting Started & Setup Guide

### 1. Prerequisites

- **DevEco Studio**: Version 5.0 Release or later (recommended for HarmonyOS NEXT / HarmonyOS 6.0).
- **HarmonyOS SDK**: HarmonyOS 6.0.1 (API 21) or compatible SDK components.
- **Node.js**: Node.js 18.x or 20.x (bundled with DevEco Studio).
- **Git**: Installed and available in your shell.

---

### 2. Cloning the Repository

```bash
# Clone the repository
git clone https://github.com/renzo1417/HypoAlert.git

# Navigate into the project folder
cd HypoAlert
```

---

### 3. DevEco Studio SDK Configuration

1. Launch **DevEco Studio**.
2. Select **Open** and choose the `HypoAlert` directory.
3. Open **Tools > SDK Manager > HarmonyOS SDK**.
4. Ensure the following components are installed under **HarmonyOS 6.0.1 (API 21)** (or the latest NEXT release):
   - `ArkTS`
   - `JS`
   - `Native`
   - `Toolchains`
   - `Previewer`
5. Verify that your environment variable `DEVECO_SDK_HOME` points to your SDK path (e.g. `C:\Users\<YourUser>\AppData\Local\Huawei\Sdk`).

---

### 4. Dependency Synchronization

In DevEco Studio:
- Click **Sync Now** in the top-right notification bar, or run in the terminal:
  ```bash
  ohpm install
  ```

---

### 5. Running & Previewing

#### Option A: DevEco Studio Real-Time Previewer (No Device Required)
- **Phone UI**:
  - Open `entry/src/main/ets/phone/PhonePage.ets` or `entry/src/main/ets/pages/Phone.ets`.
  - Open the **Previewer** panel (on the right toolbar).
  - Select device profile: **Phone** (e.g. 411 × 841).
  - Switch between the 4 bottom tabs (**Monitor**, **Trends**, **Family**, **Demo**) and test the scenario buttons.
- **Watch UI**:
  - Open `entry/src/main/ets/watch/WatchPage.ets`.
  - Open the **Previewer** panel.
  - Select device profile: **Wearable** (e.g. 466 × 466).

#### Option B: Running on Emulators or Hardware Devices
1. In the target device selector in DevEco Studio, choose either a **Phone Emulator** or a **Wearable Emulator**.
2. Click **Run (`Shift + F10`)**.
3. The device router (`Index.ets`) will automatically detect the device type and launch the corresponding experience.

---

## 🧪 Testing Clinical States (Demo Mode)

To verify the cross-device reactive behavior:
1. Open the companion phone interface and tap the **Demo** tab in the bottom navigation.
2. Tap **"Stable 5.5 — all clear"**:
   - Glucose sets to 5.5 mmol/L, heart rate stabilizes to ~62 bpm, and hero card displays *"Steady all night"*.
3. Tap **"Pre-Drop 4.2 — falling"**:
   - Glucose drops to 4.2 mmol/L, restlessness rises (PSD 0.85), and hero flips to a warning status (*"Dropping — check on them"*).
4. Tap **"Crisis 3.1 — emergency + alarm"**:
   - Glucose plummets to 3.1 mmol/L, tremor PSD reaches 1.84, heart rate spikes to 108 bpm.
   - Watch and phone activate alarm protocols.
   - The phone hero and sticky top emergency banner flip to solid **Urgent Red** (`#FF3B30`).
   - Huawei Cloud SMN logs an automated SMS dispatch to the primary caregiver.
5. Tap **"I'm with them"**:
   - Immediately snoozes alarms and records caregiver bedside presence in the audit log.

---

## 📄 License

Copyright (c) 2026 HypoAlert.  
Distributed under the MIT License.
