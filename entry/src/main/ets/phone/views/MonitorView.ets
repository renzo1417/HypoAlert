/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Screen 1: Huawei Health Bedside Nocturnal Monitor & Finger-Prick Check-In.
 */

import { GateProgress, VitalsData, VitalsEngine } from '../../models/VitalsModel';
import { HistoryRepository } from '../../models/HistoryModel';
import { PhoneHeroCard } from '../components/PhoneHeroCard';
import { PhoneMetricGrid } from '../components/PhoneMetricGrid';
import { PhoneTheme } from '../utils/PhoneTheme';

@Component
export struct MonitorView {
  @Prop vitals: VitalsData = VitalsEngine.createInitialVitals();
  @Prop gateProgress: GateProgress = HistoryRepository.getGateProgress();
  @Prop currentTime: string = '00:00:00';
  @Prop watchBattery: number = 86;
  @Prop isWatchConnected: boolean = true;
  @Prop pendingPrickCheck: boolean = false;
  @Prop caregiverName: string = 'Maria Santos';
  @Prop caregiverPhone: string = '+63 917 123 4567';
  @State prickInputText: string = '';
  ppgContext: CanvasRenderingContext2D | null = null;
  onCanvasReady: () => void = () => {};
  onCallNow: () => void = () => {};
  onMarkWithThem: () => void = () => {};
  onConnectWatch: () => void = () => {};
  onLogFingerPrick: (mgDl: number) => void = () => {};
  onNavigateTab: (index: number) => void = () => {};

  private submitCustomPrick(): void {
    const val: number = parseInt(this.prickInputText.trim());
    if (!isNaN(val) && val >= 20 && val <= 600) {
      this.onLogFingerPrick(val);
      this.prickInputText = '';
    }
  }

  build() {
    Scroll() {
      Column({ space: 12 }) {
        if (!this.isWatchConnected) {
          Row({ space: 10 }) {
            Circle({ width: 6, height: 6 })
              .fill(PhoneTheme.STATE_WARN)

            Text('Watch offline — wearable still monitors locally')
              .fontSize(PhoneTheme.FONT_BODY)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.TEXT_PRIMARY)
              .layoutWeight(1)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            Button('Connect')
              .fontSize(PhoneTheme.FONT_BODY)
              .fontWeight(FontWeight.Bold)
              .height(40)
              .padding({ left: 14, right: 14 })
              .backgroundColor(PhoneTheme.BRAND_PRIMARY)
              .fontColor(PhoneTheme.TEXT_ON_DARK)
              .borderRadius(PhoneTheme.TILE_RADIUS)
              .onClick(() => {
                this.onConnectWatch();
              })
          }
          .width('100%')
          .padding({ left: 14, right: 14, top: 10, bottom: 10 })
          .backgroundColor(PhoneTheme.BG_CARD)
          .borderWidth(1)
          .borderColor(PhoneTheme.STATE_WARN)
          .borderRadius(PhoneTheme.CARD_RADIUS)
          .alignItems(VerticalAlign.Center)
        }

        // Section: Tonight
        Row() {
          Text('Tonight • Huawei Health')
            .fontSize(PhoneTheme.FONT_SECTION)
            .fontWeight(FontWeight.Bold)
            .fontColor(PhoneTheme.TEXT_PRIMARY)
            .layoutWeight(1)
          Text('22:00–06:00')
            .fontSize(PhoneTheme.FONT_CAPTION)
            .fontColor(PhoneTheme.TEXT_MUTED)
        }
        .width('100%')
        .padding({ left: 2, right: 2 })
        .alignItems(VerticalAlign.Center)

        // Hero Symptom Risk Card
        PhoneHeroCard({
          vitals: this.vitals,
          currentTime: this.currentTime,
          watchBattery: this.watchBattery,
          isWatchConnected: this.isWatchConnected,
          onCallNow: this.onCallNow,
          onMarkWithThem: this.onMarkWithThem
        })

        // Morning / Buzz-Linked Finger-Prick Check-In Card (real BGM ground truth)
        Column({ space: 8 }) {
          Row() {
            Text(this.pendingPrickCheck ? 'Log Buzz Finger-Prick Check' : 'Morning Finger-Prick Check')
              .fontSize(PhoneTheme.FONT_SECTION)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.TEXT_PRIMARY)
              .layoutWeight(1)

            Text(this.gateProgress.isCnnUnlocked
              ? '1D-CNN Active'
              : (this.gateProgress.hasPersonalLine ? 'Personal Line Ready' : `Pricks ${this.gateProgress.buzzLinkedPricks}/3`))
              .fontSize(PhoneTheme.FONT_MICRO)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.pendingPrickCheck ? PhoneTheme.STATE_WARN_TEXT : PhoneTheme.BRAND_ACCENT)
              .backgroundColor(this.pendingPrickCheck ? PhoneTheme.STATE_WARN_BG : PhoneTheme.BRAND_ACCENT_BG)
              .borderRadius(PhoneTheme.PILL_RADIUS)
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          }
          .width('100%')

          Text(this.pendingPrickCheck
            ? 'Watch buzzed — type your real finger-prick reading (mg/dL) so the watch learns if it was right.'
            : 'Log 1 morning blood sugar check (mg/dL) to unlock Phase 2 personal cutoff & Phase 3 1D-CNN.')
            .fontSize(PhoneTheme.FONT_CAPTION)
            .fontColor(PhoneTheme.TEXT_MUTED)
            .width('100%')

          Row({ space: 8 }) {
            TextInput({ placeholder: 'e.g. 54 or 105 mg/dL', text: this.prickInputText })
              .type(InputType.Number)
              .layoutWeight(1)
              .height(40)
              .fontSize(PhoneTheme.FONT_BODY)
              .backgroundColor(PhoneTheme.BG_SUBTLE)
              .borderRadius(PhoneTheme.TILE_RADIUS)
              .padding({ left: 10, right: 10 })
              .onChange((val: string) => {
                this.prickInputText = val;
              })

            Button('Save')
              .height(40)
              .fontSize(PhoneTheme.FONT_BODY)
              .fontWeight(FontWeight.Bold)
              .backgroundColor(PhoneTheme.BRAND_PRIMARY)
              .fontColor(PhoneTheme.TEXT_ON_DARK)
              .borderRadius(PhoneTheme.TILE_RADIUS)
              .padding({ left: 14, right: 14 })
              .onClick(() => {
                this.submitCustomPrick();
              })
          }
          .width('100%')

          Row({ space: 8 }) {
            Button('Quick: 54 mg/dL (Low)')
              .fontSize(PhoneTheme.FONT_CAPTION)
              .fontWeight(FontWeight.Medium)
              .height(34)
              .layoutWeight(1)
              .backgroundColor(PhoneTheme.STATE_CRIT_BG)
              .fontColor(PhoneTheme.STATE_CRIT_TEXT)
              .borderRadius(PhoneTheme.TILE_RADIUS)
              .onClick(() => {
                this.onLogFingerPrick(54);
              })

            Button('Quick: 108 mg/dL (Fine)')
              .fontSize(PhoneTheme.FONT_CAPTION)
              .fontWeight(FontWeight.Medium)
              .height(34)
              .layoutWeight(1)
              .backgroundColor(PhoneTheme.STATE_OK_BG)
              .fontColor(PhoneTheme.STATE_OK_TEXT)
              .borderRadius(PhoneTheme.TILE_RADIUS)
              .onClick(() => {
                this.onLogFingerPrick(108);
              })
          }
          .width('100%')
        }
        .width('100%')
        .padding(PhoneTheme.CARD_PADDING)
        .backgroundColor(PhoneTheme.BG_CARD)
        .borderWidth(1)
        .borderColor(this.pendingPrickCheck ? PhoneTheme.STATE_WARN : PhoneTheme.BORDER_SUBTLE)
        .borderRadius(PhoneTheme.CARD_RADIUS)

        // Section: Live Symptom Vitals
        Row() {
          Text('What the watch checks')
            .fontSize(PhoneTheme.FONT_SECTION)
            .fontWeight(FontWeight.Bold)
            .fontColor(PhoneTheme.TEXT_PRIMARY)
            .layoutWeight(1)
          Circle({ width: 6, height: 6 })
            .fill(this.isWatchConnected ? PhoneTheme.STATE_OK : PhoneTheme.TEXT_TERTIARY)
          Text(this.isWatchConnected ? ' Live 5m' : ' Autonomous')
            .fontSize(PhoneTheme.FONT_CAPTION)
            .fontColor(PhoneTheme.TEXT_MUTED)
        }
        .width('100%')
        .padding({ left: 2, right: 2 })
        .alignItems(VerticalAlign.Center)

        PhoneMetricGrid({
          vitals: this.vitals,
          ppgContext: this.ppgContext,
          onCanvasReady: this.onCanvasReady
        })

        // Caregiver quick path
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
            Text('Caregiver')
              .fontSize(PhoneTheme.FONT_MICRO)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.TEXT_TERTIARY)
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
        .padding(12)
        .backgroundColor(PhoneTheme.BG_CARD)
        .borderWidth(1)
        .borderColor(PhoneTheme.BORDER_SUBTLE)
        .borderRadius(PhoneTheme.CARD_RADIUS)
        .alignItems(VerticalAlign.Center)
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
