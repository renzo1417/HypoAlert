/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Huawei Health Bedside Coordinator with 3 Navigation Tabs:
 * 1. Monitor (Symptom Risk & Finger-Prick Check-In) • 2. History (Overnight Risk) • 3. Guardian (Profile, Gates & Alerts).
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
import { HistoryRepository } from '../models/HistoryModel';
import { AlertService } from '../services/AlertService';
import { DeviceConnectionManager, ConnectionState, ConnectionListener } from '../services/DeviceConnectionManager';
import { formatLocalTime, formatLogTime } from '../common/utils/TimeUtils';
import { AuditEntry } from './models/PhoneTypes';
import { ppgSample, riskLevel } from './utils/PhoneRiskUtils';
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
  @State phenotype: BodyPhenotype = BodyPhenotype.ADRENERGIC;
  @State activePhase: DetectionPhase = 1;
  @State gateProgress: GateProgress = HistoryRepository.getGateProgress();
  @State vitals: VitalsData = VitalsEngine.createInitialVitals(BodyPhenotype.ADRENERGIC, 1, 3.7);
  @State pendingPrickCheck: boolean = false;
  @State historyVersion: number = 0;
  @State watchBattery: number = 86;
  @State isWatchConnected: boolean = true;
  @State deviceName: string = 'HUAWEI WATCH 4 Pro';
  @State isTestSheetOpen: boolean = false;
  @State replayActive: boolean = false;

  @State caregiverName: string = 'Maria Santos';
  @State caregiverPhone: string = '+63 917 123 4567';
  @State smnEnabled: boolean = true;
  @State smnLastSent: string = '';
  @State auditLog: AuditEntry[] = [
    { time: '22:00', message: '75-min sleep baseline started', level: 'ok' },
    { time: '23:15', message: 'Baseline ready — checking every 5 min', level: 'ok' }
  ];

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
  private ppgPhase: number = 0.0;
  private ppgData: number[] = [];
  private readonly PPG_LEN: number = 120;

  aboutToAppear(): void {
    this.currentTime = formatLocalTime(new Date());
    for (let i: number = 0; i < this.PPG_LEN; i++) {
      this.ppgData.push(ppgSample(i / this.PPG_LEN));
    }

    this.isWatchConnected = this.connManager.isConnected();
    this.deviceName = this.connManager.getState().deviceName;
    this.watchBattery = this.connManager.getState().batteryLevel;
    this.connListener = (state: ConnectionState) => {
      this.isWatchConnected = state.isConnected;
      this.deviceName = state.deviceName;
      this.watchBattery = state.batteryLevel;
      if (!state.isConnected) {
        this.logEvent('Phone link paused — watch monitors autonomously', 'warn');
      } else {
        this.logEvent('Watch connected — live telemetry active', 'ok');
      }
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
    }, 100);
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
    const step: number = 0.045 + this.vitals.pulse / 4000.0;
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

  private drawPPG(): void {
    if (!this.ppgReady) {
      return;
    }
    const ctx: CanvasRenderingContext2D = this.ppgContext;
    const W: number = 320;
    const H: number = 56;
    ctx.clearRect(0, 0, W, H);
    ctx.beginPath();
    ctx.strokeStyle = this.isEmergency() ? '#EF4444' : '#0284C7';
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

  private simulateBaseline(): void {
    this.stopReplay();
    this.alertService.stopEmergencyAlert();
    this.tcnnNight = VitalsEngine.createPhase3NightState(this.phenotype, false);
    this.vitals = VitalsEngine.generateBaselineVitals(
      this.vitals,
      this.phenotype,
      this.activePhase,
      this.getActiveThreshold(),
      40,
      this.tcnnNight
    );
    this.logEvent('75-min silent baseline warm-up previewed', 'info');
  }

  private simulateSteady(): void {
    this.stopReplay();
    this.alertService.stopEmergencyAlert();
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
    this.logEvent('Calm nocturnal vitals restored', 'ok');
  }

  private simulateStepCheck(): void {
    this.stopReplay();
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
    } else {
      this.logEvent(`Elevated check ${this.vitals.streakCount}/${this.vitals.streakRequired} (waiting for repeat)`, 'warn');
    }
  }

  private simulateSurge(): void {
    this.stopReplay();
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
    } else {
      this.logEvent('Sustained surge blocked by 30m cooldown or max 2/night cap', 'warn');
    }
  }

  private simulateMoving(): void {
    this.stopReplay();
    this.alertService.stopEmergencyAlert();
    this.vitals = VitalsEngine.generateMovingVitals(
      this.vitals,
      this.phenotype,
      this.activePhase,
      this.getActiveThreshold(),
      this.tcnnNight
    );
    this.logEvent('Motion detected — checks paused', 'info');
  }

  private simulateReplayC2s02(): void {
    if (this.replayActive) {
      this.stopReplay();
      this.logEvent('Stopped real c2s02_7 LOSO replay', 'info');
      return;
    }
    this.alertService.stopEmergencyAlert();
    this.activePhase = 3;
    this.phenotype = BodyPhenotype.ADRENERGIC;
    this.replayActive = true;

    let frameIdx: number = 0;
    let streak: number = 0;
    let cooldownMin: number = 0;
    const alertsCount: number = 0;
    this.logEvent('Streaming held-out c2s02_7 night through Phase 3 1D-CNN', 'info');

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
    this.logEvent(`Symptom alert fired (${this.vitals.alertsTonight}/2 tonight)`, 'crit');
    if (this.smnEnabled) {
      const t: string = formatLogTime(new Date());
      this.smnLastSent = t;
      this.logEvent(`Check-in SMS queued to ${this.caregiverName}`, 'crit');
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
    this.logEvent('Awake confirmed • 30-min cooldown active', 'ok');
    HistoryRepository.updateTonightResolved();
    this.historyVersion += 1;
  }

  private handleLogFingerPrick(mgDl: number): void {
    this.stopReplay();
    const updated: GateProgress = HistoryRepository.recordFingerPrick(mgDl, this.pendingPrickCheck);
    this.gateProgress = updated;
    this.pendingPrickCheck = false;
    this.historyVersion += 1;
    if (updated.isCnnUnlocked && this.activePhase < 3) {
      this.activePhase = 3;
      this.tcnnNight = VitalsEngine.createPhase3NightState(
        this.phenotype,
        this.vitals.baselineMinutes >= VitalsEngine.BASELINE_TOTAL_MINUTES
      );
      this.logEvent('Gate 2 passed — Phase 3 1D-CNN unlocked!', 'ok');
    } else if (updated.hasPersonalLine && this.activePhase === 1) {
      this.activePhase = 2;
      this.logEvent(`Gate 1 passed — personal line ${updated.personalLine.toFixed(2)} ready`, 'ok');
    } else {
      this.logEvent(`Finger-prick logged: ${mgDl} mg/dL`, 'ok');
    }
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

  private handleCallNow(): void {
    const lvl: string = riskLevel(this.vitals);
    if (lvl === 'Critical') {
      this.logEvent(`Emergency call placed to ${this.caregiverName}`, 'crit');
    } else {
      this.logEvent(`Checked in with ${this.caregiverName}`, 'info');
    }
  }

  private sendTestSmn(): void {
    const t: string = formatLogTime(new Date());
    this.smnLastSent = t;
    this.logEvent(`Test SMS simulated for ${this.caregiverPhone}`, 'ok');
  }

  private switchToTab(index: number): void {
    this.currentTabIndex = index;
    this.tabsController.changeIndex(index);
  }

  @Builder
  globalEmergencyBanner() {
    if (this.isEmergency()) {
      Row({ space: 10 }) {
        Circle({ width: 6, height: 6 })
          .fill(PhoneTheme.BG_CARD)

        Text(`${this.vitals.symptomRiskPct}% Risk • ${this.vitals.streakCount}/${this.vitals.streakRequired} checks`)
          .fontSize(PhoneTheme.FONT_BODY)
          .fontWeight(FontWeight.Bold)
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
          .fontColor(PhoneTheme.STATE_CRIT)
          .borderRadius(PhoneTheme.PILL_RADIUS)
          .onClick(() => {
            this.markWithThem();
          })
      }
      .width('100%')
      .height(44)
      .padding({ left: 16, right: 12 })
      .backgroundColor(PhoneTheme.STATE_CRIT)
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
            Row({ space: 2 }) {
              Row().width(3).height(8).backgroundColor(this.currentTabIndex === index ? PhoneTheme.TEXT_ON_DARK : PhoneTheme.TEXT_TERTIARY).borderRadius(1)
              Row().width(3).height(14).backgroundColor(this.currentTabIndex === index ? PhoneTheme.TEXT_ON_DARK : PhoneTheme.TEXT_TERTIARY).borderRadius(1)
              Row().width(3).height(6).backgroundColor(this.currentTabIndex === index ? PhoneTheme.TEXT_ON_DARK : PhoneTheme.TEXT_TERTIARY).borderRadius(1)
            }
            .alignItems(VerticalAlign.Center)
          } else if (index === 1) {
            Row({ space: 2 }) {
              Row().width(3).height(6).backgroundColor(this.currentTabIndex === index ? PhoneTheme.TEXT_ON_DARK : PhoneTheme.TEXT_TERTIARY).borderRadius(1)
              Row().width(3).height(10).backgroundColor(this.currentTabIndex === index ? PhoneTheme.TEXT_ON_DARK : PhoneTheme.TEXT_TERTIARY).borderRadius(1)
              Row().width(3).height(14).backgroundColor(this.currentTabIndex === index ? PhoneTheme.TEXT_ON_DARK : PhoneTheme.TEXT_TERTIARY).borderRadius(1)
            }
            .alignItems(VerticalAlign.Bottom)
          } else {
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

        this.globalEmergencyBanner()

        Tabs({ barPosition: BarPosition.End, controller: this.tabsController }) {
          TabContent() {
            MonitorView({
              vitals: this.vitals,
              gateProgress: this.gateProgress,
              currentTime: this.currentTime,
              watchBattery: this.watchBattery,
              isWatchConnected: this.isWatchConnected,
              pendingPrickCheck: this.pendingPrickCheck,
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
              onLogFingerPrick: (mgDl: number) => {
                this.handleLogFingerPrick(mgDl);
              },
              onNavigateTab: (tabIndex: number) => {
                this.switchToTab(tabIndex);
              }
            })
          }

          TabContent() {
            TrendsView({
              vitals: this.vitals,
              currentTime: this.currentTime,
              historyVersion: this.historyVersion
            })
          }

          TabContent() {
            FamilyView({
              caregiverName: $caregiverName,
              caregiverPhone: $caregiverPhone,
              smnEnabled: $smnEnabled,
              smnLastSent: this.smnLastSent,
              phenotype: this.phenotype,
              activePhase: this.activePhase,
              gateProgress: this.gateProgress,
              onCallNow: () => {
                this.handleCallNow();
              },
              onToggleSmn: (isOn: boolean) => {
                this.logEvent(isOn ? 'Caregiver SMS alerts enabled' : 'Caregiver SMS alerts paused', 'info');
              },
              onSendTestSmn: () => {
                this.sendTestSmn();
              },
              onSelectPhenotype: (p: BodyPhenotype) => {
                this.handleSelectPhenotype(p);
              },
              onSelectPhase: (phase: DetectionPhase) => {
                this.handleSelectPhase(phase);
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

      Column({ space: 0 }) {
        Divider().color(PhoneTheme.BORDER_LIGHT).strokeWidth(1)
        Row() {
          this.floatingTabButton(0, 'Monitor')
          this.floatingTabButton(1, 'History')
          this.floatingTabButton(2, 'Guardian')
        }
        .width('100%')
        .height(64)
        .backgroundColor(PhoneTheme.BG_CARD)
        .padding({ left: 12, right: 12, bottom: 8 })
        .justifyContent(FlexAlign.SpaceAround)
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .backgroundColor(PhoneTheme.BG_CARD)

      if (this.isTestSheetOpen) {
        Column() {
          Blank()
            .onClick(() => {
              this.isTestSheetOpen = false;
            })

          DemoSheet({
            isWatchConnected: this.isWatchConnected,
            watchBattery: this.watchBattery,
            phenotype: this.phenotype,
            activePhase: this.activePhase,
            onSimulateBaseline: () => {
              this.simulateBaseline();
            },
            onSimulateSteady: () => {
              this.simulateSteady();
            },
            onSimulateStepCheck: () => {
              this.simulateStepCheck();
            },
            onSimulateSurge: () => {
              this.simulateSurge();
            },
            onSimulateMoving: () => {
              this.simulateMoving();
            },
            onSimulateReplayC2s02: () => {
              this.simulateReplayC2s02();
            },
            onTogglePhenotype: () => {
              this.handleSelectPhenotype(
                this.phenotype === BodyPhenotype.ADRENERGIC
                  ? BodyPhenotype.BRADYCARDIC
                  : BodyPhenotype.ADRENERGIC
              );
            },
            onCyclePhase: () => {
              const next: DetectionPhase = this.activePhase === 1 ? 2 : (this.activePhase === 2 ? 3 : 1);
              this.handleSelectPhase(next);
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
