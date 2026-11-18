/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Screen 1: Pastel Bento Wellness Monitor.
 * Combines editorial greeting header, sky-blue Symptom Score hero, asymmetric Lavender/Sage/Peach bento grid,
 * finger-prick calibration check-in, and caregiver quick-call card.
 */

import { CalibrationProgress } from '../../models/HistoryModel';
import { BodyType, DetectionPhase } from '../models/PhoneTypes';
import { PhoneTopBar } from '../components/PhoneTopBar';
import { PhoneCaregiverCard } from '../components/PhoneCaregiverCard';
import { FingerPrickCard } from '../components/FingerPrickCard';
import { PhoneHeroCard } from '../components/PhoneHeroCard';
import { PhoneMetricGrid } from '../components/PhoneMetricGrid';
import { evaluateSymptomState } from '../utils/PhoneRiskUtils';
import { PhoneTheme } from '../utils/PhoneTheme';

@Component
export struct MonitorView {
  @Prop symptomScore: number = 1.2;
  @Prop cnnRiskPct: number = 14;
  @Prop phase: DetectionPhase = 'P1';
  @Prop bodyType: BodyType = 'Adrenergic';
  @Prop streakCount: number = 0;
  @Prop alertsTonight: number = 0;
  @Prop isMotionGated: boolean = false;
  @Prop smaValue: number = 0.04;
  @Prop baselineSlots: number = 15;
  @Prop heartRate: number = 62;
  @Prop deltaHR: number = 1;
  @Prop variability: number = 42;
  @Prop watchBattery: number = 86;
  @Prop tremorPSD: number = 0.12;
  @Prop isWatchConnected: boolean = true;
  @Prop caregiverName: string = 'Maria Santos';
  @Prop caregiverPhone: string = '+63 917 123 4567';
  @Prop smnEnabled: boolean = true;
  @Prop smnLastSent: string = '';
  @Prop pendingBuzzCheck: boolean = false;
  @Prop calibration: CalibrationProgress = {
    buzzPricks: 2,
    buzzPricksTarget: 3,
    confirmedLows: 0,
    confirmedLowsTarget: 1,
    fineNights: 6,
    fineNightsTarget: 10,
    personalCutoff: 4.3,
    phase2Unlocked: false,
    phase3Unlocked: false,
    lastCheckSummary: ''
  };
  ppgContext: CanvasRenderingContext2D | null = null;
  onCanvasReady: () => void = () => {};
  onCanvasResize: (w: number, h: number) => void = () => {};
  onCallNow: () => void = () => {};
  onMarkWithThem: () => void = () => {};
  onConnectWatch: () => void = () => {};
  onLogFingerPrick: (mgDl: number) => void = () => {};
  onOpenTest: () => void = () => {};
  onNavigateTab: (index: number) => void = () => {};

  private isEmergency(): boolean {
    return evaluateSymptomState(
      this.symptomScore,
      this.cnnRiskPct,
      this.phase,
      this.calibration.personalCutoff,
      this.streakCount,
      this.bodyType,
      this.isMotionGated,
      this.baselineSlots
    ) === 'Critical';
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        // Editorial top bar & greeting
        PhoneTopBar({
          isEmergency: this.isEmergency(),
          isWatchConnected: this.isWatchConnected,
          watchBattery: this.watchBattery,
          phase: this.phase,
          bodyType: this.bodyType,
          onOpenTest: this.onOpenTest,
          onOpenAlerts: this.onOpenTest,
          onNavigateGuardian: () => {
            this.onNavigateTab(3);
          }
        })

        // Watch disconnected strip if offline
        if (!this.isWatchConnected) {
          Row({ space: 10 }) {
            SymbolGlyph($r('sys.symbol.watch'))
              .fontSize(15)
              .fontColor([PhoneTheme.STATE_WARN_TEXT])

            Text('Watch offline · Local alerts on')
              .fontSize(PhoneTheme.FONT_CAPTION)
              .fontWeight(FontWeight.Medium)
              .fontColor(PhoneTheme.STATE_WARN_TEXT)
              .layoutWeight(1)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            Button('Link')
              .fontSize(PhoneTheme.FONT_CAPTION)
              .fontWeight(FontWeight.Bold)
              .height(32)
              .padding({ left: 12, right: 12 })
              .backgroundColor(PhoneTheme.BRAND_PRIMARY)
              .fontColor(PhoneTheme.TEXT_ON_DARK)
              .borderRadius(PhoneTheme.PILL_RADIUS)
              .onClick(() => {
                this.onConnectWatch();
              })
          }
          .width('100%')
          .padding({ left: 14, right: 10, top: 8, bottom: 8 })
          .backgroundColor(PhoneTheme.STATE_WARN_BG)
          .borderRadius(PhoneTheme.TILE_RADIUS)
          .alignItems(VerticalAlign.Center)
        }

        // 1. Soft Sky-Blue Hero Card
        PhoneHeroCard({
          symptomScore: this.symptomScore,
          cnnRiskPct: this.cnnRiskPct,
          phase: this.phase,
          bodyType: this.bodyType,
          personalCutoff: this.calibration.personalCutoff,
          streakCount: this.streakCount,
          alertsTonight: this.alertsTonight,
          isMotionGated: this.isMotionGated,
          baselineSlots: this.baselineSlots,
          smnSentTime: this.smnLastSent,
          caregiverName: this.caregiverName,
          onCallNow: this.onCallNow,
          onMarkWithThem: this.onMarkWithThem,
          onQuickCheck: () => {
            this.onLogFingerPrick(54);
          }
        })

        // 2. Overview Asymmetric Pastel Bento Grid (Lavender + Sage + Peach)
        PhoneMetricGrid({
          heartRate: this.heartRate,
          deltaHR: this.deltaHR,
          variability: this.variability,
          tremorPSD: this.tremorPSD,
          smaValue: this.smaValue,
          isMotionGated: this.isMotionGated,
          baselineSlots: this.baselineSlots,
          bodyType: this.bodyType,
          ppgContext: this.ppgContext,
          onCanvasReady: this.onCanvasReady,
          onCanvasResize: this.onCanvasResize,
          onPrevSection: () => {
            this.onNavigateTab(1);
          },
          onNextSection: () => {
            this.onNavigateTab(2);
          }
        })

        // 3. White Finger-Prick Calibration Card
        FingerPrickCard({
          calibration: this.calibration,
          pendingBuzzCheck: this.pendingBuzzCheck,
          onLogFingerPrick: this.onLogFingerPrick,
          onViewReports: () => {
            this.onNavigateTab(2);
          }
        })

        // 4. Primary Caregiver Quick Call Strip
        PhoneCaregiverCard({
          caregiverName: this.caregiverName,
          caregiverRole: 'Primary caregiver',
          caregiverPhone: this.caregiverPhone,
          isEmergency: this.isEmergency(),
          smnEnabled: this.smnEnabled,
          smnLastSent: this.smnLastSent,
          onCall: this.onCallNow
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 104 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(PhoneTheme.BG_PAGE)
    .scrollBar(BarState.Off)
    .scrollable(ScrollDirection.Vertical)
  }
}
