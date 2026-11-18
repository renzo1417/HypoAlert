/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Live Physiological Symptom Biomarkers (Zero Skin Temp, Zero Fake Glucose):
 * 1. Heart Rate & Baseline Shift (PPG)
 * 2. Heart Calmness / HRV (RMSSD & SDNN ms)
 * 3. 8-12 Hz Wrist Tremor & Motion Gate
 */

import { VitalsData, VitalsEngine } from '../../models/VitalsModel';
import {
  heartStatusLabel,
  hrvColor,
  hrvStatusLabel,
  tremorColor,
  tremorLabel
} from '../utils/PhoneRiskUtils';
import { PhoneTheme } from '../utils/PhoneTheme';

@Component
export struct PhoneMetricGrid {
  @Prop vitals: VitalsData = VitalsEngine.createInitialVitals();
  ppgContext: CanvasRenderingContext2D | null = null;
  onCanvasReady: () => void = () => {};

  build() {
    Column({ space: 10 }) {
      Row({ space: 10 }) {
        // Heart rate + PPG strip
        Column({ space: 4 }) {
          Text('Heart rate')
            .fontSize(PhoneTheme.FONT_CAPTION)
            .fontColor(PhoneTheme.TEXT_MUTED)

          Row({ space: 3 }) {
            Text(`${this.vitals.pulse}`)
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

          Text(heartStatusLabel(this.vitals))
            .fontSize(PhoneTheme.FONT_CAPTION)
            .fontColor(PhoneTheme.TEXT_SECONDARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .padding(12)
        .backgroundColor(PhoneTheme.BG_CARD)
        .borderWidth(1)
        .borderColor(PhoneTheme.BORDER_SUBTLE)
        .borderRadius(PhoneTheme.TILE_RADIUS)
        .alignItems(HorizontalAlign.Start)

        // HRV + Tremor/Motion stacked
        Column({ space: 10 }) {
          // HRV (Heart calmness: RMSSD / SDNN)
          Row({ space: 8 }) {
            Circle({ width: 6, height: 6 })
              .fill(hrvColor(this.vitals.rmssd))
            Column({ space: 1 }) {
              Text('Heart calmness (HRV)')
                .fontSize(PhoneTheme.FONT_CAPTION)
                .fontColor(PhoneTheme.TEXT_MUTED)
                .maxLines(1)
              Text(`${this.vitals.rmssd} ms • ${hrvStatusLabel(this.vitals.rmssd)}`)
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

          // 8-12 Hz Tremor & Motion Gate
          Row({ space: 8 }) {
            Circle({ width: 6, height: 6 })
              .fill(tremorColor(this.vitals.tremorIndex, this.vitals.isSedentary))
            Column({ space: 1 }) {
              Text('Wrist tremor & motion')
                .fontSize(PhoneTheme.FONT_CAPTION)
                .fontColor(PhoneTheme.TEXT_MUTED)
                .maxLines(1)
              Text(`${tremorLabel(this.vitals.tremorIndex, this.vitals.isSedentary)} • ${this.vitals.isSedentary ? 'Still' : 'Paused'}`)
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
