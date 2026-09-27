/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Overnight glucose history card and check-in timeline.
 */

import { OvernightPoint } from '../models/PhoneTypes';
import {
  computeOvernightPoints,
  getOvernightBarColor,
  computeOvernightEvents
} from '../utils/PhoneRiskUtils';

@Component
export struct PhoneOvernightCard {
  @Prop glucose: number = 5.5;
  @Prop tremorPSD: number = 0.12;
  @Prop riskIndex: number = 12;

  build() {
    Column({ space: 10 }) {
      Row({ space: 8 }) {
        Column({ space: 2 }) {
          Text('Overnight')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#0F1B2D')
          Text('Glucose through the night, in plain words')
            .fontSize(13)
            .fontColor('#8A94A6')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text('12am–8am')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2E86DE')
          .backgroundColor('#E7F0FE')
          .borderRadius(12)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Row({ space: 8 }) {
        ForEach(computeOvernightPoints(this.glucose), (pt: OvernightPoint) => {
          Column({ space: 4 }) {
            Text(`${pt.value.toFixed(1)}`)
              .fontSize(10)
              .fontWeight(FontWeight.Bold)
              .fontColor('#0F1B2D')

            Stack({ alignContent: Alignment.Bottom }) {
              Row()
                .width('100%')
                .height(84)
                .backgroundColor('#EDF2F8')
                .borderRadius(8)
              Row()
                .width('100%')
                .height(Math.round((pt.value / 6.5) * 84))
                .backgroundColor(getOvernightBarColor(pt.value))
                .borderRadius(8)
            }
            .width('100%')
            .height(84)

            Text(pt.hour)
              .fontSize(11)
              .fontColor('#8A94A6')
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
        }, (pt: OvernightPoint) => pt.hour)
      }
      .width('100%')
      .alignItems(VerticalAlign.Bottom)

      Column({ space: 6 }) {
        ForEach(computeOvernightEvents(this.tremorPSD, this.riskIndex), (msg: string) => {
          Row({ space: 8 }) {
            Circle({ width: 8, height: 8 })
              .fill('#2E86DE')
              .margin({ top: 6 })
            Text(msg)
              .fontSize(14)
              .fontColor('#0F1B2D')
              .layoutWeight(1)
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)
        }, (msg: string) => msg)
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#F4F7FB')
      .borderRadius(14)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(22)
    .border({ width: 1, color: '#E3E9F2', radius: 22 })
    .shadow({ radius: 14, color: 'rgba(15,27,45,0.08)', offsetX: 0, offsetY: 6 })
  }
}

@Preview({ title: 'Phone Overnight Card' })
@Component
struct PhoneOvernightCardPreview {
  build() {
    Column() {
      PhoneOvernightCard({
        glucose: 5.2,
        tremorPSD: 0.15,
        riskIndex: 15
      })
    }
    .padding(16)
    .backgroundColor('#EEF2F7')
  }
}
