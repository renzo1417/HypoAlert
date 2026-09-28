/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Minimalist Caregiver Quick-Contact Card.
 * Clean, pure white card without background accent fills.
 */

import { PhoneTheme } from '../utils/PhoneTheme';

@Component
export struct PhoneCaregiverCard {
  @Prop caregiverName: string = 'Maria Santos';
  @Prop caregiverRole: string = 'Primary Caregiver';
  @Prop caregiverPhone: string = '+63 917 123 4567';
  @Prop isEmergency: boolean = false;
  onCall: () => void = () => {};
  onMessage: () => void = () => {};

  build() {
    Row({ space: 12 }) {
      // Caregiver Avatar / Status Indicator
      Stack({ alignContent: Alignment.Center }) {
        Circle({ width: 42, height: 42 })
          .fill(this.isEmergency ? PhoneTheme.STATE_CRIT_BG : PhoneTheme.BG_MUTED)

        Text(this.caregiverName.length > 0 ? this.caregiverName.substring(0, 1) : 'C')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isEmergency ? PhoneTheme.STATE_CRIT : PhoneTheme.TEXT_PRIMARY)
      }
      .width(42)
      .height(42)

      // Name & Role Details
      Column({ space: 2 }) {
        Text(this.caregiverName)
          .fontSize(PhoneTheme.FONT_SECTION)
          .fontWeight(FontWeight.Bold)
          .fontColor(PhoneTheme.TEXT_PRIMARY)

        Row({ space: 5 }) {
          Circle({ width: 6, height: 6 })
            .fill(this.isEmergency ? PhoneTheme.STATE_CRIT : PhoneTheme.STATE_OK)
          Text(this.isEmergency ? 'Urgent Alert Sent' : `${this.caregiverRole} • Ready`)
            .fontSize(PhoneTheme.FONT_BODY)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.isEmergency ? PhoneTheme.STATE_CRIT : PhoneTheme.TEXT_MUTED)
        }
        .alignItems(VerticalAlign.Center)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // Action Buttons (Message & Call)
      Row({ space: 8 }) {
        // Message / Notification button
        Button() {
          Stack({ alignContent: Alignment.Center }) {
            // Chat bubble glyph
            Column({ space: 2 }) {
              Row()
                .width(14)
                .height(10)
                .backgroundColor(this.isEmergency ? PhoneTheme.STATE_CRIT : PhoneTheme.TEXT_SECONDARY)
                .borderRadius(2)
              Row()
                .width(5)
                .height(3)
                .backgroundColor(this.isEmergency ? PhoneTheme.STATE_CRIT : PhoneTheme.TEXT_SECONDARY)
                .borderRadius(1)
                .margin({ left: 2 })
            }
            .alignItems(HorizontalAlign.Start)
          }
          .width(38)
          .height(38)
        }
        .width(38)
        .height(38)
        .backgroundColor(PhoneTheme.BG_CARD)
        .borderWidth(1)
        .borderColor(PhoneTheme.BORDER_SUBTLE)
        .borderRadius(PhoneTheme.TILE_RADIUS)
        .onClick(() => {
          this.onMessage();
        })

        // Call button
        Button() {
          Stack({ alignContent: Alignment.Center }) {
            // Phone handset glyph
            Row() {
              Circle({ width: 7, height: 7 })
                .fill(this.isEmergency ? PhoneTheme.TEXT_ON_DARK : PhoneTheme.BRAND_PRIMARY)
              Row()
                .width(4)
                .height(10)
                .backgroundColor(this.isEmergency ? PhoneTheme.TEXT_ON_DARK : PhoneTheme.BRAND_PRIMARY)
                .borderRadius(2)
            }
            .rotate({ angle: -25 })
          }
          .width(38)
          .height(38)
        }
        .width(38)
        .height(38)
        .backgroundColor(this.isEmergency ? PhoneTheme.STATE_CRIT : PhoneTheme.BG_CARD)
        .borderWidth(1)
        .borderColor(this.isEmergency ? PhoneTheme.STATE_CRIT : PhoneTheme.BORDER_SUBTLE)
        .borderRadius(PhoneTheme.TILE_RADIUS)
        .onClick(() => {
          this.onCall();
        })
      }
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 12, bottom: 12 })
    .backgroundColor(PhoneTheme.BG_CARD)
    .borderWidth(1)
    .borderColor(PhoneTheme.BORDER_SUBTLE)
    .borderRadius(PhoneTheme.CARD_RADIUS)
    .shadow({ radius: 8, color: 'rgba(15, 23, 42, 0.04)', offsetY: 2 })
    .alignItems(VerticalAlign.Center)
  }
}
