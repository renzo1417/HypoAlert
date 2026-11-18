/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Metric tile for 8-12 Hz wrist tremor and nocturnal stillness.
 */

import { TremorBand } from '../../models/PhoneTypes';
import { tremorLabel, tremorHint, computeTremorBands } from '../../utils/PhoneRiskUtils';

@Component
export struct RestlessTile {
  @Prop tremorTpi: number = 0.08;
  @Prop isSedentary: boolean = true;

  build() {
    Column({ space: 6 }) {
      Text('WRIST TREMOR')
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor('#8A94A6')
        .width('100%')

      Text(tremorLabel(this.tremorTpi, this.isSedentary))
        .fontSize(24)
        .fontWeight(FontWeight.Bolder)
        .fontColor('#0F1B2D')
        .width('100%')

      Text(tremorHint(this.tremorTpi, this.isSedentary))
        .fontSize(13)
        .fontColor('#0F1B2D')
        .width('100%')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Row({ space: 6 }) {
        ForEach(computeTremorBands(this.tremorTpi), (band: TremorBand) => {
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

      Text(`8-12 Hz TPI ${this.tremorTpi.toFixed(2)} • ${this.isSedentary ? 'Still' : 'Paused'}`)
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
      RestlessTile({ tremorTpi: 0.19, isSedentary: true })
    }
    .width(180)
    .padding(8)
  }
}
