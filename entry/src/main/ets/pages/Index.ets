/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion App - diagnostic & monitoring hub.
 * Dark telemetry theme, Canvas PPG, tremor meter, risk gauge, caregiver panel.
 */

import { AlertService } from '../services/AlertService';

// ---------- Strictly typed models ----------
interface AuditEntry {
  time: string;
  message: string;
  level: string;
}

interface TremorBand {
  label: string;
  range: string;
  power: number; // 0.0 - 1.0 normalized
  color: string;
}

// ---------- Modular helpers (canvas + simulation) ----------
function formatLocalTime(d: Date): string {
  const hh: string = d.getHours() < 10 ? `0${d.getHours()}` : `${d.getHours()}`;
  const mm: string = d.getMinutes() < 10 ? `0${d.getMinutes()}` : `${d.getMinutes()}`;
  const ss: string = d.getSeconds() < 10 ? `0${d.getSeconds()}` : `${d.getSeconds()}`;
  return `${hh}:${mm}:${ss}`;
}

function formatLogTime(d: Date): string {
  const hh: string = d.getHours() < 10 ? `0${d.getHours()}` : `${d.getHours()}`;
  const mm: string = d.getMinutes() < 10 ? `0${d.getMinutes()}` : `${d.getMinutes()}`;
  return `${hh}:${mm}`;
}

/**
 * PPG sample with systolic peak + dicrotic notch.
 * phase in [0,1). Returns 0.0 - 1.2 amplitude.
 */
function ppgSample(phase: number): number {
  const sys: number = Math.exp(-Math.pow((phase - 0.18) / 0.07, 2));
  const notch: number = 0.35 * Math.exp(-Math.pow((phase - 0.38) / 0.05, 2));
  const drift: number = 0.05 * Math.sin(phase * Math.PI * 2.0);
  return sys + notch + drift;
}

/** Risk 0-100 from glucose + tremor PSD. */
function computeRiskIndex(glucose: number, tremorPSD: number): number {
  const gPart: number = (5.8 - glucose) * 28.0;
  const tPart: number = tremorPSD * 22.0;
  let r: number = Math.round(gPart + tPart);
  if (r < 0) {
    r = 0;
  }
  if (r > 100) {
    r = 100;
  }
  return r;
}

function riskLevel(risk: number): string {
  if (risk > 70) {
    return 'Critical';
  }
  if (risk >= 30) {
    return 'Warning';
  }
  return 'Normal';
}

function riskColor(risk: number): string {
  if (risk > 70) {
    return '#FF1744';
  }
  if (risk >= 30) {
    return '#FFD600';
  }
  return '#00E676';
}

@Entry
@Component
struct Index {
  // Header / connection
  @State currentTime: string = '00:00:00';
  @State phoneBattery: number = 87;
  @State watchBattery: number = 92;

  // Live telemetry
  @State heartRate: number = 62;
  @State variability: number = 42;
  @State skinTemp: number = 36.0;
  @State glucose: number = 5.4;
  @State tremorPSD: number = 0.12;
  @State riskIndex: number = 12;

  // Caregiver
  @State caregiverName: string = 'Maria Santos';
  @State caregiverPhone: string = '+63 917 123 4567';
  @State smnEnabled: boolean = true;
  @State auditLog: AuditEntry[] = [
    { time: '23:00', message: 'Baseline Calibrated', level: 'info' },
    { time: '02:15', message: 'Mild Micro-Tremor Detected', level: 'warn' },
    { time: '02:16', message: 'Status Normal', level: 'ok' }
  ];

  // UI flash for critical banner
  @State bannerFlash: boolean = false;

  private alertService: AlertService = AlertService.getInstance();
  private clockTimerId: number = -1;
  private streamTimerId: number = -1;
  private flashTimerId: number = -1;

  // Canvas PPG
  private ppgSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private ppgContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.ppgSettings);
  private ppgReady: boolean = false;
  private ppgPhase: number = 0.0;
  private ppgData: number[] = [];
  private readonly PPG_LEN: number = 120;

  aboutToAppear(): void {
    this.currentTime = formatLocalTime(new Date());
    for (let i: number = 0; i < this.PPG_LEN; i++) {
      this.ppgData.push(ppgSample(i / this.PPG_LEN));
    }
    this.riskIndex = computeRiskIndex(this.glucose, this.tremorPSD);

    this.clockTimerId = setInterval(() => {
      this.currentTime = formatLocalTime(new Date());
    }, 1000);

    // ~50 Hz streaming: push 5 samples every 100 ms
    this.streamTimerId = setInterval(() => {
      this.pushPpgSamples();
      this.jitterTelemetry();
      this.drawPPG();
    }, 100);

    this.flashTimerId = setInterval(() => {
      this.bannerFlash = !this.bannerFlash;
    }, 600);
  }

  aboutToDisappear(): void {
    if (this.clockTimerId !== -1) {
      clearInterval(this.clockTimerId);
      this.clockTimerId = -1;
    }
    if (this.streamTimerId !== -1) {
      clearInterval(this.streamTimerId);
      this.streamTimerId = -1;
    }
    if (this.flashTimerId !== -1) {
      clearInterval(this.flashTimerId);
      this.flashTimerId = -1;
    }
    this.alertService.stopEmergencyAlert();
  }

  // ---------- Telemetry simulation ----------
  private pushPpgSamples(): void {
    const step: number = 0.045 + this.heartRate / 4000.0;
    for (let k: number = 0; k < 5; k++) {
      this.ppgPhase += step;
      if (this.ppgPhase >= 1.0) {
        this.ppgPhase -= 1.0;
      }
      const noise: number = (Math.random() - 0.5) * 0.04;
      this.ppgData.push(ppgSample(this.ppgPhase) + noise);
      if (this.ppgData.length > this.PPG_LEN) {
        this.ppgData.shift();
      }
    }
  }

  private jitterTelemetry(): void {
    const lvl: string = riskLevel(this.riskIndex);
    if (lvl === 'Critical') {
      this.heartRate = 104 + Math.round((Math.random() - 0.5) * 6);
      this.variability = 12 + Math.round(Math.random() * 6);
      this.skinTemp = Math.round((34.7 + Math.random() * 0.3) * 10) / 10;
    } else if (lvl === 'Warning') {
      this.heartRate = 76 + Math.round((Math.random() - 0.5) * 5);
      this.variability = 26 + Math.round(Math.random() * 6);
      this.skinTemp = Math.round((35.5 + Math.random() * 0.2) * 10) / 10;
    } else {
      this.heartRate = 61 + Math.round((Math.random() - 0.5) * 3);
      this.variability = 40 + Math.round(Math.random() * 8);
      this.skinTemp = Math.round((35.9 + Math.random() * 0.2) * 10) / 10;
    }
    this.riskIndex = computeRiskIndex(this.glucose, this.tremorPSD);
  }

  private drawPPG(): void {
    if (!this.ppgReady) {
      return;
    }
    const ctx: CanvasRenderingContext2D = this.ppgContext;
    const W: number = 320;
    const H: number = 120;
    ctx.clearRect(0, 0, W, H);
    // Grid
    ctx.strokeStyle = '#1E2632';
    ctx.lineWidth = 1;
    for (let g: number = 1; g < 4; g++) {
      const gy: number = (H / 4) * g;
      ctx.beginPath();
      ctx.moveTo(0, gy);
      ctx.lineTo(W, gy);
      ctx.stroke();
    }
    // Waveform
    ctx.beginPath();
    ctx.strokeStyle = '#00E5FF';
    ctx.lineWidth = 2;
    const n: number = this.ppgData.length;
    for (let i: number = 0; i < n; i++) {
      const v: number = this.ppgData[i];
      const x: number = (i / (this.PPG_LEN - 1)) * W;
      let y: number = H - 12 - v * 72;
      if (y < 6) {
        y = 6;
      }
      if (y > H - 6) {
        y = H - 6;
      }
      if (i === 0) {
        ctx.moveTo(x, y);
      } else {
        ctx.lineTo(x, y);
      }
    }
    ctx.stroke();
  }

  private tremorBands(): TremorBand[] {
    // Normalize PSD (~0-2.0) into 3 bands
    const p: number = this.tremorPSD;
    let b0: number = 0.25;
    let b1: number = 0.2;
    let b2: number = 0.1;
    if (p > 0.5 && p <= 1.2) {
      b0 = 0.3;
      b1 = 0.55;
      b2 = 0.45;
    } else if (p > 1.2) {
      b0 = 0.3;
      b1 = 0.6;
      b2 = 0.95;
    }
    return [
      { label: 'Normal', range: '0-4 Hz', power: b0, color: '#00E676' },
      { label: 'Movement', range: '4-8 Hz', power: b1, color: '#FFD600' },
      { label: 'Sympathetic', range: '8-12 Hz', power: b2, color: '#FF1744' }
    ];
  }

  private tremorText(): string {
    const v: string = this.tremorPSD.toFixed(2);
    if (this.tremorPSD > 1.2) {
      return `Tremor PSD: ${v} μV²/Hz — Elevated`;
    }
    if (this.tremorPSD > 0.5) {
      return `Tremor PSD: ${v} μV²/Hz — Rising`;
    }
    return `Tremor PSD: ${v} μV²/Hz — Normal`;
  }

  private glucoseText(): string {
    const g: string = this.glucose.toFixed(1);
    const lvl: string = riskLevel(this.riskIndex);
    if (lvl === 'Critical') {
      return `${g} mmol/L • CRITICAL`;
    }
    if (lvl === 'Warning') {
      return `${g} mmol/L • FALLING`;
    }
    return `${g} mmol/L • STABLE`;
  }

  private statusTitle(): string {
    const lvl: string = riskLevel(this.riskIndex);
    if (lvl === 'Critical') {
      return 'Critical Emergency: <3.9 mmol/L';
    }
    if (lvl === 'Warning') {
      return 'Warning: Rapid Decline';
    }
    return 'Stable';
  }

  private statusColor(): string {
    return riskColor(this.riskIndex);
  }

  private logEvent(message: string, level: string): void {
    const t: string = formatLogTime(new Date());
    const entry: AuditEntry = { time: t, message: message, level: level };
    this.auditLog.unshift(entry);
    if (this.auditLog.length > 8) {
      this.auditLog.pop();
    }
  }

  // ---------- Simulation presets ----------
  private simulateStable(): void {
    this.alertService.stopEmergencyAlert();
    this.glucose = 5.5;
    this.tremorPSD = 0.12;
    this.heartRate = 62;
    this.skinTemp = 36.0;
    this.riskIndex = computeRiskIndex(this.glucose, this.tremorPSD);
    this.logEvent('Baseline Calibrated — Status Normal', 'ok');
  }

  private simulatePreDrop(): void {
    this.alertService.stopEmergencyAlert();
    this.glucose = 4.2;
    this.tremorPSD = 0.85;
    this.heartRate = 78;
    this.skinTemp = 35.6;
    this.riskIndex = computeRiskIndex(this.glucose, this.tremorPSD);
    this.logEvent('Mild Micro-Tremor Detected — Watch Closely', 'warn');
  }

  private simulateCrisis(): void {
    this.glucose = 3.1;
    this.tremorPSD = 1.84;
    this.heartRate = 108;
    this.skinTemp = 34.8;
    this.riskIndex = computeRiskIndex(this.glucose, this.tremorPSD);
    this.alertService.startEmergencyAlert();
    this.logEvent('CRITICAL <3.9 mmol/L — Alarm + SMN Dispatch', 'crit');
    if (this.smnEnabled) {
      this.logEvent(`Cloud SMS payload → ${this.caregiverName} (${this.caregiverPhone})`, 'crit');
    }
  }

  build() {
    Scroll() {
      Column({ space: 12 }) {
        this.headerCard()
        this.ppgCard()
        this.tremorCard()
        this.riskCard()
        this.caregiverCard()
        this.simBar()
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 24 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0B0E14')
    .scrollBar(BarState.Off)
    .scrollable(ScrollDirection.Vertical)
  }

  @Builder
  headerCard() {
    Column({ space: 8 }) {
      Row() {
        Text('HYPOALERT COMPANION')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .letterSpacing(1)
        Blank()
        Text(this.bannerFlash ? '● LIVE' : '○ LIVE')
          .fontSize(10)
          .fontWeight(FontWeight.Bold)
          .fontColor('#00E5FF')
      }
      .width('100%')

      Row({ space: 8 }) {
        Text('Watch Connected: BT-LE Active')
          .fontSize(11)
          .fontWeight(FontWeight.Medium)
          .fontColor('#00E676')
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .backgroundColor('#0E2A1F')
          .border({ width: 1, color: '#00E676', radius: 12 })
        Text('50 Hz streaming')
          .fontSize(11)
          .fontColor('#00E5FF')
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .backgroundColor('#0E2229')
          .border({ width: 1, color: '#00E5FF', radius: 12 })
      }
      .width('100%')

      Row() {
        Text(this.currentTime)
          .fontSize(12)
          .fontColor('#8B949E')
        Blank()
        Text(`Phone ${this.phoneBattery}%`)
          .fontSize(12)
          .fontColor('#8B949E')
        Text('  •  ')
          .fontSize(12)
          .fontColor('#30363D')
        Text(`Watch ${this.watchBattery}%`)
          .fontSize(12)
          .fontColor('#8B949E')
      }
      .width('100%')
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#161B22')
    .borderRadius(14)
    .border({ width: 1, color: '#21262D' })
  }

  @Builder
  ppgCard() {
    Column({ space: 8 }) {
      Row() {
        Text('ARTERIAL PPG • LIVE')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .letterSpacing(0.5)
        Blank()
        Text(`${this.heartRate} BPM`)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#00E5FF')
      }
      .width('100%')

      Canvas(this.ppgContext)
        .width('100%')
        .height(120)
        .backgroundColor('#0B0E14')
        .border({ width: 1, color: '#21262D', radius: 10 })
        .onReady(() => {
          this.ppgReady = true;
          this.drawPPG();
        })

      Row() {
        Column() {
          Text('HEART RATE')
            .fontSize(9)
            .fontColor('#8B949E')
          Text(`${this.heartRate} BPM`)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Column() {
          Text('VARIABILITY')
            .fontSize(9)
            .fontColor('#8B949E')
          Text(`${this.variability} ms`)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
        }
        .alignItems(HorizontalAlign.Center)
        .layoutWeight(1)

        Column() {
          Text('SKIN TEMP')
            .fontSize(9)
            .fontColor('#8B949E')
          Text(`${this.skinTemp.toFixed(1)} °C`)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
        }
        .alignItems(HorizontalAlign.End)
        .layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#161B22')
    .borderRadius(14)
    .border({ width: 1, color: '#21262D' })
  }

  @Builder
  tremorCard() {
    Column({ space: 8 }) {
      Text('AUTONOMIC TREMOR 8–12 Hz')
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .width('100%')

      Row({ space: 10 }) {
        ForEach(this.tremorBands(), (band: TremorBand) => {
          Column({ space: 6 }) {
            Stack({ alignContent: Alignment.Bottom }) {
              Row()
                .width('100%')
                .height(90)
                .backgroundColor('#0B0E14')
                .borderRadius(8)
              Row()
                .width('100%')
                .height(Math.round(band.power * 90))
                .backgroundColor(band.color)
                .borderRadius(8)
                .opacity(0.9)
            }
            .width('100%')
            .height(90)

            Text(band.range)
              .fontSize(10)
              .fontWeight(FontWeight.Bold)
              .fontColor(band.color)
            Text(band.label)
              .fontSize(9)
              .fontColor('#8B949E')
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
        }, (band: TremorBand) => band.range)
      }
      .width('100%')
      .alignItems(VerticalAlign.Bottom)

      Text(this.tremorText())
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.tremorPSD > 1.2 ? '#FF1744' : (this.tremorPSD > 0.5 ? '#FFD600' : '#00E676'))
        .width('100%')
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#161B22')
    .borderRadius(14)
    .border({ width: 1, color: '#21262D' })
  }

  @Builder
  riskCard() {
    Column({ space: 8 }) {
      Row() {
        Text('HYPOGLYCEMIA RISK')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
        Blank()
        Text(`${this.riskIndex}%`)
          .fontSize(22)
          .fontWeight(FontWeight.Bolder)
          .fontColor(this.statusColor())
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Progress({ value: this.riskIndex, total: 100, type: ProgressType.Linear })
        .width('100%')
        .color(this.statusColor())
        .backgroundColor('#0B0E14')

      Row() {
        Text('0%')
          .fontSize(9)
          .fontColor('#8B949E')
        Blank()
        Text('30%')
          .fontSize(9)
          .fontColor('#8B949E')
        Blank()
        Text('70%')
          .fontSize(9)
          .fontColor('#8B949E')
        Blank()
        Text('100%')
          .fontSize(9)
          .fontColor('#8B949E')
      }
      .width('100%')

      Text(this.glucoseText())
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .width('100%')
        .textAlign(TextAlign.Center)

      // State banner Green -> Yellow -> Pulsing Red
      Text(this.statusTitle())
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(riskLevel(this.riskIndex) === 'Normal' ? '#00E676' : (riskLevel(this.riskIndex) === 'Warning' ? '#1A1A00' : '#FFFFFF'))
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding({ top: 8, bottom: 8 })
        .backgroundColor(
          riskLevel(this.riskIndex) === 'Normal' ? '#0E2A1F' : (riskLevel(this.riskIndex) === 'Warning' ? '#FFD600' : '#FF1744')
        )
        .borderRadius(10)
        .opacity(riskLevel(this.riskIndex) === 'Critical' ? (this.bannerFlash ? 1.0 : 0.55) : 1.0)
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#161B22')
    .borderRadius(14)
    .border({ width: 1, color: this.statusColor() })
  }

  @Builder
  caregiverCard() {
    Column({ space: 10 }) {
      Text('CAREGIVER & EMERGENCY DISPATCH')
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .width('100%')

      Column({ space: 4 }) {
        Text('Contact Name')
          .fontSize(10)
          .fontColor('#8B949E')
          .width('100%')
        TextInput({ text: this.caregiverName, placeholder: 'Caregiver name' })
          .width('100%')
          .height(40)
          .fontSize(13)
          .fontColor('#FFFFFF')
          .backgroundColor('#0B0E14')
          .placeholderColor('#484F58')
          .border({ width: 1, color: '#30363D', radius: 8 })
          .onChange((value: string) => {
            this.caregiverName = value;
          })
      }
      .width('100%')

      Column({ space: 4 }) {
        Text('Phone Number')
          .fontSize(10)
          .fontColor('#8B949E')
          .width('100%')
        TextInput({ text: this.caregiverPhone, placeholder: '+63 ...' })
          .width('100%')
          .height(40)
          .fontSize(13)
          .fontColor('#FFFFFF')
          .backgroundColor('#0B0E14')
          .placeholderColor('#484F58')
          .border({ width: 1, color: '#30363D', radius: 8 })
          .onChange((value: string) => {
            this.caregiverPhone = value;
          })
      }
      .width('100%')

      Row() {
        Column() {
          Text('Huawei Cloud SMN Emergency Dispatch')
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
          Text('Auto-SMS upon critical threshold')
            .fontSize(10)
            .fontColor('#8B949E')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.smnEnabled })
          .selectedColor('#00E5FF')
          .switchPointColor('#FFFFFF')
          .onChange((isOn: boolean) => {
            this.smnEnabled = isOn;
            this.logEvent(isOn ? 'Cloud SMN Dispatch Enabled' : 'Cloud SMN Dispatch Disabled', 'info');
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Divider().color('#21262D').strokeWidth(1)

      Text('AUDIT LOG')
        .fontSize(10)
        .fontWeight(FontWeight.Bold)
        .fontColor('#8B949E')
        .width('100%')

      Column({ space: 6 }) {
        ForEach(this.auditLog, (entry: AuditEntry) => {
          Row({ space: 8 }) {
            Text(entry.time)
              .fontSize(11)
              .fontColor('#8B949E')
              .width(44)
            Text(entry.message)
              .fontSize(11)
              .fontColor(entry.level === 'crit' ? '#FF1744' : (entry.level === 'warn' ? '#FFD600' : '#E6EDF3'))
              .layoutWeight(1)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          .padding(8)
          .backgroundColor('#0B0E14')
          .borderRadius(8)
        }, (entry: AuditEntry, index: number) => `${index}_${entry.time}_${entry.level}`)
      }
      .width('100%')
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#161B22')
    .borderRadius(14)
    .border({ width: 1, color: '#21262D' })
  }

  @Builder
  simBar() {
    Column({ space: 8 }) {
      Text('INTERACTIVE SIMULATION • DEMO MODE')
        .fontSize(11)
        .fontWeight(FontWeight.Bold)
        .fontColor('#8B949E')
        .width('100%')
        .textAlign(TextAlign.Center)

      Row({ space: 8 }) {
        Button('Simulate Stable')
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .height(40)
          .layoutWeight(1)
          .backgroundColor('#0E2A1F')
          .fontColor('#00E676')
          .border({ width: 1, color: '#00E676', radius: 10 })
          .onClick(() => {
            this.simulateStable();
          })
        Button('Simulate Pre-Drop')
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .height(40)
          .layoutWeight(1)
          .backgroundColor('#2A2500')
          .fontColor('#FFD600')
          .border({ width: 1, color: '#FFD600', radius: 10 })
          .onClick(() => {
            this.simulatePreDrop();
          })
        Button('Simulate Crisis')
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .height(40)
          .layoutWeight(1)
          .backgroundColor('#FF1744')
          .fontColor('#FFFFFF')
          .borderRadius(10)
          .onClick(() => {
            this.simulateCrisis();
          })
      }
      .width('100%')

      Text('Stable 5.5 • Pre-Drop 4.2 • Crisis 3.1 mmol/L')
        .fontSize(10)
        .fontColor('#484F58')
        .width('100%')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#161B22')
    .borderRadius(14)
    .border({ width: 1, color: '#00E5FF' })
  }
}

@Preview({ title: 'HypoAlert Phone', width: 411, height: 841 })
@Component
struct IndexPreview {
  build() {
    Index()
  }
}
