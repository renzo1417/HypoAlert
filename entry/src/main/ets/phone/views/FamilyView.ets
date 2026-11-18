/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Screen 3: Profile Setup, Phase 1-3 Calibration Progress, and Caregiver Settings.
 */

import { BodyPhenotype, DetectionPhase, GateProgress, VitalsEngine } from '../../models/VitalsModel';
import { PhoneTheme } from '../utils/PhoneTheme';

@Component
export struct FamilyView {
  @Link caregiverName: string;
  @Link caregiverPhone: string;
  @Link smnEnabled: boolean;
  @Prop smnLastSent: string = '';
  @Prop phenotype: BodyPhenotype = BodyPhenotype.ADRENERGIC;
  @Prop activePhase: DetectionPhase = 1;
  @Prop gateProgress: GateProgress = {
    buzzLinkedPricks: 2,
    confirmedLows: 0,
    fineNights: 6,
    personalLine: 3.7,
    hasPersonalLine: false,
    isCnnUnlocked: false,
    isA2Personalized: false
  };
  @Prop ageYears: number = 26;
  @Prop t1dYears: number = 8;
  @State guardianMasterEnabled: boolean = true;
  @State watchVibrationEnabled: boolean = true;
  @State scheduleStartTime: string = '22:00';
  @State scheduleEndTime: string = '06:00';
  onCallNow: () => void = () => {};
  onToggleSmn: (isOn: boolean) => void = () => {};
  onSendTestSmn: () => void = () => {};
  onSelectPhenotype: (p: BodyPhenotype) => void = () => {};
  onSelectPhase: (phase: DetectionPhase) => void = () => {};

  build() {
    Scroll() {
      Column({ space: 12 }) {
        Column({ space: 2 }) {
          Row() {
            Text('Guardian & Profile')
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
          Text('75m baseline • 30m cooldown • Max 2 alerts/night')
            .fontSize(PhoneTheme.FONT_CAPTION)
            .fontColor(PhoneTheme.TEXT_MUTED)
            .width('100%')
        }
        .width('100%')
        .padding({ left: 2, right: 2, top: 2 })

        // 1. One-Time Setup (Body Response Type)
        Column({ space: 10 }) {
          Row() {
            Text('Your Body Response')
              .fontSize(PhoneTheme.FONT_SECTION)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.TEXT_PRIMARY)
              .layoutWeight(1)
            Text(`Age ${this.ageYears} • T1D ${this.t1dYears}y`)
              .fontSize(PhoneTheme.FONT_CAPTION)
              .fontColor(PhoneTheme.TEXT_MUTED)
          }
          .width('100%')

          Row({ space: 8 }) {
            Button('Adrenergic (3 checks)')
              .fontSize(PhoneTheme.FONT_CAPTION)
              .fontWeight(FontWeight.Bold)
              .height(40)
              .layoutWeight(1)
              .backgroundColor(this.phenotype === BodyPhenotype.ADRENERGIC ? PhoneTheme.BRAND_PRIMARY : PhoneTheme.BG_SUBTLE)
              .fontColor(this.phenotype === BodyPhenotype.ADRENERGIC ? PhoneTheme.TEXT_ON_DARK : PhoneTheme.TEXT_SECONDARY)
              .borderRadius(PhoneTheme.TILE_RADIUS)
              .onClick(() => {
                this.onSelectPhenotype(BodyPhenotype.ADRENERGIC);
              })

            Button('Blunted (2 checks)')
              .fontSize(PhoneTheme.FONT_CAPTION)
              .fontWeight(FontWeight.Bold)
              .height(40)
              .layoutWeight(1)
              .backgroundColor(this.phenotype === BodyPhenotype.BRADYCARDIC ? PhoneTheme.BRAND_PRIMARY : PhoneTheme.BG_SUBTLE)
              .fontColor(this.phenotype === BodyPhenotype.BRADYCARDIC ? PhoneTheme.TEXT_ON_DARK : PhoneTheme.TEXT_SECONDARY)
              .borderRadius(PhoneTheme.TILE_RADIUS)
              .onClick(() => {
                this.onSelectPhenotype(BodyPhenotype.BRADYCARDIC);
              })
          }
          .width('100%')

          Text(this.phenotype === BodyPhenotype.ADRENERGIC
            ? 'Adrenergic: reacts with fast heart rate + shaking. Needs 3 high checks in a row (~15 min).'
            : 'Blunted: quieter or flat pulse response. Needs 2 high checks in a row (~10 min).')
            .fontSize(PhoneTheme.FONT_CAPTION)
            .fontColor(PhoneTheme.TEXT_MUTED)
            .width('100%')
        }
        .width('100%')
        .padding(PhoneTheme.CARD_PADDING)
        .backgroundColor(PhoneTheme.BG_CARD)
        .borderWidth(1)
        .borderColor(PhoneTheme.BORDER_SUBTLE)
        .borderRadius(PhoneTheme.CARD_RADIUS)

        // 2. Phase 1 -> Phase 2 -> Phase 3 Learning Progress
        Column({ space: 10 }) {
          Row() {
            Text('Learning Phases')
              .fontSize(PhoneTheme.FONT_SECTION)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.TEXT_PRIMARY)
              .layoutWeight(1)
            Text(VitalsEngine.getPhaseName(this.activePhase))
              .fontSize(PhoneTheme.FONT_MICRO)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.BRAND_ACCENT)
              .backgroundColor(PhoneTheme.BRAND_ACCENT_BG)
              .borderRadius(PhoneTheme.PILL_RADIUS)
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          }
          .width('100%')

          Row({ space: 6 }) {
            Button('P1 Warm-Up')
              .fontSize(PhoneTheme.FONT_MICRO)
              .fontWeight(FontWeight.Bold)
              .height(34)
              .layoutWeight(1)
              .backgroundColor(this.activePhase === 1 ? PhoneTheme.BRAND_ACCENT : PhoneTheme.BG_SUBTLE)
              .fontColor(this.activePhase === 1 ? PhoneTheme.TEXT_ON_DARK : PhoneTheme.TEXT_SECONDARY)
              .borderRadius(PhoneTheme.TILE_RADIUS)
              .onClick(() => {
                this.onSelectPhase(1);
              })

            Button('P2 My Line')
              .fontSize(PhoneTheme.FONT_MICRO)
              .fontWeight(FontWeight.Bold)
              .height(34)
              .layoutWeight(1)
              .backgroundColor(this.activePhase === 2 ? PhoneTheme.BRAND_ACCENT : PhoneTheme.BG_SUBTLE)
              .fontColor(this.activePhase === 2 ? PhoneTheme.TEXT_ON_DARK : PhoneTheme.TEXT_SECONDARY)
              .borderRadius(PhoneTheme.TILE_RADIUS)
              .onClick(() => {
                this.onSelectPhase(2);
              })

            Button('P3 1D-CNN')
              .fontSize(PhoneTheme.FONT_MICRO)
              .fontWeight(FontWeight.Bold)
              .height(34)
              .layoutWeight(1)
              .backgroundColor(this.activePhase === 3 ? PhoneTheme.BRAND_ACCENT : PhoneTheme.BG_SUBTLE)
              .fontColor(this.activePhase === 3 ? PhoneTheme.TEXT_ON_DARK : PhoneTheme.TEXT_SECONDARY)
              .borderRadius(PhoneTheme.TILE_RADIUS)
              .onClick(() => {
                this.onSelectPhase(3);
              })
          }
          .width('100%')

          Column({ space: 4 }) {
            Row() {
              Text('Gate 1: Personal cutoff (Phase 2)')
                .fontSize(PhoneTheme.FONT_CAPTION)
                .fontColor(PhoneTheme.TEXT_SECONDARY)
                .layoutWeight(1)
              Text(`${Math.min(3, this.gateProgress.buzzLinkedPricks)}/3 buzz pricks`)
                .fontSize(PhoneTheme.FONT_CAPTION)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.gateProgress.hasPersonalLine ? PhoneTheme.STATE_OK_TEXT : PhoneTheme.TEXT_MUTED)
            }
            .width('100%')

            Progress({ value: Math.min(3, this.gateProgress.buzzLinkedPricks), total: 3, type: ProgressType.Linear })
              .width('100%')
              .color(this.gateProgress.hasPersonalLine ? PhoneTheme.STATE_OK : PhoneTheme.BRAND_ACCENT)
              .backgroundColor(PhoneTheme.BG_SUBTLE)
          }
          .width('100%')

          Column({ space: 4 }) {
            Row() {
              Text('Gate 2: 60-min 1D-CNN (Phase 3)')
                .fontSize(PhoneTheme.FONT_CAPTION)
                .fontColor(PhoneTheme.TEXT_SECONDARY)
                .layoutWeight(1)
              Text(`${Math.min(1, this.gateProgress.confirmedLows)}/1 low • ${Math.min(10, this.gateProgress.fineNights)}/10 fine`)
                .fontSize(PhoneTheme.FONT_CAPTION)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.gateProgress.isCnnUnlocked ? PhoneTheme.STATE_OK_TEXT : PhoneTheme.TEXT_MUTED)
            }
            .width('100%')

            Progress({
              value: Math.min(10, this.gateProgress.fineNights) + (this.gateProgress.confirmedLows > 0 ? 1 : 0),
              total: 11,
              type: ProgressType.Linear
            })
              .width('100%')
              .color(this.gateProgress.isCnnUnlocked ? PhoneTheme.STATE_OK : PhoneTheme.BRAND_ACCENT)
              .backgroundColor(PhoneTheme.BG_SUBTLE)
          }
          .width('100%')
        }
        .width('100%')
        .padding(PhoneTheme.CARD_PADDING)
        .backgroundColor(PhoneTheme.BG_CARD)
        .borderWidth(1)
        .borderColor(PhoneTheme.BORDER_SUBTLE)
        .borderRadius(PhoneTheme.CARD_RADIUS)

        // 3. Night watch window & watch vibration
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
            Text('Watch wrist vibration')
              .fontSize(PhoneTheme.FONT_BODY)
              .fontColor(PhoneTheme.TEXT_PRIMARY)
              .layoutWeight(1)

            Toggle({ type: ToggleType.Switch, isOn: this.watchVibrationEnabled })
              .selectedColor(PhoneTheme.BRAND_ACCENT)
              .width(42)
              .height(24)
              .onChange((isOn: boolean) => {
                this.watchVibrationEnabled = isOn;
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

        // 4. Caregiver & Alert Dispatch
        Column({ space: 12 }) {
          Row() {
            Text('Caregiver alerts (max 2/night)')
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
            Text(`Last test sent ${this.smnLastSent}`)
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
