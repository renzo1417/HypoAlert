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
      Column({ space: 12 }) {
        // Header with context
        Column({ space: 2 }) {
          Row() {
            Text('Guardian')
              .fontSize(PhoneTheme.FONT_TITLE)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.TEXT_PRIMARY)
              .layoutWeight(1)

            Text(this.guardianMasterEnabled ? 'Armed' : 'Paused')
              .fontSize(PhoneTheme.FONT_MICRO)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.guardianMasterEnabled ? PhoneTheme.STATE_OK_TEXT : PhoneTheme.TEXT_TERTIARY)
              .backgroundColor(this.guardianMasterEnabled ? PhoneTheme.STATE_OK_BG : PhoneTheme.BG_MUTED)
              .borderRadius(PhoneTheme.PILL_RADIUS)
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          Text('Night monitoring 22:00–06:00 • Alerts on')
            .fontSize(PhoneTheme.FONT_CAPTION)
            .fontColor(PhoneTheme.TEXT_MUTED)
            .width('100%')
        }
        .width('100%')
        .padding({ left: 2, right: 2, top: 2 })

        // 1. Night watch window
        Column({ space: 12 }) {
          Row() {
            Column({ space: 0 }) {
              Text('Night watch')
                .fontSize(PhoneTheme.FONT_SECTION)
                .fontWeight(FontWeight.Bold)
                .fontColor(PhoneTheme.TEXT_PRIMARY)
              Text(`${this.scheduleStartTime} – ${this.scheduleEndTime}`)
                .fontSize(PhoneTheme.FONT_CAPTION)
                .fontColor(PhoneTheme.TEXT_MUTED)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Toggle({ type: ToggleType.Switch, isOn: this.guardianMasterEnabled })
              .selectedColor(PhoneTheme.STATE_OK)
              .width(46)
              .height(26)
              .onChange((isOn: boolean) => {
                this.guardianMasterEnabled = isOn;
              })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Divider().color(PhoneTheme.BORDER_LIGHT).strokeWidth(1)

          Row() {
            Text('Adaptive baseline')
              .fontSize(PhoneTheme.FONT_BODY)
              .fontColor(PhoneTheme.TEXT_PRIMARY)
              .layoutWeight(1)

            Toggle({ type: ToggleType.Switch, isOn: this.adaptiveBaselineEnabled })
              .selectedColor(PhoneTheme.BRAND_ACCENT)
              .width(42)
              .height(24)
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

        // 2. Alerts + contact
        Column({ space: 12 }) {
          Row() {
            Text('Alerts')
              .fontSize(PhoneTheme.FONT_SECTION)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.TEXT_PRIMARY)
              .layoutWeight(1)

            Toggle({ type: ToggleType.Switch, isOn: this.smnEnabled })
              .selectedColor(PhoneTheme.BRAND_ACCENT)
              .width(46)
              .height(26)
              .onChange((isOn: boolean) => {
                this.smnEnabled = isOn;
                this.onToggleSmn(isOn);
              })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          // Contact row with initial + primary call
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
          .alignItems(VerticalAlign.Center)

          Divider().color(PhoneTheme.BORDER_LIGHT).strokeWidth(1)

          // Clear test action
          Row({ space: 10 }) {
            Button('Send test SMS')
              .fontSize(PhoneTheme.FONT_BODY)
              .fontWeight(FontWeight.Bold)
              .height(44)
              .layoutWeight(1)
              .backgroundColor(PhoneTheme.BG_CARD)
              .borderWidth(1)
              .borderColor(PhoneTheme.BORDER_SUBTLE)
              .fontColor(PhoneTheme.TEXT_PRIMARY)
              .borderRadius(PhoneTheme.TILE_RADIUS)
              .onClick(() => {
                this.onSendTestSmn();
              })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          if (this.smnLastSent.length > 0) {
            Text(`Last sent ${this.smnLastSent}`)
              .fontSize(PhoneTheme.FONT_CAPTION)
              .fontColor(PhoneTheme.TEXT_MUTED)
              .width('100%')
              .textAlign(TextAlign.End)
          }
        }
        .width('100%')
        .padding(PhoneTheme.CARD_PADDING)
        .backgroundColor(PhoneTheme.BG_CARD)
        .borderWidth(1)
        .borderColor(PhoneTheme.BORDER_SUBTLE)
        .borderRadius(PhoneTheme.CARD_RADIUS)
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
