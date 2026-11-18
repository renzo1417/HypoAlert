/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Pastel Wellness UI Root Coordinator bound directly to 7676da5 VitalsModel & TcnnEngine.
 * Tabs: 0 Monitor • 1 History • 2 Reports (Arc Gauge & Phase Switch) • 3 Guardian (Routing & SMN).
 */

import {
  BodyPhenotype,
  DetectionPhase,
  GateProgress,
  ReplayStepOutput,
  VitalsData,
  VitalsEngine
} from '../models/VitalsModel';
import { TcnnNightState } from '../models/TcnnEngine';
import { LOSO_C2S02_BUNDLE, REPLAY_C2S02_NIGHT } from '../models/TcnnWeights';
import { HistoryRepository, NightHistoryRecord } from '../models/HistoryModel';
import { AlertService } from '../services/AlertService';
import { DeviceConnectionManager, ConnectionState, ConnectionListener } from '../services/DeviceConnectionManager';
import { formatLocalTime, formatLogTime } from '../common/utils/TimeUtils';
import { ScenarioPreset } from './models/PhoneTypes';
import { ppgSample, riskLevel } from './utils/PhoneRiskUtils';
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
  @State phenotype: BodyPhenotype = BodyPhenotype.ADRENERGIC;
  @State activePhase: DetectionPhase = 1;
  @State gateProgress: GateProgress = HistoryRepository.getGateProgress();
  @State vitals: VitalsData = VitalsEngine.createInitialVitals(BodyPhenotype.ADRENERGIC, 1, 3.7);
  @State pendingPrickCheck: boolean = false;
  @State lastCheckSummary: string = '';
  @State historyVersion: number = 0;

  @State watchBattery: number = 86;
  @State isWatchConnected: boolean = true;
  @State isTestSheetOpen: boolean = false;
  @State replayActive: boolean = false;

  @State caregiverName: string = 'Maria Santos';
  @State caregiverPhone: string = '+63 917 123 4567';
  @State smnEnabled: boolean = true;
  @State smnLastSent: string = '';

  private alertService: AlertService = AlertService.getInstance();
  private connManager: DeviceConnectionManager = DeviceConnectionManager.getInstance();
  private connListener: ConnectionListener | null = null;
  private tabsController: TabsController = new TabsController();
  private clockTimerId: number = -1;
  private streamTimerId: number = -1;
  private replayTimerId: number = -1;
  private tcnnNight: TcnnNightState = VitalsEngine.createPhase3NightState(BodyPhenotype.ADRENERGIC, true);

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
    this.gateProgress = HistoryRepository.getGateProgress();
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
    this.stopReplay();
    this.alertService.stopEmergencyAlert();
  }

  private getActiveThreshold(): number {
    if (this.activePhase === 1) {
      return VitalsEngine.PHASE1_THRESHOLD;
    }
    if (this.activePhase === 2) {
      return this.gateProgress.hasPersonalLine ? this.gateProgress.personalLine : 5.44;
    }
    return this.phenotype === BodyPhenotype.BRADYCARDIC ? -2.62 : -1.48;
  }

  private stopReplay(): void {
    this.replayActive = false;
    if (this.replayTimerId !== -1) {
      clearInterval(this.replayTimerId);
      this.replayTimerId = -1;
    }
  }

  private isEmergency(): boolean {
    return riskLevel(this.vitals) === 'Critical';
  }

  private pushPpgSamples(): void {
    const step: number = 0.042 + this.vitals.pulse / 4200.0;
    for (let k: number = 0; k < 3; k++) {
      this.ppgPhase += step;
      if (this.ppgPhase >= 1.0) {
        this.ppgPhase -= 1.0;
      }
      const noise: number = (Math.random() - 0.5) * (!this.vitals.isSedentary ? 0.07 : 0.025);
      this.ppgData.push(ppgSample(this.ppgPhase) + noise);
      if (this.ppgData.length > this.PPG_LEN) {
        this.ppgData.shift();
      }
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

    const lvl: string = riskLevel(this.vitals);
    const strokeColor: string = lvl === 'Critical'
      ? PhoneTheme.STATE_CRIT
      : (lvl === 'Warning' ? PhoneTheme.STATE_WARN : PhoneTheme.BENTO_LAV_LINE);

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

    const grad: CanvasGradient = ctx.createLinearGradient(0, padTop, 0, H);
    grad.addColorStop(0, lvl === 'Critical' ? 'rgba(239, 68, 68, 0.26)' : 'rgba(139, 92, 246, 0.24)');
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
    if (preset === 'replay') {
      this.simulateReplayC2s02();
      return;
    }

    this.stopReplay();
    this.alertService.stopEmergencyAlert();
    if (preset === 'calm') {
      this.tcnnNight = VitalsEngine.createPhase3NightState(this.phenotype, true);
      this.vitals = VitalsEngine.generateSteadyVitals(
        this.vitals,
        this.phenotype,
        this.activePhase,
        this.getActiveThreshold(),
        75,
        this.vitals.alertsTonight,
        0,
        this.tcnnNight
      );
      this.pendingPrickCheck = false;
    } else if (preset === 'motion') {
      this.vitals = VitalsEngine.generateMovingVitals(
        this.vitals,
        this.phenotype,
        this.activePhase,
        this.getActiveThreshold(),
        this.tcnnNight
      );
    } else if (preset === 'baseline') {
      this.tcnnNight = VitalsEngine.createPhase3NightState(this.phenotype, false);
      this.vitals = VitalsEngine.generateBaselineVitals(
        this.vitals,
        this.phenotype,
        this.activePhase,
        this.getActiveThreshold(),
        40,
        this.tcnnNight
      );
      this.pendingPrickCheck = false;
    } else if (preset === 'warning') {
      this.vitals = VitalsEngine.generateElevatedStep(
        this.vitals,
        this.phenotype,
        this.activePhase,
        this.getActiveThreshold(),
        false,
        this.tcnnNight
      );
      if (VitalsEngine.shouldTriggerAlert(this.vitals)) {
        this.fireEmergencyAlert();
      }
    } else if (preset === 'surge') {
      this.vitals = VitalsEngine.generateElevatedStep(
        this.vitals,
        this.phenotype,
        this.activePhase,
        this.getActiveThreshold(),
        true,
        this.tcnnNight
      );
      if (VitalsEngine.shouldTriggerAlert(this.vitals)) {
        this.fireEmergencyAlert();
      }
    }
    this.drawPPG();
  }

  private simulateReplayC2s02(): void {
    if (this.replayActive) {
      this.stopReplay();
      return;
    }
    this.alertService.stopEmergencyAlert();
    this.activePhase = 3;
    this.phenotype = BodyPhenotype.ADRENERGIC;
    this.tcnnNight = VitalsEngine.createPhase3NightState(BodyPhenotype.ADRENERGIC, true);
    this.replayActive = true;

    let frameIdx: number = 0;
    let streak: number = 0;
    let cooldownMin: number = 0;
    const alertsCount: number = 0;

    const stepReplay = (): void => {
      if (!this.replayActive || frameIdx >= REPLAY_C2S02_NIGHT.framesZ.length) {
        this.stopReplay();
        return;
      }
      const out: ReplayStepOutput = VitalsEngine.replayStepFromNight(
        REPLAY_C2S02_NIGHT,
        LOSO_C2S02_BUNDLE,
        this.tcnnNight,
        frameIdx,
        alertsCount,
        cooldownMin,
        streak
      );
      this.vitals = out.vitals;
      streak = out.stepResult.isHot ? streak + 1 : 0;
      cooldownMin = out.vitals.cooldownMinutes;
      frameIdx += 1;

      if (VitalsEngine.shouldTriggerAlert(this.vitals)) {
        this.stopReplay();
        this.fireEmergencyAlert();
      }
    };

    stepReplay();
    this.replayTimerId = setInterval(() => {
      stepReplay();
    }, 650);
  }

  private fireEmergencyAlert(): void {
    this.vitals.alertsTonight = Math.min(VitalsEngine.MAX_ALERTS_PER_NIGHT, this.vitals.alertsTonight + 1);
    this.pendingPrickCheck = true;
    this.alertService.startEmergencyAlert();
    if (this.smnEnabled) {
      const t: string = formatLogTime(new Date());
      this.smnLastSent = t;
      HistoryRepository.updateTonightCrisis(
        this.vitals.symptomRiskPct,
        this.vitals.heuristicScore,
        this.vitals.reasonSummary,
        this.vitals.alertsTonight,
        this.caregiverName,
        this.caregiverPhone,
        this.activePhase
      );
      this.historyVersion += 1;
    }
  }

  private markWithThem(): void {
    this.stopReplay();
    this.alertService.stopEmergencyAlert();
    this.vitals = VitalsEngine.generateSteadyVitals(
      this.vitals,
      this.phenotype,
      this.activePhase,
      this.getActiveThreshold(),
      75,
      this.vitals.alertsTonight,
      VitalsEngine.COOLDOWN_MINUTES,
      this.tcnnNight
    );
    HistoryRepository.updateTonightResolved();
    this.historyVersion += 1;
    this.drawPPG();
  }

  private handleLogFingerPrick(mgDl: number): void {
    this.stopReplay();
    const updated: GateProgress = HistoryRepository.recordFingerPrick(mgDl, this.pendingPrickCheck);
    this.gateProgress = updated;
    this.pendingPrickCheck = false;
    this.historyVersion += 1;

    if (updated.isCnnUnlocked && this.activePhase < 3) {
      this.activePhase = 3;
    } else if (updated.hasPersonalLine && this.activePhase === 1) {
      this.activePhase = 2;
    }

    const tonight: NightHistoryRecord = HistoryRepository.getHistory()[0];
    this.lastCheckSummary = tonight.actionsSummary;

    this.tcnnNight = VitalsEngine.createPhase3NightState(
      this.phenotype,
      this.vitals.baselineMinutes >= VitalsEngine.BASELINE_TOTAL_MINUTES
    );
    this.vitals = VitalsEngine.generateSteadyVitals(
      this.vitals,
      this.phenotype,
      this.activePhase,
      this.getActiveThreshold(),
      this.vitals.baselineMinutes,
      this.vitals.alertsTonight,
      this.vitals.cooldownMinutes,
      this.tcnnNight
    );
  }

  private handleSelectPhase(phase: DetectionPhase): void {
    this.stopReplay();
    this.activePhase = phase;
    this.tcnnNight = VitalsEngine.createPhase3NightState(
      this.phenotype,
      this.vitals.baselineMinutes >= VitalsEngine.BASELINE_TOTAL_MINUTES
    );
    this.vitals = VitalsEngine.generateSteadyVitals(
      this.vitals,
      this.phenotype,
      this.activePhase,
      this.getActiveThreshold(),
      this.vitals.baselineMinutes,
      this.vitals.alertsTonight,
      this.vitals.cooldownMinutes,
      this.tcnnNight
    );
  }

  private handleSelectPhenotype(p: BodyPhenotype): void {
    this.stopReplay();
    this.phenotype = p;
    this.tcnnNight = VitalsEngine.createPhase3NightState(
      this.phenotype,
      this.vitals.baselineMinutes >= VitalsEngine.BASELINE_TOTAL_MINUTES
    );
    this.vitals = VitalsEngine.generateSteadyVitals(
      this.vitals,
      this.phenotype,
      this.activePhase,
      this.getActiveThreshold(),
      this.vitals.baselineMinutes,
      this.vitals.alertsTonight,
      this.vitals.cooldownMinutes,
      this.tcnnNight
    );
  }

  private handleCallNow(): void {
    const t: string = formatLogTime(new Date());
    const tonight: NightHistoryRecord = HistoryRepository.getHistory()[0];
    tonight.actionsTaken.unshift({
      time: t,
      type: 'call',
      title: `Call Placed to ${this.caregiverName}`,
      detail: `${this.caregiverPhone}`,
      target: `${this.caregiverName} (${this.caregiverPhone})`,
      status: 'Delivered'
    });
    this.historyVersion += 1;
  }

  private sendTestSmn(): void {
    const t: string = formatLogTime(new Date());
    this.smnLastSent = t;
    const tonight: NightHistoryRecord = HistoryRepository.getHistory()[0];
    tonight.actionsTaken.unshift({
      time: t,
      type: 'sms',
      title: `Test SMS Sent to ${this.caregiverName}`,
      detail: `Huawei Cloud SMN link verified (${this.caregiverPhone})`,
      target: `${this.caregiverName} (${this.caregiverPhone})`,
      status: 'Delivered'
    });
    this.historyVersion += 1;
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

        Text(
          this.activePhase === 3
            ? `Surge · ${this.vitals.symptomRiskPct}%`
            : `Surge · ${this.vitals.heuristicScore.toFixed(1)}`
        )
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
          // 0: Home Monitor
          TabContent() {
            MonitorView({
              vitals: this.vitals,
              gateProgress: this.gateProgress,
              watchBattery: this.watchBattery,
              isWatchConnected: this.isWatchConnected,
              replayActive: this.replayActive,
              caregiverName: this.caregiverName,
              caregiverPhone: this.caregiverPhone,
              smnEnabled: this.smnEnabled,
              smnLastSent: this.smnLastSent,
              pendingPrickCheck: this.pendingPrickCheck,
              lastCheckSummary: this.lastCheckSummary,
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
                this.isTestSheetOpen = !this.isTestSheetOpen;
              },
              onNavigateTab: (tabIndex: number) => {
                this.switchToTab(tabIndex);
              }
            })
          }

          // 1: History & Select Window Ruler
          TabContent() {
            TrendsView({
              vitals: this.vitals,
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
              vitals: this.vitals,
              gateProgress: this.gateProgress,
              historyVersion: this.historyVersion,
              onBack: () => {
                this.switchToTab(0);
              },
              onSelectPhase: (p: DetectionPhase) => {
                this.handleSelectPhase(p);
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
              phenotype: $phenotype,
              smnLastSent: this.smnLastSent,
              isEmergency: this.isEmergency(),
              gateProgress: this.gateProgress,
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
                this.handleSelectPhase(p);
              },
              onSelectPhenotype: (p: BodyPhenotype) => {
                this.handleSelectPhenotype(p);
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
            phenotype: this.phenotype,
            replayActive: this.replayActive,
            onSelectPhase: (phase: DetectionPhase) => {
              this.handleSelectPhase(phase);
            },
            onSelectPhenotype: (p: BodyPhenotype) => {
              this.handleSelectPhenotype(p);
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
