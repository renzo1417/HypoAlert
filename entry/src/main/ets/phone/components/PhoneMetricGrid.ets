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

  private getReflectionIndex(): number {
    if (this.isCritical()) {
      return 32;
    }
    if (this.isWarning()) {
      return 46;
    }
    return 68;
  }

  private getTempDelta(): string {
    const delta: number = Math.round((this.skinTemp - 36.0) * 10) / 10;
    if (delta <= -0.8) {
      return `ΔT ${delta.toFixed(1)}°C (Cold sweat)`;
    }
    if (delta < 0) {
      return `ΔT ${delta.toFixed(1)}°C (Cooling)`;
    }
    return 'Steady baseline';
  }

  build() {
    Column({ space: 10 }) {
      // Row 1: The 2 Primary Sympathetic Surge Biomarkers
      Row({ space: 10 }) {
        // Tile 1: 8-12 Hz Micro-Tremor
        Column({ space: 5 }) {
          Row() {
            Text('Micro-Tremor')
              .fontSize(PhoneTheme.FONT_CAPTION)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.TEXT_SECONDARY)

            Blank()

            Text(this.tremorPSD > 1.0 ? 'SURGE' : (this.tremorPSD > 0.4 ? 'ACTIVE' : 'CALM'))
              .fontSize(PhoneTheme.FONT_MICRO)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.tremorPSD > 1.0 ? PhoneTheme.STATE_CRIT_TEXT : (this.tremorPSD > 0.4 ? PhoneTheme.STATE_WARN_TEXT : PhoneTheme.STATE_OK_TEXT))
              .backgroundColor(this.tremorPSD > 1.0 ? PhoneTheme.STATE_CRIT_BG : (this.tremorPSD > 0.4 ? PhoneTheme.STATE_WARN_BG : PhoneTheme.STATE_OK_BG))
              .borderRadius(PhoneTheme.PILL_RADIUS)
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Row({ space: 3 }) {
            Text(`${this.tremorPSD.toFixed(2)}`)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.tremorPSD > 1.0 ? PhoneTheme.STATE_CRIT : PhoneTheme.TEXT_PRIMARY)
            Text('PSD')
              .fontSize(PhoneTheme.FONT_CAPTION)
              .fontWeight(FontWeight.Medium)
              .fontColor(PhoneTheme.TEXT_MUTED)
              .margin({ bottom: 2 })
          }
          .width('100%')
          .alignItems(VerticalAlign.Bottom)

          Text('8–12 Hz sympathetic band')
            .fontSize(PhoneTheme.FONT_MICRO)
            .fontColor(PhoneTheme.TEXT_TERTIARY)

          Text(this.tremorPSD > 1.0 ? 'Episodic shivering detected' : 'Resting • Motion-gated')
            .fontSize(PhoneTheme.FONT_MICRO)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.tremorPSD > 1.0 ? PhoneTheme.STATE_CRIT_TEXT : PhoneTheme.STATE_OK_TEXT)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
        }
        .layoutWeight(1)
        .padding(12)
        .backgroundColor(PhoneTheme.BG_CARD)
        .borderWidth(1)
        .borderColor(PhoneTheme.BORDER_SUBTLE)
        .borderRadius(PhoneTheme.TILE_RADIUS)
        .shadow({ radius: 6, color: 'rgba(15, 23, 42, 0.03)', offsetY: 1 })
        .alignItems(HorizontalAlign.Start)

        // Tile 2: Vascular Tone & Pulse Waveform
        Column({ space: 5 }) {
          Row() {
            Text('Pulse & Tone')
              .fontSize(PhoneTheme.FONT_CAPTION)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.TEXT_SECONDARY)

            Blank()

            Text(`RI ${this.getReflectionIndex()}%`)
              .fontSize(PhoneTheme.FONT_MICRO)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.getReflectionIndex() < 40 ? PhoneTheme.STATE_CRIT_TEXT : PhoneTheme.STATE_OK_TEXT)
              .backgroundColor(this.getReflectionIndex() < 40 ? PhoneTheme.STATE_CRIT_BG : PhoneTheme.STATE_OK_BG)
              .borderRadius(PhoneTheme.PILL_RADIUS)
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Row({ space: 3 }) {
            Text(`${this.heartRate}`)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.TEXT_PRIMARY)
            Text('bpm')
              .fontSize(PhoneTheme.FONT_CAPTION)
              .fontWeight(FontWeight.Medium)
              .fontColor(PhoneTheme.TEXT_MUTED)
              .margin({ bottom: 2 })
          }
          .width('100%')
          .alignItems(VerticalAlign.Bottom)

          // PPG Waveform Canvas
          if (this.ppgContext) {
            Canvas(this.ppgContext)
              .width('100%')
              .height(26)
              .backgroundColor(PhoneTheme.TEXT_PRIMARY)
              .borderRadius(4)
              .onReady(() => {
                this.onCanvasReady();
              })
          }

          Text(this.getReflectionIndex() < 40 ? 'Vascular damping alert' : 'Steady pulse morphology')
            .fontSize(PhoneTheme.FONT_MICRO)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.getReflectionIndex() < 40 ? PhoneTheme.STATE_CRIT_TEXT : PhoneTheme.STATE_OK_TEXT)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
        }
        .layoutWeight(1)
        .padding(12)
        .backgroundColor(PhoneTheme.BG_CARD)
        .borderWidth(1)
        .borderColor(PhoneTheme.BORDER_SUBTLE)
        .borderRadius(PhoneTheme.TILE_RADIUS)
        .shadow({ radius: 6, color: 'rgba(15, 23, 42, 0.03)', offsetY: 1 })
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      // Row 2: Skin Temp & Dynamic Baseline State
      Row({ space: 10 }) {
        // Tile 3: Skin Temperature (Cold Diaphoresis)
        Row({ space: 8 }) {
          Stack({ alignContent: Alignment.Center }) {
            Circle({ width: 26, height: 26 })
              .fill(this.skinTemp < 35.2 ? PhoneTheme.STATE_CRIT_BG : PhoneTheme.BG_MUTED)
            Circle({ width: 7, height: 7 })
              .fill(tempColor(this.skinTemp))
          }
          .width(26)
          .height(26)

          Column({ space: 1 }) {
            Text('Skin Temperature')
              .fontSize(PhoneTheme.FONT_MICRO)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.TEXT_MUTED)

            Row({ space: 2 }) {
              Text(`${this.skinTemp.toFixed(1)}`)
                .fontSize(17)
                .fontWeight(FontWeight.Bold)
                .fontColor(PhoneTheme.TEXT_PRIMARY)
              Text('°C')
                .fontSize(PhoneTheme.FONT_MICRO)
                .fontColor(PhoneTheme.TEXT_MUTED)
                .margin({ bottom: 2 })
            }
            .alignItems(VerticalAlign.Bottom)

            Text(this.getTempDelta())
              .fontSize(PhoneTheme.FONT_MICRO)
              .fontColor(this.skinTemp < 35.2 ? PhoneTheme.STATE_CRIT_TEXT : PhoneTheme.TEXT_MUTED)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)
        .padding(10)
        .backgroundColor(PhoneTheme.BG_CARD)
        .borderWidth(1)
        .borderColor(PhoneTheme.BORDER_SUBTLE)
        .borderRadius(PhoneTheme.TILE_RADIUS)
        .shadow({ radius: 6, color: 'rgba(15, 23, 42, 0.03)', offsetY: 1 })
        .alignItems(VerticalAlign.Center)

        // Tile 4: Dynamic Nightly Baseline State
        Row({ space: 8 }) {
          Stack({ alignContent: Alignment.Center }) {
            Circle({ width: 26, height: 26 })
              .fill(PhoneTheme.BRAND_ACCENT_BG)
            Circle({ width: 7, height: 7 })
              .fill(PhoneTheme.BRAND_ACCENT)
          }
          .width(26)
          .height(26)

          Column({ space: 1 }) {
            Text('Nightly Baseline')
              .fontSize(PhoneTheme.FONT_MICRO)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.TEXT_MUTED)

            Text('Calibrated')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.TEXT_PRIMARY)

            Text('45m sleep window steady')
              .fontSize(PhoneTheme.FONT_MICRO)
              .fontWeight(FontWeight.Medium)
              .fontColor(PhoneTheme.STATE_OK_TEXT)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)
        .padding(10)
        .backgroundColor(PhoneTheme.BG_CARD)
        .borderWidth(1)
        .borderColor(PhoneTheme.BORDER_SUBTLE)
        .borderRadius(PhoneTheme.TILE_RADIUS)
        .shadow({ radius: 6, color: 'rgba(15, 23, 42, 0.03)', offsetY: 1 })
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
    }
    .width('100%')
  }
}
