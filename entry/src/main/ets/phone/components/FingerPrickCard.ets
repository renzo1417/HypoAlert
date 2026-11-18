/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Compact Finger-Prick Check-In Card (minimal copy, stroke-free pills).
 */

import { CalibrationProgress } from '../../models/HistoryModel';
import { PhoneTheme } from '../utils/PhoneTheme';

@Component
export struct FingerPrickCard {
  @Prop calibration: CalibrationProgress = {
    buzzPricks: 2,
    buzzPricksTarget: 3,
    confirmedLows: 0,
    confirmedLowsTarget: 1,
    fineNights: 6,
    fineNightsTarget: 10,
    personalCutoff: 4.3,
    phase2Unlocked: false,
    phase3Unlocked: false,
    lastCheckSummary: ''
  };
  @Prop pendingBuzzCheck: boolean = false;
  onLogFingerPrick: (mgDl: number) => void = () => {};
  onViewReports: () => void = () => {};

  private unlockLabel(): string {
    if (this.calibration.phase3Unlocked) {
      return 'P3 Ready';
    }
    if (this.calibration.phase2Unlocked) {
      return 'P2 Active';
    }
    return `P2 · ${this.calibration.buzzPricks}/${this.calibration.buzzPricksTarget}`;
  }

  build() {
    Column({ space: 12 }) {
      Row({ space: 8 }) {
        Column({ space: 1 }) {
          Text('Finger-Prick')
            .fontSize(PhoneTheme.FONT_SECTION)
            .fontWeight(FontWeight.Bold)
            .fontColor(PhoneTheme.TEXT_PRIMARY)

          if (this.pendingBuzzCheck) {
            Text('Check blood sugar')
              .fontSize(PhoneTheme.FONT_CAPTION)
              .fontColor(PhoneTheme.STATE_WARN_TEXT)
          } else if (this.calibration.lastCheckSummary.length > 0) {
            Text(this.calibration.lastCheckSummary)
              .fontSize(PhoneTheme.FONT_CAPTION)
              .fontColor(PhoneTheme.TEXT_MUTED)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Button(this.unlockLabel())
          .fontSize(PhoneTheme.FONT_CAPTION)
          .fontWeight(FontWeight.Medium)
          .height(30)
          .padding({ left: 11, right: 11 })
          .backgroundColor(PhoneTheme.BG_INSET)
          .fontColor(PhoneTheme.TEXT_PRIMARY)
          .borderRadius(PhoneTheme.PILL_RADIUS)
          .onClick(() => {
            this.onViewReports();
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Row({ space: 8 }) {
        Column({ space: 1 }) {
          Text('Buzz')
            .fontSize(PhoneTheme.FONT_MICRO)
            .fontColor(PhoneTheme.TEXT_MUTED)
          Text(`${this.calibration.buzzPricks}/${this.calibration.buzzPricksTarget}`)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontFeature('"tnum" on')
            .fontColor(this.calibration.phase2Unlocked ? PhoneTheme.STATE_OK_TEXT : PhoneTheme.TEXT_PRIMARY)
        }
        .layoutWeight(1)
        .padding({ left: 10, right: 10, top: 8, bottom: 8 })
        .backgroundColor(PhoneTheme.BG_INSET)
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        Column({ space: 1 }) {
          Text('Low')
            .fontSize(PhoneTheme.FONT_MICRO)
            .fontColor(PhoneTheme.TEXT_MUTED)
          Text(`${this.calibration.confirmedLows}/${this.calibration.confirmedLowsTarget}`)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontFeature('"tnum" on')
            .fontColor(this.calibration.confirmedLows >= this.calibration.confirmedLowsTarget ? PhoneTheme.STATE_OK_TEXT : PhoneTheme.TEXT_PRIMARY)
        }
        .layoutWeight(1)
        .padding({ left: 10, right: 10, top: 8, bottom: 8 })
        .backgroundColor(PhoneTheme.BG_INSET)
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        Column({ space: 1 }) {
          Text('Fine')
            .fontSize(PhoneTheme.FONT_MICRO)
            .fontColor(PhoneTheme.TEXT_MUTED)
          Text(`${this.calibration.fineNights}/${this.calibration.fineNightsTarget}`)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontFeature('"tnum" on')
            .fontColor(this.calibration.fineNights >= this.calibration.fineNightsTarget ? PhoneTheme.STATE_OK_TEXT : PhoneTheme.TEXT_PRIMARY)
        }
        .layoutWeight(1)
        .padding({ left: 10, right: 10, top: 8, bottom: 8 })
        .backgroundColor(PhoneTheme.BG_INSET)
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      Row({ space: 10 }) {
        Button() {
          Row({ space: 6 }) {
            SymbolGlyph($r('sys.symbol.drop_fill'))
              .fontSize(13)
              .fontColor([PhoneTheme.STATE_CRIT_TEXT])

            Text('54 · Low')
              .fontSize(PhoneTheme.FONT_BODY)
              .fontWeight(FontWeight.Bold)
              .fontFeature('"tnum" on')
              .fontColor(PhoneTheme.STATE_CRIT_TEXT)
          }
          .alignItems(VerticalAlign.Center)
        }
        .height(42)
        .layoutWeight(1)
        .backgroundColor(PhoneTheme.STATE_CRIT_BG)
        .borderRadius(PhoneTheme.PILL_RADIUS)
        .onClick(() => {
          this.onLogFingerPrick(54);
        })

        Button() {
          Row({ space: 6 }) {
            SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))
              .fontSize(13)
              .fontColor([PhoneTheme.STATE_OK_TEXT])

            Text('108 · Fine')
              .fontSize(PhoneTheme.FONT_BODY)
              .fontWeight(FontWeight.Bold)
              .fontFeature('"tnum" on')
              .fontColor(PhoneTheme.STATE_OK_TEXT)
          }
          .alignItems(VerticalAlign.Center)
        }
        .height(42)
        .layoutWeight(1)
        .backgroundColor(PhoneTheme.STATE_OK_BG)
        .borderRadius(PhoneTheme.PILL_RADIUS)
        .onClick(() => {
          this.onLogFingerPrick(108);
        })
      }
      .width('100%')
    }
    .width('100%')
    .padding(PhoneTheme.CARD_PADDING)
    .backgroundColor(PhoneTheme.BG_CARD)
    .borderRadius(PhoneTheme.CARD_RADIUS)
    .shadow({ radius: 12, color: 'rgba(17, 19, 24, 0.04)', offsetY: 3 })
  }
}
