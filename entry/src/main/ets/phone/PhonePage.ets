/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Caregiver dashboard coordinator with floating pill navigation.
 * Redesigned to match the modern, serene health monitoring aesthetic.
 */

import { AlertService } from '../services/AlertService';
import { DeviceConnectionManager, ConnectionState, ConnectionListener } from '../services/DeviceConnectionManager';
import { formatLocalTime, formatLogTime } from '../common/utils/TimeUtils';
import { AuditEntry } from './models/PhoneTypes';
import { HistoryRepository } from '../models/HistoryModel';
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
  @State isWatchConnected: boolean = true;
  @State deviceName: string = 'HUAWEI WATCH 4 Pro';

  @State caregiverName: string = 'Maria Santos';
  @State caregiverPhone: string = '+63 917 123 4567';
  @State smnEnabled: boolean = true;
  @State smnLastSent: string = '';
  @State bannerFlash: boolean = false;
  @State auditLog: AuditEntry[] = [
    { time: '23:00', message: 'Night Guardian calibrated • Normal vitals', level: 'ok' },
    { time: '02:15', message: 'Minor position shift • Normal', level: 'warn' },
    { time: '02:16', message: 'Glucose stable at 5.5 mmol/L', level: 'ok' }
  ];

  private alertService: AlertService = AlertService.getInstance();
  private connManager: DeviceConnectionManager = DeviceConnectionManager.getInstance();
  private connListener: ConnectionListener | null = null;
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

    this.isWatchConnected = this.connManager.isConnected();
    this.deviceName = this.connManager.getState().deviceName;
    this.watchBattery = this.connManager.getState().batteryLevel;
    this.connListener = (state: ConnectionState) => {
      this.isWatchConnected = state.isConnected;
      this.deviceName = state.deviceName;
      this.watchBattery = state.batteryLevel;
      if (!state.isConnected) {
        this.logEvent('Watch disconnected — stream paused', 'warn');
      } else {
        this.logEvent('Watch connected — live stream active', 'ok');
      }
    };
    this.connManager.addListener(this.connListener);

    this.clockTimerId = setInterval(() => {
      this.currentTime = formatLocalTime(new Date());
    }, 1000);
    this.streamTimerId = setInterval(() => {
      if (this.isWatchConnected) {
        this.pushPpgSamples();
        this.jitterTelemetry();
        this.drawPPG();
      }
    }, 100);
    this.flashTimerId = setInterval(() => {
      this.bannerFlash = !this.bannerFlash;
    }, 600);
  }

  aboutToDisappear(): void {
    if (this.connListener) {
      this.connManager.removeListener(this.connListener);
      this.connListener = null;
    }
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
      this.connManager.setBattery(this.watchBattery);
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
    ctx.strokeStyle = 'rgba(255,255,255,0.2)';
    ctx.lineWidth = 1;
    const gy: number = H / 2;
    ctx.beginPath();
    ctx.moveTo(0, gy);
    ctx.lineTo(W, gy);
    ctx.stroke();
    ctx.beginPath();
    ctx.strokeStyle = '#60A5FA';
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
    this.logEvent('Stable nocturnal vitals restored', 'ok');
  }

  private simulatePreDrop(): void {
    this.alertService.stopEmergencyAlert();
    this.glucose = 4.2;
    this.tremorPSD = 0.85;
    this.heartRate = 78;
    this.skinTemp = 35.6;
    this.variability = 26;
    this.riskIndex = computeRiskIndex(this.glucose, this.tremorPSD);
    this.logEvent('Glucose trending down (4.2 mmol/L)', 'warn');
  }

  private simulateCrisis(): void {
    this.glucose = 3.1;
    this.tremorPSD = 1.84;
    this.heartRate = 108;
    this.skinTemp = 34.8;
    this.variability = 12;
    this.riskIndex = computeRiskIndex(this.glucose, this.tremorPSD);
    this.alertService.startEmergencyAlert();
    this.logEvent('Emergency alert active • Alarm sounding', 'crit');
    if (this.smnEnabled) {
      const t: string = formatLogTime(new Date());
      this.smnLastSent = t;
      this.logEvent(`SMS dispatched to ${this.caregiverName} (${this.caregiverPhone})`, 'crit');
      HistoryRepository.updateTonightCrisis(this.glucose, this.riskIndex, this.caregiverName, this.caregiverPhone);
    } else {
      this.logEvent('SMS dispatch paused by user settings', 'warn');
    }
  }

  private markWithThem(): void {
    this.alertService.stopEmergencyAlert();
    this.glucose = 4.6;
    this.tremorPSD = 0.4;
    this.riskIndex = computeRiskIndex(this.glucose, this.tremorPSD);
    this.logEvent('Caregiver confirmed assistance • Alarm silenced', 'ok');
    HistoryRepository.updateTonightResolved();
  }

  private handleCallNow(): void {
    const lvl: string = riskLevel(this.riskIndex);
    if (lvl === 'Critical') {
      this.logEvent(`Direct emergency dial to ${this.caregiverName}`, 'crit');
      const tonight = HistoryRepository.getHistory()[0];
      tonight.actionsTaken.unshift({
        time: 'Just now',
        type: 'call',
        title: 'Emergency Phone Call Placed',
        detail: `Direct phone dial to primary contact ${this.caregiverName}.`,
        target: `${this.caregiverName} (${this.caregiverPhone})`,
        status: 'Completed'
      });
    } else if (lvl === 'Warning') {
      this.logEvent(`Alert check call to ${this.caregiverName}`, 'warn');
    } else {
      this.logEvent(`Connected with ${this.caregiverName}`, 'info');
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
            .fontColor('#EF4444')
        }
        .width(28)
        .height(28)

        Column({ space: 1 }) {
          Text('CRITICAL EMERGENCY')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
          Text('Glucose 3.1 mmol/L • Alarm ringing')
            .fontSize(11)
            .fontColor('#FFFFFF')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Button("I'm with them")
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .height(32)
          .backgroundColor('#FFFFFF')
          .fontColor('#EF4444')
          .borderRadius(10)
          .onClick(() => {
            this.markWithThem();
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 8, bottom: 8 })
      .backgroundColor('#EF4444')
      .opacity(this.bannerFlash ? 1.0 : 0.88)
    }
  }

  @Builder
  floatingTabButton(index: number) {
    Button() {
      Stack({ alignContent: Alignment.Center }) {
        if (this.currentTabIndex === index) {
          Circle({ width: 42, height: 42 })
            .fill('#111827')
        }

        // Vector Icon matching reference design
        if (index === 0) {
          // Tab 0: Home / Monitor
          Column({ space: 1 }) {
            Row()
              .width(12)
              .height(6)
              .backgroundColor(this.currentTabIndex === index ? '#FFFFFF' : '#94A3B8')
              .borderRadius({ topLeft: 6, topRight: 6 })
            Row()
              .width(14)
              .height(8)
              .backgroundColor(this.currentTabIndex === index ? '#FFFFFF' : '#94A3B8')
              .borderRadius({ bottomLeft: 2, bottomRight: 2 })
          }
          .alignItems(HorizontalAlign.Center)
        } else if (index === 1) {
          // Tab 1: Trends
          Row({ space: 2 }) {
            Row()
              .width(3)
              .height(8)
              .backgroundColor(this.currentTabIndex === index ? '#FFFFFF' : '#94A3B8')
              .borderRadius(1.5)
            Row()
              .width(3)
              .height(14)
              .backgroundColor(this.currentTabIndex === index ? '#FFFFFF' : '#94A3B8')
              .borderRadius(1.5)
            Row()
              .width(3)
              .height(10)
              .backgroundColor(this.currentTabIndex === index ? '#FFFFFF' : '#94A3B8')
              .borderRadius(1.5)
          }
          .alignItems(VerticalAlign.Bottom)
        } else if (index === 2) {
          // Tab 2: Care Circle / Family (Chat bubble)
          Stack({ alignContent: Alignment.Center }) {
            Column({ space: 1 }) {
              Row()
                .width(14)
                .height(10)
                .backgroundColor(this.currentTabIndex === index ? '#FFFFFF' : '#94A3B8')
                .borderRadius(3)
              Row()
                .width(5)
                .height(3)
                .backgroundColor(this.currentTabIndex === index ? '#FFFFFF' : '#94A3B8')
                .borderRadius(1)
                .margin({ left: 3 })
            }
            .alignItems(HorizontalAlign.Start)

            // Alert dot on Care Circle tab during emergency
            if (this.isEmergency()) {
              Circle({ width: 6, height: 6 })
                .fill('#EF4444')
                .offset({ x: 8, y: -6 })
            }
          }
          .width(18)
          .height(18)
        } else {
          // Tab 3: Demo / Tools (Sliders)
          Row({ space: 2 }) {
            Circle({ width: 4, height: 4 })
              .fill(this.currentTabIndex === index ? '#FFFFFF' : '#94A3B8')
            Row()
              .width(8)
              .height(3)
              .backgroundColor(this.currentTabIndex === index ? '#FFFFFF' : '#94A3B8')
              .borderRadius(1.5)
            Circle({ width: 4, height: 4 })
              .fill(this.currentTabIndex === index ? '#FFFFFF' : '#94A3B8')
          }
          .alignItems(VerticalAlign.Center)
        }
      }
      .width(44)
      .height(44)
    }
    .width(44)
    .height(44)
    .backgroundColor('transparent')
    .onClick(() => {
      this.switchToTab(index);
    })
  }

  build() {
    Column() {
      // Top Bar (clean greeting + watch pill + notification bell)
      PhoneTopBar({
        currentTime: this.currentTime,
        isEmergency: this.isEmergency(),
        isWatchConnected: this.isWatchConnected,
        watchBattery: this.watchBattery,
        deviceName: this.deviceName,
        userName: this.caregiverName,
        onNotificationClick: () => {
          this.switchToTab(2);
        }
      })

      // Persistent emergency banner across all screens if critical
      this.globalEmergencyBanner()

      // Primary Navigation Viewport with Floating Nav Pill
      Stack({ alignContent: Alignment.Bottom }) {
        // Tab Content Pages
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
              skinTemp: this.skinTemp,
              bannerFlash: this.bannerFlash,
              isWatchConnected: this.isWatchConnected,
              caregiverName: this.caregiverName,
              caregiverPhone: this.caregiverPhone,
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
              onConnectWatch: () => {
                this.connManager.setConnected(true);
              },
              onNavigateTab: (tabIndex: number) => {
                this.switchToTab(tabIndex);
              }
            })
          }

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

          // Tab 2: Family / Care Circle
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
                this.logEvent(isOn ? 'Family SMS alerts enabled' : 'Family SMS alerts paused', 'info');
              },
              onSendTestSmn: () => {
                this.sendTestSmn();
              }
            })
          }

          // Tab 3: Demo & Tools
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
              isWatchConnected: this.isWatchConnected,
              watchBattery: this.watchBattery,
              deviceName: this.deviceName,
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
              },
              onToggleWatchConnection: () => {
                this.connManager.toggleConnection();
              }
            })
          }
        }
        .layoutWeight(1)
        .barHeight(0) // Hide default bar in favor of floating pill
        .scrollable(false)
        .width('100%')
        .height('100%')
        .onChange((index: number) => {
          this.currentTabIndex = index;
        })

        // Floating Pill Navigation Bar (Matching reference design)
        Row() {
          this.floatingTabButton(0)
          this.floatingTabButton(1)
          this.floatingTabButton(2)
          this.floatingTabButton(3)
        }
        .width('84%')
        .height(58)
        .backgroundColor('rgba(255, 255, 255, 0.96)')
        .borderRadius(29)
        .shadow({ radius: 16, color: 'rgba(0, 0, 0, 0.08)', offsetY: 4 })
        .margin({ bottom: 18 })
        .padding({ left: 16, right: 16 })
        .justifyContent(FlexAlign.SpaceAround)
        .alignItems(VerticalAlign.Center)
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F9FAFC')
  }
}

@Preview({ title: 'HypoAlert Phone', width: 411, height: 841 })
@Component
struct PhonePreview {
  build() {
    PhonePage()
  }
}
