/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Screen 3: Guardian Feature Activation, Care Circle & Emergency Dispatch Settings.
 * Centralized configuration for bedtime monitoring, X emergency contacts, and automated alerts.
 */

import { AuditEntry } from '../models/PhoneTypes';
import { EmergencyContact, HistoryRepository } from '../../models/HistoryModel';
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
  @State guardianMasterEnabled: boolean = true;
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

  private isWarning(): boolean {
    return riskLevel(this.riskIndex) === 'Warning';
  }

  private getCallButtonText(): string {
    if (this.isEmergency()) {
      return `CALL ${this.caregiverName.toUpperCase()} NOW`;
    }
    if (this.isWarning()) {
      return `Call ${this.caregiverName} — Alert Check`;
    }
    return `Call ${this.caregiverName}`;
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        // Screen Header
        Column({ space: 4 }) {
          Row() {
            Text('Guardian Settings')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#111827')
            Blank()
            Text(this.guardianMasterEnabled ? 'ARMED' : 'PAUSED')
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.guardianMasterEnabled ? '#15803D' : '#94A3B8')
              .backgroundColor(this.guardianMasterEnabled ? '#DCFCE7' : '#F1F5F9')
              .borderRadius(999)
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Text('Nocturnal monitoring activation, emergency contacts & alerts')
            .fontSize(13)
            .fontColor('#64748B')
            .width('100%')
        }
        .width('100%')
        .padding({ left: 4, right: 4 })

        // ==========================================
        // 1. MASTER FEATURE ACTIVATION CARD
        // ==========================================
        Column({ space: 12 }) {
          Row() {
            Column({ space: 2 }) {
              Text('Night Guardian Feature')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#111827')
              Text(this.guardianMasterEnabled ? 'Actively monitoring biometric streams' : 'Monitoring paused by user')
                .fontSize(12)
                .fontColor(this.guardianMasterEnabled ? '#15803D' : '#64748B')
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Toggle({ type: ToggleType.Switch, isOn: this.guardianMasterEnabled })
              .selectedColor('#10B981')
              .width(44)
              .height(24)
              .onChange((isOn: boolean) => {
                this.guardianMasterEnabled = isOn;
              })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Divider().color('#F1F5F9').strokeWidth(1)

          // Schedule window row
          Row({ space: 12 }) {
            Column({ space: 2 }) {
              Text('MONITORING SCHEDULE')
                .fontSize(10)
                .fontWeight(FontWeight.Bold)
                .fontColor('#94A3B8')
              Text(`${this.scheduleStartTime} – ${this.scheduleEndTime}`)
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor('#111827')
              Text('Every night • Auto-engages during sleep')
                .fontSize(11)
                .fontColor('#64748B')
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            Row({ space: 4 }) {
              Circle({ width: 6, height: 6 }).fill('#2563EB')
              Text('Synced to Watch')
                .fontSize(11)
                .fontWeight(FontWeight.Medium)
                .fontColor('#2563EB')
            }
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor('#EFF6FF')
            .borderRadius(999)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .padding(18)
        .backgroundColor('#FFFFFF')
        .borderRadius(22)
        .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.04)', offsetY: 2 })

        // Primary Call Button (High priority thumb zone)
        Button(this.getCallButtonText())
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .height(48)
          .width('100%')
          .backgroundColor(this.isEmergency() ? '#EF4444' : '#111827')
          .fontColor('#FFFFFF')
          .borderRadius(16)
          .shadow({ radius: 8, color: this.isEmergency() ? 'rgba(239,68,68,0.25)' : 'rgba(0,0,0,0.08)', offsetY: 2 })
          .onClick(() => {
            this.onCallNow();
          })

        // ==========================================
        // 2. EMERGENCY CONTACTS CIRCLE (X PEOPLE)
        // ==========================================
        Column({ space: 14 }) {
          Row() {
            Column({ space: 2 }) {
              Text('Emergency Contacts Circle')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#111827')
              Text('Notified via automated SMS & calls upon critical drop')
                .fontSize(12)
                .fontColor('#64748B')
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Text(`${this.contactsList.length} Contacts`)
              .fontSize(11)
              .fontWeight(FontWeight.Medium)
              .fontColor('#2563EB')
              .backgroundColor('#EFF6FF')
              .borderRadius(999)
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          }
          .width('100%')

          // Contact Cards List
          Column({ space: 8 }) {
            ForEach(this.contactsList, (contact: EmergencyContact) => {
              Row({ space: 10 }) {
                Stack({ alignContent: Alignment.Center }) {
                  Circle({ width: 36, height: 36 })
                    .fill(contact.isPrimary ? '#DBEAFE' : '#F1F5F9')
                  Text(contact.isPrimary ? '⭐' : '👤')
                    .fontSize(14)
                }
                .width(36)
                .height(36)

                Column({ space: 2 }) {
                  Row() {
                    Text(contact.name)
                      .fontSize(14)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#111827')
                    if (contact.isPrimary) {
                      Text('PRIMARY')
                        .fontSize(9)
                        .fontWeight(FontWeight.Bold)
                        .fontColor('#2563EB')
                        .backgroundColor('#EFF6FF')
                        .borderRadius(4)
                        .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                        .margin({ left: 6 })
                    }
                  }

                  Text(`${contact.relation} • ${contact.phone}`)
                    .fontSize(12)
                    .fontColor('#64748B')
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)

                // Individual SMS alert badge
                Row({ space: 3 }) {
                  Circle({ width: 5, height: 5 })
                    .fill(contact.smnEnabled ? '#10B981' : '#94A3B8')
                  Text(contact.smnEnabled ? 'SMS On' : 'Muted')
                    .fontSize(10)
                    .fontColor(contact.smnEnabled ? '#15803D' : '#94A3B8')
                }
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .backgroundColor(contact.smnEnabled ? '#DCFCE7' : '#F1F5F9')
                .borderRadius(6)
              }
              .width('100%')
              .padding(12)
              .backgroundColor('#F8FAFC')
              .borderRadius(14)
              .alignItems(VerticalAlign.Center)
            })
          }
          .width('100%')

          // Editable Primary Caregiver Inputs
          Column({ space: 10 }) {
            Text('Quick Edit Primary Contact')
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor('#475569')
              .width('100%')

            TextInput({ text: this.caregiverName, placeholder: 'Primary Caregiver Name' })
              .width('100%')
              .height(42)
              .fontSize(13)
              .fontColor('#111827')
              .backgroundColor('#F8FAFC')
              .borderRadius(10)
              .onChange((val: string) => {
                this.caregiverName = val;
                if (this.contactsList.length > 0) {
                  this.contactsList[0].name = val;
                }
              })

            TextInput({ text: this.caregiverPhone, placeholder: 'Primary Mobile Phone Number' })
              .width('100%')
              .height(42)
              .fontSize(13)
              .fontColor('#111827')
              .backgroundColor('#F8FAFC')
              .borderRadius(10)
              .onChange((val: string) => {
                this.caregiverPhone = val;
                if (this.contactsList.length > 0) {
                  this.contactsList[0].phone = val;
                }
              })
          }
          .width('100%')
          .padding({ top: 4 })
        }
        .width('100%')
        .padding(18)
        .backgroundColor('#FFFFFF')
        .borderRadius(22)
        .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.04)', offsetY: 2 })

        // ==========================================
        // 3. HUAWEI CLOUD SMN AUTOMATED DISPATCH
        // ==========================================
        Column({ space: 14 }) {
          Row() {
            Column({ space: 2 }) {
              Text('Huawei Cloud SMN Service')
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor('#111827')
              Text('Priority telecom SMS gateway (< 3.9 mmol/L)')
                .fontSize(12)
                .fontColor('#64748B')
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Toggle({ type: ToggleType.Switch, isOn: this.smnEnabled })
              .selectedColor('#2563EB')
              .width(42)
              .height(24)
              .onChange((isOn: boolean) => {
                this.smnEnabled = isOn;
                this.onToggleSmn(isOn);
              })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Row({ space: 8 }) {
            Button('Send Test Alert')
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .height(34)
              .padding({ left: 14, right: 14 })
              .backgroundColor('#F1F5F9')
              .fontColor('#1E293B')
              .borderRadius(10)
              .onClick(() => {
                this.onSendTestSmn();
              })

            if (this.smnLastSent.length > 0) {
              Text(`Last test: ${this.smnLastSent}`)
                .fontSize(11)
                .fontColor('#94A3B8')
                .layoutWeight(1)
                .textAlign(TextAlign.End)
            }
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .padding(18)
        .backgroundColor('#FFFFFF')
        .borderRadius(22)
        .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.04)', offsetY: 2 })

        // Recent Audit Activity Feed
        Column({ space: 12 }) {
          Row() {
            Text('Recent Activity Trail')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#111827')
            Blank()
            Text(`${this.auditLog.length} events`)
              .fontSize(11)
              .fontColor('#94A3B8')
          }
          .width('100%')

          Column({ space: 8 }) {
            ForEach(this.auditLog, (entry: AuditEntry) => {
              Row({ space: 10 }) {
                Circle({ width: 7, height: 7 })
                  .fill(entry.level === 'crit' ? '#EF4444' : (entry.level === 'warn' ? '#F59E0B' : '#22C55E'))
                  .margin({ top: 5 })

                Column({ space: 1 }) {
                  Text(entry.message)
                    .fontSize(13)
                    .fontColor('#111827')
                    .width('100%')
                  Text(entry.time)
                    .fontSize(11)
                    .fontColor('#94A3B8')
                    .width('100%')
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
              }
              .width('100%')
              .alignItems(VerticalAlign.Top)
            }, (entry: AuditEntry) => `${entry.time}_${entry.message}`)
          }
          .width('100%')
          .padding(14)
          .backgroundColor('#F8FAFC')
          .borderRadius(16)
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
