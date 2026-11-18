/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Asymmetric 1 + 2 Pastel Bento Overview Grid.
 * Matches the reference wellness aesthetic:
 * - Left tall Lavender card with smooth curved pulse/PPG area chart & dot markers
 * - Right stacked Sage Green card (HRV RMSSD) + Warm Peach card (8-12 Hz Tremor & Motion Gate)
 */

import { BodyType } from '../models/PhoneTypes';
import { hrvStatusLabel, tremorStatusLabel } from '../utils/PhoneRiskUtils';
import { PhoneTheme } from '../utils/PhoneTheme';

@Component
export struct PhoneMetricGrid {
  @Prop heartRate: number = 62;
  @Prop deltaHR: number = 1;
  @Prop variability: number = 42;
  @Prop tremorPSD: number = 0.12;
  @Prop smaValue: number = 0.04;
  @Prop isMotionGated: boolean = false;
  @Prop baselineSlots: number = 15;
  @Prop bodyType: BodyType = 'Adrenergic';
  ppgContext: CanvasRenderingContext2D | null = null;
  onCanvasReady: () => void = () => {};
  onCanvasResize: (w: number, h: number) => void = () => {};
  onPrevSection: () => void = () => {};
  onNextSection: () => void = () => {};

  private formatDeltaHR(): string {
    const sign: string = this.deltaHR > 0 ? '+' : '';
    return `${sign}${this.deltaHR} ΔHR`;
  }

  build() {
    Column({ space: 12 }) {
      // Overview header + < > circular controls
      Row({ space: 8 }) {
        Text('Overview')
          .fontSize(PhoneTheme.FONT_SECTION)
          .fontWeight(FontWeight.Bold)
          .fontColor(PhoneTheme.TEXT_PRIMARY)
          .layoutWeight(1)

        Row({ space: 8 }) {
          Button() {
            SymbolGlyph($r('sys.symbol.chevron_left'))
              .fontSize(14)
              .fontColor([PhoneTheme.TEXT_PRIMARY])
          }
          .width(34)
          .height(34)
          .backgroundColor(PhoneTheme.BG_CARD)
          .borderRadius(17)
          .shadow({ radius: 8, color: 'rgba(17, 19, 24, 0.05)', offsetY: 2 })
          .onClick(() => {
            this.onPrevSection();
          })

          Button() {
            SymbolGlyph($r('sys.symbol.chevron_right'))
              .fontSize(14)
              .fontColor([PhoneTheme.TEXT_ON_DARK])
          }
          .width(34)
          .height(34)
          .backgroundColor(PhoneTheme.BRAND_PRIMARY)
          .borderRadius(17)
          .onClick(() => {
            this.onNextSection();
          })
        }
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 1 + 2 Asymmetric Pastel Bento Grid
      Row({ space: 12 }) {
        // Left Tall Lavender Bento Card (Pulse & PPG Curve)
        Column({ space: 0 }) {
          Column({ space: 4 }) {
            Row() {
              Text('Pulse')
                .fontSize(PhoneTheme.FONT_BODY)
                .fontWeight(FontWeight.Medium)
                .fontColor(PhoneTheme.TEXT_SECONDARY)
                .layoutWeight(1)

              Stack({ alignContent: Alignment.Center }) {
                Circle({ width: 34, height: 34 })
                  .fill(PhoneTheme.BG_CARD)
                SymbolGlyph($r('sys.symbol.heart_fill'))
                  .fontSize(15)
                  .fontColor([PhoneTheme.TEXT_PRIMARY])
              }
              .width(34)
              .height(34)
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)

            Row({ space: 4 }) {
              Text(`${this.heartRate}`)
                .fontSize(30)
                .fontWeight(FontWeight.Bold)
                .fontFeature('"tnum" on')
                .fontColor(PhoneTheme.TEXT_PRIMARY)

              Text('bpm')
                .fontSize(PhoneTheme.FONT_BODY)
                .fontWeight(FontWeight.Medium)
                .fontColor(PhoneTheme.TEXT_SECONDARY)
                .margin({ bottom: 4 })
            }
            .alignItems(VerticalAlign.Bottom)

            Text(`${this.formatDeltaHR()} · ${this.baselineSlots >= 15 ? '75m base' : `${this.baselineSlots}/15`}`)
              .fontSize(PhoneTheme.FONT_CAPTION)
              .fontFeature('"tnum" on')
              .fontColor(PhoneTheme.TEXT_SECONDARY)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          .padding({ left: 16, right: 14, top: 14 })
          .alignItems(HorizontalAlign.Start)

          Blank()

          if (this.ppgContext) {
            Canvas(this.ppgContext)
              .width('100%')
              .height(98)
              .onAreaChange((_o: Area, n: Area) => {
                const w: number = Number(n.width);
                const h: number = Number(n.height);
                if (w > 0 && h > 0) {
                  this.onCanvasResize(w, h);
                }
              })
              .onReady(() => {
                this.onCanvasReady();
              })
          }
        }
        .layoutWeight(1)
        .height(236)
        .borderRadius(PhoneTheme.CARD_RADIUS)
        .clip(true)
        .linearGradient({
          angle: 170,
          colors: [[PhoneTheme.BENTO_LAV_TOP, 0.0], [PhoneTheme.BENTO_LAV_BOT, 1.0]]
        })

        // Right 2 Stacked Pastel Bento Cards (Sage HRV + Peach Tremor/Motion)
        Column({ space: 12 }) {
          // Top Right: Sage Green (HRV · RMSSD)
          Column({ space: 4 }) {
            Row() {
              Text('HRV')
                .fontSize(PhoneTheme.FONT_BODY)
                .fontWeight(FontWeight.Medium)
                .fontColor(PhoneTheme.TEXT_SECONDARY)
                .layoutWeight(1)

              Stack({ alignContent: Alignment.Center }) {
                Circle({ width: 32, height: 32 })
                  .fill(PhoneTheme.BG_CARD)
                SymbolGlyph($r('sys.symbol.waveform'))
                  .fontSize(14)
                  .fontColor([PhoneTheme.TEXT_PRIMARY])
              }
              .width(32)
              .height(32)
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)

            Row({ space: 4 }) {
              Text(`${this.variability}`)
                .fontSize(PhoneTheme.FONT_METRIC)
                .fontWeight(FontWeight.Bold)
                .fontFeature('"tnum" on')
                .fontColor(PhoneTheme.TEXT_PRIMARY)

              Text('ms')
                .fontSize(PhoneTheme.FONT_BODY)
                .fontWeight(FontWeight.Medium)
                .fontColor(PhoneTheme.TEXT_SECONDARY)
                .margin({ bottom: 3 })
            }
            .alignItems(VerticalAlign.Bottom)

            Text(`${hrvStatusLabel(this.variability, this.isMotionGated)} · RMSSD`)
              .fontSize(PhoneTheme.FONT_MICRO)
              .fontColor(PhoneTheme.TEXT_SECONDARY)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          .height(112)
          .padding({ left: 14, right: 12, top: 12, bottom: 12 })
          .borderRadius(PhoneTheme.CARD_RADIUS)
          .linearGradient({
            angle: 170,
            colors: [[PhoneTheme.BENTO_SAGE_TOP, 0.0], [PhoneTheme.BENTO_SAGE_BOT, 1.0]]
          })
          .alignItems(HorizontalAlign.Start)

          // Bottom Right: Warm Peach (8-12 Hz Tremor & Motion Gate)
          Column({ space: 4 }) {
            Row() {
              Text('Tremor')
                .fontSize(PhoneTheme.FONT_BODY)
                .fontWeight(FontWeight.Medium)
                .fontColor(PhoneTheme.TEXT_SECONDARY)
                .layoutWeight(1)

              Stack({ alignContent: Alignment.Center }) {
                Circle({ width: 32, height: 32 })
                  .fill(PhoneTheme.BG_CARD)
                SymbolGlyph($r('sys.symbol.flame_fill'))
                  .fontSize(14)
                  .fontColor([PhoneTheme.TEXT_PRIMARY])
              }
              .width(32)
              .height(32)
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)

            Row({ space: 4 }) {
              Text(`${this.tremorPSD.toFixed(2)}`)
                .fontSize(PhoneTheme.FONT_METRIC)
                .fontWeight(FontWeight.Bold)
                .fontFeature('"tnum" on')
                .fontColor(PhoneTheme.TEXT_PRIMARY)

              Text('PSD')
                .fontSize(PhoneTheme.FONT_BODY)
                .fontWeight(FontWeight.Medium)
                .fontColor(PhoneTheme.TEXT_SECONDARY)
                .margin({ bottom: 3 })
            }
            .alignItems(VerticalAlign.Bottom)

            Text(`${tremorStatusLabel(this.tremorPSD, this.isMotionGated)} · ${this.smaValue.toFixed(2)}g`)
              .fontSize(PhoneTheme.FONT_MICRO)
              .fontFeature('"tnum" on')
              .fontColor(this.isMotionGated ? PhoneTheme.BRAND_ACCENT : PhoneTheme.TEXT_SECONDARY)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          .height(112)
          .padding({ left: 14, right: 12, top: 12, bottom: 12 })
          .borderRadius(PhoneTheme.CARD_RADIUS)
          .linearGradient({
            angle: 170,
            colors: [[PhoneTheme.BENTO_PEACH_TOP, 0.0], [PhoneTheme.BENTO_PEACH_BOT, 1.0]]
          })
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)
        .height(236)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
    }
    .width('100%')
  }
}
