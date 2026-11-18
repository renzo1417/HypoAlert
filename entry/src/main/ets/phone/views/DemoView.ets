/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Symptom simulation presets & Phase 1-3 testing view.
 */

import { VitalsData, VitalsEngine } from '../../models/VitalsModel';
import { riskLevel } from '../utils/PhoneRiskUtils';
import { PhoneTheme } from '../utils/PhoneTheme';

@Component
export struct DemoView {
  @Prop vitals: VitalsData = VitalsEngine.createInitialVitals();
  @Prop caregiverName: string = 'Maria Santos';
  @Prop caregiverPhone: string = '+63 917 123 4567';
  @Prop isWatchConnected: boolean = true;
  @Prop watchBattery: number = 86;
  @Prop deviceName: string = 'HUAWEI WATCH 4 Pro';
  onSimulateSteady: () => void = () => {};
  onSimulateStepCheck: () => void = () => {};
  onSimulateSurge: () => void = () => {};
  onMarkWithThem: () => void = () => {};
  onToggleWatchConnection: () => void = () => {};

  private isEmergency(): boolean {
    return riskLevel(this.vitals) === 'Critical';
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
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

          Text('Test Phase 1-3 symptom presets and wearable link')
            .fontSize(PhoneTheme.FONT_BODY)
            .fontColor(PhoneTheme.TEXT_MUTED)
            .width('100%')
        }
        .width('100%')
        .padding({ left: 2, right: 2 })

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
              Text(this.isWatchConnected ? `Battery: ${this.watchBattery}% • Sync OK` : 'Watch monitors autonomously')
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

        if (this.isEmergency()) {
          Row({ space: 10 }) {
            Column({ space: 2 }) {
              Text('Symptom Alert Active')
                .fontSize(PhoneTheme.FONT_SECTION)
                .fontWeight(FontWeight.Bold)
                .fontColor(PhoneTheme.STATE_CRIT)
              Text('Tap when awake to silence & enter 30m cooldown')
                .fontSize(PhoneTheme.FONT_CAPTION)
                .fontColor(PhoneTheme.TEXT_MUTED)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Button("I'm awake")
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

        Column({ space: 10 }) {
          Text('Symptom Scenario Presets')
            .fontSize(PhoneTheme.FONT_SECTION)
            .fontWeight(FontWeight.Bold)
            .fontColor(PhoneTheme.TEXT_PRIMARY)
            .width('100%')

          Row({ space: 10 }) {
            Circle({ width: 8, height: 8 }).fill(PhoneTheme.STATE_OK)
            Column({ space: 2 }) {
              Text('1. Calm Sleep (Normal Baseline)')
                .fontSize(PhoneTheme.FONT_BODY)
                .fontWeight(FontWeight.Bold)
                .fontColor(PhoneTheme.TEXT_PRIMARY)
              Text('HR, HRV, and wrist stillness within nightly baseline')
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
            this.onSimulateSteady();
          })

          Row({ space: 10 }) {
            Circle({ width: 8, height: 8 }).fill(PhoneTheme.STATE_WARN)
            Column({ space: 2 }) {
              Text('2. Elevated Check (+1 Streak)')
                .fontSize(PhoneTheme.FONT_BODY)
                .fontWeight(FontWeight.Bold)
                .fontColor(PhoneTheme.TEXT_PRIMARY)
              Text('Proves a single 5-min spike does not wake the user')
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
            this.onSimulateStepCheck();
          })

          Row({ space: 10 }) {
            Circle({ width: 8, height: 8 }).fill(PhoneTheme.STATE_CRIT)
            Column({ space: 2 }) {
              Text('3. Sustained Symptom Surge')
                .fontSize(PhoneTheme.FONT_BODY)
                .fontWeight(FontWeight.Bold)
                .fontColor(PhoneTheme.TEXT_PRIMARY)
              Text('Sustained streak fires wrist buzz & caregiver SMS (max 2/night)')
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
            this.onSimulateSurge();
          })
        }
        .width('100%')
        .padding(PhoneTheme.CARD_PADDING)
        .backgroundColor(PhoneTheme.BG_CARD)
        .borderWidth(1)
        .borderColor(PhoneTheme.BORDER_SUBTLE)
        .borderRadius(PhoneTheme.CARD_RADIUS)
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
