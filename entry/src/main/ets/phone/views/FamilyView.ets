/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Screen 3: Guardian Settings & Emergency Dispatch.
 * Bedside monitoring schedule, adaptive baseline calibration, Huawei Cloud SMN dispatch, and caregiver contacts.
 */

import { EmergencyContact, HistoryRepository } from '../../models/HistoryModel';
import { riskLevel } from '../utils/PhoneRiskUtils';
import { PhoneTheme } from '../utils/PhoneTheme';

@Component
export struct FamilyView {
  @Link caregiverName: string;
  @Link caregiverPhone: string;
  @Link smnEnabled: boolean;
  @Prop smnLastSent: string = '';
  @Prop riskIndex: number = 12;
  @Prop glucose: number = 5.5;
  @State guardianMasterEnabled: boolean = true;
  @State adaptiveBaselineEnabled: boolean = true;
  @State scheduleStartTime: string = '22:00';
  @State scheduleEndTime: string = '06:00';
  @State contactsList: EmergencyContact[] = [];
  onCallNow: () => void = () => {};
  onToggleSmn: (isOn: boolean) => void = () => {};
  onSendTestSmn: () => void = () => {};

  aboutToAppear(): void {
    this.contactsList = HistoryRepository.getContacts();
  }

  private isEmergency(): boolean {
    return riskLevel(this.riskIndex) === 'Critical';
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        // Screen Header
        Row() {
          Column({ space: 1 }) {
            Text('Guardian Settings')
              .fontSize(PhoneTheme.FONT_TITLE)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.TEXT_PRIMARY)
            Text('Bedtime monitoring and automated caregiver dispatch')
              .fontSize(PhoneTheme.FONT_CAPTION)
              .fontColor(PhoneTheme.TEXT_MUTED)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Text(this.guardianMasterEnabled ? 'ARMED' : 'PAUSED')
            .fontSize(PhoneTheme.FONT_MICRO)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.guardianMasterEnabled ? PhoneTheme.STATE_OK_TEXT : PhoneTheme.TEXT_TERTIARY)
            .backgroundColor(this.guardianMasterEnabled ? PhoneTheme.STATE_OK_BG : PhoneTheme.BG_MUTED)
            .borderRadius(PhoneTheme.PILL_RADIUS)
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
        }
        .width('100%')
        .padding({ left: 2, right: 2, top: 2 })

        // 1. Bedtime Schedule & Baseline Calibration
        Column({ space: 12 }) {
          // Master switch
          Row() {
            Column({ space: 2 }) {
              Text('Nocturnal Monitoring Window')
                .fontSize(PhoneTheme.FONT_SECTION)
                .fontWeight(FontWeight.Bold)
                .fontColor(PhoneTheme.TEXT_PRIMARY)
              Text(`${this.scheduleStartTime} – ${this.scheduleEndTime} • Auto-activates on sleep`)
                .fontSize(PhoneTheme.FONT_CAPTION)
                .fontColor(PhoneTheme.TEXT_MUTED)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Toggle({ type: ToggleType.Switch, isOn: this.guardianMasterEnabled })
              .selectedColor(PhoneTheme.STATE_OK)
              .width(42)
              .height(24)
              .onChange((isOn: boolean) => {
                this.guardianMasterEnabled = isOn;
              })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Divider().color(PhoneTheme.BORDER_LIGHT).strokeWidth(1)

          // Adaptive baseline switch (Core Technical Feature from Concept!)
          Row() {
            Column({ space: 2 }) {
              Text('Adaptive Nightly Baseline')
                .fontSize(PhoneTheme.FONT_BODY)
                .fontWeight(FontWeight.Bold)
                .fontColor(PhoneTheme.TEXT_PRIMARY)
              Text('Calibrates individual resting tone in first 30m of sleep')
                .fontSize(PhoneTheme.FONT_MICRO)
                .fontColor(PhoneTheme.TEXT_MUTED)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Toggle({ type: ToggleType.Switch, isOn: this.adaptiveBaselineEnabled })
              .selectedColor(PhoneTheme.BRAND_ACCENT)
              .width(38)
              .height(22)
              .onChange((isOn: boolean) => {
                this.adaptiveBaselineEnabled = isOn;
              })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .padding(PhoneTheme.CARD_PADDING)
        .backgroundColor(PhoneTheme.BG_CARD)
        .borderWidth(1)
        .borderColor(PhoneTheme.BORDER_SUBTLE)
        .borderRadius(PhoneTheme.CARD_RADIUS)
        .shadow({ radius: 8, color: 'rgba(15, 23, 42, 0.04)', offsetY: 2 })

        // 2. Emergency Dispatch (Huawei Cloud SMN)
        Column({ space: 12 }) {
          Row() {
            Column({ space: 1 }) {
              Text('Emergency Dispatch (SMN)')
                .fontSize(PhoneTheme.FONT_SECTION)
                .fontWeight(FontWeight.Bold)
                .fontColor(PhoneTheme.TEXT_PRIMARY)
              Text('Automated SMS & voice alerts for critical drops (< 3.9)')
                .fontSize(PhoneTheme.FONT_CAPTION)
                .fontColor(PhoneTheme.TEXT_MUTED)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Toggle({ type: ToggleType.Switch, isOn: this.smnEnabled })
              .selectedColor(PhoneTheme.BRAND_ACCENT)
              .width(42)
              .height(24)
              .onChange((isOn: boolean) => {
                this.smnEnabled = isOn;
                this.onToggleSmn(isOn);
              })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          // Primary Contact Card
          Row({ space: 10 }) {
            Stack({ alignContent: Alignment.Center }) {
              Circle({ width: 34, height: 34 })
                .fill(PhoneTheme.BRAND_ACCENT_BG)
              Text(this.caregiverName.length > 0 ? this.caregiverName.substring(0, 1) : 'C')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor(PhoneTheme.BRAND_ACCENT)
            }
            .width(34)
            .height(34)

            Column({ space: 1 }) {
              Row() {
                Text(this.caregiverName)
                  .fontSize(PhoneTheme.FONT_BODY)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(PhoneTheme.TEXT_PRIMARY)
                Text('PRIMARY')
                  .fontSize(PhoneTheme.FONT_MICRO)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(PhoneTheme.BRAND_ACCENT)
                  .backgroundColor(PhoneTheme.BRAND_ACCENT_BG)
                  .borderRadius(3)
                  .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                  .margin({ left: 6 })
              }

              Text(`Primary Caregiver • ${this.caregiverPhone}`)
                .fontSize(PhoneTheme.FONT_CAPTION)
                .fontColor(PhoneTheme.TEXT_MUTED)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            Button('Call')
              .fontSize(PhoneTheme.FONT_MICRO)
              .fontWeight(FontWeight.Bold)
              .height(28)
              .padding({ left: 10, right: 10 })
              .backgroundColor(PhoneTheme.BG_CARD)
              .borderWidth(1)
              .borderColor(PhoneTheme.BORDER_SUBTLE)
              .fontColor(PhoneTheme.BRAND_PRIMARY)
              .borderRadius(PhoneTheme.TILE_RADIUS)
              .onClick(() => {
                this.onCallNow();
              })
          }
          .width('100%')
          .padding(10)
          .backgroundColor(PhoneTheme.BG_PAGE)
          .borderRadius(PhoneTheme.TILE_RADIUS)
          .alignItems(VerticalAlign.Center)

          // Test Dispatch Button
          Row({ space: 8 }) {
            Button('Send Test Alert')
              .fontSize(PhoneTheme.FONT_BODY)
              .fontWeight(FontWeight.Bold)
              .height(32)
              .padding({ left: 12, right: 12 })
              .backgroundColor(PhoneTheme.BG_MUTED)
              .fontColor(PhoneTheme.TEXT_PRIMARY)
              .borderRadius(PhoneTheme.TILE_RADIUS)
              .onClick(() => {
                this.onSendTestSmn();
              })

            if (this.smnLastSent.length > 0) {
              Text(`Dispatched: ${this.smnLastSent}`)
                .fontSize(PhoneTheme.FONT_MICRO)
                .fontColor(PhoneTheme.TEXT_TERTIARY)
                .layoutWeight(1)
                .textAlign(TextAlign.End)
            }
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .padding(PhoneTheme.CARD_PADDING)
        .backgroundColor(PhoneTheme.BG_CARD)
        .borderWidth(1)
        .borderColor(PhoneTheme.BORDER_SUBTLE)
        .borderRadius(PhoneTheme.CARD_RADIUS)
        .shadow({ radius: 8, color: 'rgba(15, 23, 42, 0.04)', offsetY: 2 })

        // 3. Bedside Auditory Wake-up Alarm
        Column({ space: 8 }) {
          Row() {
            Column({ space: 1 }) {
              Text('Bedside Siren')
                .fontSize(PhoneTheme.FONT_SECTION)
                .fontWeight(FontWeight.Bold)
                .fontColor(PhoneTheme.TEXT_PRIMARY)
              Text('Sounds loud audio alarm if wrist vibrations fail to awaken')
                .fontSize(PhoneTheme.FONT_CAPTION)
                .fontColor(PhoneTheme.TEXT_MUTED)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Text('85 dB (High)')
              .fontSize(PhoneTheme.FONT_CAPTION)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.BRAND_PRIMARY)
              .backgroundColor(PhoneTheme.BG_MUTED)
              .borderRadius(PhoneTheme.PILL_RADIUS)
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .padding(PhoneTheme.CARD_PADDING)
        .backgroundColor(PhoneTheme.BG_CARD)
        .borderWidth(1)
        .borderColor(PhoneTheme.BORDER_SUBTLE)
        .borderRadius(PhoneTheme.CARD_RADIUS)
        .shadow({ radius: 8, color: 'rgba(15, 23, 42, 0.04)', offsetY: 2 })
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
