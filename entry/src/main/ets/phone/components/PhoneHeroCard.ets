/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Hero banner card displaying nocturnal state, vitals chips, and quick actions.
 */

import {
  riskLevel,
  heroSentence,
  trendWord,
  heartSub,
  statusPillText
} from '../utils/PhoneRiskUtils';

@Component
export struct PhoneHeroCard {
  @Prop glucose: number = 5.5;
  @Prop riskIndex: number = 12;
  @Prop currentTime: string = '00:00:00';
  @Prop heartRate: number = 62;
  @Prop watchBattery: number = 86;
  @Prop bannerFlash: boolean = false;
  onCallNow: () => void = () => {};
  onMarkWithThem: () => void = () => {};

  private isEmergency(): boolean {
    return riskLevel(this.riskIndex) === 'Critical';
  }

  private statusKind(): string {
    return riskLevel(this.riskIndex);
  }

  @Builder
  moonMotif() {
    Stack({ alignContent: Alignment.Center }) {
      Circle({ width: 44, height: 44 })
        .fill('#FFFFFF')
        .shadow({ radius: 8, color: 'rgba(46,134,222,0.25)', offsetX: 0, offsetY: 2 })
      Circle({ width: 34, height: 34 })
        .fill('#DFE9FA')
        .offset({ x: 11, y: -7 })
      Circle({ width: 5, height: 5 })
        .fill('#F6B8C1')
        .offset({ x: -15, y: -11 })
      Circle({ width: 4, height: 4 })
        .fill('#2E86DE')
        .offset({ x: 15, y: 13 })
    }
    .width(52)
    .height(52)
  }

  @Builder
  emergencyMark() {
    Stack({ alignContent: Alignment.Center }) {
      Circle({ width: 46, height: 46 })
        .fill('#FFFFFF')
      Text('!')
        .fontSize(28)
        .fontWeight(FontWeight.Bolder)
        .fontColor('#FF3B30')
    }
    .width(52)
    .height(52)
  }

  @Builder
  statusPill() {
    Text(statusPillText(this.riskIndex))
      .fontSize(13)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.isEmergency() ? '#FF3B30' : (this.statusKind() === 'Warning' ? '#B25E09' : '#1E7E34'))
      .backgroundColor('#FFFFFF')
      .borderRadius(20)
      .padding({ left: 12, right: 12, top: 7, bottom: 7 })
  }

  @Builder
  glassChip(caption: string, value: string, sub: string, dot: string) {
    Row({ space: 8 }) {
      Circle({ width: 9, height: 9 })
        .fill(dot)
      Column({ space: 1 }) {
        Text(caption)
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor('#8A94A6')
        Text(value)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#0F1B2D')
        Text(sub)
          .fontSize(12)
          .fontColor('#5B6B82')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .layoutWeight(1)
    .padding(10)
    .backgroundColor('rgba(255,255,255,0.94)')
    .borderRadius(14)
    .border({ width: 1, color: '#FFFFFF', radius: 14 })
    .shadow({ radius: 8, color: 'rgba(15,27,45,0.10)', offsetX: 0, offsetY: 3 })
  }

  build() {
    Column({ space: 10 }) {
      Row({ space: 10 }) {
        if (this.isEmergency()) {
          this.emergencyMark()
        } else {
          this.moonMotif()
        }
        Column({ space: 2 }) {
          Text('TONIGHT')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.isEmergency() ? '#FFFFFF' : '#5B6B82')
            .width('100%')
          Text('Night guardian • 22:00–06:00')
            .fontSize(14)
            .fontColor(this.isEmergency() ? '#FFFFFF' : '#0F1B2D')
            .width('100%')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        this.statusPill()
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Row({ space: 6 }) {
        Text(`${this.glucose.toFixed(1)}`)
          .fontSize(52)
          .fontWeight(FontWeight.Bolder)
          .fontColor(this.isEmergency() ? '#FFFFFF' : '#0F1B2D')
        Text('mmol/L')
          .fontSize(15)
          .fontColor(this.isEmergency() ? '#FFFFFF' : '#5B6B82')
          .margin({ bottom: 8 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Bottom)

      Text(heroSentence(this.riskIndex))
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isEmergency() ? '#FFFFFF' : '#0F1B2D')
        .width('100%')

      Text(`${trendWord(this.riskIndex)} • Updated ${this.currentTime}`)
        .fontSize(14)
        .fontColor(this.isEmergency() ? '#FFFFFF' : '#5B6B82')
        .width('100%')
        .opacity(this.isEmergency() ? 0.92 : 1.0)

      Row({ space: 8 }) {
        this.glassChip('HEART', `${this.heartRate} bpm`, heartSub(this.riskIndex), '#2E86DE')
        this.glassChip('WATCH', `${this.watchBattery}%`, 'connected • guarding', '#34C759')
      }
      .width('100%')

      if (this.isEmergency()) {
        Row({ space: 10 }) {
          Button('Call now')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .height(52)
            .layoutWeight(1)
            .backgroundColor('#FFFFFF')
            .fontColor('#FF3B30')
            .borderRadius(16)
            .onClick(() => {
              this.onCallNow();
            })
          Button("I'm with them")
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .height(52)
            .layoutWeight(1)
            .backgroundColor('#FFFFFF')
            .fontColor('#FF3B30')
            .borderRadius(16)
            .onClick(() => {
              this.onMarkWithThem();
            })
        }
        .width('100%')
        .opacity(this.bannerFlash ? 1.0 : 0.82)
      } else if (this.statusKind() === 'Warning') {
        Button('Call now')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .height(52)
          .width('100%')
          .backgroundColor('#2E86DE')
          .fontColor('#FFFFFF')
          .borderRadius(16)
          .onClick(() => {
            this.onCallNow();
          })
      }
    }
    .width('100%')
    .padding(18)
    .backgroundColor(this.isEmergency() ? '#FF3B30' : '#DFE9FA')
    .borderRadius(22)
    .shadow({ radius: 16, color: 'rgba(15,27,45,0.10)', offsetX: 0, offsetY: 6 })
  }
}

@Preview({ title: 'Phone Hero Card Normal' })
@Component
struct PhoneHeroCardNormalPreview {
  build() {
    Column() {
      PhoneHeroCard({
        glucose: 5.5,
        riskIndex: 12,
        currentTime: '23:45:12',
        heartRate: 62,
        watchBattery: 86
      })
    }
    .padding(16)
    .backgroundColor('#EEF2F7')
  }
}

@Preview({ title: 'Phone Hero Card Emergency' })
@Component
struct PhoneHeroCardEmergencyPreview {
  build() {
    Column() {
      PhoneHeroCard({
        glucose: 3.1,
        riskIndex: 85,
        currentTime: '03:15:00',
        heartRate: 110,
        watchBattery: 80,
        bannerFlash: true
      })
    }
    .padding(16)
    .backgroundColor('#EEF2F7')
  }
}
