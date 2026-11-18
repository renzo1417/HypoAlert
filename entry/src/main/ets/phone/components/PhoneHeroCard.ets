/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Clinical-Grade Hero Status Card with Circular Hypoglycemia Risk Gauge.
 * Dual-readout: On-Device Sympathetic Surge Probability (0-100%) & Estimated Glycemic Trajectory (mmol/L).
 */

import {
  riskLevel,
  heroSentence,
  trendWord
} from '../utils/PhoneRiskUtils';
import { PhoneTheme } from '../utils/PhoneTheme';

@Component
export struct PhoneHeroCard {
  @Prop glucose: number = 5.5;
  @Prop riskIndex: number = 12;
  @Prop currentTime: string = '00:00:00';
  @Prop heartRate: number = 62;
  @Prop watchBattery: number = 86;
  @Prop bannerFlash: boolean = false;
  @Prop isWatchConnected: boolean = true;
  onCallNow: () => void = () => {};
  onMarkWithThem: () => void = () => {};

  private isEmergency(): boolean {
    return riskLevel(this.riskIndex) === 'Critical';
  }

  private isWarning(): boolean {
    return riskLevel(this.riskIndex) === 'Warning';
  }

  private getCardBg(): string {
    if (this.isEmergency()) {
      return PhoneTheme.STATE_CRIT;
    }
    return PhoneTheme.BG_CARD;
  }

  private getBorderColor(): string {
    if (this.isEmergency()) {
      return PhoneTheme.STATE_CRIT_DARK;
    }
    if (this.isWarning()) {
      return PhoneTheme.STATE_WARN;
    }
    return PhoneTheme.BORDER_SUBTLE;
  }

  private getRingColor(): string {
    if (this.isEmergency()) {
      return PhoneTheme.TEXT_ON_DARK;
    }
    if (this.isWarning()) {
      return PhoneTheme.STATE_WARN;
    }
    return PhoneTheme.STATE_OK;
  }

  private getRingBgColor(): string {
    if (this.isEmergency()) {
      return 'rgba(255, 255, 255, 0.25)';
    }
    return PhoneTheme.BG_MUTED;
  }

  build() {
    Column({ space: 12 }) {
      // Top Row: Single status pill only
      Row() {
        Row({ space: 4 }) {
          Circle({ width: 5, height: 5 })
            .fill(this.isEmergency() ? PhoneTheme.BG_CARD : (this.isWarning() ? PhoneTheme.STATE_WARN_TEXT : PhoneTheme.STATE_OK_TEXT))
          Text(this.isEmergency() ? 'URGENT' : (this.isWarning() ? 'WATCH' : 'STEADY'))
            .fontSize(PhoneTheme.FONT_MICRO)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.isEmergency() ? PhoneTheme.BG_CARD : (this.isWarning() ? PhoneTheme.STATE_WARN_TEXT : PhoneTheme.STATE_OK_TEXT))
        }
        .backgroundColor(this.isEmergency() ? 'rgba(255,255,255,0.2)' : (this.isWarning() ? PhoneTheme.STATE_WARN_BG : PhoneTheme.STATE_OK_BG))
        .borderRadius(PhoneTheme.PILL_RADIUS)
        .padding({ left: 8, right: 8, top: 3, bottom: 3 })

        Blank()

        Text(this.currentTime)
          .fontSize(PhoneTheme.FONT_CAPTION)
          .fontColor(this.isEmergency() ? 'rgba(255,255,255,0.75)' : PhoneTheme.TEXT_TERTIARY)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // Main: single dominant glucose + secondary risk ring
      Row({ space: 14 }) {
        // Right-first on mobile: glucose block grows, ring is secondary
        Column({ space: 2 }) {
          Text('GLUCOSE')
            .fontSize(PhoneTheme.FONT_MICRO)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.isEmergency() ? 'rgba(255,255,255,0.8)' : PhoneTheme.TEXT_TERTIARY)
          Row({ space: 4 }) {
            Text(`${this.glucose.toFixed(1)}`)
              .fontSize(PhoneTheme.FONT_HERO)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.isEmergency() ? PhoneTheme.TEXT_ON_DARK : PhoneTheme.TEXT_PRIMARY)

            Text('mmol/L')
              .fontSize(PhoneTheme.FONT_BODY)
              .fontColor(this.isEmergency() ? 'rgba(255,255,255,0.9)' : PhoneTheme.TEXT_MUTED)
              .margin({ bottom: 4 })
          }
          .alignItems(VerticalAlign.Bottom)

          Text(`${trendWord(this.riskIndex)} • Target ≥3.9`)
            .fontSize(PhoneTheme.FONT_CAPTION)
            .fontColor(this.isEmergency() ? PhoneTheme.TEXT_ON_DARK : (this.isWarning() ? PhoneTheme.STATE_WARN_TEXT : PhoneTheme.TEXT_MUTED))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        // Secondary: smaller risk ring with label
        Column({ space: 2 }) {
          Stack({ alignContent: Alignment.Center }) {
            Progress({
              value: this.riskIndex,
              total: 100,
              type: ProgressType.Ring
            })
              .color(this.getRingColor())
              .backgroundColor(this.getRingBgColor())
              .style({ strokeWidth: 6 })
              .width(56)
              .height(56)

            Text(`${this.riskIndex}`)
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.isEmergency() ? PhoneTheme.TEXT_ON_DARK : PhoneTheme.TEXT_PRIMARY)
          }
          .width(56)
          .height(56)
          Text('Risk')
            .fontSize(PhoneTheme.FONT_MICRO)
            .fontColor(this.isEmergency() ? 'rgba(255,255,255,0.8)' : PhoneTheme.TEXT_MUTED)
        }
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .padding({ top: 2, bottom: 2 })

      Divider()
        .color(this.isEmergency() ? 'rgba(255,255,255,0.2)' : PhoneTheme.BORDER_LIGHT)
        .strokeWidth(1)

      // One-line status
      Text(heroSentence(this.riskIndex))
        .fontSize(PhoneTheme.FONT_BODY)
        .fontColor(this.isEmergency() ? PhoneTheme.TEXT_ON_DARK : PhoneTheme.TEXT_SECONDARY)
        .width('100%')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      // Actions (thumb-zone, emergency only)
      if (this.isEmergency()) {
        Row({ space: 10 }) {
          Button("I'm awake")
            .fontSize(PhoneTheme.FONT_SUBTITLE)
            .fontWeight(FontWeight.Bold)
            .height(48)
            .layoutWeight(1)
            .backgroundColor(PhoneTheme.BG_CARD)
            .fontColor(PhoneTheme.STATE_CRIT)
            .borderRadius(PhoneTheme.TILE_RADIUS)
            .onClick(() => {
              this.onMarkWithThem();
            })

          Button('Call now')
            .fontSize(PhoneTheme.FONT_SUBTITLE)
            .fontWeight(FontWeight.Bold)
            .height(48)
            .layoutWeight(1)
            .backgroundColor('rgba(255,255,255,0.2)')
            .fontColor(PhoneTheme.TEXT_ON_DARK)
            .border({ width: 1.5, color: PhoneTheme.TEXT_ON_DARK, radius: PhoneTheme.TILE_RADIUS })
            .borderRadius(PhoneTheme.TILE_RADIUS)
            .onClick(() => {
              this.onCallNow();
            })
        }
        .width('100%')
        .margin({ top: 2 })
      } else if (this.isWarning()) {
        Button('Check now')
          .fontSize(PhoneTheme.FONT_BODY)
          .fontWeight(FontWeight.Bold)
          .height(44)
          .width('100%')
          .backgroundColor(PhoneTheme.STATE_WARN)
          .fontColor(PhoneTheme.TEXT_ON_DARK)
          .borderRadius(PhoneTheme.TILE_RADIUS)
          .onClick(() => {
            this.onCallNow();
          })
      }
    }
    .width('100%')
    .padding(PhoneTheme.CARD_PADDING)
    .backgroundColor(this.getCardBg())
    .borderWidth(1)
    .borderColor(this.getBorderColor())
    .borderRadius(PhoneTheme.CARD_RADIUS)
    .shadow({ radius: 10, color: 'rgba(15, 23, 42, 0.06)', offsetY: 2 })
  }
}
