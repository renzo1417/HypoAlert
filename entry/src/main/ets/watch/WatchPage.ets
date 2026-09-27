/*
 * Copyright (c) 2026 HypoAlert.
 * Wearable — Main watch controller managing Monitor, Settings, TimePicker, and Alert views.
 */

import { AlertState, VitalsData, VitalsEngine } from '../models/VitalsModel';
import { AlertService } from '../services/AlertService';
import { formatHM } from '../common/utils/TimeUtils';
import { parseTimeToDate } from './utils/WatchUtils';
import { WatchMonitorView } from './components/WatchMonitorView';
import { WatchSettingsView } from './components/WatchSettingsView';
import { WatchTimeEditView } from './components/WatchTimeEditView';
import { WatchAlertView } from './components/WatchAlertView';

@Component
export struct WatchPage {
  @State currentAlertState: AlertState = AlertState.MONITORING;
  @State isMonitoringActive: boolean = false;
  @State currentPage: number = 0;
  @State vitals: VitalsData = {
    pulse: 62,
    skinTemp: 36.0,
    tremorIndex: 0.2,
    glucose: 5.4,
    timestamp: '12:23 PM'
  };
  @State autoScheduleEnabled: boolean = true;
  @State scheduleStartTime: string = '22:00';
  @State scheduleEndTime: string = '06:00';
  @State ringScale: number = 1.0;
  @State ringOpacity: number = 0.9;
  @State simStatus: string = 'Standby - tap START';
  @State hapticStatus: string = 'Haptic: idle';
  @State testToolsOpen: boolean = false;
  @State editingTime: boolean = false;
  @State editingStart: boolean = true;
  @State editHourIdx: number = 9;
  @State editMinIdx: number = 0;
  @State editAmpmIdx: number = 1;

  private vitalsTimerId: number = -1;
  private animTimerId: number = -1;
  private alertService: AlertService = AlertService.getInstance();
  private swiperCtl: SwiperController = new SwiperController();

  aboutToAppear(): void {
    this.vitals = VitalsEngine.generateNormalVitals();
    this.alertService.setStatusListener((active: boolean, msg: string) => {
      this.simStatus = msg;
      this.hapticStatus = active ? 'Haptic: alerting' : 'Haptic: idle';
    });
    this.vitalsTimerId = setInterval(() => {
      if (!this.isMonitoringActive) {
        return;
      }
      if (this.currentAlertState === AlertState.CRITICAL_ALERT) {
        this.vitals = VitalsEngine.generateCriticalVitals(this.vitals);
        return;
      }
      this.vitals = VitalsEngine.generateNormalVitals(this.vitals);
      if (VitalsEngine.isCritical(this.vitals.glucose)) {
        this.triggerCrisisAlert();
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
    if (this.vitalsTimerId !== -1) {
      clearInterval(this.vitalsTimerId);
      this.vitalsTimerId = -1;
    }
    if (this.animTimerId !== -1) {
      clearInterval(this.animTimerId);
      this.animTimerId = -1;
    }
    this.alertService.setStatusListener(null);
    this.alertService.stopEmergencyAlert();
  }

  private toggleMonitoring(): void {
    this.isMonitoringActive = !this.isMonitoringActive;
    if (this.isMonitoringActive) {
      this.currentAlertState = AlertState.MONITORING;
      this.vitals = VitalsEngine.generateNormalVitals();
      this.simStatus = 'Monitoring...';
      this.hapticStatus = 'Haptic: idle';
    } else {
      this.alertService.stopEmergencyAlert();
      this.currentAlertState = AlertState.MONITORING;
      this.vitals = VitalsEngine.generateNormalVitals();
      this.simStatus = 'Standby - tap START';
      this.hapticStatus = 'Haptic: idle';
    }
  }

  private triggerCrisisAlert(): void {
    if (this.currentAlertState === AlertState.CRITICAL_ALERT) {
      return;
    }
    this.currentAlertState = AlertState.CRITICAL_ALERT;
    this.vitals = VitalsEngine.generateCriticalVitals(this.vitals);
    this.alertService.startEmergencyAlert();
  }

  private dropStep(): void {
    if (this.currentAlertState === AlertState.CRITICAL_ALERT) {
      return;
    }
    this.isMonitoringActive = true;
    this.vitals = VitalsEngine.dropTowardsHypo(this.vitals);
    if (VitalsEngine.isCritical(this.vitals.glucose)) {
      this.triggerCrisisAlert();
    } else {
      this.simStatus = `Dropping: ${this.vitals.glucose.toFixed(1)} mmol/L`;
    }
  }

  private dismissAlert(): void {
    this.alertService.stopEmergencyAlert();
    this.currentAlertState = AlertState.MONITORING;
    this.vitals = VitalsEngine.generateNormalVitals();
    this.simStatus = 'Monitoring resumed';
    this.hapticStatus = 'Haptic: idle';
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

          WatchSettingsView({
            testToolsOpen: $testToolsOpen,
            autoScheduleEnabled: $autoScheduleEnabled,
            scheduleStartTime: this.scheduleStartTime,
            scheduleEndTime: this.scheduleEndTime,
            currentPage: this.currentPage,
            onGoToPage: (index: number) => {
              this.goToPage(index);
            },
            onDropStep: () => {
              this.dropStep();
            },
            onTriggerCrisis: () => {
              this.triggerCrisisAlert();
            },
            onOpenTimeEdit: (isStart: boolean) => {
              this.openTimeEdit(isStart);
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
