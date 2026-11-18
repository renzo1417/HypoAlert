/*
 * Copyright (c) 2026 HypoAlert.
 * Wearable — Main watch controller managing Monitor, History, Settings, TimePicker, and Symptom Alert views.
 */

import {
  AlertState,
  BodyPhenotype,
  DetectionPhase,
  ReplayStepOutput,
  VitalsData,
  VitalsEngine
} from '../models/VitalsModel';
import { TcnnNightState } from '../models/TcnnEngine';
import { LOSO_C2S02_BUNDLE, REPLAY_C2S02_NIGHT } from '../models/TcnnWeights';
import { HistoryRepository } from '../models/HistoryModel';
import { AlertService } from '../services/AlertService';
import { DeviceConnectionManager, ConnectionState, ConnectionListener } from '../services/DeviceConnectionManager';
import { formatHM } from '../common/utils/TimeUtils';
import { parseTimeToDate } from './utils/WatchUtils';
import { WatchMonitorView } from './components/WatchMonitorView';
import { WatchHistoryView } from './components/WatchHistoryView';
import { WatchSettingsView } from './components/WatchSettingsView';
import { WatchTimeEditView } from './components/WatchTimeEditView';
import { WatchAlertView } from './components/WatchAlertView';

@Component
export struct WatchPage {
  @State currentAlertState: AlertState = AlertState.MONITORING;
  @State isMonitoringActive: boolean = false;
  @State isPhoneConnected: boolean = true;
  @State currentPage: number = 0;
  @State phenotype: BodyPhenotype = BodyPhenotype.ADRENERGIC;
  @State activePhase: DetectionPhase = 1;
  @State personalThreshold: number = VitalsEngine.PHASE1_THRESHOLD;
  @State vitals: VitalsData = VitalsEngine.createInitialVitals(BodyPhenotype.ADRENERGIC, 1, 3.7);
  @State autoScheduleEnabled: boolean = true;
  @State scheduleStartTime: string = '22:00';
  @State scheduleEndTime: string = '06:00';
  @State ringScale: number = 1.0;
  @State ringOpacity: number = 0.9;
  @State simStatus: string = 'Standby - tap START';
  @State hapticStatus: string = 'Checks 0/3 • Max 2/night';
  @State testToolsOpen: boolean = false;
  @State replayActive: boolean = false;
  @State editingTime: boolean = false;
  @State editingStart: boolean = true;
  @State editHourIdx: number = 9;
  @State editMinIdx: number = 0;
  @State editAmpmIdx: number = 1;

  private vitalsTimerId: number = -1;
  private replayTimerId: number = -1;
  private animTimerId: number = -1;
  private tcnnNight: TcnnNightState = VitalsEngine.createPhase3NightState(BodyPhenotype.ADRENERGIC, true);
  private replayIndex: number = 0;
  private alertService: AlertService = AlertService.getInstance();
  private connManager: DeviceConnectionManager = DeviceConnectionManager.getInstance();
  private connListener: ConnectionListener | null = null;
  private swiperCtl: SwiperController = new SwiperController();

  aboutToAppear(): void {
    this.syncVitalsIdle();
    this.isPhoneConnected = this.connManager.isConnected();
    this.connListener = (state: ConnectionState) => {
      this.isPhoneConnected = state.isConnected;
    };
    this.connManager.addListener(this.connListener);

    this.alertService.setStatusListener((active: boolean, msg: string) => {
      this.simStatus = msg;
      this.hapticStatus = active ? 'Buzzing — tap Awake' : this.buildGuardText();
    });

    this.vitalsTimerId = setInterval(() => {
      if (!this.isMonitoringActive || this.replayActive) {
        return;
      }
      if (this.currentAlertState === AlertState.CRITICAL_ALERT) {
        return;
      }
      if (this.vitals.baselineMinutes < VitalsEngine.BASELINE_TOTAL_MINUTES) {
        const nextBase: number = Math.min(VitalsEngine.BASELINE_TOTAL_MINUTES, this.vitals.baselineMinutes + 5);
        if (nextBase < VitalsEngine.BASELINE_TOTAL_MINUTES) {
          this.vitals = VitalsEngine.generateBaselineVitals(
            this.vitals,
            this.phenotype,
            this.activePhase,
            this.getActiveThreshold(),
            nextBase,
            this.tcnnNight
          );
        } else {
          this.vitals = VitalsEngine.generateSteadyVitals(
            this.vitals,
            this.phenotype,
            this.activePhase,
            this.getActiveThreshold(),
            75,
            this.vitals.alertsTonight,
            this.vitals.cooldownMinutes,
            this.tcnnNight
          );
        }
        this.refreshStatusText();
        return;
      }
      if (!this.vitals.isSedentary) {
        return;
      }
      if (this.vitals.streakCount === 0) {
        const nextCd: number = this.vitals.cooldownMinutes > 0 ? Math.max(0, this.vitals.cooldownMinutes - 1) : 0;
        this.vitals = VitalsEngine.generateSteadyVitals(
          this.vitals,
          this.phenotype,
          this.activePhase,
          this.getActiveThreshold(),
          75,
          this.vitals.alertsTonight,
          nextCd,
          this.tcnnNight
        );
        this.refreshStatusText();
      }
    }, 2500);

    this.animTimerId = setInterval(() => {
      if (this.isMonitoringActive && this.currentAlertState === AlertState.MONITORING) {
        const contracted: boolean = this.ringScale < 1.0;
        this.ringScale = contracted ? 1.03 : 0.98;
        this.ringOpacity = contracted ? 0.95 : 0.45;
      } else {
        this.ringScale = 1.0;
        this.ringOpacity = 0.9;
      }
    }, 900);
  }

  aboutToDisappear(): void {
    if (this.connListener) {
      this.connManager.removeListener(this.connListener);
      this.connListener = null;
    }
    if (this.vitalsTimerId !== -1) {
      clearInterval(this.vitalsTimerId);
      this.vitalsTimerId = -1;
    }
    this.stopReplay();
    if (this.animTimerId !== -1) {
      clearInterval(this.animTimerId);
      this.animTimerId = -1;
    }
    this.alertService.setStatusListener(null);
    this.alertService.stopEmergencyAlert();
  }

  private getActiveThreshold(): number {
    if (this.activePhase === 1) {
      return VitalsEngine.PHASE1_THRESHOLD;
    }
    if (this.activePhase === 2) {
      return this.personalThreshold > VitalsEngine.PHASE1_THRESHOLD ? this.personalThreshold : 5.44;
    }
    return this.phenotype === BodyPhenotype.BRADYCARDIC ? -2.62 : -1.48;
  }

  private buildGuardText(): string {
    if (this.replayActive && this.vitals.tcnnEma !== undefined && this.vitals.tcnnThr !== undefined) {
      return `EMA ${this.vitals.tcnnEma.toFixed(2)} vs ${this.vitals.tcnnThr.toFixed(2)} • ${this.vitals.streakCount}/${this.vitals.streakRequired}`;
    }
    if (this.vitals.baselineMinutes < VitalsEngine.BASELINE_TOTAL_MINUTES) {
      return 'Alerts start after 75m';
    }
    if (!this.vitals.isSedentary) {
      return 'Moving — check paused';
    }
    if (this.vitals.alertsTonight >= VitalsEngine.MAX_ALERTS_PER_NIGHT) {
      return 'Max 2 alerts reached tonight';
    }
    if (this.vitals.cooldownMinutes > 0) {
      return `Cooldown ${this.vitals.cooldownMinutes}m • ${this.vitals.alertsTonight}/2 alerts`;
    }
    if (this.activePhase === 3 && this.vitals.tcnnEma !== undefined && this.vitals.tcnnThr !== undefined) {
      return `CNN ${this.vitals.tcnnEma.toFixed(2)}/${this.vitals.tcnnThr.toFixed(2)} • ${this.vitals.streakCount}/${this.vitals.streakRequired}`;
    }
    return `Checks ${this.vitals.streakCount}/${this.vitals.streakRequired} • ${this.vitals.alertsTonight}/2 alerts`;
  }

  private refreshStatusText(): void {
    if (!this.isMonitoringActive) {
      this.simStatus = 'Standby - tap START';
      this.hapticStatus = `Checks 0/${VitalsEngine.getStreakRequired(this.phenotype)} • Max 2/night`;
      return;
    }
    if (this.replayActive) {
      this.simStatus = `P3 Replay • ${this.vitals.replayLabel ?? 'c2s02_7'}`;
    } else if (this.vitals.baselineMinutes < VitalsEngine.BASELINE_TOTAL_MINUTES) {
      this.simStatus = `${VitalsEngine.getPhaseShort(this.activePhase)} • Learning sleep`;
    } else if (this.activePhase === 3) {
      this.simStatus = `P3 1D-CNN • ${this.vitals.tcnnSlotsFilled ?? 12}/12`;
    } else {
      this.simStatus = `${VitalsEngine.getPhaseShort(this.activePhase)} • Base OK`;
    }
    this.hapticStatus = this.buildGuardText();
  }

  private stopReplay(): void {
    this.replayActive = false;
    if (this.replayTimerId !== -1) {
      clearInterval(this.replayTimerId);
      this.replayTimerId = -1;
    }
  }

  private syncVitalsIdle(): void {
    this.tcnnNight = VitalsEngine.createPhase3NightState(this.phenotype, true);
    this.vitals = VitalsEngine.createInitialVitals(this.phenotype, this.activePhase, this.getActiveThreshold(), this.tcnnNight);
    this.refreshStatusText();
  }

  private toggleMonitoring(): void {
    this.stopReplay();
    this.isMonitoringActive = !this.isMonitoringActive;
    if (this.isMonitoringActive) {
      this.currentAlertState = AlertState.MONITORING;
      this.tcnnNight = VitalsEngine.createPhase3NightState(this.phenotype, true);
      this.vitals = VitalsEngine.generateSteadyVitals(
        undefined,
        this.phenotype,
        this.activePhase,
        this.getActiveThreshold(),
        75,
        0,
        0,
        this.tcnnNight
      );
    } else {
      this.alertService.stopEmergencyAlert();
      this.currentAlertState = AlertState.MONITORING;
      this.tcnnNight = VitalsEngine.createPhase3NightState(this.phenotype, true);
      this.vitals = VitalsEngine.createInitialVitals(this.phenotype, this.activePhase, this.getActiveThreshold(), this.tcnnNight);
    }
    this.refreshStatusText();
  }

  private stepElevatedCheck(): void {
    if (this.currentAlertState === AlertState.CRITICAL_ALERT) {
      return;
    }
    this.stopReplay();
    this.isMonitoringActive = true;
    this.vitals = VitalsEngine.generateElevatedStep(
      this.vitals,
      this.phenotype,
      this.activePhase,
      this.getActiveThreshold(),
      false,
      this.tcnnNight
    );
    if (VitalsEngine.shouldTriggerAlert(this.vitals)) {
      this.activateAlertFromVitals();
    } else {
      this.refreshStatusText();
    }
  }

  private triggerCrisisAlert(): void {
    if (this.currentAlertState === AlertState.CRITICAL_ALERT) {
      return;
    }
    this.stopReplay();
    this.isMonitoringActive = true;
    this.vitals = VitalsEngine.generateElevatedStep(
      this.vitals,
      this.phenotype,
      this.activePhase,
      this.getActiveThreshold(),
      true,
      this.tcnnNight
    );
    if (VitalsEngine.shouldTriggerAlert(this.vitals)) {
      this.activateAlertFromVitals();
    } else {
      this.refreshStatusText();
    }
  }

  private toggleReplayReal(): void {
    if (this.replayActive) {
      this.stopReplay();
      this.refreshStatusText();
      return;
    }
    this.alertService.stopEmergencyAlert();
    this.currentAlertState = AlertState.MONITORING;
    this.isMonitoringActive = true;
    this.activePhase = 3;
    this.phenotype = BodyPhenotype.ADRENERGIC;
    this.replayIndex = 0;
    this.replayActive = true;

    let alertsCount: number = 0;
    let cooldownMin: number = 0;
    let streak: number = 0;

    const runOneFrame = (): void => {
      if (!this.replayActive || this.replayIndex >= REPLAY_C2S02_NIGHT.framesZ.length) {
        this.stopReplay();
        this.refreshStatusText();
        return;
      }
      const out: ReplayStepOutput = VitalsEngine.replayStepFromNight(
        REPLAY_C2S02_NIGHT,
        LOSO_C2S02_BUNDLE,
        this.tcnnNight,
        this.replayIndex,
        alertsCount,
        cooldownMin,
        streak
      );
      this.vitals = out.vitals;
      streak = out.stepResult.isHot ? streak + 1 : 0;
      cooldownMin = out.vitals.cooldownMinutes;
      this.replayIndex += 1;

      if (VitalsEngine.shouldTriggerAlert(this.vitals)) {
        this.stopReplay();
        this.activateAlertFromVitals();
      } else {
        this.refreshStatusText();
      }
    };

    runOneFrame();
    this.goToPage(0);
    this.replayTimerId = setInterval(() => {
      runOneFrame();
    }, 650);
  }

  private activateAlertFromVitals(): void {
    this.vitals.alertsTonight = Math.min(VitalsEngine.MAX_ALERTS_PER_NIGHT, this.vitals.alertsTonight + 1);
    this.currentAlertState = AlertState.CRITICAL_ALERT;
    this.alertService.startEmergencyAlert();
    HistoryRepository.updateTonightCrisis(
      this.vitals.symptomRiskPct,
      this.vitals.heuristicScore,
      this.vitals.reasonSummary,
      this.vitals.alertsTonight,
      'Maria Santos',
      '+63 917 123 4567',
      this.activePhase
    );
  }

  private toggleMotionGate(): void {
    this.stopReplay();
    this.isMonitoringActive = true;
    this.currentAlertState = AlertState.MONITORING;
    if (this.vitals.isSedentary) {
      this.vitals = VitalsEngine.generateMovingVitals(
        this.vitals,
        this.phenotype,
        this.activePhase,
        this.getActiveThreshold(),
        this.tcnnNight
      );
    } else {
      this.vitals = VitalsEngine.generateSteadyVitals(
        this.vitals,
        this.phenotype,
        this.activePhase,
        this.getActiveThreshold(),
        75,
        this.vitals.alertsTonight,
        this.vitals.cooldownMinutes,
        this.tcnnNight
      );
    }
    this.refreshStatusText();
  }

  private startBaselineWarmup(): void {
    this.stopReplay();
    this.isMonitoringActive = true;
    this.currentAlertState = AlertState.MONITORING;
    this.tcnnNight = VitalsEngine.createPhase3NightState(this.phenotype, false);
    this.vitals = VitalsEngine.generateBaselineVitals(
      this.vitals,
      this.phenotype,
      this.activePhase,
      this.getActiveThreshold(),
      35,
      this.tcnnNight
    );
    this.refreshStatusText();
  }

  private togglePhenotype(): void {
    this.stopReplay();
    this.phenotype = this.phenotype === BodyPhenotype.ADRENERGIC
      ? BodyPhenotype.BRADYCARDIC
      : BodyPhenotype.ADRENERGIC;
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
    this.refreshStatusText();
  }

  private cyclePhase(): void {
    this.stopReplay();
    this.activePhase = this.activePhase === 1 ? 2 : (this.activePhase === 2 ? 3 : 1);
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
    this.refreshStatusText();
  }

  private dismissAlert(): void {
    this.stopReplay();
    this.alertService.stopEmergencyAlert();
    this.currentAlertState = AlertState.MONITORING;
    HistoryRepository.updateTonightResolved();
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
    this.refreshStatusText();
    this.goToPage(0);
  }

  private goToPage(index: number): void {
    this.currentPage = index;
    this.swiperCtl.changeIndex(index, true);
  }

  private openTimeEdit(isStart: boolean): void {
    this.editingStart = isStart;
    const t: string = isStart ? this.scheduleStartTime : this.scheduleEndTime;
    const d: Date = parseTimeToDate(t);
    const h24: number = d.getHours();
    this.editAmpmIdx = h24 >= 12 ? 1 : 0;
    let h12: number = h24 % 12;
    if (h12 === 0) {
      h12 = 12;
    }
    this.editHourIdx = h12 - 1;
    this.editMinIdx = d.getMinutes();
    this.editingTime = true;
  }

  private applyEditTime(): void {
    const h12: number = this.editHourIdx + 1;
    const h24: number = (h12 % 12) + (this.editAmpmIdx === 1 ? 12 : 0);
    const t: string = formatHM(h24, this.editMinIdx);
    if (this.editingStart) {
      this.scheduleStartTime = t;
    } else {
      this.scheduleEndTime = t;
    }
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      if (this.currentAlertState === AlertState.CRITICAL_ALERT) {
        WatchAlertView({
          vitals: this.vitals,
          onDismiss: () => {
            this.dismissAlert();
          }
        })
      } else if (this.editingTime) {
        WatchTimeEditView({
          editingStart: this.editingStart,
          activeTime: this.editingStart ? this.scheduleStartTime : this.scheduleEndTime,
          editHourIdx: $editHourIdx,
          editMinIdx: $editMinIdx,
          editAmpmIdx: $editAmpmIdx,
          onApplyTime: () => {
            this.applyEditTime();
          },
          onDone: () => {
            this.editingTime = false;
          }
        })
      } else {
        Swiper(this.swiperCtl) {
          WatchMonitorView({
            isMonitoringActive: this.isMonitoringActive,
            isPhoneConnected: this.isPhoneConnected,
            vitals: this.vitals,
            ringScale: this.ringScale,
            ringOpacity: this.ringOpacity,
            simStatus: this.simStatus,
            hapticStatus: this.hapticStatus,
            currentPage: this.currentPage,
            onToggleMonitoring: () => {
              this.toggleMonitoring();
            },
            onSelectPage: (index: number) => {
              this.goToPage(index);
            }
          })

          WatchHistoryView({
            currentPage: this.currentPage,
            onGoToPage: (index: number) => {
              this.goToPage(index);
            }
          })

          WatchSettingsView({
            testToolsOpen: $testToolsOpen,
            autoScheduleEnabled: $autoScheduleEnabled,
            isPhoneConnected: this.isPhoneConnected,
            phenotype: this.phenotype,
            activePhase: this.activePhase,
            replayActive: this.replayActive,
            scheduleStartTime: this.scheduleStartTime,
            scheduleEndTime: this.scheduleEndTime,
            currentPage: this.currentPage,
            onGoToPage: (index: number) => {
              this.goToPage(index);
            },
            onStepCheck: () => {
              this.stepElevatedCheck();
            },
            onTriggerCrisis: () => {
              this.triggerCrisisAlert();
            },
            onToggleMotion: () => {
              this.toggleMotionGate();
            },
            onStartBaseline: () => {
              this.startBaselineWarmup();
            },
            onReplayReal: () => {
              this.toggleReplayReal();
            },
            onTogglePhenotype: () => {
              this.togglePhenotype();
            },
            onCyclePhase: () => {
              this.cyclePhase();
            },
            onOpenTimeEdit: (isStart: boolean) => {
              this.openTimeEdit(isStart);
            },
            onTogglePhoneConnection: () => {
              this.connManager.toggleConnection();
            }
          })
        }
        .loop(false)
        .indicator(false)
        .width('100%')
        .height('100%')
        .backgroundColor('#000000')
        .onChange((index: number) => {
          this.currentPage = index;
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.currentAlertState === AlertState.CRITICAL_ALERT ? '#EE1C25' : '#000000')
  }
}

@Preview({ title: 'HypoAlert Watch', width: 466, height: 466 })
@Component
struct WatchPreview {
  build() {
    WatchPage()
  }
}
