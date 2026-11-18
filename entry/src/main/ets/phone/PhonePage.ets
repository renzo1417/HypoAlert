/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Root Coordinator with 4 Pastel Wellness Screens + Obsidian Floating Dock + Blue + Action FAB.
 * Tabs: 0 Monitor • 1 History • 2 Reports (Arc Gauge & Phase Switch) • 3 Guardian (Routing & SMN).
 */

import { AlertService } from '../services/AlertService';
import { DeviceConnectionManager, ConnectionState, ConnectionListener } from '../services/DeviceConnectionManager';
import { formatLocalTime, formatLogTime } from '../common/utils/TimeUtils';
import { CalibrationProgress, HistoryRepository } from '../models/HistoryModel';
import { BodyType, DetectionPhase, ScenarioPreset } from './models/PhoneTypes';
import {
  evaluateSymptomState,
  ppgSample,
  requiredStreakForBody
} from './utils/PhoneRiskUtils';
import { PhoneTheme } from './utils/PhoneTheme';
import { DemoSheet } from './components/DemoSheet';
import { MonitorView } from './views/MonitorView';
import { TrendsView } from './views/TrendsView';
import { ReportsView } from './views/ReportsView';
import { FamilyView } from './views/FamilyView';

@Component
export struct PhonePage {
  @State currentTabIndex: number = 0;
  @State currentTime: string = '00:00:00';
  @State activePhase: DetectionPhase = 'P1';
  @State bodyType: BodyType = 'Adrenergic';
  @State symptomScore: number = 1.2;
  @State cnnRiskPct: number = 14;
  @State streakCount: number = 0;
  @State alertsTonight: number = 0;
  @State isMotionGated: boolean = false;
  @State smaValue: number = 0.04;
  @State baselineSlots: number = 15;
  @State pendingBuzzCheck: boolean = false;
  @State historyVersion: number = 0;

  @State heartRate: number = 62;
  @State deltaHR: number = 1;
  @State variability: number = 42;
  @State tremorPSD: number = 0.12;
  @State watchBattery: number = 86;
  @State isWatchConnected: boolean = true;
  @State isTestSheetOpen: boolean = false;

  @State caregiverName: string = 'Maria Santos';
  @State caregiverPhone: string = '+63 917 123 4567';
  @State smnEnabled: boolean = true;
  @State smnLastSent: string = '';

  @State calibration: CalibrationProgress = HistoryRepository.getCalibration();

  private alertService: AlertService = AlertService.getInstance();
  private connManager: DeviceConnectionManager = DeviceConnectionManager.getInstance();
  private connListener: ConnectionListener | null = null;
  private tabsController: TabsController = new TabsController();
  private clockTimerId: number = -1;
  private streamTimerId: number = -1;

  private ppgSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private ppgContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.ppgSettings);
  private ppgReady: boolean = false;
  private ppgWidth: number = 170;
  private ppgHeight: number = 98;
  private ppgPhase: number = 0.0;
  private ppgData: number[] = [];
  private readonly PPG_LEN: number = 90;

  aboutToAppear(): void {
    this.currentTime = formatLocalTime(new Date());
    this.calibration = HistoryRepository.getCalibration();
    for (let i: number = 0; i < this.PPG_LEN; i++) {
      this.ppgData.push(ppgSample(i / this.PPG_LEN));
    }

    this.isWatchConnected = this.connManager.isConnected();
    this.watchBattery = this.connManager.getState().batteryLevel;
    this.connListener = (state: ConnectionState) => {
      this.isWatchConnected = state.isConnected;
      this.watchBattery = state.batteryLevel;
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
    }, 110);
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
    this.alertService.stopEmergencyAlert();
  }

  private currentState(): string {
    return evaluateSymptomState(
      this.symptomScore,
      this.cnnRiskPct,
      this.activePhase,
      this.calibration.personalCutoff,
      this.streakCount,
      this.bodyType,
      this.isMotionGated,
      this.baselineSlots
    );
  }

  private isEmergency(): boolean {
    return this.currentState() === 'Critical';
  }

  private pushPpgSamples(): void {
    const step: number = 0.042 + this.heartRate / 4200.0;
    for (let k: number = 0; k < 3; k++) {
      this.ppgPhase += step;
      if (this.ppgPhase >= 1.0) {
        this.ppgPhase -= 1.0;
      }
      const noise: number = (Math.random() - 0.5) * (this.isMotionGated ? 0.07 : 0.025);
      this.ppgData.push(ppgSample(this.ppgPhase) + noise);
      if (this.ppgData.length > this.PPG_LEN) {
        this.ppgData.shift();
      }
    }
  }

  private jitterTelemetry(): void {
    const state: string = this.currentState();
    if (state === 'Critical') {
      if (this.bodyType === 'Blunted') {
        this.heartRate = 58 + Math.round((Math.random() - 0.5) * 3);
        this.deltaHR = -2;
      } else {
        this.heartRate = 94 + Math.round((Math.random() - 0.5) * 6);
        this.deltaHR = 26 + Math.round((Math.random() - 0.5) * 4);
      }
      this.variability = 18 + Math.round(Math.random() * 4);
    } else if (state === 'Warning') {
      if (this.bodyType === 'Blunted') {
        this.heartRate = 59 + Math.round((Math.random() - 0.5) * 2);
        this.deltaHR = -1;
      } else {
        this.heartRate = 76 + Math.round((Math.random() - 0.5) * 4);
        this.deltaHR = 14 + Math.round((Math.random() - 0.5) * 3);
      }
      this.variability = 28 + Math.round(Math.random() * 5);
    } else if (state === 'Gated') {
      this.heartRate = 71 + Math.round((Math.random() - 0.5) * 4);
      this.deltaHR = 8;
      this.variability = 36 + Math.round(Math.random() * 6);
    } else {
      this.heartRate = 61 + Math.round((Math.random() - 0.5) * 3);
      this.deltaHR = Math.round((Math.random() - 0.5) * 2);
      this.variability = 40 + Math.round(Math.random() * 6);
    }

    if (this.watchBattery > 20 && Math.random() < 0.008) {
      this.watchBattery -= 1;
      this.connManager.setBattery(this.watchBattery);
    }
  }

  private drawPPG(): void {
    if (!this.ppgReady) {
      return;
    }
    const ctx: CanvasRenderingContext2D = this.ppgContext;
    const W: number = this.ppgWidth > 0 ? this.ppgWidth : 170;
    const H: number = this.ppgHeight > 0 ? this.ppgHeight : 98;
    ctx.clearRect(0, 0, W, H);

    const n: number = this.ppgData.length;
    if (n < 4) {
      return;
    }

    const state: string = this.currentState();
    const strokeColor: string = state === 'Critical'
      ? PhoneTheme.STATE_CRIT
      : (state === 'Warning' ? PhoneTheme.STATE_WARN : PhoneTheme.BENTO_LAV_LINE);

    const padTop: number = 16;
    const padBot: number = 14;
    const usableH: number = Math.max(24, H - padTop - padBot);

    const pointsX: number[] = [];
    const pointsY: number[] = [];
    for (let i: number = 0; i < n; i++) {
      const v: number = Math.min(1.15, Math.max(-0.1, this.ppgData[i]));
      const x: number = (i / (this.PPG_LEN - 1)) * W;
      const y: number = H - padBot - (v / 1.15) * usableH;
      pointsX.push(x);
      pointsY.push(y);
    }

    // Soft translucent area under-fill matching the Lavender card curve in reference Screen 1
    const grad: CanvasGradient = ctx.createLinearGradient(0, padTop, 0, H);
    grad.addColorStop(0, state === 'Critical' ? 'rgba(239, 68, 68, 0.26)' : 'rgba(139, 92, 246, 0.24)');
    grad.addColorStop(1, 'rgba(139, 92, 246, 0.02)');

    ctx.beginPath();
    ctx.moveTo(pointsX[0], H);
    for (let i: number = 0; i < n; i++) {
      ctx.lineTo(pointsX[i], pointsY[i]);
    }
    ctx.lineTo(pointsX[n - 1], H);
    ctx.closePath();
    ctx.fillStyle = grad;
    ctx.fill();

    // Smooth curve stroke
    ctx.beginPath();
    ctx.strokeStyle = strokeColor;
    ctx.lineWidth = 2.2;
    ctx.lineCap = 'round';
    for (let i: number = 0; i < n; i++) {
      if (i === 0) {
        ctx.moveTo(pointsX[i], pointsY[i]);
      } else {
        ctx.lineTo(pointsX[i], pointsY[i]);
      }
    }
    ctx.stroke();

    // Two crisp white-centered dot markers like the reference Steps curve
    const idxA: number = Math.floor(n * 0.42);
    const idxB: number = Math.floor(n * 0.78);
    const markers: number[] = [idxA, idxB];
    for (let m: number = 0; m < markers.length; m++) {
      const idx: number = markers[m];
      ctx.fillStyle = strokeColor;
      ctx.beginPath();
      ctx.arc(pointsX[idx], pointsY[idx], 5, 0, Math.PI * 2);
      ctx.fill();

      ctx.fillStyle = '#FFFFFF';
      ctx.beginPath();
      ctx.arc(pointsX[idx], pointsY[idx], 2.5, 0, Math.PI * 2);
      ctx.fill();
    }
  }

  private runScenario(preset: ScenarioPreset): void {
    this.alertService.stopEmergencyAlert();
    if (preset === 'calm') {
      this.isMotionGated = false;
      this.baselineSlots = 15;
      this.smaValue = 0.04;
      this.symptomScore = 1.2;
      this.cnnRiskPct = 14;
      this.streakCount = 0;
      this.tremorPSD = 0.12;
      this.pendingBuzzCheck = false;
    } else if (preset === 'motion') {
      this.isMotionGated = true;
      this.baselineSlots = 15;
      this.smaValue = 0.36;
      this.symptomScore = 1.8;
      this.cnnRiskPct = 18;
      this.streakCount = 0;
      this.tremorPSD = 0.72;
      this.pendingBuzzCheck = false;
    } else if (preset === 'baseline') {
      this.isMotionGated = false;
      this.baselineSlots = 11;
      this.smaValue = 0.03;
      this.symptomScore = 0.9;
      this.cnnRiskPct = 9;
      this.streakCount = 0;
      this.tremorPSD = 0.10;
      this.pendingBuzzCheck = false;
    } else if (preset === 'warning') {
      this.isMotionGated = false;
      this.baselineSlots = 15;
      this.smaValue = 0.06;
      this.symptomScore = 4.1;
      this.cnnRiskPct = 58;
      this.streakCount = this.bodyType === 'Blunted' ? 1 : 2;
      this.tremorPSD = 0.88;
      this.pendingBuzzCheck = true;
    } else if (preset === 'surge') {
      this.isMotionGated = false;
      this.baselineSlots = 15;
      this.smaValue = 0.07;
      this.symptomScore = 5.4;
      this.cnnRiskPct = 86;
      this.streakCount = requiredStreakForBody(this.bodyType);
      this.tremorPSD = 1.64;
      this.alertsTonight = Math.min(2, this.alertsTonight + 1);
      this.pendingBuzzCheck = true;
      this.alertService.startEmergencyAlert();

      if (this.smnEnabled) {
        const t: string = formatLogTime(new Date());
        this.smnLastSent = t;
        HistoryRepository.updateTonightSymptomCrisis(this.symptomScore, this.cnnRiskPct, this.caregiverName, this.caregiverPhone);
        this.historyVersion += 1;
      }
    }
    this.drawPPG();
  }

  private markWithThem(): void {
    this.alertService.stopEmergencyAlert();
    this.symptomScore = 1.9;
    this.cnnRiskPct = 22;
    this.streakCount = 0;
    this.tremorPSD = 0.28;
    HistoryRepository.updateTonightResolved();
    this.historyVersion += 1;
    this.drawPPG();
  }

  private handleLogFingerPrick(mgDl: number): void {
    const t: string = formatLogTime(new Date());
    const linkedToBuzz: boolean = this.pendingBuzzCheck || this.calibration.buzzPricks < this.calibration.buzzPricksTarget;
    const prevP2: boolean = this.calibration.phase2Unlocked;
    const prevP3: boolean = this.calibration.phase3Unlocked;

    this.calibration = HistoryRepository.logFingerPrick(mgDl, linkedToBuzz, t);
    this.pendingBuzzCheck = false;
    this.historyVersion += 1;

    if (!prevP3 && this.calibration.phase3Unlocked) {
      this.activePhase = 'P3';
    } else if (!prevP2 && this.calibration.phase2Unlocked && this.activePhase === 'P1') {
      this.activePhase = 'P2';
    }
  }

  private handleCallNow(): void {
    const tonight = HistoryRepository.getHistory()[0];
    tonight.actionsTaken.unshift({
      time: formatLogTime(new Date()),
      type: 'call',
      title: 'Caregiver Call',
      detail: this.caregiverName,
      target: `${this.caregiverName} (${this.caregiverPhone})`,
      status: 'Completed'
    });
    this.historyVersion += 1;
  }

  private sendTestSmn(): void {
    const t: string = formatLogTime(new Date());
    this.smnLastSent = t;
  }

  private switchToTab(index: number): void {
    this.currentTabIndex = index;
    this.tabsController.changeIndex(index);
  }

  private dockSymbol(index: number, active: boolean): Resource {
    if (index === 0) {
      return active ? $r('sys.symbol.house_fill') : $r('sys.symbol.house');
    }
    if (index === 1) {
      return active ? $r('sys.symbol.calendar_fill') : $r('sys.symbol.calendar');
    }
    if (index === 2) {
      return active ? $r('sys.symbol.histogram_fill') : $r('sys.symbol.histogram');
    }
    return active ? $r('sys.symbol.person_fill') : $r('sys.symbol.person');
  }

  @Builder
  globalEmergencyBanner() {
    if (this.isEmergency()) {
      Row({ space: 10 }) {
        SymbolGlyph($r('sys.symbol.exclamationmark_triangle_fill'))
          .fontSize(14)
          .fontColor([PhoneTheme.TEXT_ON_DARK])

        Text(`Surge · ${this.activePhase === 'P3' ? `${this.cnnRiskPct}%` : `${this.symptomScore.toFixed(1)}`}`)
          .fontSize(PhoneTheme.FONT_BODY)
          .fontWeight(FontWeight.Bold)
          .fontFeature('"tnum" on')
          .fontColor(PhoneTheme.TEXT_ON_DARK)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Button("I'm awake")
          .fontSize(PhoneTheme.FONT_CAPTION)
          .fontWeight(FontWeight.Bold)
          .height(32)
          .padding({ left: 12, right: 12 })
          .backgroundColor(PhoneTheme.BG_CARD)
          .fontColor(PhoneTheme.STATE_CRIT_DARK)
          .borderRadius(PhoneTheme.PILL_RADIUS)
          .onClick(() => {
            this.markWithThem();
          })
      }
      .width('100%')
      .height(44)
      .padding({ left: 16, right: 12 })
      .backgroundColor(PhoneTheme.STATE_CRIT_DARK)
      .alignItems(VerticalAlign.Center)
    }
  }

  @Builder
  dockTabButton(index: number) {
    Button() {
      Stack({ alignContent: Alignment.Center }) {
        if (this.currentTabIndex === index) {
          Circle({ width: 48, height: 48 })
            .fill(PhoneTheme.BG_CARD)
        }

        SymbolGlyph(this.dockSymbol(index, this.currentTabIndex === index))
          .fontSize(20)
          .fontColor([this.currentTabIndex === index ? PhoneTheme.BG_NAV : PhoneTheme.TEXT_ON_DARK])

        if (index === 3 && this.isEmergency() && this.currentTabIndex !== 3) {
          Circle({ width: 6, height: 6 })
            .fill(PhoneTheme.STATE_CRIT)
            .offset({ x: 11, y: -9 })
        }
      }
      .width(48)
      .height(48)
    }
    .layoutWeight(1)
    .height(54)
    .backgroundColor(Color.Transparent)
    .padding(0)
    .onClick(() => {
      this.switchToTab(index);
    })
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        this.globalEmergencyBanner()

        Tabs({ barPosition: BarPosition.End, controller: this.tabsController }) {
          // 0: Monitor (Home Bento)
          TabContent() {
            MonitorView({
              symptomScore: this.symptomScore,
              cnnRiskPct: this.cnnRiskPct,
              phase: this.activePhase,
              bodyType: this.bodyType,
              streakCount: this.streakCount,
              alertsTonight: this.alertsTonight,
              isMotionGated: this.isMotionGated,
              smaValue: this.smaValue,
              baselineSlots: this.baselineSlots,
              heartRate: this.heartRate,
              deltaHR: this.deltaHR,
              variability: this.variability,
              watchBattery: this.watchBattery,
              tremorPSD: this.tremorPSD,
              isWatchConnected: this.isWatchConnected,
              caregiverName: this.caregiverName,
              caregiverPhone: this.caregiverPhone,
              smnEnabled: this.smnEnabled,
              smnLastSent: this.smnLastSent,
              pendingBuzzCheck: this.pendingBuzzCheck,
              calibration: this.calibration,
              ppgContext: this.ppgContext,
              onCanvasReady: () => {
                this.ppgReady = true;
                this.drawPPG();
              },
              onCanvasResize: (w: number, h: number) => {
                this.ppgWidth = w;
                this.ppgHeight = h;
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
              onLogFingerPrick: (mgDl: number) => {
                this.handleLogFingerPrick(mgDl);
              },
              onOpenTest: () => {
                this.isTestSheetOpen = true;
              },
              onNavigateTab: (idx: number) => {
                this.switchToTab(idx);
              }
            })
          }

          // 1: History (Date + Time Ruler + Summary)
          TabContent() {
            TrendsView({
              activePhase: this.activePhase,
              symptomScore: this.symptomScore,
              isEmergency: this.isEmergency(),
              calibration: this.calibration,
              historyVersion: this.historyVersion,
              onOpenReports: () => {
                this.switchToTab(2);
              }
            })
          }

          // 2: Reports (Phase Switcher + Multi-Color Arc Gauge + Dotted Bars)
          TabContent() {
            ReportsView({
              activePhase: $activePhase,
              symptomScore: this.symptomScore,
              cnnRiskPct: this.cnnRiskPct,
              bodyType: this.bodyType,
              calibration: this.calibration,
              historyVersion: this.historyVersion,
              onBack: () => {
                this.switchToTab(0);
              },
              onSelectPhase: (p: DetectionPhase) => {
                this.activePhase = p;
              }
            })
          }

          // 3: Guardian (Body-Type Routing, Baseline, SMN & Contacts)
          TabContent() {
            FamilyView({
              caregiverName: $caregiverName,
              caregiverPhone: $caregiverPhone,
              smnEnabled: $smnEnabled,
              activePhase: $activePhase,
              bodyType: $bodyType,
              smnLastSent: this.smnLastSent,
              isEmergency: this.isEmergency(),
              calibration: this.calibration,
              onCallNow: () => {
                this.handleCallNow();
              },
              onToggleSmn: (_isOn: boolean) => {
                this.historyVersion += 1;
              },
              onSendTestSmn: () => {
                this.sendTestSmn();
              },
              onSelectPhase: (p: DetectionPhase) => {
                this.activePhase = p;
              },
              onSelectBodyType: (b: BodyType) => {
                this.bodyType = b;
                if (this.isEmergency()) {
                  this.streakCount = requiredStreakForBody(b);
                }
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

      // Signature Floating Navigation Dock: Obsidian Pill (4 tabs + White Active Circle) + Vivid Blue + Button
      Row({ space: 10 }) {
        Row() {
          this.dockTabButton(0)
          this.dockTabButton(1)
          this.dockTabButton(2)
          this.dockTabButton(3)
        }
        .layoutWeight(1)
        .height(64)
        .padding({ left: 8, right: 8 })
        .backgroundColor(PhoneTheme.BG_NAV)
        .borderRadius(32)
        .shadow({ radius: 22, color: 'rgba(17, 19, 24, 0.20)', offsetY: 8 })
        .alignItems(VerticalAlign.Center)

        Button() {
          SymbolGlyph($r('sys.symbol.plus'))
            .fontSize(24)
            .fontWeight(FontWeight.Medium)
            .fontColor([PhoneTheme.TEXT_ON_DARK])
        }
        .width(60)
        .height(60)
        .backgroundColor(PhoneTheme.BRAND_ACCENT)
        .borderRadius(30)
        .shadow({ radius: 18, color: 'rgba(42, 130, 240, 0.36)', offsetY: 6 })
        .onClick(() => {
          this.isTestSheetOpen = !this.isTestSheetOpen;
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 14 })
      .alignItems(VerticalAlign.Center)

      // Quick Check & Demo Overlay Sheet
      if (this.isTestSheetOpen) {
        Column() {
          Blank()
            .onClick(() => {
              this.isTestSheetOpen = false;
            })

          DemoSheet({
            isWatchConnected: this.isWatchConnected,
            watchBattery: this.watchBattery,
            activePhase: this.activePhase,
            bodyType: this.bodyType,
            onSelectPhase: (phase: DetectionPhase) => {
              this.activePhase = phase;
            },
            onSelectBodyType: (bodyType: BodyType) => {
              this.bodyType = bodyType;
              if (this.isEmergency()) {
                this.streakCount = requiredStreakForBody(bodyType);
              }
            },
            onRunScenario: (preset: ScenarioPreset) => {
              this.runScenario(preset);
            },
            onLogFingerPrick: (mgDl: number) => {
              this.handleLogFingerPrick(mgDl);
            },
            onToggleWatchConnection: () => {
              this.connManager.toggleConnection();
            },
            onClose: () => {
              this.isTestSheetOpen = false;
            }
          })
          .padding({ left: 10, right: 10, bottom: 12 })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(17, 19, 24, 0.36)')
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
