/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Clean Editorial Top Bar (No pill strokes, minimal copy).
 */

import { BodyPhenotype, DetectionPhase } from '../../models/VitalsModel';
import { phaseShortLabel } from '../utils/PhoneRiskUtils';
import { PhoneTheme } from '../utils/PhoneTheme';

@Component
export struct PhoneTopBar {
  @Prop isEmergency: boolean = false;
  @Prop isWatchConnected: boolean = true;
  @Prop watchBattery: number = 86;
  @Prop phase: DetectionPhase = 1;
  @Prop phenotype: BodyPhenotype = BodyPhenotype.ADRENERGIC;
  @Prop replayActive: boolean = false;
  onOpenTest: () => void = () => {};
  onOpenAlerts: () => void = () => {};
  onNavigateGuardian: () => void = () => {};

  build() {
    Column({ space: 12 }) {
      Row({ space: 10 }) {
        Button() {
          Row({ space: 8 }) {
            Stack({ alignContent: Alignment.Center }) {
              Circle({ width: 40, height: 40 })
                .fill('#DCE7F2')
              SymbolGlyph($r('sys.symbol.person_crop_circle_fill_1'))
                .fontSize(26)
                .fontColor([PhoneTheme.BRAND_PRIMARY])
            }
            .width(40)
            .height(40)

            Row({ space: 5 }) {
              Circle({ width: 6, height: 6 })
                .fill(this.isWatchConnected ? PhoneTheme.STATE_OK : PhoneTheme.STATE_WARN)

              Text(this.isWatchConnected ? `${this.watchBattery}%` : 'Off')
                .fontSize(PhoneTheme.FONT_CAPTION)
                .fontWeight(FontWeight.Medium)
                .fontFeature('"tnum" on')
                .fontColor(PhoneTheme.TEXT_SECONDARY)
            }
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .backgroundColor(PhoneTheme.BG_CARD)
            .borderRadius(PhoneTheme.PILL_RADIUS)
            .shadow({ radius: 8, color: 'rgba(17, 19, 24, 0.04)', offsetY: 2 })
          }
          .alignItems(VerticalAlign.Center)
        }
        .backgroundColor(Color.Transparent)
        .padding(0)
        .onClick(() => {
          this.onNavigateGuardian();
        })

        Blank()

        // Twin white pill (Bell + Menu) — zero inner divider stroke
        Row({ space: 2 }) {
          Button() {
            Stack({ alignContent: Alignment.TopEnd }) {
              SymbolGlyph($r('sys.symbol.bell'))
                .fontSize(18)
                .fontColor([PhoneTheme.TEXT_PRIMARY])

              if (this.isEmergency) {
                Circle({ width: 7, height: 7 })
                  .fill(PhoneTheme.STATE_CRIT)
                  .offset({ x: 2, y: -1 })
              }
            }
            .width(24)
            .height(24)
            .alignContent(Alignment.Center)
          }
          .width(40)
          .height(38)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.onOpenAlerts();
          })

          Button() {
            SymbolGlyph($r('sys.symbol.line_3_horizontal'))
              .fontSize(18)
              .fontColor([PhoneTheme.TEXT_PRIMARY])
          }
          .width(40)
          .height(38)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.onOpenTest();
          })
        }
        .height(42)
        .padding({ left: 6, right: 6 })
        .backgroundColor(PhoneTheme.BG_CARD)
        .borderRadius(21)
        .shadow({ radius: 12, color: 'rgba(17, 19, 24, 0.06)', offsetY: 3 })
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Column({ space: 2 }) {
        Text(this.replayActive ? 'P3 Replay · c2s02_7' : phaseShortLabel(this.phase))
          .fontSize(15)
          .fontWeight(FontWeight.Normal)
          .fontColor(this.replayActive ? PhoneTheme.BRAND_ACCENT : PhoneTheme.TEXT_MUTED)

        Text(this.isEmergency ? 'Surge Alert' : 'Sleep Monitor')
          .fontSize(PhoneTheme.FONT_DISPLAY)
          .fontWeight(FontWeight.Bold)
          .letterSpacing(-0.6)
          .fontColor(this.isEmergency ? PhoneTheme.STATE_CRIT_DARK : PhoneTheme.TEXT_PRIMARY)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
  }
}
