/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Caregiver contact management, emergency dispatch toggle, and audit log.
 */

import { AuditEntry } from '../models/PhoneTypes';

@Component
export struct PhoneCaregiverCard {
  @Link caregiverName: string;
  @Link caregiverPhone: string;
  @Link smnEnabled: boolean;
  @Prop auditLog: AuditEntry[] = [];
  onCallNow: () => void = () => {};
  onToggleSmn: (isOn: boolean) => void = () => {};

  build() {
    Column({ space: 12 }) {
      Row({ space: 8 }) {
        Text('Caregiver')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#0F1B2D')
          .layoutWeight(1)

        Circle({ width: 9, height: 9 })
          .fill('#F6B8C1')
        Text('family')
          .fontSize(12)
          .fontColor('#8A94A6')
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Button('Call now')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .height(56)
        .width('100%')
        .backgroundColor('#2E86DE')
        .fontColor('#FFFFFF')
        .borderRadius(16)
        .onClick(() => {
          this.onCallNow();
        })

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

      Row({ space: 10 }) {
        Column({ space: 2 }) {
          Text('Text family in emergency')
            .fontSize(14)
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
      .padding({ top: 4, bottom: 4 })

      Divider().color('#E3E9F2').strokeWidth(1)

      Text('Recent updates')
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor('#8A94A6')
        .width('100%')

      Column({ space: 6 }) {
        ForEach(this.auditLog, (entry: AuditEntry) => {
          Row({ space: 8 }) {
            Text(entry.time)
              .fontSize(13)
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
    .shadow({ radius: 14, color: 'rgba(15,27,45,0.08)', offsetX: 0, offsetY: 6 })
  }
}

@Preview({ title: 'Phone Caregiver Card' })
@Component
struct PhoneCaregiverCardPreview {
  @State caregiverName: string = 'Maria Santos';
  @State caregiverPhone: string = '+63 917 123 4567';
  @State smnEnabled: boolean = true;
  @State auditLog: AuditEntry[] = [
    { time: '23:00', message: 'Set up finished — all good', level: 'ok' },
    { time: '02:15', message: 'Small movement noticed — all okay', level: 'warn' }
  ];

  build() {
    Column() {
      PhoneCaregiverCard({
        caregiverName: $caregiverName,
        caregiverPhone: $caregiverPhone,
        smnEnabled: $smnEnabled,
        auditLog: this.auditLog
      })
    }
    .padding(16)
    .backgroundColor('#EEF2F7')
  }
}
