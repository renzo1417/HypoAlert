/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Minimalist Bedside Status Header.
 * Clinical-grade status indicator: Watch BLE link, battery, and quick scenario test action.
 */

import { PhoneTheme } from '../utils/PhoneTheme';

@Component
export struct PhoneTopBar {
  @Prop currentTime: string = '00:00:00';
  @Prop isEmergency: boolean = false;
  @Prop isWatchConnected: boolean = true;
  @Prop watchBattery: number = 86;
  @Prop deviceName: string = 'WATCH 4 Pro';
  onOpenTest: () => void = () => {};

  build() {
    Row() {
      // Left: Tonight context + status + time
      Row({ space: 10 }) {
        Circle({ width: 10, height: 10 })
          .fill(this.isEmergency ? PhoneTheme.STATE_CRIT : (this.isWatchConnected ? PhoneTheme.STATE_OK : PhoneTheme.STATE_WARN))

        Column({ space: 0 }) {
          Text('TONIGHT')
            .fontSize(PhoneTheme.FONT_MICRO)
            .fontWeight(FontWeight.Bold)
            .fontColor(PhoneTheme.TEXT_TERTIARY)
          Text(this.isEmergency ? 'Urgent — check now' : (this.isWatchConnected ? 'Monitoring' : 'Watch offline'))
            .fontSize(PhoneTheme.FONT_SECTION)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.isEmergency ? PhoneTheme.STATE_CRIT : PhoneTheme.TEXT_PRIMARY)
          Text(this.currentTime)
            .fontSize(PhoneTheme.FONT_CAPTION)
            .fontColor(PhoneTheme.TEXT_MUTED)
        }
        .alignItems(HorizontalAlign.Start)
      }
      .alignItems(VerticalAlign.Center)
      .layoutWeight(1)

      // Right: Watch link + labeled Test
      Row({ space: 8 }) {
        Row({ space: 6 }) {
          Circle({ width: 6, height: 6 })
            .fill(this.isWatchConnected ? PhoneTheme.STATE_OK : PhoneTheme.TEXT_TERTIARY)
          Text(this.isWatchConnected ? `Watch ${this.watchBattery}%` : 'Watch off')
            .fontSize(PhoneTheme.FONT_CAPTION)
            .fontWeight(FontWeight.Medium)
            .fontColor(PhoneTheme.TEXT_SECONDARY)
        }
        .padding({ left: 10, right: 10, top: 6, bottom: 6 })
        .backgroundColor(PhoneTheme.BG_CARD)
        .borderWidth(1)
        .borderColor(PhoneTheme.BORDER_SUBTLE)
        .borderRadius(PhoneTheme.PILL_RADIUS)
        .alignItems(VerticalAlign.Center)

        Button('Test')
          .fontSize(PhoneTheme.FONT_CAPTION)
          .fontWeight(FontWeight.Bold)
          .height(32)
          .padding({ left: 12, right: 12 })
          .backgroundColor(PhoneTheme.BRAND_PRIMARY)
          .fontColor(PhoneTheme.TEXT_ON_DARK)
          .borderRadius(PhoneTheme.PILL_RADIUS)
          .onClick(() => {
            this.onOpenTest();
          })
      }
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding({ left: 16, right: 16, top: 12, bottom: 8 })
    .backgroundColor(PhoneTheme.BG_PAGE)
  }
}
