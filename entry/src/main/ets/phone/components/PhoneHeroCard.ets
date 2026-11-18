/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Soft Sky-Blue Hero Card with Multi-Height Telemetry Bars.
 * Displays Symptom Score (P1/P2) or 1D-CNN Symptom Risk (P3), Safety Streak filter, and urgent crisis actions.
 */

import { VitalsData, VitalsEngine } from '../../models/VitalsModel';
import {
  heroHeadline,
  phenotypeShortLabel,
  statusBadgeLabel
} from '../utils/PhoneRiskUtils';
import { PhoneTheme } from '../utils/PhoneTheme';

@Component
export struct PhoneHeroCard {
  @Prop @Watch('onHeroPropsChange') vitals: VitalsData = VitalsEngine.createInitialVitals();
  @Prop smnSentTime: string = '';
  @Prop caregiverName: string = 'Maria Santos';
  onCallNow: () => void = () => {};
  onMarkWithThem: () => void = () => {};
  onQuickCheck: () => void = () => {};

  private barSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private barCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.barSettings);
  private barReady: boolean = false;
  private barW: number = 112;
  private barH: number = 46;

  onHeroPropsChange(): void {
    this.drawSymptomBars();
  }

  private isCritical(): boolean {
    return this.vitals.statusTier === 'ALERT';
  }

  private isWarning(): boolean {
    return this.vitals.statusTier === 'WATCH';
  }

  private isGated(): boolean {
    return !this.vitals.isSedentary;
  }

  private isLearning(): boolean {
    return this.vitals.baselineMinutes < VitalsEngine.BASELINE_TOTAL_MINUTES;
  }

  private isCooldown(): boolean {
    return this.vitals.cooldownMinutes > 0 && !this.isCritical() && !this.isWarning();
  }

  private pillBg(): string {
    if (this.isCritical()) {
      return 'rgba(255, 255, 255, 0.22)';
    }
    if (this.isWarning()) {
      return PhoneTheme.STATE_WARN_BG;
    }
    if (this.isGated() || this.isLearning() || this.isCooldown()) {
      return PhoneTheme.BRAND_ACCENT_BG;
    }
    return PhoneTheme.STATE_OK_BG;
  }

  private pillText(): string {
    if (this.isCritical()) {
      return PhoneTheme.TEXT_ON_DARK;
    }
    if (this.isWarning()) {
      return PhoneTheme.STATE_WARN_TEXT;
    }
    if (this.isGated() || this.isLearning() || this.isCooldown()) {
      return PhoneTheme.BRAND_ACCENT;
    }
    return PhoneTheme.STATE_OK_TEXT;
  }

  private drawSymptomBars(): void {
    if (!this.barReady) {
      return;
    }
    const ctx: CanvasRenderingContext2D = this.barCtx;
    const W: number = this.barW > 0 ? this.barW : 112;
    const H: number = this.barH > 0 ? this.barH : 46;
    ctx.clearRect(0, 0, W, H);

    const crit: boolean = this.isCritical();
    const warn: boolean = this.isWarning();
    const heights: number[] = crit
      ? [0.46, 0.78, 0.62, 0.94, 0.72, 0.98, 0.84, 0.64, 0.88, 0.74]
      : (warn
        ? [0.35, 0.56, 0.44, 0.78, 0.64, 0.82, 0.54, 0.48, 0.68, 0.42]
        : [0.38, 0.64, 0.46, 0.82, 0.72, 0.48, 0.62, 0.52, 0.78, 0.44]);

    const colors: string[] = crit
      ? ['#FFFFFF', '#FCA5A5', '#FFFFFF', '#FECACA', '#FFFFFF', '#FFFFFF', '#FCA5A5', '#FFFFFF', '#FECACA', '#FFFFFF']
      : ['#111318', '#EF4444', '#111318', '#EF4444', '#111318', '#2A82F0', '#111318', '#EF4444', '#111318', '#111318'];

    const count: number = heights.length;
    const barWidth: number = 3.5;
    const step: number = (W - barWidth) / (count - 1);

    ctx.lineCap = 'round';
    ctx.lineWidth = barWidth;

    for (let i: number = 0; i < count; i++) {
      const x: number = barWidth / 2 + i * step;
      const barLen: number = Math.max(10, heights[i] * (H - 8));
      const yTop: number = (H - barLen) / 2;
      const yBot: number = yTop + barLen;

      ctx.strokeStyle = colors[i];
      ctx.beginPath();
      ctx.moveTo(x, yTop);
      ctx.lineTo(x, yBot);
      ctx.stroke();
    }
  }

  build() {
    Column({ space: 12 }) {
      // Top row: Title & status badge
      Row({ space: 8 }) {
        Text(this.vitals.phase === 3 ? 'Symptom Risk' : 'Symptom Score')
          .fontSize(PhoneTheme.FONT_SUBTITLE)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.isCritical() ? 'rgba(255,255,255,0.9)' : PhoneTheme.TEXT_SECONDARY)
          .layoutWeight(1)

        Text(statusBadgeLabel(this.vitals))
          .fontSize(PhoneTheme.FONT_CAPTION)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.pillText())
          .backgroundColor(this.pillBg())
          .borderRadius(PhoneTheme.PILL_RADIUS)
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // Focal split row: Big score on left + vertical symptom bars on right
      Row({ space: 10 }) {
        Column({ space: 2 }) {
          Row({ space: 5 }) {
            Text(this.vitals.phase === 3 ? `${this.vitals.symptomRiskPct}` : `${this.vitals.heuristicScore.toFixed(1)}`)
              .fontSize(PhoneTheme.FONT_HERO)
              .fontWeight(FontWeight.Bold)
              .letterSpacing(-1.2)
              .fontFeature('"tnum" on')
              .fontColor(this.isCritical() ? PhoneTheme.TEXT_ON_DARK : PhoneTheme.TEXT_PRIMARY)

            Text(this.vitals.phase === 3 ? '%' : 'score')
              .fontSize(PhoneTheme.FONT_SUBTITLE)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.isCritical() ? 'rgba(255,255,255,0.88)' : PhoneTheme.TEXT_SECONDARY)
              .margin({ bottom: 6 })
          }
          .alignItems(VerticalAlign.Bottom)

          Text(
            this.vitals.phase === 3
              ? `${this.vitals.streakCount}/${this.vitals.streakRequired} · ${phenotypeShortLabel(this.vitals.phenotype)} · ${this.vitals.alertsTonight}/2`
              : `Cutoff ${this.vitals.threshold.toFixed(1)} · ${this.vitals.streakCount}/${this.vitals.streakRequired} · ${this.vitals.alertsTonight}/2`
          )
            .fontSize(PhoneTheme.FONT_CAPTION)
            .fontFeature('"tnum" on')
            .fontColor(this.isCritical() ? 'rgba(255,255,255,0.85)' : PhoneTheme.TEXT_SECONDARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Canvas(this.barCtx)
          .width(114)
          .height(46)
          .onAreaChange((_o: Area, n: Area) => {
            const w: number = Number(n.width);
            const h: number = Number(n.height);
            if (w > 0 && h > 0) {
              this.barW = w;
              this.barH = h;
              this.drawSymptomBars();
            }
          })
          .onReady(() => {
            this.barReady = true;
            this.drawSymptomBars();
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 75-min Baseline / Phase 3 1D-CNN live readout / Motion Gate / Alert status note
      if (this.isLearning()) {
        Column({ space: 5 }) {
          Row() {
            Text('75m baseline')
              .fontSize(PhoneTheme.FONT_CAPTION)
              .fontWeight(FontWeight.Medium)
              .fontColor(PhoneTheme.BRAND_ACCENT)
              .layoutWeight(1)
            Text(`${this.vitals.baselineMinutes}/75m`)
              .fontSize(PhoneTheme.FONT_CAPTION)
              .fontWeight(FontWeight.Bold)
              .fontFeature('"tnum" on')
              .fontColor(PhoneTheme.TEXT_PRIMARY)
          }
          .width('100%')

          Progress({ value: this.vitals.baselineMinutes, total: VitalsEngine.BASELINE_TOTAL_MINUTES, type: ProgressType.Linear })
            .width('100%')
            .height(6)
            .color(PhoneTheme.BRAND_ACCENT)
            .backgroundColor('rgba(255,255,255,0.65)')
        }
        .width('100%')
        .padding(10)
        .backgroundColor('rgba(255,255,255,0.55)')
        .borderRadius(14)
      } else if (this.vitals.phase === 3 && this.vitals.tcnnEma !== undefined && this.vitals.tcnnThr !== undefined) {
        Row({ space: 6 }) {
          Text(`CNN ${this.vitals.tcnnSlotsFilled ?? 12}/12`)
            .fontSize(PhoneTheme.FONT_MICRO)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.isCritical() ? PhoneTheme.TEXT_ON_DARK : PhoneTheme.BRAND_ACCENT)

          Text(`EMA ${this.vitals.tcnnEma.toFixed(2)} / ${this.vitals.tcnnThr.toFixed(2)}`)
            .fontSize(PhoneTheme.FONT_MICRO)
            .fontFeature('"tnum" on')
            .fontColor(this.isCritical() ? 'rgba(255,255,255,0.9)' : PhoneTheme.TEXT_SECONDARY)
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
        .padding({ left: 10, right: 10, top: 6, bottom: 6 })
        .backgroundColor(this.isCritical() ? 'rgba(255,255,255,0.16)' : 'rgba(255,255,255,0.55)')
        .borderRadius(12)
      } else if (this.isGated() || this.isWarning() || this.isCritical() || this.isCooldown()) {
        Text(heroHeadline(this.vitals))
          .fontSize(PhoneTheme.FONT_CAPTION)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.isCritical() ? PhoneTheme.TEXT_ON_DARK : PhoneTheme.TEXT_PRIMARY)
          .width('100%')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }

      // Crisis & Warning controls (stroke-free pills)
      if (this.isCritical()) {
        if (this.smnSentTime.length > 0) {
          Text(`SMS sent · ${this.smnSentTime}`)
            .fontSize(PhoneTheme.FONT_CAPTION)
            .fontColor('rgba(255,255,255,0.92)')
            .width('100%')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }

        Row({ space: 10 }) {
          Button("I'm awake")
            .fontSize(PhoneTheme.FONT_SUBTITLE)
            .fontWeight(FontWeight.Bold)
            .height(44)
            .layoutWeight(1)
            .backgroundColor(PhoneTheme.BG_CARD)
            .fontColor(PhoneTheme.STATE_CRIT_DARK)
            .borderRadius(PhoneTheme.PILL_RADIUS)
            .onClick(() => {
              this.onMarkWithThem();
            })

          Button('Call')
            .fontSize(PhoneTheme.FONT_SUBTITLE)
            .fontWeight(FontWeight.Bold)
            .height(44)
            .layoutWeight(1)
            .backgroundColor('rgba(255,255,255,0.22)')
            .fontColor(PhoneTheme.TEXT_ON_DARK)
            .borderRadius(PhoneTheme.PILL_RADIUS)
            .onClick(() => {
              this.onCallNow();
            })
        }
        .width('100%')
      } else if (this.isWarning()) {
        Row({ space: 8 }) {
          Button('Log check')
            .fontSize(PhoneTheme.FONT_CAPTION)
            .fontWeight(FontWeight.Bold)
            .height(38)
            .layoutWeight(1)
            .backgroundColor(PhoneTheme.BRAND_PRIMARY)
            .fontColor(PhoneTheme.TEXT_ON_DARK)
            .borderRadius(PhoneTheme.PILL_RADIUS)
            .onClick(() => {
              this.onQuickCheck();
            })

          Button('Call')
            .fontSize(PhoneTheme.FONT_CAPTION)
            .fontWeight(FontWeight.Bold)
            .height(38)
            .padding({ left: 16, right: 16 })
            .backgroundColor(PhoneTheme.BG_CARD)
            .fontColor(PhoneTheme.TEXT_PRIMARY)
            .borderRadius(PhoneTheme.PILL_RADIUS)
            .onClick(() => {
              this.onCallNow();
            })
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(PhoneTheme.CARD_PADDING)
    .borderRadius(PhoneTheme.CARD_RADIUS)
    .linearGradient(
      this.isCritical()
        ? { angle: 165, colors: [[PhoneTheme.STATE_CRIT_DARK, 0.0], ['#B91C1C', 1.0]] }
        : { angle: 165, colors: [[PhoneTheme.HERO_SKY_TOP, 0.0], [PhoneTheme.HERO_SKY_BOT, 1.0]] }
    )
    .shadow({ radius: 14, color: 'rgba(17, 19, 24, 0.06)', offsetY: 4 })
  }
}
