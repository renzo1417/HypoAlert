/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Huawei Health Style Hero Card showing Symptom Risk, Phase, Streak, and Plain Reason.
 */

import { VitalsData, VitalsEngine } from '../../models/VitalsModel';
import { heroSentence, riskLevel, statusBadgeText } from '../utils/PhoneRiskUtils';
import { PhoneTheme } from '../utils/PhoneTheme';

@Component
export struct PhoneHeroCard {
  @Prop vitals: VitalsData = VitalsEngine.createInitialVitals();
  @Prop currentTime: string = '00:00:00';
  @Prop watchBattery: number = 86;
  @Prop isWatchConnected: boolean = true;
  onCallNow: () => void = () => {};
  onMarkWithThem: () => void = () => {};

  private isEmergency(): boolean {
    return riskLevel(this.vitals) === 'Critical';
  }

  private isWarning(): boolean {
    return riskLevel(this.vitals) === 'Warning';
  }

  private isBaseline(): boolean {
    return this.vitals.baselineMinutes < VitalsEngine.BASELINE_TOTAL_MINUTES;
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
    if (this.isBaseline()) {
      return PhoneTheme.BRAND_ACCENT;
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
    if (this.isBaseline()) {
      return PhoneTheme.BRAND_ACCENT;
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
      // Top Row: Status badge + Phase chip + time
      Row() {
        Row({ space: 4 }) {
          Circle({ width: 5, height: 5 })
            .fill(this.isEmergency() ? PhoneTheme.BG_CARD : (this.isWarning() ? PhoneTheme.STATE_WARN_TEXT : (this.isBaseline() ? PhoneTheme.BRAND_ACCENT : PhoneTheme.STATE_OK_TEXT)))
          Text(statusBadgeText(this.vitals))
            .fontSize(PhoneTheme.FONT_MICRO)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.isEmergency() ? PhoneTheme.BG_CARD : (this.isWarning() ? PhoneTheme.STATE_WARN_TEXT : (this.isBaseline() ? PhoneTheme.BRAND_ACCENT : PhoneTheme.STATE_OK_TEXT)))
        }
        .backgroundColor(this.isEmergency() ? 'rgba(255,255,255,0.2)' : (this.isWarning() ? PhoneTheme.STATE_WARN_BG : (this.isBaseline() ? PhoneTheme.BRAND_ACCENT_BG : PhoneTheme.STATE_OK_BG)))
        .borderRadius(PhoneTheme.PILL_RADIUS)
        .padding({ left: 8, right: 8, top: 3, bottom: 3 })

        Text(VitalsEngine.getPhaseShort(this.vitals.phase))
          .fontSize(PhoneTheme.FONT_MICRO)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.isEmergency() ? 'rgba(255,255,255,0.9)' : PhoneTheme.TEXT_SECONDARY)
          .backgroundColor(this.isEmergency() ? 'rgba(255,255,255,0.16)' : PhoneTheme.BG_SUBTLE)
          .borderRadius(PhoneTheme.PILL_RADIUS)
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .margin({ left: 6 })

        Blank()

        Text(this.currentTime)
          .fontSize(PhoneTheme.FONT_CAPTION)
          .fontColor(this.isEmergency() ? 'rgba(255,255,255,0.75)' : PhoneTheme.TEXT_TERTIARY)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // Main: Symptom risk % or 75-min baseline progress + Ring Gauge
      Row({ space: 14 }) {
        Column({ space: 2 }) {
          Text('HYPO SYMPTOM RISK')
            .fontSize(PhoneTheme.FONT_MICRO)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.isEmergency() ? 'rgba(255,255,255,0.85)' : PhoneTheme.TEXT_TERTIARY)

          if (this.isBaseline()) {
            Row({ space: 4 }) {
              Text(`${this.vitals.baselineMinutes}`)
                .fontSize(PhoneTheme.FONT_HERO)
                .fontWeight(FontWeight.Bold)
                .fontColor(PhoneTheme.TEXT_PRIMARY)
              Text('/ 75 min')
                .fontSize(PhoneTheme.FONT_BODY)
                .fontColor(PhoneTheme.TEXT_MUTED)
                .margin({ bottom: 4 })
            }
            .alignItems(VerticalAlign.Bottom)
          } else {
            Row({ space: 4 }) {
              Text(`${this.vitals.symptomRiskPct}%`)
                .fontSize(PhoneTheme.FONT_HERO)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.isEmergency() ? PhoneTheme.TEXT_ON_DARK : PhoneTheme.TEXT_PRIMARY)

              Text(this.vitals.isSedentary ? 'symptom risk' : 'paused')
                .fontSize(PhoneTheme.FONT_BODY)
                .fontColor(this.isEmergency() ? 'rgba(255,255,255,0.9)' : PhoneTheme.TEXT_MUTED)
                .margin({ bottom: 4 })
            }
            .alignItems(VerticalAlign.Bottom)
          }

          Text(`Checks: ${this.vitals.streakCount}/${this.vitals.streakRequired} in a row • Alerts: ${this.vitals.alertsTonight}/2`)
            .fontSize(PhoneTheme.FONT_CAPTION)
            .fontColor(this.isEmergency() ? PhoneTheme.TEXT_ON_DARK : (this.isWarning() ? PhoneTheme.STATE_WARN_TEXT : PhoneTheme.TEXT_MUTED))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Column({ space: 2 }) {
          Stack({ alignContent: Alignment.Center }) {
            Progress({
              value: this.isBaseline()
                ? Math.round((this.vitals.baselineMinutes / VitalsEngine.BASELINE_TOTAL_MINUTES) * 100)
                : this.vitals.symptomRiskPct,
              total: 100,
              type: ProgressType.Ring
            })
              .color(this.getRingColor())
              .backgroundColor(this.getRingBgColor())
              .style({ strokeWidth: 6 })
              .width(56)
              .height(56)

            Text(this.isBaseline() ? `${this.vitals.baselineMinutes}m` : `${this.vitals.symptomRiskPct}`)
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.isEmergency() ? PhoneTheme.TEXT_ON_DARK : PhoneTheme.TEXT_PRIMARY)
          }
          .width(56)
          .height(56)
          Text(this.isBaseline() ? 'Setup' : 'Risk')
            .fontSize(PhoneTheme.FONT_MICRO)
            .fontColor(this.isEmergency() ? 'rgba(255,255,255,0.85)' : PhoneTheme.TEXT_MUTED)
        }
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .padding({ top: 2, bottom: 2 })

      Divider()
        .color(this.isEmergency() ? 'rgba(255,255,255,0.2)' : PhoneTheme.BORDER_LIGHT)
        .strokeWidth(1)

      // Plain-English explanation
      Text(heroSentence(this.vitals))
        .fontSize(PhoneTheme.FONT_BODY)
        .fontColor(this.isEmergency() ? PhoneTheme.TEXT_ON_DARK : PhoneTheme.TEXT_SECONDARY)
        .width('100%')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      // Driver detail chip
      Row({ space: 6 }) {
        Text(VitalsEngine.getPhenotypeLabel(this.vitals.phenotype))
          .fontSize(PhoneTheme.FONT_MICRO)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.isEmergency() ? PhoneTheme.TEXT_ON_DARK : PhoneTheme.TEXT_MUTED)
          .backgroundColor(this.isEmergency() ? 'rgba(255,255,255,0.16)' : PhoneTheme.BG_SUBTLE)
          .borderRadius(PhoneTheme.PILL_RADIUS)
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })

        Text(this.vitals.reasonSummary)
          .fontSize(PhoneTheme.FONT_MICRO)
          .fontColor(this.isEmergency() ? 'rgba(255,255,255,0.9)' : PhoneTheme.TEXT_MUTED)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      if (this.vitals.tcnnEma !== undefined && this.vitals.tcnnThr !== undefined) {
        Row({ space: 6 }) {
          Text(`1D-CNN ${this.vitals.tcnnSlotsFilled ?? 12}/12 slots`)
            .fontSize(PhoneTheme.FONT_MICRO)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.isEmergency() ? PhoneTheme.TEXT_ON_DARK : PhoneTheme.BRAND_ACCENT)

          Text(`EMA ${this.vitals.tcnnEma.toFixed(2)} vs ${this.vitals.tcnnThr.toFixed(2)}`)
            .fontSize(PhoneTheme.FONT_MICRO)
            .fontColor(this.isEmergency() ? 'rgba(255,255,255,0.9)' : PhoneTheme.TEXT_SECONDARY)
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          if (this.vitals.tcnnRawLogit !== undefined) {
            Text(`z ${this.vitals.tcnnRawLogit.toFixed(2)}`)
              .fontSize(PhoneTheme.FONT_MICRO)
              .fontColor(this.isEmergency() ? 'rgba(255,255,255,0.85)' : PhoneTheme.TEXT_TERTIARY)
          }
        }
        .width('100%')
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .backgroundColor(this.isEmergency() ? 'rgba(255,255,255,0.16)' : PhoneTheme.BG_SUBTLE)
        .borderRadius(PhoneTheme.TILE_RADIUS)
      }

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

          Button('Call caregiver')
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
        Button('Check sleeper now')
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
