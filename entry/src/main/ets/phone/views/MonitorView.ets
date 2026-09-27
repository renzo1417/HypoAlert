/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Screen 1: Real-time nocturnal monitor dashboard.
 */

import { riskLevel } from '../utils/PhoneRiskUtils';
import { PhoneHeroCard } from '../components/PhoneHeroCard';
import { PhoneMetricGrid } from '../components/PhoneMetricGrid';

@Component
export struct MonitorView {
  @Prop glucose: number = 5.5;
  @Prop riskIndex: number = 12;
  @Prop currentTime: string = '00:00:00';
  @Prop heartRate: number = 62;
  @Prop watchBattery: number = 86;
  @Prop tremorPSD: number = 0.12;
  @Prop bannerFlash: boolean = false;
  ppgContext: CanvasRenderingContext2D | null = null;
  onCanvasReady: () => void = () => {};
  onCallNow: () => void = () => {};
  onMarkWithThem: () => void = () => {};
  onNavigateTab: (index: number) => void = () => {};

  private isEmergency(): boolean {
    return riskLevel(this.riskIndex) === 'Critical';
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        // Hero card (Night guardian status, big 52sp glucose, trend, glass chips)
        PhoneHeroCard({
          glucose: this.glucose,
          riskIndex: this.riskIndex,
          currentTime: this.currentTime,
          heartRate: this.heartRate,
          watchBattery: this.watchBattery,
          bannerFlash: this.bannerFlash,
          onCallNow: this.onCallNow,
          onMarkWithThem: this.onMarkWithThem
        })

        // Guardian active reassurance card
        Row({ space: 10 }) {
          Stack({ alignContent: Alignment.Center }) {
            Circle({ width: 32, height: 32 })
              .fill('#E7F0FE')
            Circle({ width: 8, height: 8 })
              .fill('#2E86DE')
          }
          .width(32)
          .height(32)

          Column({ space: 2 }) {
            Text('Nocturnal guardian active')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor('#0F1B2D')
            Text('Syncing live telemetry via Huawei Wear Engine')
              .fontSize(12)
              .fontColor('#8A94A6')
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Text('Live')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor('#34C759')
            .backgroundColor('#E9F7EF')
            .borderRadius(12)
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
        }
        .width('100%')
        .padding(14)
        .backgroundColor('#FFFFFF')
        .borderRadius(20)
        .border({ width: 1, color: '#E3E9F2', radius: 20 })
        .shadow({ radius: 10, color: 'rgba(15,27,45,0.06)', offsetX: 0, offsetY: 3 })
        .alignItems(VerticalAlign.Center)

        // Section header
        Row() {
          Text('PHYSIOLOGICAL VITALS')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor('#8A94A6')
            .letterSpacing(1)
          Blank()
          Text('4 sensors')
            .fontSize(12)
            .fontColor('#8A94A6')
        }
        .width('100%')
        .padding({ left: 4, right: 4 })

        // 2x2 Metric Grid (Glucose with PPG sparkline, Restlessness PSD, Tonight window, Risk gauge)
        PhoneMetricGrid({
          glucose: this.glucose,
          riskIndex: this.riskIndex,
          heartRate: this.heartRate,
          tremorPSD: this.tremorPSD,
          currentTime: this.currentTime,
          ppgContext: this.ppgContext,
          onCanvasReady: this.onCanvasReady
        })

        // Quick shortcut to overnight trends
        Row({ space: 8 }) {
          Column({ space: 2 }) {
            Text('Want to review nocturnal stability?')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor('#0F1B2D')
            Text('See glucose history and sleep events over time')
              .fontSize(12)
              .fontColor('#8A94A6')
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Button('View trends')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .height(36)
            .backgroundColor('#E7F0FE')
            .fontColor('#2E86DE')
            .borderRadius(10)
            .onClick(() => {
              this.onNavigateTab(1); // Jump to Trends tab
            })
        }
        .width('100%')
        .padding(14)
        .backgroundColor('#FFFFFF')
        .borderRadius(20)
        .border({ width: 1, color: '#E3E9F2', radius: 20 })
        .shadow({ radius: 10, color: 'rgba(15,27,45,0.06)', offsetX: 0, offsetY: 3 })
        .alignItems(VerticalAlign.Center)
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

@Preview({ title: 'Monitor View' })
@Component
struct MonitorViewPreview {
  build() {
    Column() {
      MonitorView({
        glucose: 5.5,
        riskIndex: 12,
        currentTime: '23:45:12',
        heartRate: 62,
        watchBattery: 86,
        tremorPSD: 0.12
      })
    }
    .backgroundColor('#EEF2F7')
  }
}
