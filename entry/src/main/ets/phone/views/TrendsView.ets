/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Screen 2: Multi-Night History, Readings & Detailed Actions Taken.
 * Comprehensive nocturnal glycemic progression, vital markers, and clinical dispatch logs.
 */

import { NightHistoryRecord, ActionTakenEntry, HistoryRepository } from '../../models/HistoryModel';
import { getOvernightBarColor } from '../utils/PhoneRiskUtils';

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
    // Synchronize tonight's live session if risk changed
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
      // If tonight is selected, inject live telemetry
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
      return '#EF4444';
    }
    if (status === 'WARNING') {
      return '#F59E0B';
    }
    return '#10B981';
  }

  private getActionIcon(type: string): string {
    if (type === 'haptic') {
      return '📳';
    }
    if (type === 'alarm') {
      return '🔊';
    }
    if (type === 'sms') {
      return '📩';
    }
    if (type === 'call') {
      return '📞';
    }
    return '✅';
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        // Screen Header
        Column({ space: 4 }) {
          Row() {
            Text('Overnight History')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#111827')
            Blank()
            Text('7-Day Archive')
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor('#2563EB')
              .backgroundColor('#EFF6FF')
              .borderRadius(999)
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Text('Nocturnal glucose readings, stability curves & action logs')
            .fontSize(13)
            .fontColor('#64748B')
            .width('100%')
        }
        .width('100%')
        .padding({ left: 4, right: 4 })

        // Multi-Night Date Selector Carousel
        Scroll() {
          Row({ space: 8 }) {
            ForEach(this.historyRecords, (rec: NightHistoryRecord, idx: number) => {
              Button() {
                Row({ space: 6 }) {
                  Circle({ width: 7, height: 7 })
                    .fill(this.getStatusColor(rec.status))

                  Text(rec.dateShort)
                    .fontSize(12)
                    .fontWeight(this.selectedIndex === idx ? FontWeight.Bold : FontWeight.Medium)
                    .fontColor(this.selectedIndex === idx ? '#FFFFFF' : '#334155')

                  Text(`(${rec.dayOfWeek})`)
                    .fontSize(10)
                    .fontColor(this.selectedIndex === idx ? '#E2E8F0' : '#94A3B8')
                }
                .alignItems(VerticalAlign.Center)
              }
              .height(36)
              .padding({ left: 12, right: 12 })
              .backgroundColor(this.selectedIndex === idx ? '#111827' : '#FFFFFF')
              .borderRadius(18)
              .borderWidth(1)
              .borderColor(this.selectedIndex === idx ? '#111827' : '#E2E8F0')
              .shadow(this.selectedIndex === idx ? { radius: 6, color: 'rgba(0,0,0,0.1)', offsetY: 2 } : { radius: 0, color: Color.Transparent })
              .onClick(() => {
                this.selectedIndex = idx;
              })
            })
          }
          .padding({ left: 2, right: 2, top: 2, bottom: 2 })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')

        // Selected Night Overview Card
        Column({ space: 14 }) {
          Row() {
            Column({ space: 2 }) {
              Text(this.getSelectedRecord().dateLabel)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#111827')
              Text(`${this.getSelectedRecord().durationHours}h monitored • ${this.getSelectedRecord().episodesCount} alert episode(s)`)
                .fontSize(12)
                .fontColor('#64748B')
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Text(this.getSelectedRecord().status === 'CRITICAL' ? 'CRITICAL ALERT' : (this.getSelectedRecord().status === 'WARNING' ? 'WARNING' : 'ALL CLEAR'))
              .fontSize(11)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.getStatusColor(this.getSelectedRecord().status))
              .backgroundColor(this.getSelectedRecord().status === 'CRITICAL' ? '#FEE2E2' : (this.getSelectedRecord().status === 'WARNING' ? '#FEF3C7' : '#DCFCE7'))
              .borderRadius(999)
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Divider().color('#F1F5F9').strokeWidth(1)

          // 3-Metric Summary Strip
          Row() {
            // Lowest Glucose
            Column({ space: 3 }) {
              Text('LOWEST GLUCOSE')
                .fontSize(10)
                .fontWeight(FontWeight.Bold)
                .fontColor('#94A3B8')
              Row({ space: 2 }) {
                Text(`${this.getSelectedRecord().lowestGlucose.toFixed(1)}`)
                  .fontSize(22)
                  .fontWeight(FontWeight.Bolder)
                  .fontColor(this.getSelectedRecord().lowestGlucose < 3.9 ? '#EF4444' : (this.getSelectedRecord().lowestGlucose < 4.4 ? '#F59E0B' : '#111827'))
                Text('mmol/L')
                  .fontSize(11)
                  .fontColor('#64748B')
                  .margin({ bottom: 2 })
              }
              .alignItems(VerticalAlign.Bottom)
              Text(this.getSelectedRecord().lowestGlucose < 3.9 ? 'Critical drop' : (this.getSelectedRecord().lowestGlucose < 4.4 ? 'Pre-drop dip' : 'Safe range'))
                .fontSize(11)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.getSelectedRecord().lowestGlucose < 3.9 ? '#EF4444' : (this.getSelectedRecord().lowestGlucose < 4.4 ? '#F59E0B' : '#15803D'))
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)

            Divider()
              .vertical(true)
              .height(40)
              .color('#F1F5F9')

            // Time In Range
            Column({ space: 3 }) {
              Text('TIME IN RANGE')
                .fontSize(10)
                .fontWeight(FontWeight.Bold)
                .fontColor('#94A3B8')
              Text(this.getSelectedRecord().lowestGlucose >= 4.4 ? '100%' : (this.getSelectedRecord().lowestGlucose >= 3.9 ? '88%' : '76%'))
                .fontSize(22)
                .fontWeight(FontWeight.Bolder)
                .fontColor('#111827')
              Text('Target ≥ 3.9')
                .fontSize(11)
                .fontWeight(FontWeight.Medium)
                .fontColor('#15803D')
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)

            Divider()
              .vertical(true)
              .height(40)
              .color('#F1F5F9')

            // Avg Nocturnal Pulse & Temp
            Column({ space: 3 }) {
              Text('NOCTURNAL AVG')
                .fontSize(10)
                .fontWeight(FontWeight.Bold)
                .fontColor('#94A3B8')
              Text(`${this.getSelectedRecord().avgPulse} bpm`)
                .fontSize(18)
                .fontWeight(FontWeight.Bolder)
                .fontColor('#111827')
              Text(`Min ${this.getSelectedRecord().minSkinTemp.toFixed(1)}°C`)
                .fontSize(11)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.getSelectedRecord().minSkinTemp < 35.2 ? '#EF4444' : '#64748B')
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)
          }
          .width('100%')
        }
        .width('100%')
        .padding(18)
        .backgroundColor('#FFFFFF')
        .borderRadius(22)
        .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.04)', offsetY: 2 })

        // Nocturnal Glucose Progression Chart (Selected Night)
        Column({ space: 14 }) {
          Row() {
            Column({ space: 2 }) {
              Text('Overnight Progression')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#111827')
              Text('Checkpoints: 12am, 2am, 4am, 6am, 8am')
                .fontSize(12)
                .fontColor('#64748B')
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Row({ space: 6 }) {
              Row({ space: 3 }) {
                Circle({ width: 6, height: 6 }).fill('#2E86DE')
                Text('Safe').fontSize(10).fontColor('#64748B')
              }
              Row({ space: 3 }) {
                Circle({ width: 6, height: 6 }).fill('#FF9500')
                Text('Dip').fontSize(10).fontColor('#64748B')
              }
              Row({ space: 3 }) {
                Circle({ width: 6, height: 6 }).fill('#FF3B30')
                Text('Hypo').fontSize(10).fontColor('#64748B')
              }
            }
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          // 5-bar visualization with values
          Row({ space: 12 }) {
            ForEach(this.getSelectedRecord().hourlyPoints, (val: number, idx: number) => {
              Column({ space: 6 }) {
                Text(`${val.toFixed(1)}`)
                  .fontSize(12)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(val < 3.9 ? '#EF4444' : '#111827')

                Stack({ alignContent: Alignment.Bottom }) {
                  Row()
                    .width('100%')
                    .height(96)
                    .backgroundColor('#F1F5F9')
                    .borderRadius(8)
                  Row()
                    .width('100%')
                    .height(Math.round((val / 6.5) * 96))
                    .backgroundColor(getOvernightBarColor(val))
                    .borderRadius(8)
                }
                .width('100%')
                .height(96)

                Text(idx === 0 ? '12am' : (idx === 1 ? '2am' : (idx === 2 ? '4am' : (idx === 3 ? '6am' : '8am'))))
                  .fontSize(11)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#64748B')
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Center)
            })
          }
          .width('100%')
          .alignItems(VerticalAlign.Bottom)

          // Safety threshold legend
          Row({ space: 6 }) {
            Circle({ width: 6, height: 6 })
              .fill('#22C55E')
            Text('Safety threshold: 3.9 mmol/L • Micro-tremors & vascular damping alert threshold')
              .fontSize(11)
              .fontColor('#475569')
              .layoutWeight(1)
          }
          .width('100%')
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .backgroundColor('#F8FAFC')
          .borderRadius(12)
        }
        .width('100%')
        .padding(18)
        .backgroundColor('#FFFFFF')
        .borderRadius(22)
        .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.04)', offsetY: 2 })

        // ==========================================
        // DEDICATED ACTIONS TAKEN AUDIT SECTION
        // (i.e., if nanawag ba or ni text kay na low blood sugar)
        // ==========================================
        Column({ space: 12 }) {
          Row() {
            Column({ space: 2 }) {
              Text('Actions Taken Log')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#111827')
              Text('Dispatch trail: Haptics, sirens, SMS & emergency calls')
                .fontSize(12)
                .fontColor('#64748B')
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Text(`${this.getSelectedRecord().actionsTaken.length} Event(s)`)
              .fontSize(11)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.getSelectedRecord().actionsTaken.length > 2 ? '#B91C1C' : '#15803D')
              .backgroundColor(this.getSelectedRecord().actionsTaken.length > 2 ? '#FEE2E2' : '#DCFCE7')
              .borderRadius(999)
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          }
          .width('100%')

          if (this.getSelectedRecord().actionsTaken.length === 0) {
            Text('No emergency interventions required for this night.')
              .fontSize(13)
              .fontColor('#64748B')
              .padding(12)
          } else {
            Column({ space: 10 }) {
              ForEach(this.getSelectedRecord().actionsTaken, (action: ActionTakenEntry) => {
                Row({ space: 12 }) {
                  // Icon badge
                  Stack({ alignContent: Alignment.Center }) {
                    Circle({ width: 34, height: 34 })
                      .fill(action.type === 'sms' || action.type === 'call' || action.type === 'alarm' ? '#FEE2E2' : '#EFF6FF')
                    Text(this.getActionIcon(action.type))
                      .fontSize(16)
                  }
                  .width(34)
                  .height(34)

                  // Content
                  Column({ space: 2 }) {
                    Row() {
                      Text(action.title)
                        .fontSize(13)
                        .fontWeight(FontWeight.Bold)
                        .fontColor('#111827')
                        .layoutWeight(1)

                      Text(action.time)
                        .fontSize(11)
                        .fontColor('#94A3B8')
                    }
                    .width('100%')

                    Text(action.detail)
                      .fontSize(12)
                      .fontColor('#475569')
                      .width('100%')

                    if (action.target) {
                      Row({ space: 4 }) {
                        Text('Target:')
                          .fontSize(11)
                          .fontColor('#64748B')
                        Text(action.target)
                          .fontSize(11)
                          .fontWeight(FontWeight.Bold)
                          .fontColor('#1E293B')
                      }
                      .margin({ top: 2 })
                    }

                    // Status Pill
                    Row() {
                      Text(action.status)
                        .fontSize(10)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(action.status === 'Active' ? '#DC2626' : (action.status === 'Delivered' ? '#2563EB' : '#15803D'))
                        .backgroundColor(action.status === 'Active' ? '#FEF2F2' : (action.status === 'Delivered' ? '#EFF6FF' : '#F0FDF4'))
                        .borderRadius(4)
                        .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                    }
                    .margin({ top: 3 })
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)
                }
                .width('100%')
                .padding(12)
                .backgroundColor('#F8FAFC')
                .borderRadius(14)
                .alignItems(VerticalAlign.Top)
              })
            }
            .width('100%')
          }
        }
        .width('100%')
        .padding(18)
        .backgroundColor('#FFFFFF')
        .borderRadius(22)
        .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.04)', offsetY: 2 })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 6, bottom: 40 })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .scrollable(ScrollDirection.Vertical)
  }
}
