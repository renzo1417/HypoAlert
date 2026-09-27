/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Screen 3: Caregiver circle, emergency dispatch, and audit log.
 */

import { AuditEntry } from '../models/PhoneTypes';
import { riskLevel } from '../utils/PhoneRiskUtils';

@Component
export struct FamilyView {
  @Link caregiverName: string;
  @Link caregiverPhone: string;
  @Link smnEnabled: boolean;
  @Prop auditLog: AuditEntry[] = [];
  @Prop smnLastSent: string = '';
  @Prop riskIndex: number = 12;
  @Prop glucose: number = 5.5;
  onCallNow: () => void = () => {};
  onToggleSmn: (isOn: boolean) => void = () => {};
  onSendTestSmn: () => void = () => {};

  private isEmergency(): boolean {
    return riskLevel(this.riskIndex) === 'Critical';
  }

  private isWarning(): boolean {
    return riskLevel(this.riskIndex) === 'Warning';
  }

  private getCallButtonText(): string {
    if (this.isEmergency()) {
      return 'CALL CAREGIVER IMMEDIATELY';
    }
    if (this.isWarning()) {
      return 'Call Caregiver — Urgent Check';
    }
    return 'Call Caregiver';
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        // Header
        Column({ space: 4 }) {
          Row() {
            Column({ space: 2 }) {
              Text('EMERGENCY PROTOCOL')
                .fontSize(12)
                .fontWeight(FontWeight.Bold)
                .fontColor('#2E86DE')
                .letterSpacing(1)
              Text('Care Circle & Dispatch')
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor('#0F1B2D')
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Row({ space: 6 }) {
              Circle({ width: 9, height: 9 })
                .fill('#F6B8C1')
              Text('family')
                .fontSize(12)
                .fontColor('#8A94A6')
            }
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
            .border({ width: 1, color: '#E3E9F2', radius: 12 })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Text('Direct contact and Huawei Cloud SMN automated emergency dispatch for nighttime protection.')
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

        // Primary Call Action Card (Thumb zone high-priority)
        Column({ space: 8 }) {
          Button(this.getCallButtonText())
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .height(56)
            .width('100%')
            .backgroundColor(this.isEmergency() ? '#FF3B30' : '#2E86DE')
            .fontColor('#FFFFFF')
            .borderRadius(16)
            .shadow({
              radius: 12,
              color: this.isEmergency() ? 'rgba(255,59,48,0.35)' : 'rgba(46,134,222,0.30)',
              offsetX: 0,
              offsetY: 4
            })
            .onClick(() => {
              this.onCallNow();
            })

          Text(`Direct dial to ${this.caregiverName} (${this.caregiverPhone})`)
            .fontSize(12)
            .fontColor('#8A94A6')
            .width('100%')
            .textAlign(TextAlign.Center)
        }
        .width('100%')

        // Caregiver Contact Card
        Column({ space: 12 }) {
          Row() {
            Text('Primary Contact Information')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#0F1B2D')
            Blank()
            Text('Designated Responder')
              .fontSize(12)
              .fontColor('#8A94A6')
          }
          .width('100%')

          Column({ space: 4 }) {
            Text('Contact name')
              .fontSize(13)
              .fontColor('#8A94A6')
              .width('100%')
            TextInput({ text: this.caregiverName, placeholder: 'Family member name' })
              .width('100%')
              .height(48)
              .fontSize(14)
              .fontColor('#0F1B2D')
              .backgroundColor('#F1F5FA')
              .placeholderColor('#8A94A6')
              .border({ width: 1, color: '#E0E7F0', radius: 12 })
              .onChange((value: string) => {
                this.caregiverName = value;
              })
          }
          .width('100%')

          Column({ space: 4 }) {
            Text('Phone number')
              .fontSize(13)
              .fontColor('#8A94A6')
              .width('100%')
            TextInput({ text: this.caregiverPhone, placeholder: '+63 ...' })
              .width('100%')
              .height(48)
              .fontSize(14)
              .fontColor('#0F1B2D')
              .backgroundColor('#F1F5FA')
              .placeholderColor('#8A94A6')
              .border({ width: 1, color: '#E0E7F0', radius: 12 })
              .onChange((value: string) => {
                this.caregiverPhone = value;
              })
          }
          .width('100%')

          Text('This number receives high-priority phone notifications and automatic SMS alerts if nocturnal hypoglycemia is flagged.')
            .fontSize(12)
            .fontColor('#5B6B82')
            .width('100%')
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(22)
        .border({ width: 1, color: '#E3E9F2', radius: 22 })
        .shadow({ radius: 12, color: 'rgba(15,27,45,0.06)', offsetX: 0, offsetY: 4 })

        // Huawei Cloud SMN Emergency Dispatch Card
        Column({ space: 12 }) {
          Row() {
            Column({ space: 2 }) {
              Text('Huawei Cloud SMN Dispatch')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#0F1B2D')
              Text('Simple Message Notification Service')
                .fontSize(12)
                .fontColor('#8A94A6')
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Text(this.smnEnabled ? 'Armed' : 'Paused')
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.smnEnabled ? '#34C759' : '#8A94A6')
              .backgroundColor(this.smnEnabled ? '#E9F7EF' : '#F1F5FA')
              .borderRadius(12)
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Row({ space: 10 }) {
            Column({ space: 2 }) {
              Text('Text family in emergency')
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor('#0F1B2D')
              Text('Texts family automatically in emergency')
                .fontSize(13)
                .fontColor('#8A94A6')
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Toggle({ type: ToggleType.Switch, isOn: this.smnEnabled })
              .width(52)
              .height(32)
              .selectedColor('#2E86DE')
              .switchPointColor('#FFFFFF')
              .onChange((isOn: boolean) => {
                this.smnEnabled = isOn;
                this.onToggleSmn(isOn);
              })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Column({ space: 6 }) {
            Row() {
              Text('Trigger: Critical Hypoglycemia (< 3.9 mmol/L)')
                .fontSize(12)
                .fontColor('#5B6B82')
              Blank()
              Text('SMS')
                .fontSize(11)
                .fontWeight(FontWeight.Bold)
                .fontColor('#2E86DE')
            }
            .width('100%')

            Row() {
              Text('Last Dispatch:')
                .fontSize(12)
                .fontColor('#8A94A6')
              Blank()
              Text(this.smnLastSent.length > 0 ? this.smnLastSent : 'None tonight')
                .fontSize(12)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.smnLastSent.length > 0 ? '#FF3B30' : '#8A94A6')
            }
            .width('100%')
          }
          .width('100%')
          .padding(12)
          .backgroundColor('#F4F7FB')
          .borderRadius(14)

          Button('Test SMS Notification Ping')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .height(40)
            .width('100%')
            .backgroundColor('#FFFFFF')
            .fontColor('#2E86DE')
            .border({ width: 1, color: '#2E86DE', radius: 10 })
            .onClick(() => {
              this.onSendTestSmn();
            })
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(22)
        .border({ width: 1, color: '#E3E9F2', radius: 22 })
        .shadow({ radius: 12, color: 'rgba(15,27,45,0.06)', offsetX: 0, offsetY: 4 })

        // Recent Updates & Audit Trail Card
        Column({ space: 10 }) {
          Row() {
            Text('Recent updates')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#0F1B2D')
            Blank()
            Text(`${this.auditLog.length} events logged`)
              .fontSize(12)
              .fontColor('#8A94A6')
          }
          .width('100%')

          Column({ space: 6 }) {
            ForEach(this.auditLog, (entry: AuditEntry) => {
              Row({ space: 8 }) {
                Circle({ width: 8, height: 8 })
                  .fill(
                    entry.level === 'crit'
                      ? '#FF3B30'
                      : (entry.level === 'warn' ? '#FF9500' : (entry.level === 'ok' ? '#34C759' : '#2E86DE'))
                  )
                  .margin({ top: 6 })

                Text(entry.time)
                  .fontSize(13)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#8A94A6')
                  .width(44)

                Text(entry.message)
                  .fontSize(14)
                  .fontColor('#0F1B2D')
                  .layoutWeight(1)
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width('100%')
              .padding(10)
              .backgroundColor('#F4F7FB')
              .borderRadius(10)
              .alignItems(VerticalAlign.Top)
            }, (entry: AuditEntry, index: number) => `${index}_${entry.time}_${entry.level}`)
          }
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

@Preview({ title: 'Family View' })
@Component
struct FamilyViewPreview {
  @State caregiverName: string = 'Maria Santos';
  @State caregiverPhone: string = '+63 917 123 4567';
  @State smnEnabled: boolean = true;
  @State auditLog: AuditEntry[] = [
    { time: '23:00', message: 'Set up finished — all good', level: 'ok' },
    { time: '02:15', message: 'Small movement noticed — all okay', level: 'warn' },
    { time: '03:15', message: 'Emergency — alarm ringing, family texted', level: 'crit' }
  ];

  build() {
    Column() {
      FamilyView({
        caregiverName: $caregiverName,
        caregiverPhone: $caregiverPhone,
        smnEnabled: $smnEnabled,
        auditLog: this.auditLog,
        riskIndex: 12,
        glucose: 5.5
      })
    }
    .backgroundColor('#EEF2F7')
  }
}
