/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Test Scenario Slide-up Sheet.
 * Compact bottom-sheet version of DemoView for PhonePage overlay.
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
      // Grab handle
      Row()
        .width(40)
        .height(4)
        .backgroundColor(PhoneTheme.BORDER_SUBTLE)
        .borderRadius(2)
        .margin({ top: 8 })

      // Header
      Row() {
        Column({ space: 1 }) {
          Text('Test Scenarios')
            .fontSize(PhoneTheme.FONT_SECTION)
            .fontWeight(FontWeight.Bold)
            .fontColor(PhoneTheme.TEXT_PRIMARY)
          Text('Simulate vitals & wearable link')
            .fontSize(PhoneTheme.FONT_CAPTION)
            .fontColor(PhoneTheme.TEXT_MUTED)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Button('Close')
          .fontSize(PhoneTheme.FONT_MICRO)
          .fontWeight(FontWeight.Bold)
          .height(28)
          .padding({ left: 10, right: 10 })
          .backgroundColor(PhoneTheme.BG_MUTED)
          .fontColor(PhoneTheme.TEXT_SECONDARY)
          .borderRadius(PhoneTheme.PILL_RADIUS)
          .onClick(() => {
            this.onClose();
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // Wearable link row
      Row({ space: 8 }) {
        Circle({ width: 6, height: 6 })
          .fill(this.isWatchConnected ? PhoneTheme.STATE_OK : PhoneTheme.STATE_WARN)
        Column({ space: 1 }) {
          Text(this.deviceName)
            .fontSize(PhoneTheme.FONT_BODY)
            .fontWeight(FontWeight.Bold)
            .fontColor(PhoneTheme.TEXT_PRIMARY)
          Text(this.isWatchConnected ? `Battery ${this.watchBattery}% • Live` : 'Offline • Paused')
            .fontSize(PhoneTheme.FONT_CAPTION)
            .fontColor(PhoneTheme.TEXT_MUTED)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Button(this.isWatchConnected ? 'Disconnect' : 'Connect')
          .fontSize(PhoneTheme.FONT_CAPTION)
          .fontWeight(FontWeight.Bold)
          .height(30)
          .padding({ left: 10, right: 10 })
          .backgroundColor(this.isWatchConnected ? PhoneTheme.STATE_CRIT_BG : PhoneTheme.BRAND_PRIMARY)
          .fontColor(this.isWatchConnected ? PhoneTheme.STATE_CRIT : PhoneTheme.TEXT_ON_DARK)
          .borderRadius(PhoneTheme.TILE_RADIUS)
          .onClick(() => {
            this.onToggleWatchConnection();
          })
      }
      .width('100%')
      .padding(10)
      .backgroundColor(PhoneTheme.BG_PAGE)
      .borderRadius(PhoneTheme.TILE_RADIUS)
      .alignItems(VerticalAlign.Center)

      // Presets
      Column({ space: 8 }) {
        Row({ space: 10 }) {
          Circle({ width: 8, height: 8 }).fill(PhoneTheme.STATE_OK)
          Column({ space: 1 }) {
            Text('Stable Sleep (5.5 mmol/L)')
              .fontSize(PhoneTheme.FONT_BODY)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.TEXT_PRIMARY)
            Text('Normal resting vitals')
              .fontSize(PhoneTheme.FONT_CAPTION)
              .fontColor(PhoneTheme.TEXT_MUTED)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')
        .padding(12)
        .backgroundColor(PhoneTheme.BG_PAGE)
        .borderWidth(1)
        .borderColor(PhoneTheme.BORDER_SUBTLE)
        .borderRadius(PhoneTheme.TILE_RADIUS)
        .onClick(() => {
          this.onSimulateStable();
        })

        Row({ space: 10 }) {
          Circle({ width: 8, height: 8 }).fill(PhoneTheme.STATE_WARN)
          Column({ space: 1 }) {
            Text('Impending Drop (4.2 mmol/L)')
              .fontSize(PhoneTheme.FONT_BODY)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.TEXT_PRIMARY)
            Text('Trending down, restlessness rising')
              .fontSize(PhoneTheme.FONT_CAPTION)
              .fontColor(PhoneTheme.TEXT_MUTED)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')
        .padding(12)
        .backgroundColor(PhoneTheme.BG_PAGE)
        .borderWidth(1)
        .borderColor(PhoneTheme.BORDER_SUBTLE)
        .borderRadius(PhoneTheme.TILE_RADIUS)
        .onClick(() => {
          this.onSimulatePreDrop();
        })

        Row({ space: 10 }) {
          Circle({ width: 8, height: 8 }).fill(PhoneTheme.STATE_CRIT)
          Column({ space: 1 }) {
            Text('Severe Emergency (3.1 mmol/L)')
              .fontSize(PhoneTheme.FONT_BODY)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.TEXT_PRIMARY)
            Text('Critical hypo, alarm & SMS')
              .fontSize(PhoneTheme.FONT_CAPTION)
              .fontColor(PhoneTheme.TEXT_MUTED)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')
        .padding(12)
        .backgroundColor(PhoneTheme.BG_PAGE)
        .borderWidth(1)
        .borderColor(PhoneTheme.BORDER_SUBTLE)
        .borderRadius(PhoneTheme.TILE_RADIUS)
        .onClick(() => {
          this.onSimulateCrisis();
        })
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 4, bottom: 16 })
    .backgroundColor(PhoneTheme.BG_CARD)
    .borderRadius({ topLeft: 20, topRight: 20 })
  }
}
