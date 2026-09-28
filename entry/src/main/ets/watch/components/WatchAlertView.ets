/*
 * Copyright (c) 2026 HypoAlert.
 * Wearable — Screen 4: Critical emergency alert override with haptic and wake confirmation.
 */

import { VitalsData } from '../../models/VitalsModel';

@Component
export struct WatchAlertView {
  @Prop vitals: VitalsData = {
    pulse: 104,
    skinTemp: 34.8,
    tremorIndex: 8.5,
    glucose: 3.1,
    timestamp: '03:15'
  };
  onDismiss: () => void = () => {};

  build() {
    Column() {
      Column({ space: 3 }) {
        Text('CRITICAL ALERT')
          .fontSize(13)
          .fontWeight(FontWeight.Bolder)
          .fontColor('#FFFFFF')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.Center)
          .width('100%')

        Text(`${this.vitals.glucose.toFixed(1)} mmol/L`)
          .fontSize(20)
          .fontWeight(FontWeight.Bolder)
          .fontColor('#FFFFFF')
          .textAlign(TextAlign.Center)
          .width('100%')

        Text('Hypoglycemia detected')
          .fontSize(9)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFE5E5')
          .textAlign(TextAlign.Center)
          .width('100%')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        // Emergency Dispatch Banner (Calls & Messages sent)
        Column({ space: 2 }) {
          Row({ space: 3 }) {
            Text('📩')
              .fontSize(9)
            Text('SMS: Maria (+63 917...)')
              .fontSize(8)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Row({ space: 3 }) {
            Text('📞')
              .fontSize(9)
            Text('Calling Caregiver...')
              .fontSize(8)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .padding(4)
        .backgroundColor('rgba(0, 0, 0, 0.28)')
        .borderRadius(6)
        .margin({ top: 2, bottom: 2 })

        Text(`${this.vitals.pulse} BPM | ${this.vitals.skinTemp.toFixed(1)}°C`)
          .fontSize(9)
          .fontColor('#FFCDD2')
          .textAlign(TextAlign.Center)
          .width('100%')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Button("I'M AWAKE")
          .width('100%')
          .height(38)
          .backgroundColor('#FFFFFF')
          .fontColor('#C00F1A')
          .fontSize(11)
          .fontWeight(FontWeight.Bolder)
          .borderRadius(20)
          .margin({ top: 4 })
          .onClick(() => {
            this.onDismiss();
          })

        Text('Tap to stop alarms & sirens')
          .fontSize(8)
          .fontColor('#FFCDD2')
          .textAlign(TextAlign.Center)
          .width('100%')
      }
      .width(184)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .padding({ top: 24, bottom: 24 })
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#EE1C25')
  }
}

@Preview({ title: 'Watch Critical Alert', width: 466, height: 466 })
@Component
struct WatchAlertViewPreview {
  build() {
    WatchAlertView({
      vitals: {
        pulse: 108,
        skinTemp: 34.6,
        tremorIndex: 8.8,
        glucose: 2.9,
        timestamp: '03:15'
      }
    })
  }
}
