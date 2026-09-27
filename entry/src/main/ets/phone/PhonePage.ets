/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Caregiver dashboard coordinator with bottom navigation tabs.
 */

import { AlertService } from '../services/AlertService';
import { formatLocalTime, formatLogTime } from '../common/utils/TimeUtils';
import { AuditEntry } from './models/PhoneTypes';
import { ppgSample, computeRiskIndex, riskLevel } from './utils/PhoneRiskUtils';
import { PhoneTopBar } from './components/PhoneTopBar';
import { MonitorView } from './views/MonitorView';
import { TrendsView } from './views/TrendsView';
import { FamilyView } from './views/FamilyView';
import { DemoView } from './views/DemoView';

@Component
export struct PhonePage {
  @State currentTabIndex: number = 0;
  @State currentTime: string = '00:00:00';
  @State heartRate: number = 62;
  @State variability: number = 42;
  @State skinTemp: number = 36.0;
  @State glucose: number = 5.5;
  @State tremorPSD: number = 0.12;
  @State riskIndex: number = 12;
  @State watchBattery: number = 86;

  @State caregiverName: string = 'Maria Santos';
  @State caregiverPhone: string = '+63 917 123 4567';
  @State smnEnabled: boolean = true;
  @State smnLastSent: string = '';
  @State bannerFlash: boolean = false;
  @State auditLog: AuditEntry[] = [
    { time: '23:00', message: 'Set up finished — all good', level: 'ok' },
    { time: '02:15', message: 'Small movement noticed — all okay', level: 'warn' },
    { time: '02:16', message: 'All good', level: 'ok' }
  ];

  private alertService: AlertService = AlertService.getInstance();
  private tabsController: TabsController = new TabsController();
  private clockTimerId: number = -1;
  private streamTimerId: number = -1;
  private flashTimerId: number = -1;

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

  private isEmergency(): boolean {
    return riskLevel(this.riskIndex) === 'Critical';
  }

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
    if (this.watchBattery > 20 && Math.random() < 0.01) {
      this.watchBattery -= 1;
    }
    this.riskIndex = computeRiskIndex(this.glucose, this.tremorPSD);
  }

  private drawPPG(): void {
    if (!this.ppgReady) {
      return;
    }
    const ctx: CanvasRenderingContext2D = this.ppgContext;
    const W: number = 320;
    const H: number = 56;
    ctx.clearRect(0, 0, W, H);
    ctx.strokeStyle = 'rgba(255,255,255,0.35)';
    ctx.lineWidth = 1;
    const gy: number = H / 2;
    ctx.beginPath();
    ctx.moveTo(0, gy);
    ctx.lineTo(W, gy);
    ctx.stroke();
    ctx.beginPath();
    ctx.strokeStyle = '#FFFFFF';
    ctx.lineWidth = 2;
    const n: number = this.ppgData.length;
    for (let i: number = 0; i < n; i++) {
      const v: number = this.ppgData[i];
      const x: number = (i / (this.PPG_LEN - 1)) * W;
      let y: number = H - 6 - v * 36;
      if (y < 4) {
        y = 4;
      }
      if (y > H - 4) {
        y = H - 4;
      }
      if (i === 0) {
        ctx.moveTo(x, y);
      } else {
        ctx.lineTo(x, y);
      }
    }
    ctx.stroke();
  }

  private logEvent(message: string, level: string): void {
    const t: string = formatLogTime(new Date());
    const entry: AuditEntry = { time: t, message: message, level: level };
    this.auditLog.unshift(entry);
    if (this.auditLog.length > 8) {
      this.auditLog.pop();
    }
  }

  private simulateStable(): void {
    this.alertService.stopEmergencyAlert();
    this.glucose = 5.5;
    this.tremorPSD = 0.12;
    this.heartRate = 62;
    this.skinTemp = 36.0;
    this.variability = 42;
    this.riskIndex = computeRiskIndex(this.glucose, this.tremorPSD);
    this.logEvent('All good — steady', 'ok');
  }

  private simulatePreDrop(): void {
    this.alertService.stopEmergencyAlert();
    this.glucose = 4.2;
    this.tremorPSD = 0.85;
    this.heartRate = 78;
    this.skinTemp = 35.6;
    this.variability = 26;
    this.riskIndex = computeRiskIndex(this.glucose, this.tremorPSD);
    this.logEvent('Going down — keep watching', 'warn');
  }

  private simulateCrisis(): void {
    this.glucose = 3.1;
    this.tremorPSD = 1.84;
    this.heartRate = 108;
    this.skinTemp = 34.8;
    this.variability = 12;
    this.riskIndex = computeRiskIndex(this.glucose, this.tremorPSD);
    this.alertService.startEmergencyAlert();
    this.logEvent('Emergency — alarm ringing, family texted', 'crit');
    if (this.smnEnabled) {
      const t: string = formatLogTime(new Date());
      this.smnLastSent = t;
      this.logEvent(`Text sent to ${this.caregiverName} (${this.caregiverPhone})`, 'crit');
    } else {
      this.logEvent('Family texts are off — no text sent', 'warn');
    }
  }

  private markWithThem(): void {
    this.alertService.stopEmergencyAlert();
    this.glucose = 4.6;
    this.tremorPSD = 0.4;
    this.riskIndex = computeRiskIndex(this.glucose, this.tremorPSD);
    this.logEvent('You are with them — alarm stopped', 'ok');
  }

  private handleCallNow(): void {
    const lvl: string = riskLevel(this.riskIndex);
    if (lvl === 'Critical') {
      this.logEvent(`You called ${this.caregiverName} — emergency response`, 'crit');
    } else if (lvl === 'Warning') {
      this.logEvent(`You called ${this.caregiverName} — urgent check`, 'warn');
    } else {
      this.logEvent(`You called ${this.caregiverName} — all steady`, 'info');
    }
  }

  private sendTestSmn(): void {
    const t: string = formatLogTime(new Date());
    this.smnLastSent = t;
    this.logEvent(`Test SMS dispatch verified to ${this.caregiverPhone}`, 'ok');
  }

  private switchToTab(index: number): void {
    this.currentTabIndex = index;
    this.tabsController.changeIndex(index);
  }

  @Builder
  globalEmergencyBanner() {
    if (this.isEmergency()) {
      Row({ space: 10 }) {
        Stack({ alignContent: Alignment.Center }) {
          Circle({ width: 28, height: 28 })
            .fill('#FFFFFF')
          Text('!')
            .fontSize(16)
            .fontWeight(FontWeight.Bolder)
            .fontColor('#FF3B30')
        }
        .width(28)
        .height(28)

        Column({ space: 1 }) {
          Text('CRITICAL EMERGENCY')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
          Text('Glucose 3.1 mmol/L • Alarm ringing')
            .fontSize(12)
            .fontColor('#FFFFFF')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Button("I'm with them")
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .height(34)
          .backgroundColor('#FFFFFF')
          .fontColor('#FF3B30')
          .borderRadius(10)
          .onClick(() => {
            this.markWithThem();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor('#FF3B30')
      .opacity(this.bannerFlash ? 1.0 : 0.85)
    }
  }

  @Builder
  bottomTabItem(index: number, title: string) {
    Column({ space: 4 }) {
      Stack({ alignContent: Alignment.Center }) {
        if (this.currentTabIndex === index) {
          Row()
            .width(44)
            .height(26)
            .backgroundColor('#E7F0FE')
            .borderRadius(13)
        }

        // Custom vector shapes for each tab icon
        if (index === 0) {
          // Monitor: Vital pulse wave
          Row({ space: 3 }) {
            Circle({ width: 4, height: 4 })
              .fill(this.currentTabIndex === index ? '#2E86DE' : '#8A94A6')
            Row()
              .width(5)
              .height(14)
              .backgroundColor(this.currentTabIndex === index ? '#2E86DE' : '#8A94A6')
              .borderRadius(2.5)
            Circle({ width: 4, height: 4 })
              .fill(this.currentTabIndex === index ? '#2E86DE' : '#8A94A6')
          }
          .alignItems(VerticalAlign.Center)
        } else if (index === 1) {
          // Trends: 3-bar histogram
          Row({ space: 3 }) {
            Row()
              .width(4)
              .height(8)
              .backgroundColor(this.currentTabIndex === index ? '#2E86DE' : '#8A94A6')
              .borderRadius(2)
            Row()
              .width(4)
              .height(14)
              .backgroundColor(this.currentTabIndex === index ? '#2E86DE' : '#8A94A6')
              .borderRadius(2)
            Row()
              .width(4)
              .height(11)
              .backgroundColor(this.currentTabIndex === index ? '#2E86DE' : '#8A94A6')
              .borderRadius(2)
          }
          .alignItems(VerticalAlign.Bottom)
        } else if (index === 2) {
          // Family: Shield badge with blush accent dot
          Stack({ alignContent: Alignment.Center }) {
            Circle({ width: 15, height: 15 })
              .fill(this.currentTabIndex === index ? '#2E86DE' : '#8A94A6')
            Circle({ width: 6, height: 6 })
              .fill('#F6B8C1')
          }
          .width(16)
          .height(16)
        } else {
          // Demo: Sliders / Lab control
          Row({ space: 2 }) {
            Circle({ width: 4, height: 4 })
              .fill(this.currentTabIndex === index ? '#2E86DE' : '#8A94A6')
            Row()
              .width(8)
              .height(3)
              .backgroundColor(this.currentTabIndex === index ? '#2E86DE' : '#8A94A6')
              .borderRadius(1.5)
            Circle({ width: 4, height: 4 })
              .fill(this.currentTabIndex === index ? '#2E86DE' : '#8A94A6')
          }
          .alignItems(VerticalAlign.Center)
        }

        // Notification badge on Family tab if emergency
        if (index === 2 && this.isEmergency()) {
          Circle({ width: 8, height: 8 })
            .fill('#FF3B30')
            .offset({ x: 14, y: -8 })
        }
      }
      .width(48)
      .height(28)

      Text(title)
        .fontSize(11)
        .fontWeight(this.currentTabIndex === index ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.currentTabIndex === index ? '#2E86DE' : '#8A94A6')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    Column() {
      // Top Bar (branded header + live clock + connection status)
      PhoneTopBar({
        currentTime: this.currentTime,
        isEmergency: this.isEmergency(),
        watchBattery: this.watchBattery
      })

      // Persistent emergency banner across all screens
      this.globalEmergencyBanner()

      // Primary Navigation Tabs
      Tabs({ barPosition: BarPosition.End, controller: this.tabsController }) {
        // Tab 0: Monitor
        TabContent() {
          MonitorView({
            glucose: this.glucose,
            riskIndex: this.riskIndex,
            currentTime: this.currentTime,
            heartRate: this.heartRate,
            watchBattery: this.watchBattery,
            tremorPSD: this.tremorPSD,
            bannerFlash: this.bannerFlash,
            ppgContext: this.ppgContext,
            onCanvasReady: () => {
              this.ppgReady = true;
              this.drawPPG();
            },
            onCallNow: () => {
              this.handleCallNow();
            },
            onMarkWithThem: () => {
              this.markWithThem();
            },
            onNavigateTab: (tabIndex: number) => {
              this.switchToTab(tabIndex);
            }
          })
        }
        .tabBar(this.bottomTabItem(0, 'Monitor'))

        // Tab 1: Trends
        TabContent() {
          TrendsView({
            glucose: this.glucose,
            tremorPSD: this.tremorPSD,
            riskIndex: this.riskIndex,
            heartRate: this.heartRate,
            currentTime: this.currentTime
          })
        }
        .tabBar(this.bottomTabItem(1, 'Trends'))

        // Tab 2: Family
        TabContent() {
          FamilyView({
            caregiverName: $caregiverName,
            caregiverPhone: $caregiverPhone,
            smnEnabled: $smnEnabled,
            auditLog: this.auditLog,
            smnLastSent: this.smnLastSent,
            riskIndex: this.riskIndex,
            glucose: this.glucose,
            onCallNow: () => {
              this.handleCallNow();
            },
            onToggleSmn: (isOn: boolean) => {
              this.logEvent(isOn ? 'Family texts turned on' : 'Family texts turned off', 'info');
            },
            onSendTestSmn: () => {
              this.sendTestSmn();
            }
          })
        }
        .tabBar(this.bottomTabItem(2, 'Family'))

        // Tab 3: Demo
        TabContent() {
          DemoView({
            glucose: this.glucose,
            riskIndex: this.riskIndex,
            heartRate: this.heartRate,
            tremorPSD: this.tremorPSD,
            skinTemp: this.skinTemp,
            variability: this.variability,
            caregiverName: this.caregiverName,
            caregiverPhone: this.caregiverPhone,
            onSimulateStable: () => {
              this.simulateStable();
            },
            onSimulatePreDrop: () => {
              this.simulatePreDrop();
            },
            onSimulateCrisis: () => {
              this.simulateCrisis();
            },
            onMarkWithThem: () => {
              this.markWithThem();
            }
          })
        }
        .tabBar(this.bottomTabItem(3, 'Demo'))
      }
      .layoutWeight(1)
      .barWidth('100%')
      .barHeight(64)
      .barMode(BarMode.Fixed)
      .scrollable(false)
      .backgroundColor('#FFFFFF')
      .border({ width: { top: 1 }, color: { top: '#E3E9F2' } })
      .shadow({ radius: 8, color: 'rgba(15,27,45,0.04)', offsetX: 0, offsetY: -2 })
      .onChange((index: number) => {
        this.currentTabIndex = index;
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#EEF2F7')
  }
}

@Preview({ title: 'HypoAlert Phone', width: 411, height: 841 })
@Component
struct PhonePreview {
  build() {
    PhonePage()
  }
}
