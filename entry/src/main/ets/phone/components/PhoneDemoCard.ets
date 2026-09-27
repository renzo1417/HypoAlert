/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Interactive simulation demo card for testing clinical states.
 */

@Component
export struct PhoneDemoCard {
  @Link demoOpen: boolean;
  onSimulateStable: () => void = () => {};
  onSimulatePreDrop: () => void = () => {};
  onSimulateCrisis: () => void = () => {};

  build() {
    Column({ space: 10 }) {
      Button(this.demoOpen ? 'Demo mode ▲' : 'Demo mode ▼')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .height(48)
        .width('100%')
        .backgroundColor('#FFFFFF')
        .fontColor('#2E86DE')
        .border({ width: 1, color: '#2E86DE', radius: 14 })
        .onClick(() => {
          this.demoOpen = !this.demoOpen;
        })

      if (this.demoOpen) {
        Column({ space: 8 }) {
          Text('For trying the screens only.')
            .fontSize(13)
            .fontColor('#8A94A6')
            .width('100%')
            .textAlign(TextAlign.Center)

          Button('Stable 5.5 — all clear')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .height(48)
            .width('100%')
            .backgroundColor('#E9F7EF')
            .fontColor('#1E7E34')
            .border({ width: 1, color: '#34C759', radius: 12 })
            .onClick(() => {
              this.onSimulateStable();
            })

          Button('Pre-Drop 4.2 — falling')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .height(48)
            .width('100%')
            .backgroundColor('#FFF4E5')
            .fontColor('#B25E09')
            .border({ width: 1, color: '#FF9500', radius: 12 })
            .onClick(() => {
              this.onSimulatePreDrop();
            })

          Button('Crisis 3.1 — emergency + alarm')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .height(48)
            .width('100%')
            .backgroundColor('#FF3B30')
            .fontColor('#FFFFFF')
            .borderRadius(12)
            .onClick(() => {
              this.onSimulateCrisis();
            })

          Text('Crisis also rings the alarm and texts family (SMN payload).')
            .fontSize(13)
            .fontColor('#8A94A6')
            .width('100%')
            .textAlign(TextAlign.Center)
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(22)
    .border({ width: 1, color: '#E3E9F2', radius: 22 })
    .shadow({ radius: 14, color: 'rgba(15,27,45,0.08)', offsetX: 0, offsetY: 6 })
  }
}

@Preview({ title: 'Phone Demo Card' })
@Component
struct PhoneDemoCardPreview {
  @State demoOpen: boolean = true;

  build() {
    Column() {
      PhoneDemoCard({ demoOpen: $demoOpen })
    }
    .padding(16)
    .backgroundColor('#EEF2F7')
  }
}
