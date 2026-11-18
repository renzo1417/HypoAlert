/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Quick Log & Clinical Demo Sheet (Opened by Blue + FAB or Top Menu).
 * Bound directly to BodyPhenotype, DetectionPhase, and Real c2s02_7 1D-CNN Replay (7676da5).
 */

import { BodyPhenotype, DetectionPhase } from '../../models/VitalsModel';
import { ScenarioPreset } from '../models/PhoneTypes';
import { PhoneTheme } from '../utils/PhoneTheme';

@Component
export struct DemoSheet {
  @Prop isWatchConnected: boolean = true;
  @Prop watchBattery: number = 86;
  @Prop activePhase: DetectionPhase = 1;
  @Prop phenotype: BodyPhenotype = BodyPhenotype.ADRENERGIC;
  @Prop replayActive: boolean = false;
  onSelectPhase: (phase: DetectionPhase) => void = () => {};
  onSelectPhenotype: (phenotype: BodyPhenotype) => void = () => {};
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
  bodyTypePill(target: BodyPhenotype, label: string) {
    Button(label)
      .fontSize(PhoneTheme.FONT_CAPTION)
      .fontWeight(this.phenotype === target ? FontWeight.Bold : FontWeight.Medium)
      .height(34)
      .layoutWeight(1)
      .backgroundColor(this.phenotype === target ? PhoneTheme.BRAND_ACCENT : PhoneTheme.BG_INSET)
      .fontColor(this.phenotype === target ? PhoneTheme.TEXT_ON_DARK : PhoneTheme.TEXT_SECONDARY)
      .borderRadius(17)
      .onClick(() => {
        this.onSelectPhenotype(target);
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
    Column({ space: 10 }) {
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
        this.phasePill(1, 'P1 Warm-Up')
        this.phasePill(2, 'P2 My Line')
        this.phasePill(3, 'P3 1D-CNN')
      }
      .width('100%')

      Row({ space: 6 }) {
        this.bodyTypePill(BodyPhenotype.ADRENERGIC, 'Adren. (3x)')
        this.bodyTypePill(BodyPhenotype.BRADYCARDIC, 'Blunted (2x)')
      }
      .width('100%')

      // Scenarios + Real Phase 3 1D-CNN Night Replay
      Column({ space: 6 }) {
        this.scenarioRow(
          'calm',
          PhoneTheme.STATE_OK,
          'Quiet Sleep',
          'Steady resting vitals',
          'Apply'
        )
        this.scenarioRow(
          'motion',
          PhoneTheme.BRAND_ACCENT,
          'Motion Gate',
          'Movement pauses checks',
          'Test'
        )
        this.scenarioRow(
          'baseline',
          PhoneTheme.BRAND_ACCENT,
          '75m Baseline',
          'Silent rest warm-up',
          'Show'
        )
        this.scenarioRow(
          'warning',
          PhoneTheme.STATE_WARN,
          'Add +1 Check',
          'Step streak toward cutoff',
          'Step'
        )
        this.scenarioRow(
          'surge',
          PhoneTheme.STATE_CRIT,
          'Symptom Surge',
          'Sustained buzz + SMS',
          'Trigger',
          true
        )
        this.scenarioRow(
          'replay',
          PhoneTheme.BRAND_ACCENT,
          'Replay c2s02_7',
          'Real Phase 3 1D-CNN night',
          this.replayActive ? 'Stop' : 'Play'
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
