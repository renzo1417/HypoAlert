/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Screen 4: Interactive clinical simulation and telemetry diagnostics.
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
  onSimulateStable: () => void = () => {};
  onSimulatePreDrop: () => void = () => {};
  onSimulateCrisis: () => void = () => {};
  onMarkWithThem: () => void = () => {};

  private isEmergency(): boolean {
    return riskLevel(this.riskIndex) === 'Critical';
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        // Header
        Column({ space: 4 }) {
          Row() {
            Column({ space: 2 }) {
              Text('CLINICAL SIMULATION')
                .fontSize(12)
                .fontWeight(FontWeight.Bold)
                .fontColor('#2E86DE')
                .letterSpacing(1)
              Text('Simulation & Diagnostics')
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor('#0F1B2D')
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Text('Demo Hub')
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor('#2E86DE')
              .backgroundColor('#E7F0FE')
              .borderRadius(12)
              .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Text('Trigger clinical hypoglycemia presets to verify reactive alerts, phone navigation, and SMN dispatches.')
            .fontSize(13)
            .fontColor('#5B6B82')
            .width('100%')
        }
        .width('100%')
        .padding(18)
        .backgroundColor('#FFFFFF')
        .borderRadius(22)
        .border({ width: 1, color: '#E3E9F2', radius: 22 })
        .shadow({ radius: 12, color: 'rgba(15,27,45,0.06)', offsetX: 0, offsetY: 4 })

        // Dismiss action if currently in emergency
        if (this.isEmergency()) {
          Row({ space: 10 }) {
            Column({ space: 2 }) {
              Text('Emergency Alert Active!')
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FF3B30')
              Text('Alarm ringing • Tap to confirm you are assisting')
                .fontSize(12)
                .fontColor('#5B6B82')
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Button("I'm with them")
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .height(44)
              .backgroundColor('#FF3B30')
              .fontColor('#FFFFFF')
              .borderRadius(12)
              .onClick(() => {
                this.onMarkWithThem();
              })
          }
          .width('100%')
          .padding(14)
          .backgroundColor('#FFF1F0')
          .borderRadius(16)
          .border({ width: 1, color: '#FF3B30', radius: 16 })
        }

        // Scenario Preset Buttons
        Column({ space: 12 }) {
          Row() {
            Text('Clinical Scenario Presets')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#0F1B2D')
            Blank()
            Text('3 Presets')
              .fontSize(12)
              .fontColor('#8A94A6')
          }
          .width('100%')

          // Preset 1: Stable
          Button('Stable 5.5 — all clear')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .height(52)
            .width('100%')
            .backgroundColor('#E9F7EF')
            .fontColor('#1E7E34')
            .border({ width: 1.5, color: '#34C759', radius: 14 })
            .onClick(() => {
              this.onSimulateStable();
            })

          Text('Calm sleep, normal glucose 5.5 mmol/L, tremor PSD 0.12, HR 62 bpm. Steady guardian status.')
            .fontSize(12)
            .fontColor('#5B6B82')
            .width('100%')
            .margin({ top: -4, bottom: 4 })

          // Preset 2: Pre-Drop
          Button('Pre-Drop 4.2 — falling')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .height(52)
            .width('100%')
            .backgroundColor('#FFF4E5')
            .fontColor('#B25E09')
            .border({ width: 1.5, color: '#FF9500', radius: 14 })
            .onClick(() => {
              this.onSimulatePreDrop();
            })

          Text('Impending nocturnal drop to 4.2 mmol/L. Autonomic restlessness rising (PSD 0.85), HR 78 bpm.')
            .fontSize(12)
            .fontColor('#5B6B82')
            .width('100%')
            .margin({ top: -4, bottom: 4 })

          // Preset 3: Crisis
          Button('Crisis 3.1 — emergency + alarm')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .height(52)
            .width('100%')
            .backgroundColor('#FF3B30')
            .fontColor('#FFFFFF')
            .borderRadius(14)
            .shadow({ radius: 10, color: 'rgba(255,59,48,0.30)', offsetX: 0, offsetY: 4 })
            .onClick(() => {
              this.onSimulateCrisis();
            })

          Text('Crisis 3.1 mmol/L triggers wearable buzzer, flashes hero card red, and sends SMN emergency text.')
            .fontSize(12)
            .fontColor('#5B6B82')
            .width('100%')
            .margin({ top: -4, bottom: 4 })
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(22)
        .border({ width: 1, color: '#E3E9F2', radius: 22 })
        .shadow({ radius: 12, color: 'rgba(15,27,45,0.06)', offsetX: 0, offsetY: 4 })

        // Live Multi-Sensor Telemetry Breakdown
        Column({ space: 12 }) {
          Row() {
            Text('Live Sensor Telemetry')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#0F1B2D')
            Blank()
            Text('Dynamic Fusion')
              .fontSize(12)
              .fontColor('#8A94A6')
          }
          .width('100%')

          Row({ space: 10 }) {
            // Heart Rate
            Column({ space: 2 }) {
              Text('PULSE')
                .fontSize(11)
                .fontWeight(FontWeight.Bold)
                .fontColor('#8A94A6')
              Text(`${this.heartRate}`)
                .fontSize(22)
                .fontWeight(FontWeight.Bolder)
                .fontColor('#0F1B2D')
              Text('bpm (PPG)')
                .fontSize(11)
                .fontColor('#8A94A6')
            }
            .layoutWeight(1)
            .padding(12)
            .backgroundColor('#F4F7FB')
            .borderRadius(14)
            .alignItems(HorizontalAlign.Start)

            // Tremor PSD
            Column({ space: 2 }) {
              Text('TREMOR')
                .fontSize(11)
                .fontWeight(FontWeight.Bold)
                .fontColor('#8A94A6')
              Text(`${this.tremorPSD.toFixed(2)}`)
                .fontSize(22)
                .fontWeight(FontWeight.Bolder)
                .fontColor('#0F1B2D')
              Text('PSD (m/s²)')
                .fontSize(11)
                .fontColor('#8A94A6')
            }
            .layoutWeight(1)
            .padding(12)
            .backgroundColor('#F4F7FB')
            .borderRadius(14)
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')

          Row({ space: 10 }) {
            // Skin Temp
            Column({ space: 2 }) {
              Text('SKIN TEMP')
                .fontSize(11)
                .fontWeight(FontWeight.Bold)
                .fontColor('#8A94A6')
              Text(`${this.skinTemp.toFixed(1)}°C`)
                .fontSize(22)
                .fontWeight(FontWeight.Bolder)
                .fontColor('#0F1B2D')
              Text('Peripheral')
                .fontSize(11)
                .fontColor('#8A94A6')
            }
            .layoutWeight(1)
            .padding(12)
            .backgroundColor('#F4F7FB')
            .borderRadius(14)
            .alignItems(HorizontalAlign.Start)

            // Risk Score
            Column({ space: 2 }) {
              Text('RISK SCORE')
                .fontSize(11)
                .fontWeight(FontWeight.Bold)
                .fontColor('#8A94A6')
              Text(`${this.riskIndex}`)
                .fontSize(22)
                .fontWeight(FontWeight.Bolder)
                .fontColor(this.riskIndex > 70 ? '#FF3B30' : (this.riskIndex >= 30 ? '#FF9500' : '#34C759'))
              Text('of 100')
                .fontSize(11)
                .fontColor('#8A94A6')
            }
            .layoutWeight(1)
            .padding(12)
            .backgroundColor('#F4F7FB')
            .borderRadius(14)
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(22)
        .border({ width: 1, color: '#E3E9F2', radius: 22 })
        .shadow({ radius: 12, color: 'rgba(15,27,45,0.06)', offsetX: 0, offsetY: 4 })

        // Huawei Cloud SMN Payload Preview
        Column({ space: 10 }) {
          Row({ space: 6 }) {
            Circle({ width: 7, height: 7 }).fill('#2E86DE')
            Text('Huawei Cloud SMN Emergency Payload Preview')
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor('#0F1B2D')
          }
          .width('100%')

          Column({ space: 4 }) {
            Text('{\n  "service": "HuaweiCloud.SMN",\n  "topic": "urn:smn:hypoalert:emergency",\n  "urgency": "CRITICAL",\n  "recipient": "' + this.caregiverPhone + '",\n  "caregiver": "' + this.caregiverName + '",\n  "glucose": ' + this.glucose.toFixed(1) + ',\n  "heartRate": ' + this.heartRate + ',\n  "tremorPSD": ' + this.tremorPSD.toFixed(2) + ',\n  "riskIndex": ' + this.riskIndex + '\n}')
              .fontSize(12)
              .fontColor('#0F1B2D')
              .fontFamily('HarmonyOS Sans')
              .width('100%')
          }
          .width('100%')
          .padding(14)
          .backgroundColor('#F1F5FA')
          .borderRadius(14)
          .border({ width: 1, color: '#E0E7F0', radius: 14 })

          Text('In production, this encrypted JSON is published via REST API to Huawei Cloud Simple Message Notification service.')
            .fontSize(12)
            .fontColor('#8A94A6')
            .width('100%')
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(22)
        .border({ width: 1, color: '#E3E9F2', radius: 22 })
        .shadow({ radius: 12, color: 'rgba(15,27,45,0.06)', offsetX: 0, offsetY: 4 })
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

@Preview({ title: 'Demo View' })
@Component
struct DemoViewPreview {
  build() {
    Column() {
      DemoView({
        glucose: 5.5,
        riskIndex: 12,
        heartRate: 62,
        tremorPSD: 0.12,
        skinTemp: 36.0,
        variability: 42
      })
    }
    .backgroundColor('#EEF2F7')
  }
}
