/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Screen 2: Overnight trends, glucose history, and sleep stability.
 */

import { OvernightPoint } from '../models/PhoneTypes';
import {
  computeOvernightPoints,
  getOvernightBarColor,
  computeOvernightEvents,
  restlessShort
} from '../utils/PhoneRiskUtils';

@Component
export struct TrendsView {
  @Prop glucose: number = 5.5;
  @Prop tremorPSD: number = 0.12;
  @Prop riskIndex: number = 12;
  @Prop heartRate: number = 62;
  @Prop currentTime: string = '00:00:00';

  private getLowestPoint(): number {
    const pts: OvernightPoint[] = computeOvernightPoints(this.glucose);
    let minVal: number = pts[0].value;
    for (let i: number = 1; i < pts.length; i++) {
      if (pts[i].value < minVal) {
        minVal = pts[i].value;
      }
    }
    return minVal;
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        // Top Overview Banner
        Column({ space: 6 }) {
          Row() {
            Column({ space: 2 }) {
              Text('OVERNIGHT REPORT')
                .fontSize(12)
                .fontWeight(FontWeight.Bold)
                .fontColor('#2E86DE')
                .letterSpacing(1)
              Text('Glucose & Sleep Trends')
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor('#0F1B2D')
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Text('12am – 8am')
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor('#2E86DE')
              .backgroundColor('#E7F0FE')
              .borderRadius(12)
              .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Text('Track autonomic patterns and glycemic stability across the 8-hour sleep cycle.')
            .fontSize(13)
            .fontColor('#5B6B82')
            .width('100%')
        }
        .width('100%')
        .padding(18)
        .backgroundColor('#FFFFFF')
        .borderRadius(22)
        .border({ width: 1, color: '#E3E9F2', radius: 22 })
        .shadow({ radius: 12, color: 'rgba(15,27,45,0.06)', offsetX: 0, offsetY: 4 })

        // 3-Column Key Metric Summary
        Row({ space: 8 }) {
          // Lowest Glucose
          Column({ space: 3 }) {
            Text('LOWEST')
              .fontSize(10)
              .fontWeight(FontWeight.Bold)
              .fontColor('#8A94A6')
            Row({ space: 2 }) {
              Text(`${this.getLowestPoint().toFixed(1)}`)
                .fontSize(20)
                .fontWeight(FontWeight.Bolder)
                .fontColor(this.getLowestPoint() < 3.9 ? '#FF3B30' : (this.getLowestPoint() < 4.4 ? '#FF9500' : '#0F1B2D'))
              Text('mmol/L')
                .fontSize(11)
                .fontColor('#8A94A6')
                .margin({ bottom: 2 })
            }
            .alignItems(VerticalAlign.Bottom)
            Text(this.getLowestPoint() < 3.9 ? 'Hypo dip' : 'Target >3.9')
              .fontSize(11)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.getLowestPoint() < 3.9 ? '#FF3B30' : '#34C759')
          }
          .layoutWeight(1)
          .padding(12)
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .border({ width: 1, color: '#E3E9F2', radius: 16 })
          .alignItems(HorizontalAlign.Start)

          // Restlessness
          Column({ space: 3 }) {
            Text('RESTLESSNESS')
              .fontSize(10)
              .fontWeight(FontWeight.Bold)
              .fontColor('#8A94A6')
            Text(restlessShort(this.tremorPSD))
              .fontSize(20)
              .fontWeight(FontWeight.Bolder)
              .fontColor('#0F1B2D')
            Text(`PSD ${this.tremorPSD.toFixed(2)}`)
              .fontSize(11)
              .fontColor('#8A94A6')
          }
          .layoutWeight(1)
          .padding(12)
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .border({ width: 1, color: '#E3E9F2', radius: 16 })
          .alignItems(HorizontalAlign.Start)

          // Time in Range
          Column({ space: 3 }) {
            Text('IN RANGE')
              .fontSize(10)
              .fontWeight(FontWeight.Bold)
              .fontColor('#8A94A6')
            Text(this.glucose >= 4.4 ? '96%' : (this.glucose >= 3.9 ? '82%' : '64%'))
              .fontSize(20)
              .fontWeight(FontWeight.Bolder)
              .fontColor('#0F1B2D')
            Text('Target: 3.9–6.5')
              .fontSize(11)
              .fontColor('#34C759')
          }
          .layoutWeight(1)
          .padding(12)
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .border({ width: 1, color: '#E3E9F2', radius: 16 })
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')

        // Overnight Glucose Bar Chart
        Column({ space: 12 }) {
          Row() {
            Column({ space: 2 }) {
              Text('Nocturnal Glucose Curve')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#0F1B2D')
              Text('Values recorded across overnight checkpoints')
                .fontSize(13)
                .fontColor('#8A94A6')
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Row({ space: 8 }) {
              Row({ space: 4 }) {
                Circle({ width: 7, height: 7 }).fill('#2E86DE')
                Text('Steady').fontSize(11).fontColor('#8A94A6')
              }
              Row({ space: 4 }) {
                Circle({ width: 7, height: 7 }).fill('#FF9500')
                Text('Watch').fontSize(11).fontColor('#8A94A6')
              }
              Row({ space: 4 }) {
                Circle({ width: 7, height: 7 }).fill('#FF3B30')
                Text('Hypo').fontSize(11).fontColor('#8A94A6')
              }
            }
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          // 5-bar visualization
          Row({ space: 8 }) {
            ForEach(computeOvernightPoints(this.glucose), (pt: OvernightPoint) => {
              Column({ space: 4 }) {
                Text(`${pt.value.toFixed(1)}`)
                  .fontSize(11)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#0F1B2D')

                Stack({ alignContent: Alignment.Bottom }) {
                  Row()
                    .width('100%')
                    .height(96)
                    .backgroundColor('#EDF2F8')
                    .borderRadius(8)
                  Row()
                    .width('100%')
                    .height(Math.round((pt.value / 6.5) * 96))
                    .backgroundColor(getOvernightBarColor(pt.value))
                    .borderRadius(8)
                }
                .width('100%')
                .height(96)

                Text(pt.hour)
                  .fontSize(12)
                  .fontColor('#8A94A6')
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Center)
            }, (pt: OvernightPoint) => pt.hour)
          }
          .width('100%')
          .alignItems(VerticalAlign.Bottom)

          // Safety guideline reference strip
          Row({ space: 6 }) {
            Circle({ width: 6, height: 6 })
              .fill('#FF9500')
            Text('Safety threshold: 3.9 mmol/L — automatic alarm & SMN text trigger')
              .fontSize(12)
              .fontColor('#5B6B82')
              .layoutWeight(1)
          }
          .width('100%')
          .padding({ left: 10, right: 10, top: 8, bottom: 8 })
          .backgroundColor('#F4F7FB')
          .borderRadius(10)
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(22)
        .border({ width: 1, color: '#E3E9F2', radius: 22 })
        .shadow({ radius: 12, color: 'rgba(15,27,45,0.06)', offsetX: 0, offsetY: 4 })

        // Chronological Sleep Events Timeline
        Column({ space: 10 }) {
          Row() {
            Text('Sleep Events & Checkpoints')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#0F1B2D')
            Blank()
            Text('Automated Log')
              .fontSize(12)
              .fontColor('#8A94A6')
          }
          .width('100%')

          Column({ space: 8 }) {
            ForEach(computeOvernightEvents(this.tremorPSD, this.riskIndex), (msg: string) => {
              Row({ space: 10 }) {
                Circle({ width: 8, height: 8 })
                  .fill('#2E86DE')
                  .margin({ top: 6 })
                Text(msg)
                  .fontSize(14)
                  .fontColor('#0F1B2D')
                  .layoutWeight(1)
              }
              .width('100%')
              .alignItems(VerticalAlign.Top)
            }, (msg: string) => msg)

            Row({ space: 10 }) {
              Circle({ width: 8, height: 8 })
                .fill('#34C759')
                .margin({ top: 6 })
              Text(`Sensor battery sustained at ${Math.min(99, Math.round(this.glucose * 15 + 10))}% — guarding active`)
                .fontSize(14)
                .fontColor('#0F1B2D')
                .layoutWeight(1)
            }
            .width('100%')
            .alignItems(VerticalAlign.Top)
          }
          .width('100%')
          .padding(14)
          .backgroundColor('#F4F7FB')
          .borderRadius(14)
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(22)
        .border({ width: 1, color: '#E3E9F2', radius: 22 })
        .shadow({ radius: 12, color: 'rgba(15,27,45,0.06)', offsetX: 0, offsetY: 4 })

        // Clinical Educational Insight Card
        Column({ space: 6 }) {
          Row({ space: 6 }) {
            Circle({ width: 6, height: 6 })
              .fill('#F6B8C1')
            Text('Clinical Note')
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor('#8A94A6')
          }
          .width('100%')

          Text('Nocturnal hypoglycemia often occurs without waking the sleeper. By combining photoplethysmogram (PPG) autonomic heart variability and micro-tremor power spectral density, HypoAlert detects downward trends before neuroglycopenia escalates.')
            .fontSize(13)
            .fontColor('#5B6B82')
            .lineHeight(19)
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(20)
        .border({ width: 1, color: '#E3E9F2', radius: 20 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 20 })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .scrollable(ScrollDirection.Vertical)
  }
}

@Preview({ title: 'Trends View' })
@Component
struct TrendsViewPreview {
  build() {
    Column() {
      TrendsView({
        glucose: 5.2,
        tremorPSD: 0.15,
        riskIndex: 15,
        heartRate: 62,
        currentTime: '23:45:12'
      })
    }
    .backgroundColor('#EEF2F7')
  }
}
