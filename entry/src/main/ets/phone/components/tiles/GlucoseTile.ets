/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Metric tile for real-time glucose and live PPG waveform canvas.
 */

import { trendWord, heartWords } from '../../utils/PhoneRiskUtils';

@Component
export struct GlucoseTile {
  @Prop glucose: number = 5.5;
  @Prop riskIndex: number = 12;
  @Prop heartRate: number = 62;
  ppgContext: CanvasRenderingContext2D | null = null;
  onCanvasReady: () => void = () => {};

  build() {
    Column({ space: 6 }) {
      Text('GLUCOSE')
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor('rgba(255,255,255,0.85)')
        .width('100%')

      Row({ space: 4 }) {
        Text(`${this.glucose.toFixed(1)}`)
          .fontSize(32)
          .fontWeight(FontWeight.Bolder)
          .fontColor('#FFFFFF')
        Text('mmol/L')
          .fontSize(13)
          .fontColor('rgba(255,255,255,0.9)')
          .margin({ bottom: 4 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Bottom)

      Text(trendWord(this.riskIndex))
        .fontSize(14)
        .fontColor('#FFFFFF')
        .width('100%')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      if (this.ppgContext) {
        Canvas(this.ppgContext)
          .width('100%')
          .height(52)
          .backgroundColor('rgba(255,255,255,0.16)')
          .border({ width: 1, color: 'rgba(255,255,255,0.35)', radius: 10 })
          .onReady(() => {
            this.onCanvasReady();
          })
      }

      Text(heartWords(this.riskIndex, this.heartRate))
        .fontSize(12)
        .fontColor('rgba(255,255,255,0.92)')
        .width('100%')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .layoutWeight(1)
    .height(226)
    .padding(14)
    .backgroundColor('#2E86DE')
    .borderRadius(20)
    .shadow({ radius: 14, color: 'rgba(46,134,222,0.30)', offsetX: 0, offsetY: 6 })
    .alignItems(HorizontalAlign.Start)
  }
}

@Preview({ title: 'Glucose Tile' })
@Component
struct GlucoseTilePreview {
  build() {
    Row() {
      GlucoseTile({
        glucose: 5.5,
        riskIndex: 12,
        heartRate: 62
      })
    }
    .width(180)
    .padding(8)
  }
}
