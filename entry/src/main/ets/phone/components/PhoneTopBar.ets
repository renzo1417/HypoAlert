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
      // Left: App Brand & Guardian Status
      Row({ space: 8 }) {
        Stack({ alignContent: Alignment.Center }) {
          Circle({ width: 28, height: 28 })
            .fill(this.isEmergency ? PhoneTheme.STATE_CRIT_BG : PhoneTheme.BRAND_ACCENT_BG)
          Circle({ width: 8, height: 8 })
            .fill(this.isEmergency ? PhoneTheme.STATE_CRIT : PhoneTheme.BRAND_ACCENT)
        }
        .width(28)
        .height(28)

        Column({ space: 1 }) {
          Text('HypoAlert')
            .fontSize(PhoneTheme.FONT_SECTION)
            .fontWeight(FontWeight.Bold)
            .fontColor(PhoneTheme.TEXT_PRIMARY)

          Row({ space: 4 }) {
            Circle({ width: 5, height: 5 })
              .fill(this.isEmergency ? PhoneTheme.STATE_CRIT : (this.isWatchConnected ? PhoneTheme.STATE_OK : PhoneTheme.STATE_WARN))
            Text(this.isEmergency ? 'Emergency Alert' : (this.isWatchConnected ? 'Bedside Guardian Active' : 'Watch Offline'))
              .fontSize(PhoneTheme.FONT_CAPTION)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.isEmergency ? PhoneTheme.STATE_CRIT : PhoneTheme.TEXT_MUTED)
          }
          .alignItems(VerticalAlign.Center)
        }
        .alignItems(HorizontalAlign.Start)
      }
      .alignItems(VerticalAlign.Center)
      .layoutWeight(1)

      // Right: Watch Capsule + Scenario Test Button
      Row({ space: 8 }) {
        // Wearable connection capsule
        Row({ space: 5 }) {
          Circle({ width: 5, height: 5 })
            .fill(this.isWatchConnected ? PhoneTheme.STATE_OK : PhoneTheme.TEXT_TERTIARY)

          Text(this.isWatchConnected ? `${this.deviceName} • ${this.watchBattery}%` : 'Offline')
            .fontSize(PhoneTheme.FONT_CAPTION)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.isWatchConnected ? PhoneTheme.TEXT_PRIMARY : PhoneTheme.TEXT_TERTIARY)
        }
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .backgroundColor(PhoneTheme.BG_CARD)
        .borderRadius(PhoneTheme.PILL_RADIUS)
        .borderWidth(1)
        .borderColor(PhoneTheme.BORDER_SUBTLE)
        .alignItems(VerticalAlign.Center)

        // Scenario Test Button (Discreet clinical test trigger)
        Button('Test')
          .fontSize(PhoneTheme.FONT_MICRO)
          .fontWeight(FontWeight.Bold)
          .height(28)
          .padding({ left: 10, right: 10 })
          .backgroundColor(PhoneTheme.BG_MUTED)
          .fontColor(PhoneTheme.TEXT_SECONDARY)
          .borderRadius(PhoneTheme.PILL_RADIUS)
          .onClick(() => {
            this.onOpenTest();
          })
      }
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding({ left: 18, right: 18, top: 12, bottom: 8 })
  }
}
