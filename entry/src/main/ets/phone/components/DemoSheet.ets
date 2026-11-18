/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Quick Log & Clinical Demo Sheet (Opened by Blue + FAB or Top Menu).
 * Allows one-tap Finger-Prick logging, Phase P1/P2/P3 switching, Body-Type routing, and scenario emulation.
 */

import { BodyType, DetectionPhase, ScenarioPreset } from '../models/PhoneTypes';
import { PhoneTheme } from '../utils/PhoneTheme';

@Component
export struct DemoSheet {
  @Prop isWatchConnected: boolean = true;
  @Prop watchBattery: number = 86;
  @Prop activePhase: DetectionPhase = 'P1';
  @Prop bodyType: BodyType = 'Adrenergic';
  onSelectPhase: (phase: DetectionPhase) => void = () => {};
  onSelectBodyType: (bodyType: BodyType) => void = () => {};
  onRunScenario: (preset: ScenarioPreset) => void = () => {};
  onLogFingerPrick: (mgDl: number) => void = () => {};
  onToggleWatchConnection: () => void = () => {};
  onClose: () => void = () => {};

  @Builder
  phasePill(phase: DetectionPhase, label: string) {
    Button(label)
      .fontSize(PhoneTheme.FONT_CAPTION)
      .fontWeight(this.activePhase === phase ? FontWeight.Bold : FontWeight.Medium)
      .height(34)
      .layoutWeight(1)
      .backgroundColor(this.activePhase === phase ? PhoneTheme.BRAND_PRIMARY : PhoneTheme.BG_INSET)
      .fontColor(this.activePhase === phase ? PhoneTheme.TEXT_ON_DARK : PhoneTheme.TEXT_SECONDARY)
      .borderRadius(17)
      .onClick(() => {
        this.onSelectPhase(phase);
      })
  }

  @Builder
  bodyTypePill(bodyType: BodyType, label: string) {
    Button(label)
      .fontSize(PhoneTheme.FONT_CAPTION)
      .fontWeight(this.bodyType === bodyType ? FontWeight.Bold : FontWeight.Medium)
      .height(34)
      .layoutWeight(1)
      .backgroundColor(this.bodyType === bodyType ? PhoneTheme.BRAND_ACCENT : PhoneTheme.BG_INSET)
      .fontColor(this.bodyType === bodyType ? PhoneTheme.TEXT_ON_DARK : PhoneTheme.TEXT_SECONDARY)
      .borderRadius(17)
      .onClick(() => {
        this.onSelectBodyType(bodyType);
      })
  }

  @Builder
  scenarioRow(preset: ScenarioPreset, dotColor: string, title: string, detail: string, actionLabel: string, urgent: boolean = false) {
    Button() {
      Row({ space: 10 }) {
        Circle({ width: 8, height: 8 })
          .fill(dotColor)

        Column({ space: 1 }) {
          Text(title)
            .fontSize(PhoneTheme.FONT_BODY)
            .fontWeight(FontWeight.Bold)
            .fontColor(PhoneTheme.TEXT_PRIMARY)

          Text(detail)
            .fontSize(PhoneTheme.FONT_CAPTION)
            .fontColor(PhoneTheme.TEXT_MUTED)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text(actionLabel)
          .fontSize(PhoneTheme.FONT_CAPTION)
          .fontWeight(FontWeight.Bold)
          .fontColor(urgent ? PhoneTheme.STATE_CRIT_TEXT : PhoneTheme.BRAND_ACCENT)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .backgroundColor(urgent ? PhoneTheme.STATE_CRIT_BG : PhoneTheme.BG_INSET)
    .borderRadius(16)
    .onClick(() => {
      this.onRunScenario(preset);
      this.onClose();
    })
  }

  build() {
    Column({ space: 12 }) {
      // Handle
      Row()
        .width(38)
        .height(4)
        .backgroundColor(PhoneTheme.BORDER_SUBTLE)
        .borderRadius(2)

      // Header
      Row() {
        Text('Demo & Check')
          .fontSize(PhoneTheme.FONT_SECTION)
          .fontWeight(FontWeight.Bold)
          .fontColor(PhoneTheme.TEXT_PRIMARY)
          .layoutWeight(1)

        Button('Done')
          .fontSize(PhoneTheme.FONT_CAPTION)
          .fontWeight(FontWeight.Bold)
          .height(32)
          .padding({ left: 14, right: 14 })
          .backgroundColor(PhoneTheme.BG_INSET)
          .fontColor(PhoneTheme.TEXT_PRIMARY)
          .borderRadius(PhoneTheme.PILL_RADIUS)
          .onClick(() => {
            this.onClose();
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // Quick Finger-Prick Check-In
      Row({ space: 8 }) {
        Button() {
          Row({ space: 6 }) {
            SymbolGlyph($r('sys.symbol.drop_fill'))
              .fontSize(13)
              .fontColor([PhoneTheme.STATE_CRIT_TEXT])
            Text('54 · Low')
              .fontSize(PhoneTheme.FONT_CAPTION)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.STATE_CRIT_TEXT)
          }
          .alignItems(VerticalAlign.Center)
        }
        .height(40)
        .layoutWeight(1)
        .backgroundColor(PhoneTheme.STATE_CRIT_BG)
        .borderRadius(20)
        .onClick(() => {
          this.onLogFingerPrick(54);
          this.onClose();
        })

        Button() {
          Row({ space: 6 }) {
            SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))
              .fontSize(13)
              .fontColor([PhoneTheme.STATE_OK_TEXT])
            Text('108 · Fine')
              .fontSize(PhoneTheme.FONT_CAPTION)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.STATE_OK_TEXT)
          }
          .alignItems(VerticalAlign.Center)
        }
        .height(40)
        .layoutWeight(1)
        .backgroundColor(PhoneTheme.STATE_OK_BG)
        .borderRadius(20)
        .onClick(() => {
          this.onLogFingerPrick(108);
          this.onClose();
        })
      }
      .width('100%')

      // Watch link strip
      Row({ space: 10 }) {
        SymbolGlyph($r('sys.symbol.watch'))
          .fontSize(15)
          .fontColor([this.isWatchConnected ? PhoneTheme.STATE_OK : PhoneTheme.STATE_WARN])

        Text(this.isWatchConnected ? `Watch ${this.watchBattery}%` : 'Watch off')
          .fontSize(PhoneTheme.FONT_CAPTION)
          .fontWeight(FontWeight.Medium)
          .fontColor(PhoneTheme.TEXT_PRIMARY)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Button(this.isWatchConnected ? 'Unlink' : 'Link')
          .fontSize(PhoneTheme.FONT_MICRO)
          .fontWeight(FontWeight.Bold)
          .height(30)
          .padding({ left: 11, right: 11 })
          .backgroundColor(this.isWatchConnected ? PhoneTheme.STATE_CRIT_BG : PhoneTheme.BRAND_PRIMARY)
          .fontColor(this.isWatchConnected ? PhoneTheme.STATE_CRIT_TEXT : PhoneTheme.TEXT_ON_DARK)
          .borderRadius(PhoneTheme.PILL_RADIUS)
          .onClick(() => {
            this.onToggleWatchConnection();
          })
      }
      .width('100%')
      .padding({ left: 12, right: 10, top: 8, bottom: 8 })
      .backgroundColor(PhoneTheme.BG_INSET)
      .borderRadius(16)
      .alignItems(VerticalAlign.Center)

      // Instant Phase & Body-Type Switchers
      Row({ space: 6 }) {
        this.phasePill('P1', 'P1 Warm-Up')
        this.phasePill('P2', 'P2 My Line')
        this.phasePill('P3', 'P3 1D-CNN')
      }
      .width('100%')

      Row({ space: 6 }) {
        this.bodyTypePill('Adrenergic', 'Adren. (3x)')
        this.bodyTypePill('Blunted', 'Blunted (2x)')
      }
      .width('100%')

      // Scenarios
      Column({ space: 7 }) {
        this.scenarioRow(
          'calm',
          PhoneTheme.STATE_OK,
          'Quiet Sleep',
          'Score 1.2 · Baseline ok',
          'Apply'
        )
        this.scenarioRow(
          'motion',
          PhoneTheme.BRAND_ACCENT,
          'Motion Gate',
          '0.36g · False buzz off',
          'Test'
        )
        this.scenarioRow(
          'baseline',
          PhoneTheme.BRAND_ACCENT,
          '75m Baseline',
          'Learning 11/15 slots',
          'Show'
        )
        this.scenarioRow(
          'warning',
          PhoneTheme.STATE_WARN,
          'Early Rise',
          '2/3 checks · Warning',
          'Apply'
        )
        this.scenarioRow(
          'surge',
          PhoneTheme.STATE_CRIT,
          'Symptom Surge',
          'Watch buzz + SMS',
          'Trigger',
          true
        )
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 10, bottom: 18 })
    .backgroundColor(PhoneTheme.BG_CARD)
    .borderRadius(28)
    .shadow({ radius: 24, color: 'rgba(17, 19, 24, 0.16)', offsetY: -4 })
  }
}
