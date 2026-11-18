/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Screen 4: Guardian Settings & Caregiver SMS (concise copy, stroke-free pills).
 */

import { CalibrationProgress, EmergencyContact, HistoryRepository } from '../../models/HistoryModel';
import { BodyType, DetectionPhase } from '../models/PhoneTypes';
import { phaseDescription } from '../utils/PhoneRiskUtils';
import { PhoneTheme } from '../utils/PhoneTheme';

@Component
export struct FamilyView {
  @Link caregiverName: string;
  @Link caregiverPhone: string;
  @Link smnEnabled: boolean;
  @Link activePhase: DetectionPhase;
  @Link bodyType: BodyType;
  @Prop smnLastSent: string = '';
  @Prop isEmergency: boolean = false;
  @Prop calibration: CalibrationProgress = {
    buzzPricks: 2,
    buzzPricksTarget: 3,
    confirmedLows: 0,
    confirmedLowsTarget: 1,
    fineNights: 6,
    fineNightsTarget: 10,
    personalCutoff: 4.3,
    phase2Unlocked: false,
    phase3Unlocked: false,
    lastCheckSummary: ''
  };

  @State guardianMasterEnabled: boolean = true;
  @State baseline75mEnabled: boolean = true;
  @State scheduleStartTime: string = '22:00';
  @State scheduleEndTime: string = '06:00';
  @State contactsList: EmergencyContact[] = [];
  @State testSmsBanner: string = '';
  onCallNow: () => void = () => {};
  onToggleSmn: (isOn: boolean) => void = () => {};
  onSendTestSmn: () => void = () => {};
  onSelectPhase: (phase: DetectionPhase) => void = () => {};
  onSelectBodyType: (bodyType: BodyType) => void = () => {};

  aboutToAppear(): void {
    this.contactsList = HistoryRepository.getContacts();
  }

  private phaseUnlockTag(phase: DetectionPhase): string {
    if (phase === 'P1') {
      return 'Day 1';
    }
    if (phase === 'P2') {
      return this.calibration.phase2Unlocked ? 'Unlocked' : `${this.calibration.buzzPricks}/3`;
    }
    return this.calibration.phase3Unlocked
      ? 'Unlocked'
      : `${this.calibration.confirmedLows}/1·${this.calibration.fineNights}/10`;
  }

  @Builder
  phaseButton(phase: DetectionPhase, title: string) {
    Button() {
      Column({ space: 2 }) {
        Text(title)
          .fontSize(PhoneTheme.FONT_CAPTION)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.activePhase === phase ? PhoneTheme.TEXT_ON_DARK : PhoneTheme.TEXT_PRIMARY)

        Text(this.phaseUnlockTag(phase))
          .fontSize(PhoneTheme.FONT_MICRO)
          .fontFeature('"tnum" on')
          .fontColor(this.activePhase === phase ? 'rgba(255,255,255,0.82)' : PhoneTheme.TEXT_MUTED)
      }
      .alignItems(HorizontalAlign.Center)
    }
    .height(46)
    .layoutWeight(1)
    .backgroundColor(this.activePhase === phase ? PhoneTheme.BRAND_PRIMARY : PhoneTheme.BG_INSET)
    .borderRadius(16)
    .onClick(() => {
      this.onSelectPhase(phase);
    })
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        Row() {
          Column({ space: 2 }) {
            Text('Guardian')
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .letterSpacing(-0.5)
              .fontColor(PhoneTheme.TEXT_PRIMARY)

            Text(`${this.scheduleStartTime}–${this.scheduleEndTime} · ${this.bodyType}`)
              .fontSize(PhoneTheme.FONT_CAPTION)
              .fontColor(PhoneTheme.TEXT_MUTED)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Text(this.guardianMasterEnabled ? 'Armed' : 'Paused')
            .fontSize(PhoneTheme.FONT_CAPTION)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.guardianMasterEnabled ? PhoneTheme.STATE_OK_TEXT : PhoneTheme.TEXT_MUTED)
            .backgroundColor(this.guardianMasterEnabled ? PhoneTheme.STATE_OK_BG : PhoneTheme.BG_INSET)
            .borderRadius(PhoneTheme.PILL_RADIUS)
            .padding({ left: 12, right: 12, top: 5, bottom: 5 })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        // 1. Detection Model & Routing
        Column({ space: 12 }) {
          Row() {
            Text('Detection')
              .fontSize(PhoneTheme.FONT_SECTION)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.TEXT_PRIMARY)
              .layoutWeight(1)

            Text(phaseDescription(this.activePhase, this.calibration.personalCutoff))
              .fontSize(PhoneTheme.FONT_CAPTION)
              .fontColor(PhoneTheme.TEXT_MUTED)
          }
          .width('100%')

          Row({ space: 8 }) {
            this.phaseButton('P1', 'P1 Warm-Up')
            this.phaseButton('P2', 'P2 My Line')
            this.phaseButton('P3', 'P3 1D-CNN')
          }
          .width('100%')

          Row({ space: 8 }) {
            Button('Adrenergic (3x)')
              .fontSize(PhoneTheme.FONT_CAPTION)
              .fontWeight(this.bodyType === 'Adrenergic' ? FontWeight.Bold : FontWeight.Medium)
              .height(38)
              .layoutWeight(1)
              .backgroundColor(this.bodyType === 'Adrenergic' ? PhoneTheme.BRAND_ACCENT : PhoneTheme.BG_INSET)
              .fontColor(this.bodyType === 'Adrenergic' ? PhoneTheme.TEXT_ON_DARK : PhoneTheme.TEXT_SECONDARY)
              .borderRadius(19)
              .onClick(() => {
                this.onSelectBodyType('Adrenergic');
              })

            Button('Blunted (2x)')
              .fontSize(PhoneTheme.FONT_CAPTION)
              .fontWeight(this.bodyType === 'Blunted' ? FontWeight.Bold : FontWeight.Medium)
              .height(38)
              .layoutWeight(1)
              .backgroundColor(this.bodyType === 'Blunted' ? PhoneTheme.BRAND_ACCENT : PhoneTheme.BG_INSET)
              .fontColor(this.bodyType === 'Blunted' ? PhoneTheme.TEXT_ON_DARK : PhoneTheme.TEXT_SECONDARY)
              .borderRadius(19)
              .onClick(() => {
                this.onSelectBodyType('Blunted');
              })
          }
          .width('100%')

          Row() {
            Column({ space: 1 }) {
              Text('Night Watch')
                .fontSize(PhoneTheme.FONT_BODY)
                .fontWeight(FontWeight.Medium)
                .fontColor(PhoneTheme.TEXT_PRIMARY)
              Text(`${this.scheduleStartTime} – ${this.scheduleEndTime}`)
                .fontSize(PhoneTheme.FONT_CAPTION)
                .fontColor(PhoneTheme.TEXT_MUTED)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Toggle({ type: ToggleType.Switch, isOn: this.guardianMasterEnabled })
              .selectedColor(PhoneTheme.BRAND_PRIMARY)
              .width(46)
              .height(26)
              .onChange((isOn: boolean) => {
                this.guardianMasterEnabled = isOn;
              })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Row() {
            Column({ space: 1 }) {
              Text('75m Baseline')
                .fontSize(PhoneTheme.FONT_BODY)
                .fontWeight(FontWeight.Medium)
                .fontColor(PhoneTheme.TEXT_PRIMARY)
              Text('Learns resting HR')
                .fontSize(PhoneTheme.FONT_CAPTION)
                .fontColor(PhoneTheme.TEXT_MUTED)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Toggle({ type: ToggleType.Switch, isOn: this.baseline75mEnabled })
              .selectedColor(PhoneTheme.BRAND_ACCENT)
              .width(46)
              .height(26)
              .onChange((isOn: boolean) => {
                this.baseline75mEnabled = isOn;
              })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .padding(PhoneTheme.CARD_PADDING)
        .backgroundColor(PhoneTheme.BG_CARD)
        .borderRadius(PhoneTheme.CARD_RADIUS)
        .shadow({ radius: 12, color: 'rgba(17, 19, 24, 0.04)', offsetY: 3 })

        // 2. Caregiver & SMS Escalation
        Column({ space: 12 }) {
          Row() {
            Column({ space: 1 }) {
              Text('Caregiver SMS')
                .fontSize(PhoneTheme.FONT_SECTION)
                .fontWeight(FontWeight.Bold)
                .fontColor(PhoneTheme.TEXT_PRIMARY)
              Text('Huawei Cloud SMN')
                .fontSize(PhoneTheme.FONT_CAPTION)
                .fontColor(PhoneTheme.TEXT_MUTED)
            }
            .alignItems(HorizontalAlign.Start)
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

          Column({ space: 8 }) {
            ForEach(this.contactsList, (contact: EmergencyContact) => {
              Row({ space: 12 }) {
                Stack({ alignContent: Alignment.Center }) {
                  Circle({ width: 38, height: 38 })
                    .fill(contact.isPrimary ? PhoneTheme.BRAND_PRIMARY : PhoneTheme.BG_CARD)

                  Text(contact.name.length > 0 ? contact.name.substring(0, 1) : 'C')
                    .fontSize(14)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(contact.isPrimary ? PhoneTheme.TEXT_ON_DARK : PhoneTheme.TEXT_PRIMARY)
                }
                .width(38)
                .height(38)

                Column({ space: 1 }) {
                  Text(contact.name)
                    .fontSize(PhoneTheme.FONT_BODY)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(PhoneTheme.TEXT_PRIMARY)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  Text(contact.phone)
                    .fontSize(PhoneTheme.FONT_CAPTION)
                    .fontColor(PhoneTheme.TEXT_MUTED)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)

                if (contact.isPrimary) {
                  Button() {
                    SymbolGlyph($r('sys.symbol.phone_fill'))
                      .fontSize(15)
                      .fontColor([PhoneTheme.TEXT_ON_DARK])
                  }
                  .width(38)
                  .height(38)
                  .backgroundColor(this.isEmergency ? PhoneTheme.STATE_CRIT_DARK : PhoneTheme.BRAND_PRIMARY)
                  .borderRadius(19)
                  .onClick(() => {
                    this.onCallNow();
                  })
                } else {
                  Text(contact.smnEnabled ? 'SMN' : 'Off')
                    .fontSize(PhoneTheme.FONT_MICRO)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(contact.smnEnabled ? PhoneTheme.STATE_OK_TEXT : PhoneTheme.TEXT_MUTED)
                    .backgroundColor(contact.smnEnabled ? PhoneTheme.STATE_OK_BG : PhoneTheme.BG_CARD)
                    .borderRadius(PhoneTheme.PILL_RADIUS)
                    .padding({ left: 9, right: 9, top: 4, bottom: 4 })
                }
              }
              .width('100%')
              .padding({ left: 10, right: 10, top: 8, bottom: 8 })
              .backgroundColor(PhoneTheme.BG_INSET)
              .borderRadius(16)
              .alignItems(VerticalAlign.Center)
            }, (contact: EmergencyContact) => contact.id)
          }
          .width('100%')

          Button('Send test SMS')
            .fontSize(PhoneTheme.FONT_BODY)
            .fontWeight(FontWeight.Bold)
            .height(44)
            .width('100%')
            .backgroundColor(PhoneTheme.BRAND_PRIMARY)
            .fontColor(PhoneTheme.TEXT_ON_DARK)
            .borderRadius(22)
            .onClick(() => {
              this.onSendTestSmn();
              this.testSmsBanner = `Test SMS sent · ${this.caregiverPhone}`;
            })

          if (this.testSmsBanner.length > 0 || this.smnLastSent.length > 0) {
            Row({ space: 6 }) {
              SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))
                .fontSize(13)
                .fontColor([PhoneTheme.STATE_OK_TEXT])

              Text(
                this.testSmsBanner.length > 0
                  ? `${this.testSmsBanner} · ${this.smnLastSent}`
                  : `SMS sent · ${this.smnLastSent}`
              )
                .fontSize(PhoneTheme.FONT_CAPTION)
                .fontColor(PhoneTheme.STATE_OK_TEXT)
                .layoutWeight(1)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%')
            .padding(10)
            .backgroundColor(PhoneTheme.STATE_OK_BG)
            .borderRadius(12)
          }
        }
        .width('100%')
        .padding(PhoneTheme.CARD_PADDING)
        .backgroundColor(PhoneTheme.BG_CARD)
        .borderRadius(PhoneTheme.CARD_RADIUS)
        .shadow({ radius: 12, color: 'rgba(17, 19, 24, 0.04)', offsetY: 3 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 104 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(PhoneTheme.BG_PAGE)
    .scrollBar(BarState.Off)
    .scrollable(ScrollDirection.Vertical)
  }
}
