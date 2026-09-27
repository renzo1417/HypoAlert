/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Top Header Bar with branding, live time pill, and wearable status.
 */

@Component
export struct PhoneTopBar {
  @Prop currentTime: string = '00:00:00';
  @Prop isEmergency: boolean = false;
  @Prop watchBattery: number = 86;

  build() {
    Row({ space: 10 }) {
      // Brand mark with blush accent dot
      Stack({ alignContent: Alignment.Center }) {
        Circle({ width: 34, height: 34 })
          .fill('#FFFFFF')
          .shadow({ radius: 6, color: 'rgba(15,27,45,0.08)', offsetX: 0, offsetY: 2 })
        Circle({ width: 14, height: 14 })
          .fill('#2E86DE')
        Circle({ width: 6, height: 6 })
          .fill('#F6B8C1')
          .offset({ x: 3, y: -3 })
      }
      .width(36)
      .height(36)

      Column({ space: 2 }) {
        Text('HypoAlert Family')
          .fontSize(19)
          .fontWeight(FontWeight.Bold)
          .fontColor('#0F1B2D')
        Row({ space: 5 }) {
          Circle({ width: 6, height: 6 })
            .fill(this.isEmergency ? '#FF3B30' : '#34C759')
          Text(this.isEmergency ? 'Emergency active' : 'Night watch • guarding')
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.isEmergency ? '#FF3B30' : '#8A94A6')
        }
        .alignItems(VerticalAlign.Center)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // Time & Connection Pill
      Row({ space: 6 }) {
        Column({ space: 1 }) {
          Text(this.currentTime)
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor('#0F1B2D')
            .textAlign(TextAlign.Center)
          Text(`${this.watchBattery}% watch`)
            .fontSize(10)
            .fontColor('#8A94A6')
            .textAlign(TextAlign.Center)
        }
      }
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .backgroundColor('#FFFFFF')
      .borderRadius(14)
      .border({ width: 1, color: '#E3E9F2', radius: 14 })
      .shadow({ radius: 8, color: 'rgba(15,27,45,0.06)', offsetX: 0, offsetY: 2 })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding({ left: 16, right: 16, top: 12, bottom: 6 })
  }
}

@Preview({ title: 'Phone Top Bar' })
@Component
struct PhoneTopBarPreview {
  build() {
    Column() {
      PhoneTopBar({ currentTime: '23:45:12', watchBattery: 86 })
    }
    .backgroundColor('#EEF2F7')
  }
}
