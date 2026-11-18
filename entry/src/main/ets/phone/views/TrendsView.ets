/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Screen 2: Night History & Nocturnal Time Ruler.
 * Matches the reference History layout: header + calendar chip, pill search + black filter button,
 * Select Date strip, interactive tick-mark Select Window ruler, 3-column Night Summary, and clean timeline rows.
 */

import { ActionTakenEntry, CalibrationProgress, HistoryRepository, NightHistoryRecord } from '../../models/HistoryModel';
import { DetectionPhase } from '../models/PhoneTypes';
import { activeScoreThreshold } from '../utils/PhoneRiskUtils';
import { PhoneTheme } from '../utils/PhoneTheme';

@Component
export struct TrendsView {
  @Prop activePhase: DetectionPhase = 'P1';
  @Prop symptomScore: number = 1.2;
  @Prop isEmergency: boolean = false;
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
  @Prop @Watch('onHistoryVersionChange') historyVersion: number = 0;

  @State selectedIndex: number = 0;
  @State selectedSlot: number = 2; // 0: 12am, 1: 2am, 2: 4am, 3: 6am, 4: 8am
  @State searchText: string = '';
  @State filterMode: string = 'all'; // 'all' | 'alerts' | 'pricks'
  @State historyRecords: NightHistoryRecord[] = [];
  onOpenReports: () => void = () => {};

  aboutToAppear(): void {
    this.historyRecords = [...HistoryRepository.getHistory()];
  }

  onHistoryVersionChange(): void {
    this.historyRecords = [...HistoryRepository.getHistory()];
  }

  private records(): NightHistoryRecord[] {
    if (this.historyRecords.length > 0) {
      return this.historyRecords;
    }
    return HistoryRepository.getHistory();
  }

  private selectedRecord(): NightHistoryRecord {
    const list: NightHistoryRecord[] = this.records();
    if (this.selectedIndex >= 0 && this.selectedIndex < list.length) {
      return list[this.selectedIndex];
    }
    return list[0];
  }

  private cutoffValue(): number {
    return activeScoreThreshold(this.activePhase, this.calibration.personalCutoff);
  }

  private selectedWindowScore(): number {
    const rec: NightHistoryRecord = this.selectedRecord();
    if (this.selectedSlot >= 0 && this.selectedSlot < rec.hourlySymptomScores.length) {
      if (this.selectedIndex === 0 && this.selectedSlot === 2 && this.isEmergency) {
        return Math.max(rec.hourlySymptomScores[2], this.symptomScore);
      }
      return rec.hourlySymptomScores[this.selectedSlot];
    }
    return rec.peakSymptomScore;
  }

  private windowLabel(slot: number): string {
    if (slot === 0) {
      return '12:00 AM';
    }
    if (slot === 1) {
      return '02:00 AM';
    }
    if (slot === 2) {
      return '04:00 AM';
    }
    if (slot === 3) {
      return '06:00 AM';
    }
    return '08:00 AM';
  }

  private filteredActions(): ActionTakenEntry[] {
    const all: ActionTakenEntry[] = this.selectedRecord().actionsTaken;
    const q: string = this.searchText.trim().toLowerCase();
    const out: ActionTakenEntry[] = [];
    for (let i: number = 0; i < all.length; i++) {
      const a: ActionTakenEntry = all[i];
      if (this.filterMode === 'alerts' && a.type !== 'haptic' && a.type !== 'alarm' && a.type !== 'sms' && a.type !== 'call') {
        continue;
      }
      if (this.filterMode === 'pricks' && a.type !== 'prick') {
        continue;
      }
      if (q.length > 0) {
        const hay: string = `${a.title} ${a.detail} ${a.time}`.toLowerCase();
        if (hay.indexOf(q) === -1) {
          continue;
        }
      }
      out.push(a);
    }
    return out;
  }

  private cycleFilter(): void {
    if (this.filterMode === 'all') {
      this.filterMode = 'alerts';
    } else if (this.filterMode === 'alerts') {
      this.filterMode = 'pricks';
    } else {
      this.filterMode = 'all';
    }
  }

  private statusLabel(status: string): string {
    if (status === 'CRITICAL') {
      return 'Surge';
    }
    if (status === 'WARNING') {
      return 'Rising';
    }
    return 'Normal';
  }

  private statusBg(status: string): string {
    if (status === 'CRITICAL') {
      return PhoneTheme.STATE_CRIT_BG;
    }
    if (status === 'WARNING') {
      return PhoneTheme.STATE_WARN_BG;
    }
    return PhoneTheme.STATE_OK_BG;
  }

  private statusInk(status: string): string {
    if (status === 'CRITICAL') {
      return PhoneTheme.STATE_CRIT_TEXT;
    }
    if (status === 'WARNING') {
      return PhoneTheme.STATE_WARN_TEXT;
    }
    return PhoneTheme.STATE_OK_TEXT;
  }

  private tickIndices(): number[] {
    return [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20];
  }

  private tickHeight(i: number): number {
    if (i % 5 === 0) {
      return 24;
    }
    if (i % 2 === 0) {
      return 16;
    }
    return 10;
  }

  private tickColor(i: number): string {
    const center: number = this.selectedSlot * 5;
    if (Math.abs(i - center) <= 1) {
      return PhoneTheme.BRAND_ACCENT;
    }
    if (i % 5 === 0) {
      return PhoneTheme.TEXT_PRIMARY;
    }
    return PhoneTheme.TEXT_TERTIARY;
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        // Header row: History + white Calendar icon button
        Row() {
          Text('History')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .letterSpacing(-0.5)
            .fontColor(PhoneTheme.TEXT_PRIMARY)
            .layoutWeight(1)

          Button() {
            SymbolGlyph($r('sys.symbol.calendar'))
              .fontSize(18)
              .fontColor([PhoneTheme.TEXT_PRIMARY])
          }
          .width(42)
          .height(42)
          .backgroundColor(PhoneTheme.BG_CARD)
          .borderRadius(21)
          .shadow({ radius: 10, color: 'rgba(17, 19, 24, 0.05)', offsetY: 2 })
          .onClick(() => {
            this.selectedIndex = 0;
            this.filterMode = 'all';
            this.searchText = '';
          })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        // Pill Search Bar + Black Filter Button
        Row({ space: 8 }) {
          Row({ space: 8 }) {
            SymbolGlyph($r('sys.symbol.magnifyingglass'))
              .fontSize(16)
              .fontColor([PhoneTheme.TEXT_MUTED])

            TextInput({
              placeholder: this.filterMode === 'all' ? 'Search logs...' : `Filter: ${this.filterMode}`,
              text: this.searchText
            })
              .fontSize(PhoneTheme.FONT_BODY)
              .fontColor(PhoneTheme.TEXT_PRIMARY)
              .placeholderColor(PhoneTheme.TEXT_MUTED)
              .backgroundColor(Color.Transparent)
              .height(38)
              .padding(0)
              .layoutWeight(1)
              .onChange((val: string) => {
                this.searchText = val;
              })

            Button() {
              SymbolGlyph($r('sys.symbol.slider_horizontal_2'))
                .fontSize(16)
                .fontColor([PhoneTheme.TEXT_ON_DARK])
            }
            .width(38)
            .height(38)
            .backgroundColor(this.filterMode === 'all' ? PhoneTheme.BRAND_PRIMARY : PhoneTheme.BRAND_ACCENT)
            .borderRadius(19)
            .onClick(() => {
              this.cycleFilter();
            })
          }
          .width('100%')
          .height(48)
          .padding({ left: 16, right: 5 })
          .backgroundColor(PhoneTheme.BG_CARD)
          .borderRadius(24)
          .shadow({ radius: 10, color: 'rgba(17, 19, 24, 0.04)', offsetY: 2 })
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')

        // Combined Date + Time Ruler White Card
        Column({ space: 14 }) {
          Row() {
            Text('Select Night')
              .fontSize(PhoneTheme.FONT_BODY)
              .fontWeight(FontWeight.Medium)
              .fontColor(PhoneTheme.TEXT_SECONDARY)
              .layoutWeight(1)

            Row({ space: 10 }) {
              SymbolGlyph($r('sys.symbol.chevron_left'))
                .fontSize(13)
                .fontColor([PhoneTheme.TEXT_SECONDARY])
                .onClick(() => {
                  const list: NightHistoryRecord[] = this.records();
                  this.selectedIndex = Math.min(list.length - 1, this.selectedIndex + 1);
                })

              Text('Sep 2026')
                .fontSize(PhoneTheme.FONT_BODY)
                .fontWeight(FontWeight.Medium)
                .fontColor(PhoneTheme.TEXT_PRIMARY)

              SymbolGlyph($r('sys.symbol.chevron_right'))
                .fontSize(13)
                .fontColor([PhoneTheme.TEXT_SECONDARY])
                .onClick(() => {
                  this.selectedIndex = Math.max(0, this.selectedIndex - 1);
                })
            }
            .alignItems(VerticalAlign.Center)
          }
          .width('100%')

          // Horizontal Date Cards
          Scroll() {
            Row({ space: 8 }) {
              ForEach(this.records(), (rec: NightHistoryRecord, idx: number) => {
                Button() {
                  Column({ space: 3 }) {
                    Text(rec.dateShort)
                      .fontSize(PhoneTheme.FONT_SUBTITLE)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(this.selectedIndex === idx ? PhoneTheme.TEXT_PRIMARY : PhoneTheme.TEXT_SECONDARY)

                    Text(rec.dayOfWeek)
                      .fontSize(PhoneTheme.FONT_MICRO)
                      .fontColor(this.selectedIndex === idx ? PhoneTheme.TEXT_SECONDARY : PhoneTheme.TEXT_MUTED)
                  }
                  .alignItems(HorizontalAlign.Center)
                }
                .width(74)
                .height(62)
                .backgroundColor(this.selectedIndex === idx ? PhoneTheme.BG_CARD : PhoneTheme.BG_INSET)
                .borderRadius(16)
                .shadow(this.selectedIndex === idx ? { radius: 10, color: 'rgba(17, 19, 24, 0.08)', offsetY: 2 } : { radius: 0, color: Color.Transparent })
                .onClick(() => {
                  this.selectedIndex = idx;
                })
              }, (rec: NightHistoryRecord, idx: number) => `${rec.id}_${idx}_${this.selectedIndex === idx}`)
            }
            .padding({ left: 2, right: 2 })
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .width('100%')

          // Select Time Window Tick Ruler
          Column({ space: 8 }) {
            Row() {
              Text('Select Window')
                .fontSize(PhoneTheme.FONT_BODY)
                .fontWeight(FontWeight.Medium)
                .fontColor(PhoneTheme.TEXT_SECONDARY)
                .layoutWeight(1)

              Text(`${this.windowLabel(this.selectedSlot)} · ${this.selectedWindowScore().toFixed(1)}`)
                .fontSize(PhoneTheme.FONT_CAPTION)
                .fontWeight(FontWeight.Bold)
                .fontFeature('"tnum" on')
                .fontColor(this.selectedWindowScore() >= this.cutoffValue() ? PhoneTheme.STATE_CRIT_TEXT : PhoneTheme.BRAND_ACCENT)
            }
            .width('100%')

            // Tick Marks Strip
            Row() {
              ForEach(this.tickIndices(), (t: number) => {
                Column({ space: 4 }) {
                  Row()
                    .width(t % 5 === 0 ? 2.5 : 1.5)
                    .height(this.tickHeight(t))
                    .borderRadius(1)
                    .backgroundColor(this.tickColor(t))
                }
                .layoutWeight(1)
                .height(28)
                .justifyContent(FlexAlign.End)
                .alignItems(HorizontalAlign.Center)
                .onClick(() => {
                  this.selectedSlot = Math.min(4, Math.round(t / 5));
                })
              }, (t: number) => `tick_${t}_${this.selectedSlot}`)
            }
            .width('100%')

            // Interactive Time Labels
            Row() {
              ForEach([0, 1, 2, 3, 4], (slot: number) => {
                Text(slot === 0 ? '12am' : (slot === 1 ? '2am' : (slot === 2 ? '4am' : (slot === 3 ? '6am' : '8am'))))
                  .fontSize(PhoneTheme.FONT_MICRO)
                  .fontWeight(this.selectedSlot === slot ? FontWeight.Bold : FontWeight.Normal)
                  .fontColor(this.selectedSlot === slot ? PhoneTheme.BRAND_ACCENT : PhoneTheme.TEXT_MUTED)
                  .layoutWeight(1)
                  .textAlign(TextAlign.Center)
                  .onClick(() => {
                    this.selectedSlot = slot;
                  })
              })
            }
            .width('100%')
          }
          .width('100%')
        }
        .width('100%')
        .padding(PhoneTheme.CARD_PADDING)
        .backgroundColor(PhoneTheme.BG_CARD)
        .borderRadius(PhoneTheme.CARD_RADIUS)
        .shadow({ radius: 12, color: 'rgba(17, 19, 24, 0.04)', offsetY: 3 })

        // Night Summary Section (3 mini cards + log rows)
        Row() {
          Text('Night Summary')
            .fontSize(PhoneTheme.FONT_SECTION)
            .fontWeight(FontWeight.Bold)
            .fontColor(PhoneTheme.TEXT_PRIMARY)
            .layoutWeight(1)

          Button('Reports')
            .fontSize(PhoneTheme.FONT_CAPTION)
            .fontWeight(FontWeight.Medium)
            .height(28)
            .padding({ left: 10, right: 10 })
            .backgroundColor(PhoneTheme.BG_CARD)
            .fontColor(PhoneTheme.BRAND_ACCENT)
            .borderRadius(PhoneTheme.PILL_RADIUS)
            .onClick(() => {
              this.onOpenReports();
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        // 3 Mini Summary Cards
        Row({ space: 10 }) {
          // Peak Score
          Column({ space: 6 }) {
            Row() {
              Blank()
              Circle({ width: 10, height: 10 })
                .fill(this.selectedRecord().peakSymptomScore >= this.cutoffValue() ? PhoneTheme.STATE_CRIT : PhoneTheme.STATE_OK)
            }
            .width('100%')

            Row({ space: 3 }) {
              Text(`${this.selectedRecord().peakSymptomScore.toFixed(1)}`)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontFeature('"tnum" on')
                .fontColor(PhoneTheme.TEXT_PRIMARY)
              Text('max')
                .fontSize(PhoneTheme.FONT_MICRO)
                .fontColor(PhoneTheme.TEXT_MUTED)
                .margin({ bottom: 2 })
            }
            .alignItems(VerticalAlign.Bottom)

            Text('Peak')
              .fontSize(PhoneTheme.FONT_CAPTION)
              .fontColor(PhoneTheme.TEXT_MUTED)
          }
          .layoutWeight(1)
          .padding(12)
          .backgroundColor(PhoneTheme.BG_CARD)
          .borderRadius(18)
          .shadow({ radius: 8, color: 'rgba(17, 19, 24, 0.04)', offsetY: 2 })
          .alignItems(HorizontalAlign.Start)

          // Streak Alerts
          Column({ space: 6 }) {
            Row() {
              Blank()
              SymbolGlyph($r('sys.symbol.bell_fill'))
                .fontSize(12)
                .fontColor([this.selectedRecord().episodesCount > 0 ? PhoneTheme.STATE_WARN : PhoneTheme.TEXT_TERTIARY])
            }
            .width('100%')

            Row({ space: 3 }) {
              Text(`${this.selectedRecord().episodesCount}`)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontFeature('"tnum" on')
                .fontColor(PhoneTheme.TEXT_PRIMARY)
              Text('/ 2')
                .fontSize(PhoneTheme.FONT_MICRO)
                .fontColor(PhoneTheme.TEXT_MUTED)
                .margin({ bottom: 2 })
            }
            .alignItems(VerticalAlign.Bottom)

            Text('Alerts')
              .fontSize(PhoneTheme.FONT_CAPTION)
              .fontColor(PhoneTheme.TEXT_MUTED)
          }
          .layoutWeight(1)
          .padding(12)
          .backgroundColor(PhoneTheme.BG_CARD)
          .borderRadius(18)
          .shadow({ radius: 8, color: 'rgba(17, 19, 24, 0.04)', offsetY: 2 })
          .alignItems(HorizontalAlign.Start)

          // Finger-prick
          Column({ space: 6 }) {
            Row() {
              Blank()
              SymbolGlyph($r('sys.symbol.drop_fill'))
                .fontSize(12)
                .fontColor([PhoneTheme.BRAND_ACCENT])
            }
            .width('100%')

            Text(this.selectedRecord().fingerPrickNote)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontFeature('"tnum" on')
              .fontColor(PhoneTheme.TEXT_PRIMARY)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .height(24)

            Text('Check')
              .fontSize(PhoneTheme.FONT_CAPTION)
              .fontColor(PhoneTheme.TEXT_MUTED)
          }
          .layoutWeight(1.1)
          .padding(12)
          .backgroundColor(PhoneTheme.BG_CARD)
          .borderRadius(18)
          .shadow({ radius: 8, color: 'rgba(17, 19, 24, 0.04)', offsetY: 2 })
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')

        // Event Rows
        if (this.filteredActions().length === 0) {
          Text('No logs found')
            .fontSize(PhoneTheme.FONT_BODY)
            .fontColor(PhoneTheme.TEXT_MUTED)
            .padding(16)
            .width('100%')
            .backgroundColor(PhoneTheme.BG_CARD)
            .borderRadius(PhoneTheme.CARD_RADIUS)
        } else {
          Column({ space: 8 }) {
            ForEach(this.filteredActions(), (action: ActionTakenEntry, idx: number) => {
              Row({ space: 12 }) {
                Stack({ alignContent: Alignment.Center }) {
                  Circle({ width: 38, height: 38 })
                    .fill(
                      action.type === 'prick'
                        ? PhoneTheme.BRAND_ACCENT_BG
                        : (action.type === 'resolve' ? PhoneTheme.STATE_OK_BG : PhoneTheme.STATE_CRIT_BG)
                    )

                  SymbolGlyph(
                    action.type === 'prick'
                      ? $r('sys.symbol.drop_fill')
                      : (action.type === 'resolve' ? $r('sys.symbol.checkmark_circle_fill') : $r('sys.symbol.bell_fill'))
                  )
                    .fontSize(16)
                    .fontColor([
                      action.type === 'prick'
                        ? PhoneTheme.BRAND_ACCENT
                        : (action.type === 'resolve' ? PhoneTheme.STATE_OK_TEXT : PhoneTheme.STATE_CRIT_TEXT)
                    ])
                }
                .width(38)
                .height(38)

                Column({ space: 3 }) {
                  Row({ space: 6 }) {
                    Text(action.title)
                      .fontSize(PhoneTheme.FONT_BODY)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(PhoneTheme.TEXT_PRIMARY)
                      .layoutWeight(1)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })

                    Text(action.time)
                      .fontSize(PhoneTheme.FONT_MICRO)
                      .fontFeature('"tnum" on')
                      .fontColor(PhoneTheme.TEXT_MUTED)
                  }
                  .width('100%')

                  Row({ space: 8 }) {
                    Text(
                      action.type === 'resolve'
                        ? this.statusLabel('NORMAL')
                        : (action.type === 'prick' ? 'Checked' : this.statusLabel('CRITICAL'))
                    )
                      .fontSize(PhoneTheme.FONT_MICRO)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(
                        action.type === 'resolve'
                          ? PhoneTheme.STATE_OK_TEXT
                          : (action.type === 'prick' ? PhoneTheme.BRAND_ACCENT : PhoneTheme.STATE_CRIT_TEXT)
                      )
                      .backgroundColor(
                        action.type === 'resolve'
                          ? PhoneTheme.STATE_OK_BG
                          : (action.type === 'prick' ? PhoneTheme.BRAND_ACCENT_BG : PhoneTheme.STATE_CRIT_BG)
                      )
                      .borderRadius(PhoneTheme.PILL_RADIUS)
                      .padding({ left: 8, right: 8, top: 2, bottom: 2 })

                    Text(action.detail)
                      .fontSize(PhoneTheme.FONT_CAPTION)
                      .fontColor(PhoneTheme.TEXT_MUTED)
                      .layoutWeight(1)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .width('100%')
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)

                SymbolGlyph($r('sys.symbol.chevron_right'))
                  .fontSize(14)
                  .fontColor([PhoneTheme.TEXT_MUTED])
              }
              .width('100%')
              .padding({ left: 12, right: 14, top: 10, bottom: 10 })
              .backgroundColor(PhoneTheme.BG_CARD)
              .borderRadius(20)
              .shadow({ radius: 8, color: 'rgba(17, 19, 24, 0.04)', offsetY: 2 })
              .alignItems(VerticalAlign.Center)
            }, (action: ActionTakenEntry, idx: number) => `${this.selectedRecord().id}_${idx}_${action.title}`)
          }
          .width('100%')
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 104 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(PhoneTheme.BG_PAGE)
    .scrollBar(BarState.Off)
    .scrollable(ScrollDirection.Vertical)
  }
}
