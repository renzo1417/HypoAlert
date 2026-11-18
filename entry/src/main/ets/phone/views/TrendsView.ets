/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Screen 2: Overnight Symptom Risk History & Finger-Prick Verification Trail.
 */

import { VitalsData, VitalsEngine } from '../../models/VitalsModel';
import { NightHistoryRecord, ActionTakenEntry, HistoryRepository } from '../../models/HistoryModel';
import { getOvernightBarColor } from '../utils/PhoneRiskUtils';
import { PhoneTheme } from '../utils/PhoneTheme';

@Component
export struct TrendsView {
  @Prop vitals: VitalsData = VitalsEngine.createInitialVitals();
  @Prop currentTime: string = '00:00:00';
  @Prop historyVersion: number = 0;

  @State selectedIndex: number = 0;
  @State historyRecords: NightHistoryRecord[] = [];

  aboutToAppear(): void {
    this.historyRecords = HistoryRepository.getHistory();
  }

  private getSelectedRecord(): NightHistoryRecord {
    const records: NightHistoryRecord[] = HistoryRepository.getHistory();
    if (this.selectedIndex >= 0 && this.selectedIndex < records.length) {
      const rec: NightHistoryRecord = records[this.selectedIndex];
      if (this.selectedIndex === 0) {
        rec.peakRiskPct = Math.max(rec.peakRiskPct, this.vitals.symptomRiskPct);
        rec.episodesCount = Math.max(rec.episodesCount, this.vitals.alertsTonight);
        if (this.vitals.statusTier === 'ALERT') {
          rec.status = 'CRITICAL';
        } else if (this.vitals.statusTier === 'WATCH' && rec.status === 'NORMAL') {
          rec.status = 'WARNING';
        }
      }
      return rec;
    }
    return records[0];
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

  private getPrickDisplay(rec: NightHistoryRecord): string {
    if (rec.fingerPrickMgDl !== undefined) {
      return `${rec.fingerPrickMgDl} mg/dL`;
    }
    return rec.fingerPrickVerdict;
  }

  build() {
    Scroll() {
      Column({ space: 12 }) {
        Column({ space: 2 }) {
          Row() {
            Text('Overnight History')
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
          Text(`Peak symptom risk ${this.getSelectedRecord().peakRiskPct}% • Max 2 alerts/night`)
            .fontSize(PhoneTheme.FONT_CAPTION)
            .fontColor(PhoneTheme.TEXT_MUTED)
            .width('100%')
        }
        .width('100%')
        .padding({ left: 2, right: 2, top: 2 })

        // Night Selector Carousel
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

        // Selected Night Summary Card
        Column({ space: 12 }) {
          Row() {
            Text(this.getSelectedRecord().dateLabel)
              .fontSize(PhoneTheme.FONT_SECTION)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.TEXT_PRIMARY)
              .layoutWeight(1)

            Text(this.getSelectedRecord().status === 'CRITICAL' ? 'ALERT FIRED' : (this.getSelectedRecord().status === 'WARNING' ? 'SPIKE IGNORED' : 'CALM'))
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

          Row() {
            Column({ space: 2 }) {
              Text('PEAK RISK')
                .fontSize(PhoneTheme.FONT_MICRO)
                .fontWeight(FontWeight.Bold)
                .fontColor(PhoneTheme.TEXT_TERTIARY)

              Text(`${this.getSelectedRecord().peakRiskPct}%`)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.getSelectedRecord().peakRiskPct >= 70 ? PhoneTheme.STATE_CRIT : PhoneTheme.TEXT_PRIMARY)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)

            Divider().vertical(true).height(32).color(PhoneTheme.BORDER_LIGHT)

            Column({ space: 2 }) {
              Text('ALERTS')
                .fontSize(PhoneTheme.FONT_MICRO)
                .fontWeight(FontWeight.Bold)
                .fontColor(PhoneTheme.TEXT_TERTIARY)

              Text(`${this.getSelectedRecord().episodesCount}/2`)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor(PhoneTheme.TEXT_PRIMARY)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)

            Divider().vertical(true).height(32).color(PhoneTheme.BORDER_LIGHT)

            Column({ space: 2 }) {
              Text('FINGER-PRICK')
                .fontSize(PhoneTheme.FONT_MICRO)
                .fontWeight(FontWeight.Bold)
                .fontColor(PhoneTheme.TEXT_TERTIARY)

              Text(this.getPrickDisplay(this.getSelectedRecord()))
                .fontSize(13)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.getSelectedRecord().fingerPrickVerdict === 'Confirmed Low' ? PhoneTheme.STATE_CRIT : PhoneTheme.TEXT_PRIMARY)
                .maxLines(1)
                .margin({ top: 4 })
            }
            .layoutWeight(1.2)
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

        // Overnight Symptom Risk Bars (12am - 8am)
        Column({ space: 10 }) {
          Row() {
            Text('Symptom risk 12am–8am')
              .fontSize(PhoneTheme.FONT_SECTION)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.TEXT_PRIMARY)
            Blank()
            Text('Alert line 70%')
              .fontSize(PhoneTheme.FONT_MICRO)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.TEXT_MUTED)
              .backgroundColor(PhoneTheme.BG_SUBTLE)
              .borderRadius(PhoneTheme.PILL_RADIUS)
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Row({ space: 10 }) {
            ForEach(this.getSelectedRecord().hourlyRiskPct, (val: number, idx: number) => {
              Column({ space: 4 }) {
                Text(`${val}%`)
                  .fontSize(PhoneTheme.FONT_CAPTION)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(val >= 70 ? PhoneTheme.STATE_CRIT : PhoneTheme.TEXT_PRIMARY)
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
                    .height(Math.max(8, Math.round((val / 100) * 96)))
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

        // Action Trail
        Column({ space: 10 }) {
          Row() {
            Text('Events & check-ins')
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

          Column({ space: 8 }) {
            ForEach(this.getSelectedRecord().actionsTaken, (action: ActionTakenEntry) => {
              Row({ space: 10 }) {
                Circle({ width: 6, height: 6 })
                  .fill(action.type === 'sms' || action.type === 'call' ? PhoneTheme.STATE_CRIT : (action.type === 'prick' ? PhoneTheme.BRAND_ACCENT : PhoneTheme.STATE_OK))
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
