/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Clinical-Grade Hero Status Card with Circular Hypoglycemia Risk Gauge.
 * Dual-readout: Real-time Sympathetic Probability (0-100%) & Estimated Glycemic Trajectory (mmol/L).
 */

import {
  riskLevel,
  heroSentence,
  trendWord,
  riskColor
} from '../utils/PhoneRiskUtils';

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
      return '#EF4444';
    }
    if (this.isWarning()) {
      return '#FFFBEB';
    }
    return '#FFFFFF';
  }

  private getBorderColor(): string {
    if (this.isEmergency()) {
      return '#DC2626';
    }
    if (this.isWarning()) {
      return '#FDE68A';
    }
    return '#E2E8F0';
  }

  private getRingColor(): string {
    if (this.isEmergency()) {
      return '#FFFFFF';
    }
    if (this.isWarning()) {
      return '#F59E0B';
    }
    return '#10B981';
  }

  private getRingBgColor(): string {
    if (this.isEmergency()) {
      return 'rgba(255, 255, 255, 0.25)';
    }
    return '#F1F5F9';
  }

  build() {
    Column({ space: 14 }) {
      // Top Row: Category Header + Status Badge
      Row() {
        Row({ space: 6 }) {
          Circle({ width: 7, height: 7 })
            .fill(this.isEmergency() ? '#FFFFFF' : riskColor(this.riskIndex))
          Text('AI Hypoglycemia Early Warning')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.isEmergency() ? '#FFFFFF' : '#475569')
        }
        .alignItems(VerticalAlign.Center)

        Blank()

        // Status Badge
        Row({ space: 4 }) {
          Circle({ width: 6, height: 6 })
            .fill(this.isEmergency() ? '#EF4444' : (this.isWarning() ? '#B45309' : '#15803D'))
          Text(this.isEmergency() ? 'CRITICAL ALERT' : (this.isWarning() ? 'PRE-DROP DIP' : 'ALL CLEAR'))
            .fontSize(10)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.isEmergency() ? '#EF4444' : (this.isWarning() ? '#B45309' : '#15803D'))
        }
        .backgroundColor(this.isEmergency() ? '#FFFFFF' : (this.isWarning() ? '#FEF3C7' : '#DCFCE7'))
        .borderRadius(999)
        .padding({ left: 8, right: 8, top: 3, bottom: 3 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // Main Data Center: Circular Gauge (Left) + Estimated Glucose Block (Right)
      Row({ space: 16 }) {
        // Left: Circular Hypoglycemia Probability Gauge
        Stack({ alignContent: Alignment.Center }) {
          Progress({
            value: this.riskIndex,
            total: 100,
            type: ProgressType.Ring
          })
            .color(this.getRingColor())
            .backgroundColor(this.getRingBgColor())
            .style({ strokeWidth: 8 })
            .width(82)
            .height(82)

          Column({ space: 1 }) {
            Text(`${this.riskIndex}%`)
              .fontSize(19)
              .fontWeight(FontWeight.Bolder)
              .fontColor(this.isEmergency() ? '#FFFFFF' : '#111827')
            Text('RISK')
              .fontSize(8)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.isEmergency() ? 'rgba(255,255,255,0.85)' : '#64748B')
          }
          .alignItems(HorizontalAlign.Center)
        }
        .width(82)
        .height(82)

        // Right: Estimated Glycemic Readout & Trend
        Column({ space: 3 }) {
          Text('ESTIMATED GLUCOSE')
            .fontSize(10)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.isEmergency() ? 'rgba(255,255,255,0.85)' : '#94A3B8')

          Row({ space: 4 }) {
            Text(`${this.glucose.toFixed(1)}`)
              .fontSize(36)
              .fontWeight(FontWeight.Bolder)
              .fontColor(this.isEmergency() ? '#FFFFFF' : '#111827')

            Text('mmol/L')
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.isEmergency() ? 'rgba(255,255,255,0.9)' : '#64748B')
              .margin({ bottom: 5 })
          }
          .alignItems(VerticalAlign.Bottom)

          Row({ space: 4 }) {
            Text(`Trend: ${trendWord(this.riskIndex)}`)
              .fontSize(11)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.isEmergency() ? '#FFFFFF' : (this.isWarning() ? '#B45309' : '#15803D'))
            Text('• Non-invasive inference')
              .fontSize(10)
              .fontColor(this.isEmergency() ? 'rgba(255,255,255,0.7)' : '#94A3B8')
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .padding({ top: 4, bottom: 4 })

      Divider()
        .color(this.isEmergency() ? 'rgba(255,255,255,0.2)' : '#F1F5F9')
        .strokeWidth(1)

      // Reassuring One-Line Status Statement
      Row({ space: 8 }) {
        Stack({ alignContent: Alignment.Center }) {
          Circle({ width: 18, height: 18 })
            .fill(this.isEmergency() ? '#FFFFFF' : (this.isWarning() ? '#FEF3C7' : '#DCFCE7'))
          Text(this.isEmergency() ? '!' : '✓')
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.isEmergency() ? '#EF4444' : (this.isWarning() ? '#D97706' : '#15803D'))
        }
        .width(18)
        .height(18)

        Text(heroSentence(this.riskIndex))
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.isEmergency() ? '#FFFFFF' : '#334155')
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // Emergency / Warning Action Buttons
      if (this.isEmergency()) {
        Row({ space: 10 }) {
          Button('Call Caregiver Now')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .height(44)
            .layoutWeight(1)
            .backgroundColor('#FFFFFF')
            .fontColor('#EF4444')
            .borderRadius(14)
            .shadow({ radius: 8, color: 'rgba(0,0,0,0.1)', offsetY: 2 })
            .onClick(() => {
              this.onCallNow();
            })

          Button("I'm With Them")
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .height(44)
            .layoutWeight(1)
            .backgroundColor('rgba(255,255,255,0.25)')
            .fontColor('#FFFFFF')
            .border({ width: 1.5, color: '#FFFFFF', radius: 14 })
            .borderRadius(14)
            .onClick(() => {
              this.onMarkWithThem();
            })
        }
        .width('100%')
        .margin({ top: 2 })
      } else if (this.isWarning()) {
        Button('Check on Them — Warning Alert')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .height(40)
          .width('100%')
          .backgroundColor('#F59E0B')
          .fontColor('#FFFFFF')
          .borderRadius(12)
          .shadow({ radius: 6, color: 'rgba(245,158,11,0.25)', offsetY: 2 })
          .onClick(() => {
            this.onCallNow();
          })
      }
    }
    .width('100%')
    .padding(18)
    .backgroundColor(this.getCardBg())
    .borderWidth(1)
    .borderColor(this.getBorderColor())
    .borderRadius(22)
    .shadow({ radius: 10, color: 'rgba(0, 0, 0, 0.04)', offsetY: 2 })
  }
}
