/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Screen 1: Serene, minimalist nocturnal health dashboard.
 * Modeled after the reference health monitoring mobile UI.
 */

import { PhoneHeroCard } from '../components/PhoneHeroCard';
import { PhoneMetricGrid } from '../components/PhoneMetricGrid';
import { PhoneCaregiverCard } from '../components/PhoneCaregiverCard';

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
      Column({ space: 16 }) {
        // Watch offline reminder (minimalist soft card)
        if (!this.isWatchConnected) {
          Row({ space: 10 }) {
            Circle({ width: 8, height: 8 })
              .fill('#F59E0B')
            Column({ space: 1 }) {
              Text('Wearable Disconnected')
                .fontSize(13)
                .fontWeight(FontWeight.Bold)
                .fontColor('#111827')
              Text('Tap to link demo watch stream')
                .fontSize(11)
                .fontColor('#64748B')
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Button('Connect')
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .height(32)
              .padding({ left: 14, right: 14 })
              .backgroundColor('#111827')
              .fontColor('#FFFFFF')
              .borderRadius(16)
              .onClick(() => {
                this.onConnectWatch();
              })
          }
          .width('100%')
          .padding({ left: 14, right: 14, top: 10, bottom: 10 })
          .backgroundColor('#FFFBEB')
          .borderRadius(18)
          .alignItems(VerticalAlign.Center)
        }

        // Clinical Header: Nocturnal Hypoglycemia Guardian
        Row() {
          Column({ space: 2 }) {
            Row({ space: 8 }) {
              Text('Nocturnal Guardian')
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor('#111827')

              // Pulse radar indicator
              Row({ space: 4 }) {
                Circle({ width: 6, height: 6 })
                  .fill(this.isWatchConnected ? '#10B981' : '#F59E0B')
                Text(this.isWatchConnected ? 'ARMED' : 'OFFLINE')
                  .fontSize(10)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.isWatchConnected ? '#15803D' : '#B45309')
              }
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
              .backgroundColor(this.isWatchConnected ? '#DCFCE7' : '#FEF3C7')
              .borderRadius(999)
            }
            .alignItems(VerticalAlign.Center)

            Text('Non-invasive sympathetic surge early warning system')
              .fontSize(12)
              .fontColor('#64748B')
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')
        .padding({ left: 4, right: 4, top: 2 })

        // Hero Card (Glucose & Nocturnal State)
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

        // Vitals Section Header
        Row() {
          Text('Vitals at a glance')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#111827')
          Blank()
          Text(this.isWatchConnected ? 'Live stream •' : 'Paused')
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.isWatchConnected ? '#15803D' : '#94A3B8')
        }
        .width('100%')
        .padding({ left: 4, right: 4, top: 4 })

        // 2x2 Bento Metric Grid (Heart Rate, Sleep Motion, Temp, Stability)
        PhoneMetricGrid({
          heartRate: this.heartRate,
          tremorPSD: this.tremorPSD,
          skinTemp: this.skinTemp,
          riskIndex: this.riskIndex,
          ppgContext: this.ppgContext,
          onCanvasReady: this.onCanvasReady
        })

        // Caregiver Contact Card (Matching reference design doctor card)
        PhoneCaregiverCard({
          caregiverName: this.caregiverName,
          caregiverRole: 'Primary Caregiver',
          caregiverPhone: this.caregiverPhone,
          isEmergency: this.riskIndex > 70,
          onCall: this.onCallNow,
          onMessage: () => {
            this.onNavigateTab(2); // Jump to Care Circle / Family tab
          }
        })
        .margin({ top: 4, bottom: 20 })
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
