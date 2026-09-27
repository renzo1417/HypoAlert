/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Metric tile for nocturnal guardian schedule and wearable connection state.
 */

@Component
export struct TonightTile {
  @Prop currentTime: string = '00:00:00';

  build() {
    Column({ space: 6 }) {
      Text('TONIGHT')
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor('#8A94A6')
        .width('100%')

      Text('22:00–06:00')
        .fontSize(20)
        .fontWeight(FontWeight.Bolder)
        .fontColor('#0F1B2D')
        .width('100%')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Row({ space: 6 }) {
        Circle({ width: 9, height: 9 })
          .fill('#34C759')
        Text('Watch connected')
          .fontSize(14)
          .fontColor('#0F1B2D')
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text('Guarding while they sleep')
        .fontSize(14)
        .fontColor('#5B6B82')
        .width('100%')

      Text(`Updated ${this.currentTime}`)
        .fontSize(11)
        .fontColor('#8A94A6')
        .width('100%')
    }
    .layoutWeight(1)
    .height(196)
    .padding(14)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .border({ width: 1, color: '#E3E9F2', radius: 20 })
    .shadow({ radius: 14, color: 'rgba(15,27,45,0.08)', offsetX: 0, offsetY: 6 })
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Start)
  }
}

@Preview({ title: 'Tonight Tile' })
@Component
struct TonightTilePreview {
  build() {
    Row() {
      TonightTile({ currentTime: '23:45:12' })
    }
    .width(180)
    .padding(8)
  }
}
