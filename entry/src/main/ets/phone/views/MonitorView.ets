/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Screen 1: Bedside Nocturnal Guardian Monitor.
 * Ultra-clean, distraction-free bedside dashboard designed for nighttime glanceability.
 */

import { PhoneHeroCard } from '../components/PhoneHeroCard';
import { PhoneMetricGrid } from '../components/PhoneMetricGrid';
import { PhoneTheme } from '../utils/PhoneTheme';

@Component
export struct MonitorView {
  @Prop glucose: number = 5.5;
  @Prop riskIndex: number = 12;
  @Prop currentTime: string = '00:00:00';
  @Prop heartRate: number = 62;
  @Prop watchBattery: number = 86;
  @Prop tremorPSD: number = 0.12;
  @Prop skinTemp: number = 36.0;
  @Prop bannerFlash: boolean = false;
  @Prop isWatchConnected: boolean = true;
  @Prop caregiverName: string = 'Maria Santos';
  @Prop caregiverPhone: string = '+63 917 123 4567';
  ppgContext: CanvasRenderingContext2D | null = null;
  onCanvasReady: () => void = () => {};
  onCallNow: () => void = () => {};
  onMarkWithThem: () => void = () => {};
  onConnectWatch: () => void = () => {};
  onNavigateTab: (index: number) => void = () => {};

  build() {
    Scroll() {
      Column({ space: 12 }) {
        // Watch offline reminder (single line)
        if (!this.isWatchConnected) {
          Row({ space: 10 }) {
            Circle({ width: 6, height: 6 })
              .fill(PhoneTheme.STATE_WARN)

            Text('Watch offline — reconnect to resume')
              .fontSize(PhoneTheme.FONT_BODY)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.TEXT_PRIMARY)
              .layoutWeight(1)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            Button('Connect')
              .fontSize(PhoneTheme.FONT_BODY)
              .fontWeight(FontWeight.Bold)
              .height(40)
              .padding({ left: 14, right: 14 })
              .backgroundColor(PhoneTheme.BRAND_PRIMARY)
              .fontColor(PhoneTheme.TEXT_ON_DARK)
              .borderRadius(PhoneTheme.TILE_RADIUS)
              .onClick(() => {
                this.onConnectWatch();
              })
          }
          .width('100%')
          .padding({ left: 14, right: 14, top: 10, bottom: 10 })
          .backgroundColor(PhoneTheme.BG_CARD)
          .borderWidth(1)
          .borderColor(PhoneTheme.STATE_WARN)
          .borderRadius(PhoneTheme.CARD_RADIUS)
          .alignItems(VerticalAlign.Center)
        }

        // Section: Tonight
        Row() {
          Text('Tonight')
            .fontSize(PhoneTheme.FONT_SECTION)
            .fontWeight(FontWeight.Bold)
            .fontColor(PhoneTheme.TEXT_PRIMARY)
            .layoutWeight(1)
          Text('22:00–06:00')
            .fontSize(PhoneTheme.FONT_CAPTION)
            .fontColor(PhoneTheme.TEXT_MUTED)
        }
        .width('100%')
        .padding({ left: 2, right: 2 })
        .alignItems(VerticalAlign.Center)

        // Primary hero: single dominant reading
        PhoneHeroCard({
          glucose: this.glucose,
          riskIndex: this.riskIndex,
          currentTime: this.currentTime,
          heartRate: this.heartRate,
          watchBattery: this.watchBattery,
          bannerFlash: this.bannerFlash,
          isWatchConnected: this.isWatchConnected,
          onCallNow: this.onCallNow,
          onMarkWithThem: this.onMarkWithThem
        })

        // Section: Vitals
        Row() {
          Text('Vitals')
            .fontSize(PhoneTheme.FONT_SECTION)
            .fontWeight(FontWeight.Bold)
            .fontColor(PhoneTheme.TEXT_PRIMARY)
            .layoutWeight(1)
          Circle({ width: 6, height: 6 })
            .fill(this.isWatchConnected ? PhoneTheme.STATE_OK : PhoneTheme.TEXT_TERTIARY)
          Text(this.isWatchConnected ? 'Live' : 'Paused')
            .fontSize(PhoneTheme.FONT_CAPTION)
            .fontColor(PhoneTheme.TEXT_MUTED)
        }
        .width('100%')
        .padding({ left: 2, right: 2 })
        .alignItems(VerticalAlign.Center)

        // Quiet secondary vitals
        PhoneMetricGrid({
          heartRate: this.heartRate,
          tremorPSD: this.tremorPSD,
          skinTemp: this.skinTemp,
          riskIndex: this.riskIndex,
          ppgContext: this.ppgContext,
          onCanvasReady: this.onCanvasReady
        })

        // Section: Caregiver — always visible call path
        Row({ space: 12 }) {
          Stack({ alignContent: Alignment.Center }) {
            Circle({ width: 40, height: 40 })
              .fill(PhoneTheme.BRAND_PRIMARY)
            Text(this.caregiverName.length > 0 ? this.caregiverName.substring(0, 1) : 'M')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.TEXT_ON_DARK)
          }
          .width(40)
          .height(40)
          Column({ space: 0 }) {
            Text('Caregiver')
              .fontSize(PhoneTheme.FONT_MICRO)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.TEXT_TERTIARY)
            Text(this.caregiverName)
              .fontSize(PhoneTheme.FONT_BODY)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.TEXT_PRIMARY)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(this.caregiverPhone)
              .fontSize(PhoneTheme.FONT_CAPTION)
              .fontColor(PhoneTheme.TEXT_MUTED)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          Button('Call')
            .fontSize(PhoneTheme.FONT_BODY)
            .fontWeight(FontWeight.Bold)
            .height(48)
            .padding({ left: 18, right: 18 })
            .backgroundColor(PhoneTheme.BRAND_PRIMARY)
            .fontColor(PhoneTheme.TEXT_ON_DARK)
            .borderRadius(PhoneTheme.TILE_RADIUS)
            .onClick(() => {
              this.onCallNow();
            })
        }
        .width('100%')
        .padding(12)
        .backgroundColor(PhoneTheme.BG_CARD)
        .borderWidth(1)
        .borderColor(PhoneTheme.BORDER_SUBTLE)
        .borderRadius(PhoneTheme.CARD_RADIUS)
        .alignItems(VerticalAlign.Center)
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
