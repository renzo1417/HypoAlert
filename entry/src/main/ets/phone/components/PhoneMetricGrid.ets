/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Core Sympathetic Surge Biomarkers:
 * 1. 8–12 Hz Physiological Micro-Tremor (IMU Accelerometry with SMA Motion Gating)
 * 2. Peripheral Vascular Tone & Reflection Index (Optical PPG Pulse Morphology)
 * 3. Nocturnal Skin Temperature & Cold Diaphoresis (Thermal Drift ΔT)
 * 4. Dynamic Nightly Baseline Calibration Status
 */

import {
  tempColor,
  riskLevel
} from '../utils/PhoneRiskUtils';
import { PhoneTheme } from '../utils/PhoneTheme';

@Component
export struct PhoneMetricGrid {
  @Prop heartRate: number = 62;
  @Prop tremorPSD: number = 0.12;
  @Prop skinTemp: number = 36.0;
  @Prop riskIndex: number = 12;
  ppgContext: CanvasRenderingContext2D | null = null;
  onCanvasReady: () => void = () => {};

  private isCritical(): boolean {
    return riskLevel(this.riskIndex) === 'Critical';
  }

  private isWarning(): boolean {
    return riskLevel(this.riskIndex) === 'Warning';
  }

  private getPulseLabel(): string {
    if (this.isCritical()) {
      return 'Fast';
    }
    if (this.isWarning()) {
      return 'Raised';
    }
    return 'Steady';
  }

  private getTremorLabel(): string {
    if (this.tremorPSD > 1.0) {
      return 'Surge';
    }
    if (this.tremorPSD > 0.4) {
      return 'Active';
    }
    return 'Calm';
  }

  private getSkinLabel(): string {
    if (this.skinTemp < 35.2) {
      return 'Cool';
    }
    if (this.skinTemp < 35.8) {
      return 'Slightly cool';
    }
    return 'Normal';
  }

  build() {
    Column({ space: 10 }) {
      // Row 1: Three understandable stat modules
      Row({ space: 10 }) {
        // Heart rate
        Column({ space: 4 }) {
          Text('Heart rate')
            .fontSize(PhoneTheme.FONT_CAPTION)
            .fontColor(PhoneTheme.TEXT_MUTED)

          Row({ space: 3 }) {
            Text(`${this.heartRate}`)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.TEXT_PRIMARY)
            Text('bpm')
              .fontSize(PhoneTheme.FONT_CAPTION)
              .fontColor(PhoneTheme.TEXT_MUTED)
              .margin({ bottom: 2 })
          }
          .width('100%')
          .alignItems(VerticalAlign.Bottom)

          // Visible PPG strip
          if (this.ppgContext) {
            Canvas(this.ppgContext)
              .width('100%')
              .height(32)
              .backgroundColor(PhoneTheme.BG_SUBTLE)
              .borderRadius(6)
              .onReady(() => {
                this.onCanvasReady();
              })
          }

          Text(this.getPulseLabel())
            .fontSize(PhoneTheme.FONT_CAPTION)
            .fontColor(PhoneTheme.TEXT_SECONDARY)
        }
        .layoutWeight(1)
        .padding(12)
        .backgroundColor(PhoneTheme.BG_CARD)
        .borderWidth(1)
        .borderColor(PhoneTheme.BORDER_SUBTLE)
        .borderRadius(PhoneTheme.TILE_RADIUS)
        .alignItems(HorizontalAlign.Start)

        // Movement + Skin stacked to fill height without emptiness
        Column({ space: 10 }) {
          Column({ space: 2 }) {
            Text('Movement')
              .fontSize(PhoneTheme.FONT_CAPTION)
              .fontColor(PhoneTheme.TEXT_MUTED)
            Row({ space: 4 }) {
              Circle({ width: 6, height: 6 })
                .fill(this.tremorPSD > 1.0 ? PhoneTheme.STATE_CRIT : (this.tremorPSD > 0.4 ? PhoneTheme.STATE_WARN : PhoneTheme.STATE_OK))
                .margin({ top: 4 })
              Text(this.getTremorLabel())
                .fontSize(PhoneTheme.FONT_SECTION)
                .fontWeight(FontWeight.Bold)
                .fontColor(PhoneTheme.TEXT_PRIMARY)
            }
          }
          .width('100%')
          .padding(12)
          .backgroundColor(PhoneTheme.BG_CARD)
          .borderWidth(1)
          .borderColor(PhoneTheme.BORDER_SUBTLE)
          .borderRadius(PhoneTheme.TILE_RADIUS)
          .alignItems(HorizontalAlign.Start)

          Row({ space: 8 }) {
            Circle({ width: 6, height: 6 })
              .fill(tempColor(this.skinTemp))
            Column({ space: 0 }) {
              Text('Skin temp')
                .fontSize(PhoneTheme.FONT_CAPTION)
                .fontColor(PhoneTheme.TEXT_MUTED)
              Text(`${this.skinTemp.toFixed(1)}° • ${this.getSkinLabel()}`)
                .fontSize(PhoneTheme.FONT_BODY)
                .fontWeight(FontWeight.Bold)
                .fontColor(PhoneTheme.TEXT_PRIMARY)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .padding(12)
          .backgroundColor(PhoneTheme.BG_CARD)
          .borderWidth(1)
          .borderColor(PhoneTheme.BORDER_SUBTLE)
          .borderRadius(PhoneTheme.TILE_RADIUS)
          .alignItems(VerticalAlign.Center)
        }
        .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
    }
    .width('100%')
  }
}
