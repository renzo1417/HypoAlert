/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Minimalist Caregiver Quick-Contact Card.
 * Modeled after the primary contact/physician card in modern health apps.
 */

@Component
export struct PhoneCaregiverCard {
  @Prop caregiverName: string = 'Maria Santos';
  @Prop caregiverRole: string = 'Primary Caregiver';
  @Prop caregiverPhone: string = '+63 917 123 4567';
  @Prop isEmergency: boolean = false;
  onCall: () => void = () => {};
  onMessage: () => void = () => {};

  build() {
    Row({ space: 12 }) {
      // Caregiver Avatar / Status Indicator
      Stack({ alignContent: Alignment.Center }) {
        Circle({ width: 46, height: 46 })
          .fill(this.isEmergency ? '#FEE2E2' : '#E0E7FF')

        // Stylized initials or caregiver symbol
        Text(this.caregiverName.length > 0 ? this.caregiverName.substring(0, 1) : 'C')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isEmergency ? '#EF4444' : '#4338CA')
      }
      .width(46)
      .height(46)

      // Name & Role Details
      Column({ space: 2 }) {
        Text(this.caregiverName)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111827')

        Row({ space: 6 }) {
          Circle({ width: 6, height: 6 })
            .fill(this.isEmergency ? '#EF4444' : '#22C55E')
          Text(this.isEmergency ? 'Urgent Alert Sent' : `${this.caregiverRole} • Ready`)
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.isEmergency ? '#EF4444' : '#64748B')
        }
        .alignItems(VerticalAlign.Center)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // Action Buttons (Message & Call)
      Row({ space: 8 }) {
        // Message / Notification button
        Button() {
          Stack({ alignContent: Alignment.Center }) {
            // Chat bubble glyph
            Column({ space: 2 }) {
              Row()
                .width(16)
                .height(11)
                .backgroundColor(this.isEmergency ? '#EF4444' : '#475569')
                .borderRadius(3)
              Row()
                .width(6)
                .height(3)
                .backgroundColor(this.isEmergency ? '#EF4444' : '#475569')
                .borderRadius(1)
                .margin({ left: 3 })
            }
            .alignItems(HorizontalAlign.Start)
          }
          .width(40)
          .height(40)
        }
        .width(40)
        .height(40)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .shadow({ radius: 6, color: 'rgba(0, 0, 0, 0.05)', offsetY: 2 })
        .onClick(() => {
          this.onMessage();
        })

        // Call button
        Button() {
          Stack({ alignContent: Alignment.Center }) {
            // Phone handset glyph
            Row() {
              Circle({ width: 8, height: 8 })
                .fill(this.isEmergency ? '#FFFFFF' : '#2563EB')
              Row()
                .width(5)
                .height(12)
                .backgroundColor(this.isEmergency ? '#FFFFFF' : '#2563EB')
                .borderRadius(2)
            }
            .rotate({ angle: -25 })
          }
          .width(40)
          .height(40)
        }
        .width(40)
        .height(40)
        .backgroundColor(this.isEmergency ? '#EF4444' : '#FFFFFF')
        .borderRadius(12)
        .shadow({ radius: 6, color: 'rgba(0, 0, 0, 0.05)', offsetY: 2 })
        .onClick(() => {
          this.onCall();
        })
      }
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor('#EEF2FE')
    .borderRadius(20)
    .alignItems(VerticalAlign.Center)
  }
}
