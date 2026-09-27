/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — 2x2 metric grid assembling physiological insight tiles.
 */

import { GlucoseTile } from './tiles/GlucoseTile';
import { RestlessTile } from './tiles/RestlessTile';
import { TonightTile } from './tiles/TonightTile';
import { RiskTile } from './tiles/RiskTile';

@Component
export struct PhoneMetricGrid {
  @Prop glucose: number = 5.5;
  @Prop riskIndex: number = 12;
  @Prop heartRate: number = 62;
  @Prop tremorPSD: number = 0.12;
  @Prop currentTime: string = '00:00:00';
  ppgContext: CanvasRenderingContext2D | null = null;
  onCanvasReady: () => void = () => {};

  build() {
    Column({ space: 12 }) {
      Row({ space: 12 }) {
        GlucoseTile({
          glucose: this.glucose,
          riskIndex: this.riskIndex,
          heartRate: this.heartRate,
          ppgContext: this.ppgContext,
          onCanvasReady: this.onCanvasReady
        })
        RestlessTile({
          tremorPSD: this.tremorPSD
        })
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      Row({ space: 12 }) {
        TonightTile({
          currentTime: this.currentTime
        })
        RiskTile({
          riskIndex: this.riskIndex
        })
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
    }
    .width('100%')
  }
}

@Preview({ title: 'Phone Metric Grid' })
@Component
struct PhoneMetricGridPreview {
  build() {
    Column() {
      PhoneMetricGrid({
        glucose: 5.5,
        riskIndex: 12,
        heartRate: 62,
        tremorPSD: 0.12,
        currentTime: '23:45:12'
      })
    }
    .padding(16)
    .backgroundColor('#EEF2F7')
  }
}
