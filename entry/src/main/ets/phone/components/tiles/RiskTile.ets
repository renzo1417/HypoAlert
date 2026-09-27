/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Metric tile for hypoglycemia risk gauge and clinical status.
 */

import { riskColor, riskShort, riskHint, riskWords } from '../../utils/PhoneRiskUtils';

@Component
export struct RiskTile {
  @Prop riskIndex: number = 12;

  build() {
    Column({ space: 6 }) {
      Text('RISK')
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor('#8A94A6')
        .width('100%')

      Text(riskShort(this.riskIndex))
        .fontSize(26)
        .fontWeight(FontWeight.Bolder)
        .fontColor(riskColor(this.riskIndex))
        .width('100%')

      Text(riskHint(this.riskIndex))
        .fontSize(14)
        .fontColor('#0F1B2D')
        .width('100%')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Progress({ value: this.riskIndex, total: 100, type: ProgressType.Linear })
        .width('100%')
        .color(riskColor(this.riskIndex))
        .backgroundColor('#E7EDF5')

      Text(`${this.riskIndex} of 100 — ${riskWords(this.riskIndex)}`)
        .fontSize(11)
        .fontColor('#8A94A6')
        .width('100%')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .layoutWeight(1)
    .height(196)
    .padding(14)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .border({ width: 1, color: '#E3E9F2', radius: 20 })
    .shadow({ radius: 14, color: 'rgba(15,27,45,0.08)', offsetX: 0, offsetY: 6 })
    .alignItems(HorizontalAlign.Start)
  }
}

@Preview({ title: 'Risk Tile' })
@Component
struct RiskTilePreview {
  build() {
    Row() {
      RiskTile({ riskIndex: 45 })
    }
    .width(180)
    .padding(8)
  }
}
