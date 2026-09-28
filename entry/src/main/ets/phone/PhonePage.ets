/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Bedside Coordinator with 3 Clinical Navigation Tabs.
 * 1. Monitor (Bedside Guardian) • 2. History (Overnight Trajectory) • 3. Guardian (Settings & Dispatch).
 */

import { AlertService } from '../services/AlertService';
import { DeviceConnectionManager, ConnectionState, ConnectionListener } from '../services/DeviceConnectionManager';
import { formatLocalTime, formatLogTime } from '../common/utils/TimeUtils';
import { AuditEntry } from './models/PhoneTypes';
import { HistoryRepository } from '../models/HistoryModel';
import { ppgSample, computeRiskIndex, riskLevel } from './utils/PhoneRiskUtils';
import { PhoneTheme } from './utils/PhoneTheme';
import { PhoneTopBar } from './components/PhoneTopBar';
import { DemoSheet } from './components/DemoSheet';
import { MonitorView } from './views/MonitorView';
import { TrendsView } from './views/TrendsView';
import { FamilyView } from './views/FamilyView';

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
  @State isTestSheetOpen: boolean = false;

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
    ctx.strokeStyle = '#38BDF8';
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
    this.logEvent('Patient awake confirmed • Alarm silenced', 'ok');
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
          Circle({ width: 26, height: 26 })
            .fill(PhoneTheme.BG_CARD)
          Text('!')
            .fontSize(14)
            .fontWeight(FontWeight.Bolder)
            .fontColor(PhoneTheme.STATE_CRIT)
        }
        .width(26)
        .height(26)

        Column({ space: 1 }) {
          Text('CRITICAL NOCTURNAL HYPOGLYCEMIA')
            .fontSize(PhoneTheme.FONT_BODY)
            .fontWeight(FontWeight.Bold)
            .fontColor(PhoneTheme.TEXT_ON_DARK)
          Text('3.1 mmol/L • Wrist haptics & bedside siren active')
            .fontSize(PhoneTheme.FONT_CAPTION)
            .fontColor(PhoneTheme.TEXT_ON_DARK)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Button("I'm Awake")
          .fontSize(PhoneTheme.FONT_CAPTION)
          .fontWeight(FontWeight.Bold)
          .height(30)
          .backgroundColor(PhoneTheme.BG_CARD)
          .fontColor(PhoneTheme.STATE_CRIT)
          .borderRadius(PhoneTheme.TILE_RADIUS)
          .onClick(() => {
            this.markWithThem();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 7, bottom: 7 })
      .backgroundColor(PhoneTheme.STATE_CRIT)
      .opacity(this.bannerFlash ? 1.0 : 0.9)
    }
  }

  @Builder
  floatingTabButton(index: number, label: string) {
    Button() {
      Column({ space: 2 }) {
        Stack({ alignContent: Alignment.Center }) {
          if (this.currentTabIndex === index) {
            Circle({ width: 34, height: 34 })
              .fill(PhoneTheme.BRAND_PRIMARY)
          }

          if (index === 0) {
            // Monitor Icon (Bedside Pulse)
            Row({ space: 2 }) {
              Row().width(3).height(8).backgroundColor(this.currentTabIndex === index ? PhoneTheme.TEXT_ON_DARK : PhoneTheme.TEXT_TERTIARY).borderRadius(1)
              Row().width(3).height(14).backgroundColor(this.currentTabIndex === index ? PhoneTheme.TEXT_ON_DARK : PhoneTheme.TEXT_TERTIARY).borderRadius(1)
              Row().width(3).height(6).backgroundColor(this.currentTabIndex === index ? PhoneTheme.TEXT_ON_DARK : PhoneTheme.TEXT_TERTIARY).borderRadius(1)
            }
            .alignItems(VerticalAlign.Center)
          } else if (index === 1) {
            // History Icon (Progression Bars)
            Row({ space: 2 }) {
              Row().width(3).height(6).backgroundColor(this.currentTabIndex === index ? PhoneTheme.TEXT_ON_DARK : PhoneTheme.TEXT_TERTIARY).borderRadius(1)
              Row().width(3).height(10).backgroundColor(this.currentTabIndex === index ? PhoneTheme.TEXT_ON_DARK : PhoneTheme.TEXT_TERTIARY).borderRadius(1)
              Row().width(3).height(14).backgroundColor(this.currentTabIndex === index ? PhoneTheme.TEXT_ON_DARK : PhoneTheme.TEXT_TERTIARY).borderRadius(1)
            }
            .alignItems(VerticalAlign.Bottom)
          } else {
            // Guardian Icon (Shield)
            Stack({ alignContent: Alignment.Center }) {
              Row()
                .width(12)
                .height(14)
                .backgroundColor(this.currentTabIndex === index ? PhoneTheme.TEXT_ON_DARK : PhoneTheme.TEXT_TERTIARY)
                .borderRadius({ topLeft: 2, topRight: 2, bottomLeft: 6, bottomRight: 6 })

              if (this.isEmergency()) {
                Circle({ width: 5, height: 5 })
                  .fill(PhoneTheme.STATE_CRIT)
                  .offset({ x: 6, y: -6 })
              }
            }
            .width(16)
            .height(16)
          }
        }
        .width(36)
        .height(36)

        Text(label)
          .fontSize(PhoneTheme.FONT_MICRO)
          .fontWeight(this.currentTabIndex === index ? FontWeight.Bold : FontWeight.Medium)
          .fontColor(this.currentTabIndex === index ? PhoneTheme.TEXT_PRIMARY : PhoneTheme.TEXT_MUTED)
      }
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
    }
    .layoutWeight(1)
    .height(48)
    .backgroundColor('transparent')
    .onClick(() => {
      this.switchToTab(index);
    })
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        // Bedside Status Header
        PhoneTopBar({
          currentTime: this.currentTime,
          isEmergency: this.isEmergency(),
          isWatchConnected: this.isWatchConnected,
          watchBattery: this.watchBattery,
          deviceName: this.deviceName,
          onOpenTest: () => {
            this.isTestSheetOpen = !this.isTestSheetOpen;
          }
        })

        // Emergency banner across all screens if critical
        this.globalEmergencyBanner()

        // 3 Primary Viewports
        Tabs({ barPosition: BarPosition.End, controller: this.tabsController }) {
          // Tab 0: Monitor (Bedside Guardian)
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

          // Tab 1: History (Overnight Trajectory)
          TabContent() {
            TrendsView({
              glucose: this.glucose,
              tremorPSD: this.tremorPSD,
              riskIndex: this.riskIndex,
              heartRate: this.heartRate,
              currentTime: this.currentTime
            })
          }

          // Tab 2: Guardian (Settings & SMN Dispatch)
          TabContent() {
            FamilyView({
              caregiverName: $caregiverName,
              caregiverPhone: $caregiverPhone,
              smnEnabled: $smnEnabled,
              smnLastSent: this.smnLastSent,
              riskIndex: this.riskIndex,
              glucose: this.glucose,
              onCallNow: () => {
                this.handleCallNow();
              },
              onToggleSmn: (isOn: boolean) => {
                this.logEvent(isOn ? 'Family SMS dispatch enabled' : 'Family SMS dispatch paused', 'info');
              },
              onSendTestSmn: () => {
                this.sendTestSmn();
              }
            })
          }
        }
        .layoutWeight(1)
        .barHeight(0)
        .scrollable(false)
        .width('100%')
        .height('100%')
        .onChange((index: number) => {
          this.currentTabIndex = index;
        })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(PhoneTheme.BG_PAGE)

      // Floating 3-Tab Navigation Bar
      Row() {
        this.floatingTabButton(0, 'Monitor')
        this.floatingTabButton(1, 'History')
        this.floatingTabButton(2, 'Guardian')
      }
      .width('76%')
      .height(56)
      .backgroundColor(PhoneTheme.BG_CARD)
      .borderRadius(28)
      .borderWidth(1)
      .borderColor(PhoneTheme.BORDER_SUBTLE)
      .shadow({ radius: 12, color: 'rgba(15, 23, 42, 0.08)', offsetY: 3 })
      .margin({ bottom: 16 })
      .padding({ left: 10, right: 10 })
      .justifyContent(FlexAlign.SpaceAround)
      .alignItems(VerticalAlign.Center)

      // Test Scenario Slide-up Overlay Sheet
      if (this.isTestSheetOpen) {
        Column() {
          Blank()
            .onClick(() => {
              this.isTestSheetOpen = false;
            })

          DemoSheet({
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
            onToggleWatchConnection: () => {
              this.connManager.toggleConnection();
            },
            onClose: () => {
              this.isTestSheetOpen = false;
            }
          })
          .padding({ bottom: 20 })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(15, 23, 42, 0.4)')
      }
    }
    .width('100%')
    .height('100%')
  }
}

@Preview({ title: 'HypoAlert Phone', width: 411, height: 841 })
@Component
struct PhonePreview {
  build() {
    PhonePage()
  }
}
