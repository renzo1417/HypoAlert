/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Metric tile for tremor and nocturnal restlessness analysis.
 */

import { TremorBand } from '../../models/PhoneTypes';
import { restlessShort, restlessHint, computeTremorBands } from '../../utils/PhoneRiskUtils';

@Component
export struct RestlessTile {
  @Prop tremorPSD: number = 0.12;

  build() {
    Column({ space: 6 }) {
      Text('RESTLESSNESS')
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor('#8A94A6')
        .width('100%')

      Text(restlessShort(this.tremorPSD))
        .fontSize(26)
        .fontWeight(FontWeight.Bolder)
        .fontColor('#0F1B2D')
        .width('100%')

      Text(restlessHint(this.tremorPSD))
        .fontSize(14)
        .fontColor('#0F1B2D')
        .width('100%')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Row({ space: 6 }) {
        ForEach(computeTremorBands(this.tremorPSD), (band: TremorBand) => {
          Column({ space: 3 }) {
            Stack({ alignContent: Alignment.Bottom }) {
              Row()
                .width('100%')
                .height(40)
                .backgroundColor('#EDF2F8')
                .borderRadius(6)
              Row()
                .width('100%')
                .height(Math.round(band.power * 40))
                .backgroundColor(band.color)
                .borderRadius(6)
            }
            .width('100%')
            .height(40)

            Text(band.label)
              .fontSize(9)
              .fontColor('#8A94A6')
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
        }, (band: TremorBand) => band.range)
      }
      .width('100%')
      .alignItems(VerticalAlign.Bottom)

      Text(`Raw PSD ${this.tremorPSD.toFixed(2)} — sensor reading`)
        .fontSize(11)
        .fontColor('#8A94A6')
        .width('100%')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .layoutWeight(1)
    .height(226)
    .padding(14)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .border({ width: 1, color: '#E3E9F2', radius: 20 })
    .shadow({ radius: 14, color: 'rgba(15,27,45,0.08)', offsetX: 0, offsetY: 6 })
    .alignItems(HorizontalAlign.Start)
  }
}

@Preview({ title: 'Restless Tile' })
@Component
struct RestlessTilePreview {
  build() {
    Row() {
      RestlessTile({ tremorPSD: 0.85 })
    }
    .width(180)
    .padding(8)
  }
}
