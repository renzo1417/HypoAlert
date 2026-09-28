/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Minimalist Top Header Bar with greeting, wearable battery status, and notifications.
 * Modeled after the reference health monitoring header.
 */

@Component
export struct PhoneTopBar {
  @Prop currentTime: string = '00:00:00';
  @Prop isEmergency: boolean = false;
  @Prop isWatchConnected: boolean = true;
  @Prop watchBattery: number = 86;
  @Prop deviceName: string = 'WATCH 4 Pro';
  @Prop userName: string = 'Maria';
  onNotificationClick: () => void = () => {};

  build() {
    Row() {
      // Left: Profile Avatar + Friendly Greeting
      Row({ space: 10 }) {
        Stack({ alignContent: Alignment.Center }) {
          Circle({ width: 40, height: 40 })
            .fill(this.isEmergency ? '#FEE2E2' : '#F1F5F9')

          Text(this.userName.length > 0 ? this.userName.substring(0, 1) : 'M')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.isEmergency ? '#EF4444' : '#1E293B')
        }
        .width(40)
        .height(40)

        Column({ space: 1 }) {
          Row({ space: 4 }) {
            Text(`Hello, ${this.userName}`)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#111827')
            Text('👋')
              .fontSize(14)
          }

          Row({ space: 5 }) {
            Circle({ width: 6, height: 6 })
              .fill(this.isEmergency ? '#EF4444' : (this.isWatchConnected ? '#22C55E' : '#F59E0B'))
            Text(this.isEmergency ? 'Emergency Active' : (this.isWatchConnected ? 'Night Guardian Active' : 'Watch Offline'))
              .fontSize(11)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.isEmergency ? '#EF4444' : '#64748B')
          }
          .alignItems(VerticalAlign.Center)
        }
        .alignItems(HorizontalAlign.Start)
      }
      .alignItems(VerticalAlign.Center)
      .layoutWeight(1)

      // Right: Watch Battery Pill + Notification Bell
      Row({ space: 8 }) {
        // Wearable connection capsule
        Row({ space: 5 }) {
          Circle({ width: 6, height: 6 })
            .fill(this.isWatchConnected ? '#22C55E' : '#94A3B8')

          Text(this.isWatchConnected ? `${this.watchBattery}%` : 'Offline')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.isWatchConnected ? '#111827' : '#94A3B8')
        }
        .padding({ left: 10, right: 10, top: 6, bottom: 6 })
        .backgroundColor('#FFFFFF')
        .borderRadius(14)
        .shadow({ radius: 4, color: 'rgba(0, 0, 0, 0.04)', offsetY: 1 })
        .alignItems(VerticalAlign.Center)

        // Notification Bell Icon Button
        Button() {
          Stack({ alignContent: Alignment.Center }) {
            // Bell shape
            Column({ space: 1 }) {
              Circle({ width: 4, height: 4 })
                .fill('#475569')
              Row()
                .width(14)
                .height(10)
                .backgroundColor('#475569')
                .borderRadius({ topLeft: 7, topRight: 7 })
              Row()
                .width(16)
                .height(2)
                .backgroundColor('#475569')
                .borderRadius(1)
            }
            .alignItems(HorizontalAlign.Center)

            // Alert indicator dot if emergency
            if (this.isEmergency) {
              Circle({ width: 6, height: 6 })
                .fill('#EF4444')
                .offset({ x: 6, y: -6 })
            }
          }
          .width(36)
          .height(36)
        }
        .width(36)
        .height(36)
        .backgroundColor('#FFFFFF')
        .borderRadius(18)
        .shadow({ radius: 4, color: 'rgba(0, 0, 0, 0.04)', offsetY: 1 })
        .onClick(() => {
          this.onNotificationClick();
        })
      }
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding({ left: 20, right: 20, top: 12, bottom: 10 })
  }
}
