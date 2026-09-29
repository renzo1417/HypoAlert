/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Compact metric icon button for hub grid.
 * Shows icon + value + status dot; tap opens full detail page.
 */

import { PhoneTheme } from '../utils/PhoneTheme';

@Component
export struct MetricIconButton {
  @Prop title: string = '';
  @Prop value: string = '';
  @Prop hint: string = '';
  @Prop statusColor: string = '#16A34A';
  @Prop glyph: string = '●';
  onOpen: () => void = () => {};

  build() {
    Column({ space: 6 }) {
      Text(this.title)
        .fontSize(PhoneTheme.FONT_CAPTION)
        .fontWeight(FontWeight.Bold)
        .fontColor(PhoneTheme.TEXT_SECONDARY)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      Text(this.value)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(PhoneTheme.TEXT_PRIMARY)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      Text(this.title)
        .fontSize(PhoneTheme.FONT_CAPTION)
        .fontWeight(FontWeight.Bold)
        .fontColor(PhoneTheme.TEXT_SECONDARY)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      Text(this.hint)
        .fontSize(PhoneTheme.FONT_MICRO)
        .fontColor(PhoneTheme.TEXT_MUTED)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      Row({ space: 4 }) {
        Circle({ width: 7, height: 7 })
          .fill(this.statusColor)
        Text('View detail')
          .fontSize(PhoneTheme.FONT_MICRO)
          .fontWeight(FontWeight.Bold)
          .fontColor(PhoneTheme.BRAND_PRIMARY)
        Text('›')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(PhoneTheme.BRAND_PRIMARY)
      }
      .alignItems(VerticalAlign.Center)
    }
    .layoutWeight(1)
    .height(148)
    .padding(12)
    .backgroundColor(PhoneTheme.BG_CARD)
    .borderWidth(1)
    .borderColor(PhoneTheme.BORDER_SUBTLE)
    .borderRadius(PhoneTheme.TILE_RADIUS)
    .shadow({ radius: 6, color: 'rgba(15, 23, 42, 0.03)', offsetY: 1 })
    .alignItems(HorizontalAlign.Start)
    .onClick(() => {
      this.onOpen();
    })
  }
}
