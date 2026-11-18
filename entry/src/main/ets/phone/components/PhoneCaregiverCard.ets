/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Clean Caregiver Contact Pill Card.
 */

import { PhoneTheme } from '../utils/PhoneTheme';

@Component
export struct PhoneCaregiverCard {
  @Prop caregiverName: string = 'Maria Santos';
  @Prop caregiverRole: string = 'Primary caregiver';
  @Prop caregiverPhone: string = '+63 917 123 4567';
  @Prop isEmergency: boolean = false;
  @Prop smnEnabled: boolean = true;
  @Prop smnLastSent: string = '';
  onCall: () => void = () => {};

  private initials(): string {
    const parts: string[] = this.caregiverName.trim().split(' ');
    if (parts.length >= 2 && parts[0].length > 0 && parts[1].length > 0) {
      return `${parts[0].substring(0, 1)}${parts[1].substring(0, 1)}`.toUpperCase();
    }
    return this.caregiverName.length > 0 ? this.caregiverName.substring(0, 1).toUpperCase() : 'M';
  }

  build() {
    Row({ space: 12 }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle({ width: 42, height: 42 })
          .fill(this.isEmergency ? PhoneTheme.STATE_CRIT_BG : PhoneTheme.BG_INSET)

        Text(this.initials())
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isEmergency ? PhoneTheme.STATE_CRIT_TEXT : PhoneTheme.TEXT_PRIMARY)
      }
      .width(42)
      .height(42)

      Column({ space: 2 }) {
        Text(this.caregiverName)
          .fontSize(PhoneTheme.FONT_SUBTITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(PhoneTheme.TEXT_PRIMARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(
          this.isEmergency && this.smnLastSent.length > 0
            ? `SMS sent · ${this.smnLastSent}`
            : (this.smnEnabled ? 'Primary · SMS ready' : 'Primary · SMS off')
        )
          .fontSize(PhoneTheme.FONT_CAPTION)
          .fontColor(this.isEmergency ? PhoneTheme.STATE_CRIT_TEXT : PhoneTheme.TEXT_MUTED)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Button() {
        Row({ space: 6 }) {
          SymbolGlyph($r('sys.symbol.phone_fill'))
            .fontSize(14)
            .fontColor([PhoneTheme.TEXT_ON_DARK])

          Text('Call')
            .fontSize(PhoneTheme.FONT_BODY)
            .fontWeight(FontWeight.Bold)
            .fontColor(PhoneTheme.TEXT_ON_DARK)
        }
        .alignItems(VerticalAlign.Center)
      }
      .height(42)
      .padding({ left: 16, right: 16 })
      .backgroundColor(this.isEmergency ? PhoneTheme.STATE_CRIT_DARK : PhoneTheme.BRAND_PRIMARY)
      .borderRadius(PhoneTheme.PILL_RADIUS)
      .onClick(() => {
        this.onCall();
      })
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 12, bottom: 12 })
    .backgroundColor(PhoneTheme.BG_CARD)
    .borderRadius(PhoneTheme.CARD_RADIUS)
    .shadow({ radius: 12, color: 'rgba(17, 19, 24, 0.04)', offsetY: 3 })
    .alignItems(VerticalAlign.Center)
  }
}
