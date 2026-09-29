/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Screen 2: Overnight Trajectory & Sleep Stability.
 * Icon hub with inline expandable detail sections.
 */

import { NightHistoryRecord, ActionTakenEntry, HistoryRepository } from '../../models/HistoryModel';
import { getOvernightBarColor } from '../utils/PhoneRiskUtils';
import { MetricIconButton } from '../components/MetricIconButton';
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
  @State selectedSection: string = '';

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

  private openSection(id: string): void {
    animateTo({ duration: 220, curve: Curve.EaseInOut }, () => {
      this.selectedSection = id;
    });
  }

  private closeSection(): void {
    animateTo({ duration: 220, curve: Curve.EaseInOut }, () => {
      this.selectedSection = '';
    });
  }

  @Builder
  backRow(title: string) {
    Row({ space: 10 }) {
      Button('‹ Back')
        .fontSize(PhoneTheme.FONT_BODY)
        .fontWeight(FontWeight.Bold)
        .height(32)
        .padding({ left: 12, right: 12 })
        .backgroundColor(PhoneTheme.BG_MUTED)
        .fontColor(PhoneTheme.TEXT_PRIMARY)
        .borderRadius(PhoneTheme.TILE_RADIUS)
        .onClick(() => {
          this.closeSection();
        })
      Text(title)
        .fontSize(PhoneTheme.FONT_SECTION)
        .fontWeight(FontWeight.Bold)
        .fontColor(PhoneTheme.TEXT_PRIMARY)
        .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  summarySection() {
    Column({ space: 12 }) {
      Row() {
        Column({ space: 1 }) {
          Text(this.getSelectedRecord().dateLabel)
            .fontSize(PhoneTheme.FONT_SECTION)
            .fontWeight(FontWeight.Bold)
            .fontColor(PhoneTheme.TEXT_PRIMARY)
          Text(`${this.getSelectedRecord().durationHours}h continuous monitoring`)
            .fontSize(PhoneTheme.FONT_CAPTION)
            .fontColor(PhoneTheme.TEXT_MUTED)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text(this.getSelectedRecord().status === 'CRITICAL' ? 'CRITICAL' : (this.getSelectedRecord().status === 'WARNING' ? 'WARNING' : 'ALL CLEAR'))
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
          Text('MIN GLUCOSE')
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

          Text(this.getSelectedRecord().lowestGlucose < 3.9 ? 'Danger drop' : (this.getSelectedRecord().lowestGlucose < 4.4 ? 'Pre-drop dip' : 'Safe range'))
            .fontSize(PhoneTheme.FONT_CAPTION)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.getSelectedRecord().lowestGlucose < 3.9 ? PhoneTheme.STATE_CRIT : (this.getSelectedRecord().lowestGlucose < 4.4 ? PhoneTheme.STATE_WARN_TEXT : PhoneTheme.STATE_OK_TEXT))
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        Divider().vertical(true).height(36).color(PhoneTheme.BORDER_LIGHT)

        Column({ space: 2 }) {
          Text('TIME IN SAFE RANGE')
            .fontSize(PhoneTheme.FONT_MICRO)
            .fontWeight(FontWeight.Bold)
            .fontColor(PhoneTheme.TEXT_TERTIARY)

          Text(this.getSelectedRecord().lowestGlucose >= 4.4 ? '100%' : (this.getSelectedRecord().lowestGlucose >= 3.9 ? '88%' : '76%'))
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(PhoneTheme.TEXT_PRIMARY)

          Text('Threshold ≥ 3.9')
            .fontSize(PhoneTheme.FONT_CAPTION)
            .fontWeight(FontWeight.Medium)
            .fontColor(PhoneTheme.STATE_OK_TEXT)
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
  }

  @Builder
  chartSection() {
    Column({ space: 10 }) {
      Row() {
        Text('Glycemic Progression (12am – 8am)')
          .fontSize(PhoneTheme.FONT_SECTION)
          .fontWeight(FontWeight.Bold)
          .fontColor(PhoneTheme.TEXT_PRIMARY)

        Blank()

        Row({ space: 6 }) {
          Row({ space: 3 }) {
            Circle({ width: 5, height: 5 }).fill(PhoneTheme.BRAND_ACCENT)
            Text('Safe').fontSize(PhoneTheme.FONT_MICRO).fontColor(PhoneTheme.TEXT_MUTED)
          }
          Row({ space: 3 }) {
            Circle({ width: 5, height: 5 }).fill(PhoneTheme.STATE_WARN)
            Text('Dip').fontSize(PhoneTheme.FONT_MICRO).fontColor(PhoneTheme.TEXT_MUTED)
          }
          Row({ space: 3 }) {
            Circle({ width: 5, height: 5 }).fill(PhoneTheme.STATE_CRIT)
            Text('Hypo').fontSize(PhoneTheme.FONT_MICRO).fontColor(PhoneTheme.TEXT_MUTED)
          }
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Row({ space: 10 }) {
        ForEach(this.getSelectedRecord().hourlyPoints, (val: number, idx: number) => {
          Column({ space: 4 }) {
            Text(`${val.toFixed(1)}`)
              .fontSize(PhoneTheme.FONT_CAPTION)
              .fontWeight(FontWeight.Bold)
              .fontColor(val < 3.9 ? PhoneTheme.STATE_CRIT : PhoneTheme.TEXT_PRIMARY)

            Stack({ alignContent: Alignment.Bottom }) {
              Row()
                .width('100%')
                .height(80)
                .backgroundColor(PhoneTheme.BG_MUTED)
                .borderRadius(6)
              Row()
                .width('100%')
                .height(Math.round((val / 6.5) * 80))
                .backgroundColor(getOvernightBarColor(val))
                .borderRadius(6)
            }
            .width('100%')
            .height(80)

            Text(idx === 0 ? '12am' : (idx === 1 ? '2am' : (idx === 2 ? '4am' : (idx === 3 ? '6am' : '8am'))))
              .fontSize(PhoneTheme.FONT_MICRO)
              .fontWeight(FontWeight.Medium)
              .fontColor(PhoneTheme.TEXT_MUTED)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
        })
      }
      .width('100%')
      .alignItems(VerticalAlign.Bottom)

      Row({ space: 5 }) {
        Circle({ width: 4, height: 4 }).fill(PhoneTheme.STATE_CRIT)
        Text('Red threshold: < 3.9 mmol/L activates wrist haptics and bedside alarm')
          .fontSize(PhoneTheme.FONT_MICRO)
          .fontColor(PhoneTheme.TEXT_MUTED)
          .layoutWeight(1)
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

  @Builder
  trailSection() {
    Column({ space: 8 }) {
      if (this.getSelectedRecord().actionsTaken.length === 0) {
        Text('No emergency interventions required tonight. Normal sleep.')
          .fontSize(PhoneTheme.FONT_BODY)
          .fontColor(PhoneTheme.TEXT_MUTED)
          .padding(8)
          .width('100%')
      } else {
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

                Text(action.time)
                  .fontSize(PhoneTheme.FONT_MICRO)
                  .fontColor(PhoneTheme.TEXT_TERTIARY)
              }
              .width('100%')

              Text(action.detail)
                .fontSize(PhoneTheme.FONT_CAPTION)
                .fontColor(PhoneTheme.TEXT_MUTED)
                .width('100%')

              if (action.target) {
                Text(`Target: ${action.target}`)
                  .fontSize(PhoneTheme.FONT_MICRO)
                  .fontColor(PhoneTheme.TEXT_SECONDARY)
              }
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
    }
    .width('100%')
    .padding(PhoneTheme.CARD_PADDING)
    .backgroundColor(PhoneTheme.BG_CARD)
    .borderWidth(1)
    .borderColor(PhoneTheme.BORDER_SUBTLE)
    .borderRadius(PhoneTheme.CARD_RADIUS)
    .shadow({ radius: 8, color: 'rgba(15, 23, 42, 0.04)', offsetY: 2 })
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        // Date Selector Carousel — pinned, always visible
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

        // Icon hub — tap opens full detail
        if (this.selectedSection.length === 0) {
          Column({ space: 10 }) {
          Row() {
            Text('Night Details')
              .fontSize(PhoneTheme.FONT_SECTION)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.TEXT_PRIMARY)
            Blank()
            Text('Tap icon for detail')
              .fontSize(PhoneTheme.FONT_CAPTION)
              .fontColor(PhoneTheme.TEXT_TERTIARY)
          }
          .width('100%')
          .padding({ left: 2, right: 2 })

          Grid() {
            GridItem() {
              MetricIconButton({
                title: 'Night Summary',
                value: `${this.getSelectedRecord().lowestGlucose.toFixed(1)} mmol/L`,
                hint: this.getSelectedRecord().status,
                statusColor: this.getStatusColor(this.getSelectedRecord().status),
                  glyph: '◈',
                  onOpen: () => {
                    this.openSection('summary');
                  }
              })
            }
            GridItem() {
              MetricIconButton({
                title: 'Progression',
                value: '12am–8am',
                hint: `${this.getSelectedRecord().hourlyPoints.length} readings`,
                statusColor: PhoneTheme.BRAND_ACCENT,
                  glyph: '▥',
                  onOpen: () => {
                    this.openSection('chart');
                  }
              })
            }
            GridItem() {
              MetricIconButton({
                title: 'Incidents',
                value: `${this.getSelectedRecord().actionsTaken.length} event(s)`,
                hint: this.getSelectedRecord().actionsTaken.length > 0 ? 'Needs review' : 'Quiet night',
                statusColor: this.getSelectedRecord().actionsTaken.length > 0 ? PhoneTheme.STATE_WARN : PhoneTheme.STATE_OK,
                  glyph: '⚠',
                  onOpen: () => {
                    this.openSection('trail');
                  }
              })
            }
          }
            .columnsTemplate('1fr 1fr')
            .columnsGap(10)
            .rowsGap(10)
            .width('100%')
            .height(306)
          }
          .width('100%')
        } else {
          Column({ space: 10 }) {
            this.backRow(this.selectedSection === 'summary' ? 'Night Summary' : (this.selectedSection === 'chart' ? 'Progression Chart' : 'Incident Trail'))
            if (this.selectedSection === 'summary') {
              this.summarySection()
            } else if (this.selectedSection === 'chart') {
              this.chartSection()
            } else {
              this.trailSection()
            }
          }
          .width('100%')
        }
      }
      .width('100%')
      .padding({ left: 18, right: 18, top: 6, bottom: 36 })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .scrollable(ScrollDirection.Vertical)
  }
}
