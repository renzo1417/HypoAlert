/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Full metric detail page (new-page UX from icon hub).
 * Rendered full-screen inside MonitorView when a hub icon is tapped.
 */

import { PhoneTheme } from '../../utils/PhoneTheme';
import { TremorBand } from '../../models/PhoneTypes';
import {
  computeTremorBands,
  restlessShort,
  restlessHint,
  riskLevel
} from '../../utils/PhoneRiskUtils';

@Component
export struct MetricDetailPage {
  @Prop metricId: string = 'tremor';
  @Prop heartRate: number = 62;
  @Prop tremorPSD: number = 0.12;
  @Prop skinTemp: number = 36.0;
  @Prop riskIndex: number = 12;
  ppgContext: CanvasRenderingContext2D | null = null;
  onBack: () => void = () => {};
  onCanvasReady: () => void = () => {};

  private getTitle(): string {
    if (this.metricId === 'pulse') {
      return 'Pulse & Vascular Tone';
    }
    if (this.metricId === 'temp') {
      return 'Skin Temperature';
    }
    if (this.metricId === 'baseline') {
      return 'Nightly Baseline';
    }
    return 'Micro-Tremor (8–12 Hz)';
  }

  private getSubtitle(): string {
    if (this.metricId === 'pulse') {
      return 'Optical PPG pulse morphology & reflection index';
    }
    if (this.metricId === 'temp') {
      return 'Thermal drift & cold diaphoresis detection';
    }
    if (this.metricId === 'baseline') {
      return 'Adaptive calibration from first 30m of sleep';
    }
    return 'IMU accelerometry with motion gating';
  }

  private getTempDelta(): string {
    const delta: number = Math.round((this.skinTemp - 36.0) * 10) / 10;
    if (delta <= -0.8) {
      return `ΔT ${delta.toFixed(1)}°C — cold sweat pattern`;
    }
    if (delta < 0) {
      return `ΔT ${delta.toFixed(1)}°C — cooling trend`;
    }
    return 'Steady baseline — no thermal drift';
  }

  private getReflectionIndex(): number {
    const lvl: string = riskLevel(this.riskIndex);
    if (lvl === 'Critical') {
      return 32;
    }
    if (lvl === 'Warning') {
      return 46;
    }
    return 68;
  }

  @Builder
  tremorDetail() {
    Column({ space: 10 }) {
      Row() {
        Text(restlessShort(this.tremorPSD))
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .fontColor(PhoneTheme.TEXT_PRIMARY)
          .layoutWeight(1)
        Text(`${this.tremorPSD.toFixed(2)} PSD`)
          .fontSize(PhoneTheme.FONT_BODY)
          .fontWeight(FontWeight.Bold)
          .fontColor(PhoneTheme.TEXT_SECONDARY)
      }
      .width('100%')
      .alignItems(VerticalAlign.Bottom)

      Text(restlessHint(this.tremorPSD))
        .fontSize(PhoneTheme.FONT_BODY)
        .fontColor(PhoneTheme.TEXT_MUTED)
        .width('100%')

      Row({ space: 6 }) {
        ForEach(computeTremorBands(this.tremorPSD), (band: TremorBand) => {
          Column({ space: 4 }) {
            Stack({ alignContent: Alignment.Bottom }) {
              Row()
                .width('100%')
                .height(72)
                .backgroundColor(PhoneTheme.BG_MUTED)
                .borderRadius(6)
              Row()
                .width('100%')
                .height(Math.round(band.power * 72))
                .backgroundColor(band.color)
                .borderRadius(6)
            }
            .width('100%')
            .height(72)
            Text(band.label)
              .fontSize(PhoneTheme.FONT_CAPTION)
              .fontColor(PhoneTheme.TEXT_MUTED)
            Text(band.range + ' Hz')
              .fontSize(PhoneTheme.FONT_MICRO)
              .fontColor(PhoneTheme.TEXT_TERTIARY)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
        }, (band: TremorBand) => band.range)
      }
      .width('100%')
      .alignItems(VerticalAlign.Bottom)

      Text('Episodic shivering above 1.0 PSD suggests sympathetic surge. Motion-gated to exclude position shifts.')
        .fontSize(PhoneTheme.FONT_CAPTION)
        .fontColor(PhoneTheme.TEXT_TERTIARY)
        .width('100%')
    }
    .width('100%')
  }

  @Builder
  pulseDetail() {
    Column({ space: 10 }) {
      Row({ space: 6 }) {
        Text(`${this.heartRate}`)
          .fontSize(34)
          .fontWeight(FontWeight.Bold)
          .fontColor(PhoneTheme.TEXT_PRIMARY)
        Text('bpm')
          .fontSize(PhoneTheme.FONT_BODY)
          .fontColor(PhoneTheme.TEXT_MUTED)
          .margin({ bottom: 4 })
        Blank()
        Text(`RI ${this.getReflectionIndex()}%`)
          .fontSize(PhoneTheme.FONT_CAPTION)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getReflectionIndex() < 40 ? PhoneTheme.STATE_CRIT_TEXT : PhoneTheme.STATE_OK_TEXT)
          .backgroundColor(this.getReflectionIndex() < 40 ? PhoneTheme.STATE_CRIT_BG : PhoneTheme.STATE_OK_BG)
          .borderRadius(PhoneTheme.PILL_RADIUS)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Bottom)

      if (this.ppgContext) {
        Canvas(this.ppgContext)
          .width('100%')
          .height(84)
          .backgroundColor(PhoneTheme.TEXT_PRIMARY)
          .borderRadius(8)
          .onReady(() => {
            this.onCanvasReady();
          })
      }

      Text(this.getReflectionIndex() < 40 ? 'Vascular damping alert — reduced reflection index.' : 'Steady pulse morphology — normal vascular tone.')
        .fontSize(PhoneTheme.FONT_BODY)
        .fontColor(PhoneTheme.TEXT_MUTED)
        .width('100%')
    }
    .width('100%')
  }

  @Builder
  tempDetail() {
    Column({ space: 10 }) {
      Column({ space: 2 }) {
        Row({ space: 4 }) {
          Text(`${this.skinTemp.toFixed(1)}`)
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
            .fontColor(PhoneTheme.TEXT_PRIMARY)
          Text('°C')
            .fontSize(PhoneTheme.FONT_BODY)
            .fontColor(PhoneTheme.TEXT_MUTED)
            .margin({ bottom: 4 })
        }
        .alignItems(VerticalAlign.Bottom)
        Text(this.getTempDelta())
          .fontSize(PhoneTheme.FONT_BODY)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.skinTemp < 35.2 ? PhoneTheme.STATE_CRIT_TEXT : PhoneTheme.TEXT_MUTED)
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      Text('Sustained drop below 35.2°C with rising tremor often precedes nocturnal hypoglycemia. Verify room temperature before acting.')
        .fontSize(PhoneTheme.FONT_CAPTION)
        .fontColor(PhoneTheme.TEXT_TERTIARY)
        .width('100%')
    }
    .width('100%')
  }

  @Builder
  baselineDetail() {
    Column({ space: 10 }) {
      Text('Calibrated • 45 min sleep window')
        .fontSize(PhoneTheme.FONT_BODY)
        .fontWeight(FontWeight.Bold)
        .fontColor(PhoneTheme.TEXT_PRIMARY)
        .width('100%')
      Text('Individual resting tone captured in the first 30 minutes of sleep. All risk thresholds adapt to this baseline instead of fixed population cutoffs.')
        .fontSize(PhoneTheme.FONT_BODY)
        .fontColor(PhoneTheme.TEXT_MUTED)
        .width('100%')
      Text('Recalibrates nightly. Poor signal (watch off-wrist) pauses adaptation.')
        .fontSize(PhoneTheme.FONT_CAPTION)
        .fontColor(PhoneTheme.TEXT_TERTIARY)
        .width('100%')
    }
    .width('100%')
  }

  build() {
    Column({ space: 12 }) {
      Row({ space: 10 }) {
        Button('‹ Back')
          .fontSize(PhoneTheme.FONT_BODY)
          .fontWeight(FontWeight.Bold)
          .height(32)
          .padding({ left: 12, right: 12 })
          .backgroundColor(PhoneTheme.BG_MUTED)
          .fontColor(PhoneTheme.TEXT_PRIMARY)
          .borderRadius(PhoneTheme.TILE_RADIUS)
          .onClick(() => {
            this.onBack();
          })
        Column({ space: 1 }) {
          Text(this.getTitle())
            .fontSize(PhoneTheme.FONT_SECTION)
            .fontWeight(FontWeight.Bold)
            .fontColor(PhoneTheme.TEXT_PRIMARY)
          Text(this.getSubtitle())
            .fontSize(PhoneTheme.FONT_CAPTION)
            .fontColor(PhoneTheme.TEXT_MUTED)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Column({ space: 10 }) {
        if (this.metricId === 'pulse') {
          this.pulseDetail()
        } else if (this.metricId === 'temp') {
          this.tempDetail()
        } else if (this.metricId === 'baseline') {
          this.baselineDetail()
        } else {
          this.tremorDetail()
        }
      }
      .width('100%')
      .padding(PhoneTheme.CARD_PADDING)
      .backgroundColor(PhoneTheme.BG_CARD)
      .borderWidth(1)
      .borderColor(PhoneTheme.BORDER_SUBTLE)
      .borderRadius(PhoneTheme.CARD_RADIUS)
      .shadow({ radius: 8, color: 'rgba(15, 23, 42, 0.04)', offsetY: 2 })
    }
    .width('100%')
  }
}
