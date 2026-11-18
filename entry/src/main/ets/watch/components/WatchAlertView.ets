/*
 * Copyright (c) 2026 HypoAlert.
 * Wearable — Screen 4: Symptom alert screen with plain-English triggers, SMS dispatch status, and wake confirmation.
 */

import { BodyPhenotype, VitalsData, VitalsEngine } from '../../models/VitalsModel';

@Component
export struct WatchAlertView {
  @Prop vitals: VitalsData = VitalsEngine.generateElevatedStep(
    undefined,
    BodyPhenotype.ADRENERGIC,
    1,
    3.7,
    true
  );
  onDismiss: () => void = () => {};

  private getAlertHeading(): string {
    return this.vitals.phase < 3 ? 'POSSIBLE LOW' : 'SYMPTOM ALERT';
  }

  private getPlainSymptoms(): string {
    if (this.vitals.phenotype === BodyPhenotype.ADRENERGIC) {
      return 'Fast pulse & wrist tremor';
    }
    return 'HRV calmness drop & tremor';
  }

  build() {
    Column() {
      Column({ space: 3 }) {
        Text(this.getAlertHeading())
          .fontSize(13)
          .fontWeight(FontWeight.Bolder)
          .fontColor('#FFFFFF')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.Center)
          .width('100%')

        Text(`${this.vitals.symptomRiskPct}% RISK`)
          .fontSize(20)
          .fontWeight(FontWeight.Bolder)
          .fontColor('#FFFFFF')
          .textAlign(TextAlign.Center)
          .width('100%')

        Text(this.getPlainSymptoms())
          .fontSize(9)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFE5E5')
          .textAlign(TextAlign.Center)
          .width('100%')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        // Caregiver & Finger-Prick Reminder Box
        Column({ space: 2 }) {
          Row({ space: 3 }) {
            Text('📩')
              .fontSize(9)
            Text(`SMS: Maria (${this.vitals.alertsTonight}/2 tonight)`)
              .fontSize(8)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Row({ space: 3 }) {
            Text('🩸')
              .fontSize(9)
            Text('Check sugar & log on phone')
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

        Text(`${this.vitals.pulse} BPM | HRV ${this.vitals.rmssd}ms | ${this.vitals.streakCount}/${this.vitals.streakRequired}`)
          .fontSize(8.5)
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

        Text('Pauses 30m • Silences buzz')
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

@Preview({ title: 'Watch Symptom Alert', width: 466, height: 466 })
@Component
struct WatchAlertViewPreview {
  build() {
    WatchAlertView({
      vitals: VitalsEngine.generateElevatedStep(undefined, BodyPhenotype.ADRENERGIC, 1, 3.7, true)
    })
  }
}
