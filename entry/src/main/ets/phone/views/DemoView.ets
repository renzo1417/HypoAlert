/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Screen 4: Clinical simulation and cross-device testing.
 * Clean, soft pastel interface for testing scenarios without developer clutter.
 */

import { riskLevel } from '../utils/PhoneRiskUtils';

@Component
export struct DemoView {
  @Prop glucose: number = 5.5;
  @Prop riskIndex: number = 12;
  @Prop heartRate: number = 62;
  @Prop tremorPSD: number = 0.12;
  @Prop skinTemp: number = 36.0;
  @Prop variability: number = 42;
  @Prop caregiverName: string = 'Maria Santos';
  @Prop caregiverPhone: string = '+63 917 123 4567';
  @Prop isWatchConnected: boolean = true;
  @Prop watchBattery: number = 86;
  @Prop deviceName: string = 'HUAWEI WATCH 4 Pro';
  onSimulateStable: () => void = () => {};
  onSimulatePreDrop: () => void = () => {};
  onSimulateCrisis: () => void = () => {};
  onMarkWithThem: () => void = () => {};
  onToggleWatchConnection: () => void = () => {};

  private isEmergency(): boolean {
    return riskLevel(this.riskIndex) === 'Critical';
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        // Screen Header
        Column({ space: 4 }) {
          Row() {
            Text('Simulation & Tools')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#111827')
            Blank()
            Text('Test Scenarios')
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor('#2563EB')
              .backgroundColor('#EFF6FF')
              .borderRadius(999)
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Text('Test emergency alert presets and wearable link')
            .fontSize(13)
            .fontColor('#64748B')
            .width('100%')
        }
        .width('100%')
        .padding({ left: 4, right: 4 })

        // Cross-Device Watch Connection (Clean Card)
        Column({ space: 12 }) {
          Row() {
            Row({ space: 8 }) {
              Circle({ width: 8, height: 8 })
                .fill(this.isWatchConnected ? '#22C55E' : '#F59E0B')
              Text('Wearable Link')
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor('#111827')
            }
            .alignItems(VerticalAlign.Center)

            Blank()

            Text(this.isWatchConnected ? 'Connected' : 'Offline')
              .fontSize(11)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.isWatchConnected ? '#15803D' : '#B45309')
              .backgroundColor(this.isWatchConnected ? '#DCFCE7' : '#FEF3C7')
              .borderRadius(999)
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Row({ space: 8 }) {
            Column({ space: 1 }) {
              Text(this.deviceName)
                .fontSize(13)
                .fontWeight(FontWeight.Bold)
                .fontColor('#111827')
              Text(this.isWatchConnected ? `Battery: ${this.watchBattery}% • Signal: Excellent` : 'Telemetry stream paused')
                .fontSize(11)
                .fontColor('#64748B')
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            Button(this.isWatchConnected ? 'Disconnect' : 'Connect')
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .height(34)
              .padding({ left: 14, right: 14 })
              .backgroundColor(this.isWatchConnected ? '#FEE2E2' : '#111827')
              .fontColor(this.isWatchConnected ? '#EF4444' : '#FFFFFF')
              .borderRadius(10)
              .onClick(() => {
                this.onToggleWatchConnection();
              })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .padding(12)
          .backgroundColor('#F8FAFC')
          .borderRadius(14)
        }
        .width('100%')
        .padding(18)
        .backgroundColor('#FFFFFF')
        .borderRadius(22)
        .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.04)', offsetY: 2 })

        // Dismiss action if currently in emergency
        if (this.isEmergency()) {
          Row({ space: 10 }) {
            Column({ space: 2 }) {
              Text('Emergency Active!')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor('#EF4444')
              Text('Alarm sounding • Tap when you are assisting')
                .fontSize(11)
                .fontColor('#64748B')
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Button("I'm with them")
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .height(36)
              .backgroundColor('#EF4444')
              .fontColor('#FFFFFF')
              .borderRadius(10)
              .onClick(() => {
                this.onMarkWithThem();
              })
          }
          .width('100%')
          .padding(14)
          .backgroundColor('#FEE2E2')
          .borderRadius(18)
        }

        // Clinical Scenario Presets (Soft Pastel Cards)
        Column({ space: 12 }) {
          Row() {
            Text('Quick Presets')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#111827')
            Blank()
            Text('Tap to simulate')
              .fontSize(11)
              .fontColor('#94A3B8')
          }
          .width('100%')

          // Preset 1: Stable
          Row({ space: 10 }) {
            Circle({ width: 10, height: 10 }).fill('#22C55E')
            Column({ space: 1 }) {
              Text('1. Stable Sleep (5.5 mmol/L)')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor('#15803D')
              Text('Normal resting vitals and calm sleep')
                .fontSize(11)
                .fontColor('#166534')
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
          }
          .width('100%')
          .padding(14)
          .backgroundColor('#DCFCE7')
          .borderRadius(14)
          .onClick(() => {
            this.onSimulateStable();
          })

          // Preset 2: Pre-Drop
          Row({ space: 10 }) {
            Circle({ width: 10, height: 10 }).fill('#F59E0B')
            Column({ space: 1 }) {
              Text('2. Impending Drop (4.2 mmol/L)')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor('#B45309')
              Text('Glucose trending down, restlessness rising')
                .fontSize(11)
                .fontColor('#92400E')
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
          }
          .width('100%')
          .padding(14)
          .backgroundColor('#FEF3C7')
          .borderRadius(14)
          .onClick(() => {
            this.onSimulatePreDrop();
          })

          // Preset 3: Crisis
          Row({ space: 10 }) {
            Circle({ width: 10, height: 10 }).fill('#EF4444')
            Column({ space: 1 }) {
              Text('3. Severe Emergency (3.1 mmol/L)')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor('#B91C1C')
              Text('Critical hypoglycemia, watch alarm & SMS alert')
                .fontSize(11)
                .fontColor('#991B1B')
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
          }
          .width('100%')
          .padding(14)
          .backgroundColor('#FEE2E2')
          .borderRadius(14)
          .onClick(() => {
            this.onSimulateCrisis();
          })
        }
        .width('100%')
        .padding(18)
        .backgroundColor('#FFFFFF')
        .borderRadius(22)
        .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.04)', offsetY: 2 })

        // Huawei Cloud SMN Status Card (Replaced messy raw JSON)
        Column({ space: 10 }) {
          Row({ space: 8 }) {
            Circle({ width: 6, height: 6 }).fill('#2563EB')
            Text('Huawei Cloud SMN Status')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor('#111827')
          }
          .width('100%')

          Row({ space: 8 }) {
            Text('SMS alerts armed for')
              .fontSize(12)
              .fontColor('#64748B')
            Text(this.caregiverPhone)
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor('#111827')
          }

          Text('Automatic priority dispatch triggers whenever glucose dips under 3.9 mmol/L.')
            .fontSize(11)
            .fontColor('#94A3B8')
            .width('100%')
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
