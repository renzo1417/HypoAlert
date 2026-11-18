/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Discrete Clinical Scenario & Testing Modal Sheet.
 * Allows quick simulation of clinical states for demonstrations without cluttering the primary UI.
 */

import { PhoneTheme } from '../utils/PhoneTheme';

@Component
export struct DemoSheet {
  @Prop isWatchConnected: boolean = true;
  @Prop watchBattery: number = 86;
  @Prop deviceName: string = 'HUAWEI WATCH 4 Pro';
  onSimulateStable: () => void = () => {};
  onSimulatePreDrop: () => void = () => {};
  onSimulateCrisis: () => void = () => {};
  onToggleWatchConnection: () => void = () => {};
  onClose: () => void = () => {};

  build() {
    Column({ space: 12 }) {
      // Header
      Row() {
        Text('Test scenarios')
          .fontSize(PhoneTheme.FONT_SECTION)
          .fontWeight(FontWeight.Bold)
          .fontColor(PhoneTheme.TEXT_PRIMARY)
          .layoutWeight(1)

        Button('Done')
          .fontSize(PhoneTheme.FONT_BODY)
          .fontWeight(FontWeight.Bold)
          .height(32)
          .padding({ left: 12, right: 12 })
          .backgroundColor(PhoneTheme.BG_SUNKEN)
          .fontColor(PhoneTheme.TEXT_PRIMARY)
          .borderRadius(PhoneTheme.PILL_RADIUS)
          .onClick(() => {
            this.onClose();
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Divider().color(PhoneTheme.BORDER_LIGHT).strokeWidth(1)

      // Watch link (single line)
      Row({ space: 8 }) {
        Circle({ width: 6, height: 6 })
          .fill(this.isWatchConnected ? PhoneTheme.STATE_OK : PhoneTheme.STATE_WARN)

        Text(this.isWatchConnected ? `${this.watchBattery}% connected` : 'Offline')
          .fontSize(PhoneTheme.FONT_BODY)
          .fontColor(PhoneTheme.TEXT_SECONDARY)
          .layoutWeight(1)

        Button(this.isWatchConnected ? 'Disconnect' : 'Connect')
          .fontSize(PhoneTheme.FONT_CAPTION)
          .fontWeight(FontWeight.Bold)
          .height(32)
          .padding({ left: 12, right: 12 })
          .backgroundColor(this.isWatchConnected ? PhoneTheme.STATE_CRIT_BG : PhoneTheme.BRAND_PRIMARY)
          .fontColor(this.isWatchConnected ? PhoneTheme.STATE_CRIT : PhoneTheme.TEXT_ON_DARK)
          .borderRadius(PhoneTheme.TILE_RADIUS)
          .onClick(() => {
            this.onToggleWatchConnection();
          })
      }
      .width('100%')
      .padding(10)
      .backgroundColor(PhoneTheme.BG_SUBTLE)
      .borderRadius(PhoneTheme.TILE_RADIUS)
      .alignItems(VerticalAlign.Center)

      Column({ space: 8 }) {
        // Stable
        Button() {
          Row({ space: 10 }) {
            Circle({ width: 8, height: 8 }).fill(PhoneTheme.STATE_OK)
            Text('Stable 5.5')
              .fontSize(PhoneTheme.FONT_BODY)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.TEXT_PRIMARY)
              .layoutWeight(1)

            Text('Apply')
              .fontSize(PhoneTheme.FONT_MICRO)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.STATE_OK_TEXT)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .padding(12)
        .backgroundColor(PhoneTheme.BG_CARD)
        .borderWidth(1)
        .borderColor(PhoneTheme.BORDER_SUBTLE)
        .borderRadius(PhoneTheme.TILE_RADIUS)
        .onClick(() => {
          this.onSimulateStable();
          this.onClose();
        })

        // Drop
        Button() {
          Row({ space: 10 }) {
            Circle({ width: 8, height: 8 }).fill(PhoneTheme.STATE_WARN)
            Text('Drop 4.2')
              .fontSize(PhoneTheme.FONT_BODY)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.TEXT_PRIMARY)
              .layoutWeight(1)

            Text('Apply')
              .fontSize(PhoneTheme.FONT_MICRO)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.STATE_WARN_TEXT)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .padding(12)
        .backgroundColor(PhoneTheme.BG_CARD)
        .borderWidth(1)
        .borderColor(PhoneTheme.BORDER_SUBTLE)
        .borderRadius(PhoneTheme.TILE_RADIUS)
        .onClick(() => {
          this.onSimulatePreDrop();
          this.onClose();
        })

        // Emergency
        Button() {
          Row({ space: 10 }) {
            Circle({ width: 8, height: 8 }).fill(PhoneTheme.STATE_CRIT)
            Text('Emergency 3.1')
              .fontSize(PhoneTheme.FONT_BODY)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.TEXT_PRIMARY)
              .layoutWeight(1)

            Text('Trigger')
              .fontSize(PhoneTheme.FONT_MICRO)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.STATE_CRIT)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .padding(12)
        .backgroundColor(PhoneTheme.BG_CARD)
        .borderWidth(1)
        .borderColor(PhoneTheme.STATE_CRIT)
        .borderRadius(PhoneTheme.TILE_RADIUS)
        .onClick(() => {
          this.onSimulateCrisis();
          this.onClose();
        })
      }
      .width('100%')
    }
    .width('100%')
    .padding(PhoneTheme.CARD_PADDING)
    .backgroundColor(PhoneTheme.BG_CARD)
    .borderRadius(PhoneTheme.CARD_RADIUS)
    .borderWidth(1)
    .borderColor(PhoneTheme.BORDER_SUBTLE)
    .shadow({ radius: 16, color: 'rgba(15, 23, 42, 0.15)', offsetY: -4 })
  }
}
