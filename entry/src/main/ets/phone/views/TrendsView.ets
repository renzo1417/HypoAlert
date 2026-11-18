/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Screen 2: Overnight Trajectory & Sleep Stability.
 * Clinical-grade nocturnal progression, 3.9 mmol/L danger threshold, and intervention trail.
 */

import { NightHistoryRecord, ActionTakenEntry, HistoryRepository } from '../../models/HistoryModel';
import { getOvernightBarColor } from '../utils/PhoneRiskUtils';
import { PhoneTheme } from '../utils/PhoneTheme';

@Component
export struct TrendsView {
  @Prop glucose: number = 5.5;
  @Prop tremorPSD: number = 0.12;
  @Prop riskIndex: number = 12;
  @Prop heartRate: number = 62;
  @Prop currentTime: string = '00:00:00';

  @State selectedIndex: number = 0;
  @State historyRecords: NightHistoryRecord[] = [];

  aboutToAppear(): void {
    this.historyRecords = HistoryRepository.getHistory();
    if (this.riskIndex > 70 && this.glucose < 3.9) {
      this.historyRecords[0].status = 'CRITICAL';
      this.historyRecords[0].lowestGlucose = this.glucose;
      this.historyRecords[0].peakRiskIndex = this.riskIndex;
      this.historyRecords[0].actionsSummary = 'Haptics Active • Emergency SMS Dispatched';
      this.historyRecords[0].hourlyPoints = [5.6, 4.6, this.glucose, 4.0, 4.8];
    }
  }

  private getSelectedRecord(): NightHistoryRecord {
    if (this.selectedIndex >= 0 && this.selectedIndex < this.historyRecords.length) {
      const rec = this.historyRecords[this.selectedIndex];
      if (this.selectedIndex === 0) {
        rec.lowestGlucose = Math.min(rec.lowestGlucose, this.glucose);
        rec.peakRiskIndex = Math.max(rec.peakRiskIndex, this.riskIndex);
        if (this.glucose < 3.9) {
          rec.status = 'CRITICAL';
        } else if (this.glucose < 4.4) {
          rec.status = 'WARNING';
        }
      }
      return rec;
    }
    return this.historyRecords[0];
  }

  private getStatusColor(status: string): string {
    if (status === 'CRITICAL') {
      return PhoneTheme.STATE_CRIT;
    }
    if (status === 'WARNING') {
      return PhoneTheme.STATE_WARN;
    }
    return PhoneTheme.STATE_OK;
  }

  private getStatusBg(status: string): string {
    if (status === 'CRITICAL') {
      return PhoneTheme.STATE_CRIT_BG;
    }
    if (status === 'WARNING') {
      return PhoneTheme.STATE_WARN_BG;
    }
    return PhoneTheme.STATE_OK_BG;
  }

  private getStatusText(status: string): string {
    if (status === 'CRITICAL') {
      return PhoneTheme.STATE_CRIT_TEXT;
    }
    if (status === 'WARNING') {
      return PhoneTheme.STATE_WARN_TEXT;
    }
    return PhoneTheme.STATE_OK_TEXT;
  }

  build() {
    Scroll() {
      Column({ space: 12 }) {
        // Screen header with tonight summary
        Column({ space: 2 }) {
          Row() {
            Text('Overnight')
              .fontSize(PhoneTheme.FONT_TITLE)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.TEXT_PRIMARY)
              .layoutWeight(1)

            Text('12am–8am')
              .fontSize(PhoneTheme.FONT_CAPTION)
              .fontColor(PhoneTheme.TEXT_MUTED)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          Text(`Low ${this.getSelectedRecord().lowestGlucose.toFixed(1)} • Target ≥3.9 mmol/L`)
            .fontSize(PhoneTheme.FONT_CAPTION)
            .fontColor(PhoneTheme.TEXT_MUTED)
            .width('100%')
        }
        .width('100%')
        .padding({ left: 2, right: 2, top: 2 })

        // Date Selector Carousel (Clean pill chips)
        Scroll() {
          Row({ space: 6 }) {
            ForEach(this.historyRecords, (rec: NightHistoryRecord, idx: number) => {
              Button() {
                Row({ space: 5 }) {
                  Circle({ width: 5, height: 5 })
                    .fill(this.getStatusColor(rec.status))

                  Text(rec.dateShort)
                    .fontSize(PhoneTheme.FONT_BODY)
                    .fontWeight(this.selectedIndex === idx ? FontWeight.Bold : FontWeight.Medium)
                    .fontColor(this.selectedIndex === idx ? PhoneTheme.TEXT_ON_DARK : PhoneTheme.TEXT_SECONDARY)
                }
                .alignItems(VerticalAlign.Center)
              }
              .height(30)
              .padding({ left: 10, right: 10 })
              .backgroundColor(this.selectedIndex === idx ? PhoneTheme.BRAND_PRIMARY : PhoneTheme.BG_CARD)
              .borderRadius(PhoneTheme.PILL_RADIUS)
              .borderWidth(1)
              .borderColor(this.selectedIndex === idx ? PhoneTheme.BRAND_PRIMARY : PhoneTheme.BORDER_SUBTLE)
              .onClick(() => {
                this.selectedIndex = idx;
              })
            })
          }
          .padding({ left: 2, right: 2, top: 1, bottom: 1 })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')

        // Selected night summary (two numbers only)
        Column({ space: 12 }) {
          Row() {
            Text(this.getSelectedRecord().dateLabel)
              .fontSize(PhoneTheme.FONT_SECTION)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.TEXT_PRIMARY)
              .layoutWeight(1)

            Text(this.getSelectedRecord().status === 'CRITICAL' ? 'URGENT' : (this.getSelectedRecord().status === 'WARNING' ? 'WATCH' : 'STEADY'))
              .fontSize(PhoneTheme.FONT_MICRO)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.getStatusText(this.getSelectedRecord().status))
              .backgroundColor(this.getStatusBg(this.getSelectedRecord().status))
              .borderRadius(PhoneTheme.PILL_RADIUS)
              .padding({ left: 7, right: 7, top: 2, bottom: 2 })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Divider().color(PhoneTheme.BORDER_LIGHT).strokeWidth(1)

          // Low + in-range strip
          Row() {
            // Lowest
            Column({ space: 2 }) {
              Text('LOW')
                .fontSize(PhoneTheme.FONT_MICRO)
                .fontWeight(FontWeight.Bold)
                .fontColor(PhoneTheme.TEXT_TERTIARY)

              Row({ space: 2 }) {
                Text(`${this.getSelectedRecord().lowestGlucose.toFixed(1)}`)
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.getSelectedRecord().lowestGlucose < 3.9 ? PhoneTheme.STATE_CRIT : PhoneTheme.TEXT_PRIMARY)
                Text('mmol/L')
                  .fontSize(PhoneTheme.FONT_MICRO)
                  .fontColor(PhoneTheme.TEXT_MUTED)
                  .margin({ bottom: 2 })
              }
              .alignItems(VerticalAlign.Bottom)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)

            Divider().vertical(true).height(32).color(PhoneTheme.BORDER_LIGHT)

            // In range
            Column({ space: 2 }) {
              Text('IN RANGE')
                .fontSize(PhoneTheme.FONT_MICRO)
                .fontWeight(FontWeight.Bold)
                .fontColor(PhoneTheme.TEXT_TERTIARY)

              Text(this.getSelectedRecord().lowestGlucose >= 4.4 ? '100%' : (this.getSelectedRecord().lowestGlucose >= 3.9 ? '88%' : '76%'))
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor(PhoneTheme.TEXT_PRIMARY)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)
          }
          .width('100%')
        }
        .width('100%')
        .padding(PhoneTheme.CARD_PADDING)
        .backgroundColor(PhoneTheme.BG_CARD)
        .borderWidth(1)
        .borderColor(PhoneTheme.BORDER_SUBTLE)
        .borderRadius(PhoneTheme.CARD_RADIUS)
        .shadow({ radius: 8, color: 'rgba(15, 23, 42, 0.04)', offsetY: 2 })

        // Overnight bars (12am – 8am)
        Column({ space: 10 }) {
          Row() {
            Text('Glucose 12am–8am')
              .fontSize(PhoneTheme.FONT_SECTION)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.TEXT_PRIMARY)
            Blank()
            Text('Target ≥3.9')
              .fontSize(PhoneTheme.FONT_MICRO)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.TEXT_MUTED)
              .backgroundColor(PhoneTheme.BG_SUBTLE)
              .borderRadius(PhoneTheme.PILL_RADIUS)
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          // 5-bar visualization, all values shown
          Row({ space: 10 }) {
            ForEach(this.getSelectedRecord().hourlyPoints, (val: number, idx: number) => {
              Column({ space: 4 }) {
                Text(`${val.toFixed(1)}`)
                  .fontSize(PhoneTheme.FONT_CAPTION)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(val < 3.9 ? PhoneTheme.STATE_CRIT : PhoneTheme.TEXT_PRIMARY)
                  .height(14)
                  .maxLines(1)

                Stack({ alignContent: Alignment.Bottom }) {
                  Row()
                    .width('100%')
                    .height(96)
                    .backgroundColor(PhoneTheme.BG_SUBTLE)
                    .borderRadius(6)
                  Row()
                    .width('100%')
                    .height(Math.round((val / 6.5) * 96))
                    .backgroundColor(getOvernightBarColor(val))
                    .borderRadius(6)
                }
                .width('100%')
                .height(96)

                Text(idx === 0 ? '12am' : (idx === 1 ? '2am' : (idx === 2 ? '4am' : (idx === 3 ? '6am' : '8am'))))
                  .fontSize(PhoneTheme.FONT_MICRO)
                  .fontColor(PhoneTheme.TEXT_MUTED)
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Center)
            })
          }
          .width('100%')
          .alignItems(VerticalAlign.Bottom)
        }
        .width('100%')
        .padding(PhoneTheme.CARD_PADDING)
        .backgroundColor(PhoneTheme.BG_CARD)
        .borderWidth(1)
        .borderColor(PhoneTheme.BORDER_SUBTLE)
        .borderRadius(PhoneTheme.CARD_RADIUS)
        .shadow({ radius: 8, color: 'rgba(15, 23, 42, 0.04)', offsetY: 2 })

        // Events tonight
        Column({ space: 10 }) {
          Row() {
            Text('Events tonight')
              .fontSize(PhoneTheme.FONT_SECTION)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.TEXT_PRIMARY)

            Blank()

            Text(this.getSelectedRecord().actionsTaken.length === 0 ? 'None' : `${this.getSelectedRecord().actionsTaken.length}`)
              .fontSize(PhoneTheme.FONT_MICRO)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.getSelectedRecord().actionsTaken.length > 0 ? PhoneTheme.STATE_WARN_TEXT : PhoneTheme.STATE_OK_TEXT)
              .backgroundColor(this.getSelectedRecord().actionsTaken.length > 0 ? PhoneTheme.STATE_WARN_BG : PhoneTheme.STATE_OK_BG)
              .borderRadius(PhoneTheme.PILL_RADIUS)
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          }
          .width('100%')

          if (this.getSelectedRecord().actionsTaken.length === 0) {
            Text('Quiet night — no alerts needed.')
              .fontSize(PhoneTheme.FONT_BODY)
              .fontColor(PhoneTheme.TEXT_MUTED)
              .padding(8)
          } else {
            Column({ space: 8 }) {
              ForEach(this.getSelectedRecord().actionsTaken, (action: ActionTakenEntry) => {
                Row({ space: 10 }) {
                  Circle({ width: 6, height: 6 })
                    .fill(action.type === 'sms' || action.type === 'call' ? PhoneTheme.STATE_CRIT : PhoneTheme.STATE_WARN)
                    .margin({ top: 5 })

                  Column({ space: 2 }) {
                    Row() {
                      Text(action.title)
                        .fontSize(PhoneTheme.FONT_BODY)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(PhoneTheme.TEXT_PRIMARY)
                        .layoutWeight(1)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })

                      Text(action.time)
                        .fontSize(PhoneTheme.FONT_MICRO)
                        .fontColor(PhoneTheme.TEXT_TERTIARY)
                    }
                    .width('100%')

                    Text(action.detail)
                      .fontSize(PhoneTheme.FONT_CAPTION)
                      .fontColor(PhoneTheme.TEXT_MUTED)
                      .width('100%')
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)
                }
                .width('100%')
                .padding(10)
                .backgroundColor(PhoneTheme.BG_PAGE)
                .borderRadius(PhoneTheme.TILE_RADIUS)
                .alignItems(VerticalAlign.Top)
              })
            }
            .width('100%')
          }
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
      .padding({ left: 16, right: 16, top: 8, bottom: 88 })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .scrollable(ScrollDirection.Vertical)
  }
}
