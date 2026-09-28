/*
 * Copyright (c) 2026 HypoAlert.
 * Wearable — Screen 2: 3-7 Day Nocturnal History and Action Logs for Huawei Watch.
 * Optimized for circular 466x466 screen with high-contrast legibility.
 */

import { NightHistoryRecord, HistoryRepository } from '../../models/HistoryModel';
import { WatchPageDots } from './WatchPageDots';

@Component
export struct WatchHistoryView {
  @Prop currentPage: number = 1;
  @State historyRecords: NightHistoryRecord[] = [];
  onGoToPage: (page: number) => void = () => {};

  aboutToAppear(): void {
    this.historyRecords = HistoryRepository.getWatchHistory(5);
  }

  build() {
    Scroll() {
      Column({ space: 6 }) {
        // Top Header
        Row() {
          Button('Back')
            .fontSize(9)
            .fontColor('#8A8F98')
            .backgroundColor(Color.Transparent)
            .width(46)
            .height(26)
            .padding(0)
            .onClick(() => {
              this.onGoToPage(0);
            })

          Text('Night Log (5d)')
            .fontSize(10)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Blank()
            .width(46)
            .color(Color.Transparent)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        // Subtitle note
        Text('Last 5 days on watch • Full logs on phone')
          .fontSize(8)
          .fontColor('#6E747D')
          .textAlign(TextAlign.Center)
          .width('100%')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        // List of Night History Cards
        ForEach(this.historyRecords, (record: NightHistoryRecord) => {
          Column({ space: 3 }) {
            // Header Row: Date & Status Pill
            Row() {
              Text(`${record.dateShort} (${record.dayOfWeek})`)
                .fontSize(9)
                .fontWeight(FontWeight.Bold)
                .fontColor('#E8EBEF')
                .layoutWeight(1)

              Text(record.status === 'CRITICAL' ? 'ALERT' : (record.status === 'WARNING' ? 'WARN' : 'OK'))
                .fontSize(8)
                .fontWeight(FontWeight.Bold)
                .fontColor(record.status === 'CRITICAL' ? '#FF5252' : (record.status === 'WARNING' ? '#FFB74D' : '#00E676'))
                .backgroundColor(record.status === 'CRITICAL' ? '#2A1215' : (record.status === 'WARNING' ? '#261C0D' : '#0E2419'))
                .borderRadius(4)
                .padding({ left: 4, right: 4, top: 1, bottom: 1 })
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)

            // Value Row: Lowest Glucose & Episodes
            Row() {
              Row({ space: 2 }) {
                Text(`${record.lowestGlucose.toFixed(1)}`)
                  .fontSize(13)
                  .fontWeight(FontWeight.Bolder)
                  .fontColor(record.lowestGlucose < 3.9 ? '#FF5252' : '#FFFFFF')
                Text('mmol/L')
                  .fontSize(8)
                  .fontColor('#8A8F98')
                  .margin({ bottom: 1 })
              }
              .alignItems(VerticalAlign.Bottom)

              Blank()

              Text(`${record.durationHours}h sleep`)
                .fontSize(8)
                .fontColor('#8A8F98')
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)

            // Actions Summary Line
            Text(record.actionsSummary)
              .fontSize(8)
              .fontColor(record.status === 'CRITICAL' ? '#FF8A80' : '#8A8F98')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width('100%')
          }
          .width('100%')
          .padding({ top: 5, bottom: 5, left: 8, right: 8 })
          .backgroundColor('#14181F')
          .borderRadius(10)
        })

        // Spacer to lift dots onto matching alignment
        Blank().height(8)

        WatchPageDots({
          currentPage: this.currentPage,
          totalPages: 3,
          onSelectPage: this.onGoToPage
        })
      }
      .width(184)
      .padding({ top: 26, bottom: 44 })
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .scrollable(ScrollDirection.Vertical)
    .align(Alignment.Top)
    .backgroundColor('#000000')
  }
}

@Preview({ title: 'Watch History View', width: 466, height: 466 })
@Component
struct WatchHistoryViewPreview {
  build() {
    WatchHistoryView({
      currentPage: 1
    })
  }
}
