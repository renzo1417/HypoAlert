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
          .fontSize(14)
          .fontWeight(FontWeight.Bolder)
          .fontColor('#FFFFFF')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.Center)
          .width('100%')

        Text(`${this.vitals.glucose.toFixed(1)} mmol/L`)
          .fontSize(22)
          .fontWeight(FontWeight.Bolder)
          .fontColor('#FFFFFF')
          .textAlign(TextAlign.Center)
          .width('100%')

        Text('< 3.9 mmol/L detected')
          .fontSize(10)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .opacity(0.95)
          .textAlign(TextAlign.Center)
          .width('100%')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(`${this.vitals.pulse} BPM | ${this.vitals.skinTemp.toFixed(1)}°C`)
          .fontSize(10)
          .fontColor('#FFCDD2')
          .textAlign(TextAlign.Center)
          .width('100%')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Button("I'M AWAKE")
          .width('100%')
          .height(44)
          .backgroundColor('#FFFFFF')
          .fontColor('#C00F1A')
          .fontSize(12)
          .fontWeight(FontWeight.Bolder)
          .borderRadius(24)
          .margin({ top: 6 })
          .onClick(() => {
            this.onDismiss();
          })

        Text('Tap to stop alarms')
          .fontSize(9)
          .fontColor('#FFCDD2')
          .textAlign(TextAlign.Center)
          .width('100%')
      }
      .width(180)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .padding({ top: 32, bottom: 32 })
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
