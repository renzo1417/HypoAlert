/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Interactive Scenario & Phase 1-3 Testing Sheet.
 */

import { BodyPhenotype, DetectionPhase, VitalsEngine } from '../../models/VitalsModel';
import { PhoneTheme } from '../utils/PhoneTheme';

@Component
export struct DemoSheet {
  @Prop isWatchConnected: boolean = true;
  @Prop watchBattery: number = 86;
  @Prop phenotype: BodyPhenotype = BodyPhenotype.ADRENERGIC;
  @Prop activePhase: DetectionPhase = 1;
  onSimulateBaseline: () => void = () => {};
  onSimulateSteady: () => void = () => {};
  onSimulateStepCheck: () => void = () => {};
  onSimulateSurge: () => void = () => {};
  onSimulateMoving: () => void = () => {};
  onSimulateReplayC2s02: () => void = () => {};
  onTogglePhenotype: () => void = () => {};
  onCyclePhase: () => void = () => {};
  onToggleWatchConnection: () => void = () => {};
  onClose: () => void = () => {};

  build() {
    Column({ space: 10 }) {
      Row() {
        Text('Test sleep scenarios')
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

      // Watch link + Body Type + Phase quick toggles
      Row({ space: 8 }) {
        Button(this.phenotype === BodyPhenotype.ADRENERGIC ? 'Adrenergic (3x)' : 'Blunted (2x)')
          .fontSize(PhoneTheme.FONT_CAPTION)
          .fontWeight(FontWeight.Bold)
          .height(34)
          .layoutWeight(1)
          .backgroundColor(PhoneTheme.BG_SUBTLE)
          .fontColor(PhoneTheme.BRAND_ACCENT)
          .borderRadius(PhoneTheme.TILE_RADIUS)
          .onClick(() => {
            this.onTogglePhenotype();
          })

        Button(VitalsEngine.getPhaseShort(this.activePhase))
          .fontSize(PhoneTheme.FONT_CAPTION)
          .fontWeight(FontWeight.Bold)
          .height(34)
          .layoutWeight(1)
          .backgroundColor(PhoneTheme.BG_SUBTLE)
          .fontColor(PhoneTheme.TEXT_PRIMARY)
          .borderRadius(PhoneTheme.TILE_RADIUS)
          .onClick(() => {
            this.onCyclePhase();
          })

        Button(this.isWatchConnected ? `Watch ${this.watchBattery}%` : 'Offline')
          .fontSize(PhoneTheme.FONT_CAPTION)
          .fontWeight(FontWeight.Bold)
          .height(34)
          .padding({ left: 10, right: 10 })
          .backgroundColor(this.isWatchConnected ? PhoneTheme.STATE_OK_BG : PhoneTheme.STATE_WARN_BG)
          .fontColor(this.isWatchConnected ? PhoneTheme.STATE_OK_TEXT : PhoneTheme.STATE_WARN_TEXT)
          .borderRadius(PhoneTheme.TILE_RADIUS)
          .onClick(() => {
            this.onToggleWatchConnection();
          })
      }
      .width('100%')

      Column({ space: 8 }) {
        Button() {
          Row({ space: 10 }) {
            Circle({ width: 8, height: 8 }).fill(PhoneTheme.BRAND_ACCENT)
            Text('75-Min Silent Baseline')
              .fontSize(PhoneTheme.FONT_BODY)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.TEXT_PRIMARY)
              .layoutWeight(1)
            Text('Learning')
              .fontSize(PhoneTheme.FONT_MICRO)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.BRAND_ACCENT)
          }
          .width('100%')
        }
        .width('100%')
        .padding(11)
        .backgroundColor(PhoneTheme.BG_CARD)
        .borderWidth(1)
        .borderColor(PhoneTheme.BORDER_SUBTLE)
        .borderRadius(PhoneTheme.TILE_RADIUS)
        .onClick(() => {
          this.onSimulateBaseline();
          this.onClose();
        })

        Button() {
          Row({ space: 10 }) {
            Circle({ width: 8, height: 8 }).fill(PhoneTheme.STATE_OK)
            Text('Calm Sleep (Normal)')
              .fontSize(PhoneTheme.FONT_BODY)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.TEXT_PRIMARY)
              .layoutWeight(1)
            Text('Steady')
              .fontSize(PhoneTheme.FONT_MICRO)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.STATE_OK_TEXT)
          }
          .width('100%')
        }
        .width('100%')
        .padding(11)
        .backgroundColor(PhoneTheme.BG_CARD)
        .borderWidth(1)
        .borderColor(PhoneTheme.BORDER_SUBTLE)
        .borderRadius(PhoneTheme.TILE_RADIUS)
        .onClick(() => {
          this.onSimulateSteady();
          this.onClose();
        })

        Button() {
          Row({ space: 10 }) {
            Circle({ width: 8, height: 8 }).fill(PhoneTheme.STATE_WARN)
            Text('Add 1 Elevated Check (Streak +1)')
              .fontSize(PhoneTheme.FONT_BODY)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.TEXT_PRIMARY)
              .layoutWeight(1)
            Text('Step')
              .fontSize(PhoneTheme.FONT_MICRO)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.STATE_WARN_TEXT)
          }
          .width('100%')
        }
        .width('100%')
        .padding(11)
        .backgroundColor(PhoneTheme.BG_CARD)
        .borderWidth(1)
        .borderColor(PhoneTheme.BORDER_SUBTLE)
        .borderRadius(PhoneTheme.TILE_RADIUS)
        .onClick(() => {
          this.onSimulateStepCheck();
          this.onClose();
        })

        Button() {
          Row({ space: 10 }) {
            Circle({ width: 8, height: 8 }).fill(PhoneTheme.TEXT_TERTIARY)
            Text('Tossing / Awake (Motion Gate)')
              .fontSize(PhoneTheme.FONT_BODY)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.TEXT_PRIMARY)
              .layoutWeight(1)
            Text('Pause')
              .fontSize(PhoneTheme.FONT_MICRO)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.TEXT_MUTED)
          }
          .width('100%')
        }
        .width('100%')
        .padding(11)
        .backgroundColor(PhoneTheme.BG_CARD)
        .borderWidth(1)
        .borderColor(PhoneTheme.BORDER_SUBTLE)
        .borderRadius(PhoneTheme.TILE_RADIUS)
        .onClick(() => {
          this.onSimulateMoving();
          this.onClose();
        })

        Button() {
          Row({ space: 10 }) {
            Circle({ width: 8, height: 8 }).fill(PhoneTheme.STATE_CRIT)
            Text('Sustained Symptom Surge')
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
        }
        .width('100%')
        .padding(11)
        .backgroundColor(PhoneTheme.BG_CARD)
        .borderWidth(1)
        .borderColor(PhoneTheme.STATE_CRIT)
        .borderRadius(PhoneTheme.TILE_RADIUS)
        .onClick(() => {
          this.onSimulateSurge();
          this.onClose();
        })

        Button() {
          Row({ space: 10 }) {
            Circle({ width: 8, height: 8 }).fill(PhoneTheme.BRAND_ACCENT)
            Text('Replay Real c2s02_7 (Phase 3 1D-CNN)')
              .fontSize(PhoneTheme.FONT_BODY)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.TEXT_PRIMARY)
              .layoutWeight(1)
            Text('Real Data')
              .fontSize(PhoneTheme.FONT_MICRO)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.BRAND_ACCENT)
          }
          .width('100%')
        }
        .width('100%')
        .padding(11)
        .backgroundColor(PhoneTheme.BRAND_ACCENT_BG)
        .borderWidth(1)
        .borderColor(PhoneTheme.BRAND_ACCENT)
        .borderRadius(PhoneTheme.TILE_RADIUS)
        .onClick(() => {
          this.onSimulateReplayC2s02();
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
