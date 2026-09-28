/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — 2x2 Bento Grid featuring the 4 Core Physiological Biomarkers:
 * 1. Optical Vascular Tone & Reflection Index (RI = h2/h1 * 100)
 * 2. 8-12 Hz Autonomic Micro-Tremor PSD Spectrum
 * 3. Skin Temperature & Relative Baseline Drift (Cold Diaphoresis)
 * 4. Signal Magnitude Area (SMA) Motion Artifact Gating
 */

import {
  tempStatus,
  tempColor,
  riskLevel
} from '../utils/PhoneRiskUtils';

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

  // Reflection Index: h2/h1 * 100 (normal 68%, damped in hypo to ~32%)
  private getReflectionIndex(): number {
    if (this.isCritical()) {
      return 32;
    }
    if (this.isWarning()) {
      return 46;
    }
    return 68;
  }

  // Skin temp baseline deviation: delta T from 36.0°C baseline
  private getTempDelta(): string {
    const delta: number = Math.round((this.skinTemp - 36.0) * 10) / 10;
    if (delta <= -0.8) {
      return `ΔT: ${delta.toFixed(1)}°C (Cold sweat)`;
    }
    if (delta < 0) {
      return `ΔT: ${delta.toFixed(1)}°C (Cooling)`;
    }
    return 'ΔT: 0.0°C (Baseline steady)';
  }

  build() {
    Column({ space: 12 }) {
      // Row 1: Vascular Tone (PPG) & Micro-Tremor (IMU)
      Row({ space: 12 }) {
        // Tile 1: Optical Vascular Tone & Reflection Index
        Column({ space: 6 }) {
          Row() {
            // Pulse icon badge
            Stack({ alignContent: Alignment.Center }) {
              Circle({ width: 28, height: 28 })
                .fill(this.isCritical() ? '#FEE2E2' : '#DBEAFE')
              Text('💓')
                .fontSize(12)
            }
            .width(28)
            .height(28)

            Blank()

            // RI Biomarker Chip
            Row({ space: 3 }) {
              Circle({ width: 5, height: 5 })
                .fill(this.getReflectionIndex() < 40 ? '#EF4444' : '#15803D')
              Text(`RI ${this.getReflectionIndex()}%`)
                .fontSize(9)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.getReflectionIndex() < 40 ? '#B91C1C' : '#15803D')
            }
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .backgroundColor(this.getReflectionIndex() < 40 ? '#FEE2E2' : '#DCFCE7')
            .borderRadius(999)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Text('Vascular Tone (PPG)')
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .fontColor('#475569')

          Row({ space: 3 }) {
            Text(`${this.heartRate}`)
              .fontSize(24)
              .fontWeight(FontWeight.Bolder)
              .fontColor('#111827')
            Text('bpm')
              .fontSize(11)
              .fontWeight(FontWeight.Medium)
              .fontColor('#64748B')
              .margin({ bottom: 3 })
          }
          .width('100%')
          .alignItems(VerticalAlign.Bottom)

          // PPG Waveform Canvas
          if (this.ppgContext) {
            Canvas(this.ppgContext)
              .width('100%')
              .height(34)
              .backgroundColor('#1E293B')
              .borderRadius(8)
              .onReady(() => {
                this.onCanvasReady();
              })
          }

          Text(this.getReflectionIndex() < 40 ? '⚠️ Peripheral vascular damping' : '✓ Normal pulse morphology')
            .fontSize(9)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.getReflectionIndex() < 40 ? '#DC2626' : '#15803D')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
        }
        .layoutWeight(1)
        .padding(14)
        .backgroundColor('#F8FAFC')
        .borderWidth(1)
        .borderColor('#E2E8F0')
        .borderRadius(20)
        .alignItems(HorizontalAlign.Start)

        // Tile 2: Autonomic Micro-Tremor (8–12 Hz Band)
        Column({ space: 6 }) {
          Row() {
            // Tremor icon badge
            Stack({ alignContent: Alignment.Center }) {
              Circle({ width: 28, height: 28 })
                .fill(this.tremorPSD > 1.0 ? '#FEE2E2' : '#D1FAE5')
              Text('⚡')
                .fontSize(12)
            }
            .width(28)
            .height(28)

            Blank()

            Text(this.tremorPSD > 1.0 ? 'SURGE' : (this.tremorPSD > 0.4 ? 'ACTIVE' : 'CALM'))
              .fontSize(9)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.tremorPSD > 1.0 ? '#B91C1C' : (this.tremorPSD > 0.4 ? '#B45309' : '#15803D'))
              .backgroundColor(this.tremorPSD > 1.0 ? '#FEE2E2' : (this.tremorPSD > 0.4 ? '#FEF3C7' : '#DCFCE7'))
              .borderRadius(999)
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Text('Micro-Tremor (IMU)')
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .fontColor('#475569')

          Row({ space: 3 }) {
            Text(`${this.tremorPSD.toFixed(2)}`)
              .fontSize(24)
              .fontWeight(FontWeight.Bolder)
              .fontColor(this.tremorPSD > 1.0 ? '#DC2626' : '#111827')
            Text('PSD')
              .fontSize(11)
              .fontWeight(FontWeight.Medium)
              .fontColor('#64748B')
              .margin({ bottom: 3 })
          }
          .width('100%')
          .alignItems(VerticalAlign.Bottom)

          // 3-Band Frequency Spectrum Bars (0-4Hz, 4-8Hz, 8-12Hz)
          Column({ space: 3 }) {
            Row({ space: 4 }) {
              // 0-4 Hz
              Column({ space: 2 }) {
                Row()
                  .width('100%')
                  .height(18)
                  .backgroundColor('#10B981')
                  .borderRadius(3)
                Text('0-4Hz')
                  .fontSize(7)
                  .fontColor('#94A3B8')
              }
              .layoutWeight(1)

              // 4-8 Hz
              Column({ space: 2 }) {
                Row()
                  .width('100%')
                  .height(this.tremorPSD > 0.5 ? 24 : 14)
                  .backgroundColor(this.tremorPSD > 0.5 ? '#F59E0B' : '#E2E8F0')
                  .borderRadius(3)
                Text('4-8Hz')
                  .fontSize(7)
                  .fontColor('#94A3B8')
              }
              .layoutWeight(1)

              // 8-12 Hz (Sympathetic Tremor Band)
              Column({ space: 2 }) {
                Row()
                  .width('100%')
                  .height(this.tremorPSD > 1.0 ? 32 : (this.tremorPSD > 0.4 ? 22 : 10))
                  .backgroundColor(this.tremorPSD > 1.0 ? '#EF4444' : (this.tremorPSD > 0.4 ? '#F59E0B' : '#E2E8F0'))
                  .borderRadius(3)
                Text('8-12Hz')
                  .fontSize(7)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.tremorPSD > 1.0 ? '#DC2626' : '#64748B')
              }
              .layoutWeight(1)
            }
            .width('100%')
            .alignItems(VerticalAlign.Bottom)
          }
          .height(34)
          .justifyContent(FlexAlign.End)

          Text(this.tremorPSD > 1.0 ? '⚠️ Sympathetic micro-tremor' : '✓ Basal physiological resting')
            .fontSize(9)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.tremorPSD > 1.0 ? '#DC2626' : '#15803D')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
        }
        .layoutWeight(1)
        .padding(14)
        .backgroundColor('#F8FAFC')
        .borderWidth(1)
        .borderColor('#E2E8F0')
        .borderRadius(20)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      // Row 2: Skin Temp (Diaphoresis) & Motion Gating (SMA)
      Row({ space: 12 }) {
        // Tile 3: Skin Temperature & Baseline Drift
        Row({ space: 10 }) {
          Stack({ alignContent: Alignment.Center }) {
            Circle({ width: 32, height: 32 })
              .fill('#FEF3C7')
            Circle({ width: 8, height: 8 })
              .fill(tempColor(this.skinTemp))
          }
          .width(32)
          .height(32)

          Column({ space: 2 }) {
            Text('Skin Temp (Wrist)')
              .fontSize(10)
              .fontWeight(FontWeight.Bold)
              .fontColor('#64748B')
            Row({ space: 3 }) {
              Text(`${this.skinTemp.toFixed(1)}`)
                .fontSize(18)
                .fontWeight(FontWeight.Bolder)
                .fontColor('#111827')
              Text('°C')
                .fontSize(10)
                .fontColor('#64748B')
                .margin({ bottom: 2 })
            }
            .alignItems(VerticalAlign.Bottom)
            Text(this.getTempDelta())
              .fontSize(9)
              .fontColor(this.skinTemp < 35.2 ? '#DC2626' : '#64748B')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)
        .padding(12)
        .backgroundColor('#FFFBEB')
        .borderWidth(1)
        .borderColor('#FEF3C7')
        .borderRadius(18)
        .alignItems(VerticalAlign.Center)

        // Tile 4: Motion Artifact Gating (SMA)
        Row({ space: 10 }) {
          Stack({ alignContent: Alignment.Center }) {
            Circle({ width: 32, height: 32 })
              .fill('#EDE9FE')
            Text('🛡️')
              .fontSize(14)
          }
          .width(32)
          .height(32)

          Column({ space: 2 }) {
            Text('Sleep Motion Gate')
              .fontSize(10)
              .fontWeight(FontWeight.Bold)
              .fontColor('#64748B')
            Row({ space: 3 }) {
              Text('0.04')
                .fontSize(18)
                .fontWeight(FontWeight.Bolder)
                .fontColor('#111827')
              Text('SMA (g)')
                .fontSize(10)
                .fontColor('#64748B')
                .margin({ bottom: 2 })
            }
            .alignItems(VerticalAlign.Bottom)
            Text('Gate: Active (Resting)')
              .fontSize(9)
              .fontWeight(FontWeight.Medium)
              .fontColor('#15803D')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)
        .padding(12)
        .backgroundColor('#F5F3FF')
        .borderWidth(1)
        .borderColor('#EDE9FE')
        .borderRadius(18)
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
    }
    .width('100%')
  }
}
