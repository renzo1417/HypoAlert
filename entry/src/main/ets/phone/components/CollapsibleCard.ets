/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Reusable collapsible card (accordion section).
 */

import { PhoneTheme } from '../utils/PhoneTheme';

@Component
export struct CollapsibleCard {
  @Prop title: string = '';
  @Prop subtitle: string = '';
  @Prop statusDot: string = '';
  @Prop initiallyExpanded: boolean = false;
  @State expanded: boolean = false;

  aboutToAppear(): void {
    this.expanded = this.initiallyExpanded;
  }

  @Builder
  defaultContent() {
  }

  @BuilderParam content: () => void = this.defaultContent;

  build() {
    Column({ space: 0 }) {
      Row({ space: 10 }) {
        if (this.statusDot.length > 0) {
          Circle({ width: 8, height: 8 })
            .fill(this.statusDot)
        }
        Column({ space: 1 }) {
          Text(this.title)
            .fontSize(PhoneTheme.FONT_SECTION)
            .fontWeight(FontWeight.Bold)
            .fontColor(PhoneTheme.TEXT_PRIMARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          if (this.subtitle.length > 0) {
            Text(this.expanded ? this.subtitle : (this.subtitle.length > 42 ? this.subtitle.substring(0, 42) + '…' : this.subtitle))
              .fontSize(PhoneTheme.FONT_CAPTION)
              .fontColor(PhoneTheme.TEXT_MUTED)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text(this.expanded ? '▾' : '▸')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(PhoneTheme.TEXT_TERTIARY)
          .width(24)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: 12, bottom: this.expanded ? 8 : 12 })
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        animateTo({ duration: 220, curve: Curve.EaseInOut }, () => {
          this.expanded = !this.expanded;
        });
      })

      if (this.expanded) {
        Divider()
          .color(PhoneTheme.BORDER_LIGHT)
          .strokeWidth(1)
          .margin({ left: 14, right: 14 })

        Column() {
          this.content()
        }
        .width('100%')
        .padding({ left: 14, right: 14, top: 10, bottom: 14 })
      }
    }
    .width('100%')
    .backgroundColor(PhoneTheme.BG_CARD)
    .borderWidth(1)
    .borderColor(PhoneTheme.BORDER_SUBTLE)
    .borderRadius(PhoneTheme.CARD_RADIUS)
    .shadow({ radius: 8, color: 'rgba(15, 23, 42, 0.04)', offsetY: 2 })
  }
}
