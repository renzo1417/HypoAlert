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
      Column({ space: 14 }) {
        // Watch offline reminder banner (only visible when BLE disconnected)
        if (!this.isWatchConnected) {
          Row({ space: 10 }) {
            Circle({ width: 7, height: 7 })
              .fill(PhoneTheme.STATE_WARN)

            Column({ space: 1 }) {
              Text('Watch Disconnected')
                .fontSize(PhoneTheme.FONT_SUBTITLE)
                .fontWeight(FontWeight.Bold)
                .fontColor(PhoneTheme.TEXT_PRIMARY)
              Text('Link watch stream to resume nocturnal monitoring')
                .fontSize(PhoneTheme.FONT_CAPTION)
                .fontColor(PhoneTheme.TEXT_MUTED)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Button('Connect')
              .fontSize(PhoneTheme.FONT_BODY)
              .fontWeight(FontWeight.Bold)
              .height(30)
              .padding({ left: 12, right: 12 })
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

        // Primary Hero Card: Glycemic state, Risk gauge, and crisis actions
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

        // Core Sympathetic Biomarkers (Tremor, Pulse, Temp, Baseline)
        PhoneMetricGrid({
          heartRate: this.heartRate,
          tremorPSD: this.tremorPSD,
          skinTemp: this.skinTemp,
          riskIndex: this.riskIndex,
          ppgContext: this.ppgContext,
          onCanvasReady: this.onCanvasReady
        })

        // Calming Bedside Safeguard Footer Notice
        Row({ space: 6 }) {
          Circle({ width: 4, height: 4 }).fill(PhoneTheme.TEXT_TERTIARY)
          Text('Bedside Guardian: Haptic wrist alert sounds loud phone siren if unawakened')
            .fontSize(PhoneTheme.FONT_MICRO)
            .fontColor(PhoneTheme.TEXT_TERTIARY)
            .layoutWeight(1)
        }
        .width('100%')
        .padding({ left: 4, right: 4, top: 4, bottom: 20 })
        .alignItems(VerticalAlign.Center)
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
