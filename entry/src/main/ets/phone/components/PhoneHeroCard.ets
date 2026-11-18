/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Soft Sky-Blue Hero Card with Multi-Height Telemetry Bars.
 * Displays Symptom Score (P1/P2) or 1D-CNN Symptom Risk (P3), Safety Streak filter, and urgent crisis actions.
 */

import { BodyType, DetectionPhase } from '../models/PhoneTypes';
import {
  activeScoreThreshold,
  evaluateSymptomState,
  heroHeadline,
  requiredStreakForBody,
  statusBadgeLabel
} from '../utils/PhoneRiskUtils';
import { PhoneTheme } from '../utils/PhoneTheme';

@Component
export struct PhoneHeroCard {
  @Prop @Watch('onHeroPropsChange') symptomScore: number = 1.2;
  @Prop @Watch('onHeroPropsChange') cnnRiskPct: number = 14;
  @Prop @Watch('onHeroPropsChange') phase: DetectionPhase = 'P1';
  @Prop @Watch('onHeroPropsChange') bodyType: BodyType = 'Adrenergic';
  @Prop personalCutoff: number = 4.3;
  @Prop @Watch('onHeroPropsChange') streakCount: number = 0;
  @Prop alertsTonight: number = 0;
  @Prop @Watch('onHeroPropsChange') isMotionGated: boolean = false;
  @Prop @Watch('onHeroPropsChange') baselineSlots: number = 15;
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

  private currentState(): string {
    return evaluateSymptomState(
      this.symptomScore,
      this.cnnRiskPct,
      this.phase,
      this.personalCutoff,
      this.streakCount,
      this.bodyType,
      this.isMotionGated,
      this.baselineSlots
    );
  }

  private isCritical(): boolean {
    return this.currentState() === 'Critical';
  }

  private isWarning(): boolean {
    return this.currentState() === 'Warning';
  }

  private isGated(): boolean {
    return this.currentState() === 'Gated';
  }

  private isLearning(): boolean {
    return this.currentState() === 'Learning';
  }

  private pillBg(): string {
    if (this.isCritical()) {
      return 'rgba(255, 255, 255, 0.22)';
    }
    if (this.isWarning()) {
      return PhoneTheme.STATE_WARN_BG;
    }
    if (this.isGated() || this.isLearning()) {
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
    if (this.isGated() || this.isLearning()) {
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

    // 10 multi-height rounded vertical pulse/tremor bars matching the reference hero strip
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
        Text(this.phase === 'P3' ? 'Symptom Risk' : 'Symptom Score')
          .fontSize(PhoneTheme.FONT_SUBTITLE)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.isCritical() ? 'rgba(255,255,255,0.9)' : PhoneTheme.TEXT_SECONDARY)
          .layoutWeight(1)

        Text(statusBadgeLabel(this.currentState()))
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
            Text(this.phase === 'P3' ? `${this.cnnRiskPct}` : `${this.symptomScore.toFixed(1)}`)
              .fontSize(PhoneTheme.FONT_HERO)
              .fontWeight(FontWeight.Bold)
              .letterSpacing(-1.2)
              .fontFeature('"tnum" on')
              .fontColor(this.isCritical() ? PhoneTheme.TEXT_ON_DARK : PhoneTheme.TEXT_PRIMARY)

            Text(this.phase === 'P3' ? '%' : 'score')
              .fontSize(PhoneTheme.FONT_SUBTITLE)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.isCritical() ? 'rgba(255,255,255,0.88)' : PhoneTheme.TEXT_SECONDARY)
              .margin({ bottom: 6 })
          }
          .alignItems(VerticalAlign.Bottom)

          Text(
            this.phase === 'P3'
              ? `${this.streakCount}/${requiredStreakForBody(this.bodyType)} · ${this.bodyType}`
              : `Cutoff ${activeScoreThreshold(this.phase, this.personalCutoff).toFixed(1)} · ${this.streakCount}/${requiredStreakForBody(this.bodyType)}`
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

      // 75-min Baseline / Motion Gate / Alert status note
      if (this.isLearning()) {
        Column({ space: 5 }) {
          Row() {
            Text('75m baseline')
              .fontSize(PhoneTheme.FONT_CAPTION)
              .fontWeight(FontWeight.Medium)
              .fontColor(PhoneTheme.BRAND_ACCENT)
              .layoutWeight(1)
            Text(`${this.baselineSlots}/15`)
              .fontSize(PhoneTheme.FONT_CAPTION)
              .fontWeight(FontWeight.Bold)
              .fontFeature('"tnum" on')
              .fontColor(PhoneTheme.TEXT_PRIMARY)
          }
          .width('100%')

          Progress({ value: this.baselineSlots, total: 15, type: ProgressType.Linear })
            .width('100%')
            .height(6)
            .color(PhoneTheme.BRAND_ACCENT)
            .backgroundColor('rgba(255,255,255,0.65)')
        }
        .width('100%')
        .padding(10)
        .backgroundColor('rgba(255,255,255,0.55)')
        .borderRadius(14)
      } else if (this.isGated() || this.isWarning() || this.isCritical()) {
        Text(heroHeadline(this.currentState(), this.phase))
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
