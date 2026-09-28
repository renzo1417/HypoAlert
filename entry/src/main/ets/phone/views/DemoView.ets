/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Screen 4: Clinical simulation and cross-device testing.
 * Clean, clinical simulation suite without loud pastel fills.
 */

import { riskLevel } from '../utils/PhoneRiskUtils';
import { PhoneTheme } from '../utils/PhoneTheme';

@Component
export struct DemoView {
  @Prop glucose: number = 5.5;
  @Prop riskIndex: number = 12;
  @Prop heartRate: number = 62;
  @Prop tremorPSD: number = 0.12;
  @Prop skinTemp: number = 36.0;
  @Prop variability: number = 42;
  @Prop caregiverName: string = 'Maria Santos';
  @Prop caregiverPhone: string = '+63 917 123 4567';
  @Prop isWatchConnected: boolean = true;
  @Prop watchBattery: number = 86;
  @Prop deviceName: string = 'HUAWEI WATCH 4 Pro';
  onSimulateStable: () => void = () => {};
  onSimulatePreDrop: () => void = () => {};
  onSimulateCrisis: () => void = () => {};
  onMarkWithThem: () => void = () => {};
  onToggleWatchConnection: () => void = () => {};

  private isEmergency(): boolean {
    return riskLevel(this.riskIndex) === 'Critical';
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        // Screen Header
        Column({ space: 2 }) {
          Row() {
            Text('Simulation & Tools')
              .fontSize(PhoneTheme.FONT_TITLE)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.TEXT_PRIMARY)
            Blank()
            Text('Test Mode')
              .fontSize(PhoneTheme.FONT_CAPTION)
              .fontWeight(FontWeight.Medium)
              .fontColor(PhoneTheme.BRAND_ACCENT)
              .backgroundColor(PhoneTheme.BRAND_ACCENT_BG)
              .borderRadius(PhoneTheme.PILL_RADIUS)
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Text('Test emergency alert presets and wearable link')
            .fontSize(PhoneTheme.FONT_BODY)
            .fontColor(PhoneTheme.TEXT_MUTED)
            .width('100%')
        }
        .width('100%')
        .padding({ left: 2, right: 2 })

        // Cross-Device Watch Connection Card
        Column({ space: 10 }) {
          Row() {
            Row({ space: 6 }) {
              Circle({ width: 6, height: 6 })
                .fill(this.isWatchConnected ? PhoneTheme.STATE_OK : PhoneTheme.STATE_WARN)
              Text('Wearable Link')
                .fontSize(PhoneTheme.FONT_SECTION)
                .fontWeight(FontWeight.Bold)
                .fontColor(PhoneTheme.TEXT_PRIMARY)
            }
            .alignItems(VerticalAlign.Center)

            Blank()

            Text(this.isWatchConnected ? 'Connected' : 'Offline')
              .fontSize(PhoneTheme.FONT_MICRO)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.isWatchConnected ? PhoneTheme.STATE_OK_TEXT : PhoneTheme.STATE_WARN_TEXT)
              .backgroundColor(this.isWatchConnected ? PhoneTheme.STATE_OK_BG : PhoneTheme.STATE_WARN_BG)
              .borderRadius(PhoneTheme.PILL_RADIUS)
              .padding({ left: 7, right: 7, top: 3, bottom: 3 })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Row({ space: 8 }) {
            Column({ space: 1 }) {
              Text(this.deviceName)
                .fontSize(PhoneTheme.FONT_BODY)
                .fontWeight(FontWeight.Bold)
                .fontColor(PhoneTheme.TEXT_PRIMARY)
              Text(this.isWatchConnected ? `Battery: ${this.watchBattery}% • Signal: Good` : 'Telemetry stream paused')
                .fontSize(PhoneTheme.FONT_CAPTION)
                .fontColor(PhoneTheme.TEXT_MUTED)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            Button(this.isWatchConnected ? 'Disconnect' : 'Connect')
              .fontSize(PhoneTheme.FONT_BODY)
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
          .alignItems(VerticalAlign.Center)
          .padding(10)
          .backgroundColor(PhoneTheme.BG_PAGE)
          .borderRadius(PhoneTheme.TILE_RADIUS)
        }
        .width('100%')
        .padding(PhoneTheme.CARD_PADDING)
        .backgroundColor(PhoneTheme.BG_CARD)
        .borderWidth(1)
        .borderColor(PhoneTheme.BORDER_SUBTLE)
        .borderRadius(PhoneTheme.CARD_RADIUS)
        .shadow({ radius: 8, color: 'rgba(15, 23, 42, 0.04)', offsetY: 2 })

        // Dismiss action if currently in emergency
        if (this.isEmergency()) {
          Row({ space: 10 }) {
            Column({ space: 2 }) {
              Text('Emergency Active!')
                .fontSize(PhoneTheme.FONT_SECTION)
                .fontWeight(FontWeight.Bold)
                .fontColor(PhoneTheme.STATE_CRIT)
              Text('Alarm sounding • Tap to confirm assistance')
                .fontSize(PhoneTheme.FONT_CAPTION)
                .fontColor(PhoneTheme.TEXT_MUTED)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Button("I'm with them")
              .fontSize(PhoneTheme.FONT_BODY)
              .fontWeight(FontWeight.Bold)
              .height(34)
              .backgroundColor(PhoneTheme.STATE_CRIT)
              .fontColor(PhoneTheme.TEXT_ON_DARK)
              .borderRadius(PhoneTheme.TILE_RADIUS)
              .onClick(() => {
                this.onMarkWithThem();
              })
          }
          .width('100%')
          .padding(12)
          .backgroundColor(PhoneTheme.STATE_CRIT_BG)
          .borderRadius(PhoneTheme.CARD_RADIUS)
        }

        // Clinical Scenario Presets (Clean White Cards, No Pastel Slabs)
        Column({ space: 10 }) {
          Row() {
            Text('Quick Presets')
              .fontSize(PhoneTheme.FONT_SECTION)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.TEXT_PRIMARY)
            Blank()
            Text('Tap to simulate')
              .fontSize(PhoneTheme.FONT_CAPTION)
              .fontColor(PhoneTheme.TEXT_TERTIARY)
          }
          .width('100%')

          // Preset 1: Stable
          Row({ space: 10 }) {
            Circle({ width: 8, height: 8 }).fill(PhoneTheme.STATE_OK)
            Column({ space: 2 }) {
              Text('1. Stable Sleep (5.5 mmol/L)')
                .fontSize(PhoneTheme.FONT_BODY)
                .fontWeight(FontWeight.Bold)
                .fontColor(PhoneTheme.TEXT_PRIMARY)
              Text('Normal resting vitals and calm sleep')
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

          // Preset 2: Pre-Drop
          Row({ space: 10 }) {
            Circle({ width: 8, height: 8 }).fill(PhoneTheme.STATE_WARN)
            Column({ space: 2 }) {
              Text('2. Impending Drop (4.2 mmol/L)')
                .fontSize(PhoneTheme.FONT_BODY)
                .fontWeight(FontWeight.Bold)
                .fontColor(PhoneTheme.TEXT_PRIMARY)
              Text('Glucose trending down, restlessness rising')
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

          // Preset 3: Crisis
          Row({ space: 10 }) {
            Circle({ width: 8, height: 8 }).fill(PhoneTheme.STATE_CRIT)
            Column({ space: 2 }) {
              Text('3. Severe Emergency (3.1 mmol/L)')
                .fontSize(PhoneTheme.FONT_BODY)
                .fontWeight(FontWeight.Bold)
                .fontColor(PhoneTheme.TEXT_PRIMARY)
              Text('Critical hypoglycemia, watch alarm & SMS alert')
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
        .padding(PhoneTheme.CARD_PADDING)
        .backgroundColor(PhoneTheme.BG_CARD)
        .borderWidth(1)
        .borderColor(PhoneTheme.BORDER_SUBTLE)
        .borderRadius(PhoneTheme.CARD_RADIUS)
        .shadow({ radius: 8, color: 'rgba(15, 23, 42, 0.04)', offsetY: 2 })

        // Huawei Cloud SMN Status Card
        Column({ space: 8 }) {
          Row({ space: 6 }) {
            Circle({ width: 6, height: 6 }).fill(PhoneTheme.BRAND_ACCENT)
            Text('Huawei Cloud SMN Status')
              .fontSize(PhoneTheme.FONT_SECTION)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.TEXT_PRIMARY)
          }
          .width('100%')

          Row({ space: 6 }) {
            Text('SMS alerts armed for:')
              .fontSize(PhoneTheme.FONT_BODY)
              .fontColor(PhoneTheme.TEXT_MUTED)
            Text(this.caregiverPhone)
              .fontSize(PhoneTheme.FONT_BODY)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.TEXT_PRIMARY)
          }

          Text('Automatic priority dispatch triggers whenever glucose dips under 3.9 mmol/L.')
            .fontSize(PhoneTheme.FONT_CAPTION)
            .fontColor(PhoneTheme.TEXT_TERTIARY)
            .width('100%')
        }
        .width('100%')
        .padding(PhoneTheme.CARD_PADDING)
        .backgroundColor(PhoneTheme.BG_CARD)
        .borderWidth(1)
        .borderColor(PhoneTheme.BORDER_SUBTLE)
        .borderRadius(PhoneTheme.CARD_RADIUS)
        .shadow({ radius: 8, color: 'rgba(15, 23, 42, 0.04)', offsetY: 2 })
      }
      .width('100%')
      .padding({ left: 18, right: 18, top: 4, bottom: 36 })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .scrollable(ScrollDirection.Vertical)
  }
}
