/*
 * Copyright (c) 2026 HypoAlert.
 * Wearable — Screen 2: Past Nights peak symptom risk & finger-prick confirmation status.
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

  private getShortVerdict(record: NightHistoryRecord): string {
    if (record.fingerPrickVerdict === 'Confirmed Low') {
      return `${record.dateShort} • Low ✓`;
    }
    if (record.fingerPrickVerdict === 'Fine Night') {
      return `${record.dateShort} • Fine`;
    }
    if (record.fingerPrickVerdict === 'Pending Check') {
      return `${record.dateShort} • Check?`;
    }
    return record.dateShort;
  }

  build() {
    Scroll() {
      Column({ space: 0 }) {
        Text('Past Nights')
          .fontSize(9)
          .fontWeight(FontWeight.Medium)
          .fontColor('#E8EBEF')
          .textAlign(TextAlign.Center)
          .width('100%')
          .maxLines(1)

        Text('PEAK SYMPTOM RISK')
          .fontSize(7)
          .fontColor('#5B616B')
          .textAlign(TextAlign.Center)
          .width('100%')
          .maxLines(1)
          .margin({ top: 2, bottom: 6 })

        ForEach(this.historyRecords, (record: NightHistoryRecord, index: number) => {
          Column({ space: 0 }) {
            Row({ space: 6 }) {
              Circle({ width: 5, height: 5 })
                .fill(record.status === 'CRITICAL' ? '#FF5252' : (record.status === 'WARNING' ? '#FFB74D' : '#00E676'))

              Text(this.getShortVerdict(record))
                .fontSize(8)
                .fontWeight(FontWeight.Normal)
                .fontColor('#8A8F98')
                .layoutWeight(1)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })

              Text(`${record.peakRiskPct}%`)
                .fontSize(12)
                .fontWeight(FontWeight.Medium)
                .fontColor(record.peakRiskPct >= 70 ? '#FF5252' : (record.peakRiskPct >= 35 ? '#FFB74D' : '#FFFFFF'))
                .maxLines(1)
            }
            .width('100%')
            .height(28)
            .alignItems(VerticalAlign.Center)

            if (index !== this.historyRecords.length - 1) {
              Divider()
                .color('#1E2228')
                .strokeWidth(1)
                .width('100%')
            }
          }
          .width('100%')
        })

        Blank().height(10)

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
