/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Screen 3: Phase & Risk Reports (Matches Reference Screen 3).
 * Features:
 * - <- Reports -> header with share/audit confirmation
 * - 3-segment pill toggle (P1 Warm-Up | P2 My Line | P3 1D-CNN) with solid black active capsule
 * - Multi-color Semicircle Arc Gauge (Blue -> Amber -> Red) with movable white-center indicator thumb
 * - Halftone dotted pattern 7-night bar chart with solid black selected bar & floating Normal/Surge badge
 */

import { CalibrationProgress, HistoryRepository, NightHistoryRecord } from '../../models/HistoryModel';
import { BodyType, DetectionPhase } from '../models/PhoneTypes';
import { activeScoreThreshold, phaseDescription } from '../utils/PhoneRiskUtils';
import { PhoneTheme } from '../utils/PhoneTheme';

@Component
export struct ReportsView {
  @Link activePhase: DetectionPhase;
  @Prop @Watch('onPropsUpdate') symptomScore: number = 1.2;
  @Prop @Watch('onPropsUpdate') cnnRiskPct: number = 14;
  @Prop @Watch('onPropsUpdate') bodyType: BodyType = 'Adrenergic';
  @Prop @Watch('onPropsUpdate') calibration: CalibrationProgress = {
    buzzPricks: 2,
    buzzPricksTarget: 3,
    confirmedLows: 0,
    confirmedLowsTarget: 1,
    fineNights: 6,
    fineNightsTarget: 10,
    personalCutoff: 4.3,
    phase2Unlocked: false,
    phase3Unlocked: false,
    lastCheckSummary: ''
  };
  @Prop @Watch('onPropsUpdate') historyVersion: number = 0;

  @State selectedBarIdx: number = 4; // Tonight highlighted solid black bar
  @State exportToast: string = '';
  onBack: () => void = () => {};
  onSelectPhase: (phase: DetectionPhase) => void = () => {};

  private arcSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private arcCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.arcSettings);
  private arcReady: boolean = false;
  private arcW: number = 300;
  private arcH: number = 175;

  private barSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private barCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.barSettings);
  private barReady: boolean = false;
  private barW: number = 310;
  private barH: number = 165;

  onPropsUpdate(): void {
    this.drawArcGauge();
    this.drawDottedBars();
  }

  private gaugeFraction(): number {
    if (this.activePhase === 'P3') {
      return Math.min(1.0, Math.max(0.05, this.cnnRiskPct / 100.0));
    }
    const maxScore: number = 6.2;
    return Math.min(1.0, Math.max(0.06, this.symptomScore / maxScore));
  }

  private drawArcGauge(): void {
    if (!this.arcReady) {
      return;
    }
    const ctx: CanvasRenderingContext2D = this.arcCtx;
    const W: number = this.arcW > 0 ? this.arcW : 300;
    const H: number = this.arcH > 0 ? this.arcH : 175;
    ctx.clearRect(0, 0, W, H);

    const cx: number = W / 2;
    const cy: number = H * 0.80;
    const radius: number = Math.min(W * 0.40, H * 0.66);
    const startAngle: number = Math.PI * 0.88;
    const totalSweep: number = Math.PI * 1.24;

    ctx.lineCap = 'round';
    ctx.lineWidth = 14;

    // 1. Blue steady arc (0 -> 52%)
    const a1End: number = startAngle + totalSweep * 0.50;
    ctx.strokeStyle = PhoneTheme.BRAND_ACCENT;
    ctx.beginPath();
    ctx.arc(cx, cy, radius, startAngle, a1End);
    ctx.stroke();

    // 2. Golden Amber warning arc (54% -> 76%)
    const a2Start: number = startAngle + totalSweep * 0.54;
    const a2End: number = startAngle + totalSweep * 0.76;
    ctx.strokeStyle = PhoneTheme.STATE_WARN;
    ctx.beginPath();
    ctx.arc(cx, cy, radius, a2Start, a2End);
    ctx.stroke();

    // 3. Coral Red critical arc (80% -> 100%)
    const a3Start: number = startAngle + totalSweep * 0.80;
    const a3End: number = startAngle + totalSweep;
    ctx.strokeStyle = PhoneTheme.STATE_CRIT;
    ctx.beginPath();
    ctx.arc(cx, cy, radius, a3Start, a3End);
    ctx.stroke();

    // Indicator thumb circle at current risk position
    const frac: number = this.gaugeFraction();
    const thumbAngle: number = startAngle + totalSweep * frac;
    const tx: number = cx + Math.cos(thumbAngle) * radius;
    const ty: number = cy + Math.sin(thumbAngle) * radius;
    const thumbColor: string = frac >= 0.78
      ? PhoneTheme.STATE_CRIT
      : (frac >= 0.52 ? PhoneTheme.STATE_WARN : PhoneTheme.BRAND_ACCENT);

    ctx.fillStyle = thumbColor;
    ctx.beginPath();
    ctx.arc(tx, ty, 12, 0, Math.PI * 2);
    ctx.fill();

    ctx.fillStyle = '#FFFFFF';
    ctx.beginPath();
    ctx.arc(tx, ty, 5.5, 0, Math.PI * 2);
    ctx.fill();
  }

  private chartRecords(): NightHistoryRecord[] {
    const _v: number = this.historyVersion;
    const all: NightHistoryRecord[] = HistoryRepository.getHistory();
    if (_v >= 0 && all.length >= 5) {
      return all.slice(0, 5).reverse();
    }
    return all;
  }

  private drawDottedBars(): void {
    if (!this.barReady) {
      return;
    }
    const ctx: CanvasRenderingContext2D = this.barCtx;
    const W: number = this.barW > 0 ? this.barW : 310;
    const H: number = this.barH > 0 ? this.barH : 165;
    ctx.clearRect(0, 0, W, H);

    const list: NightHistoryRecord[] = this.chartRecords();
    const n: number = list.length;
    if (n === 0) {
      return;
    }

    const padX: number = 14;
    const bottomLabelH: number = 22;
    const topBadgeH: number = 28;
    const maxBarH: number = H - bottomLabelH - topBadgeH;
    const slotW: number = (W - padX * 2) / n;
    const barW: number = Math.min(44, slotW * 0.72);
    const cutoff: number = activeScoreThreshold(this.activePhase, this.calibration.personalCutoff);

    for (let i: number = 0; i < n; i++) {
      const rec: NightHistoryRecord = list[i];
      const score: number = rec.id === 'night_0' ? Math.max(rec.peakSymptomScore, this.symptomScore) : rec.peakSymptomScore;
      const norm: number = Math.min(1.0, Math.max(0.22, score / 6.0));
      const bh: number = Math.round(norm * maxBarH);
      const bx: number = padX + i * slotW + (slotW - barW) / 2;
      const by: number = H - bottomLabelH - bh;
      const isSelected: boolean = i === this.selectedBarIdx;

      if (isSelected) {
        // Solid dark obsidian active bar
        const r: number = 12;
        ctx.fillStyle = PhoneTheme.BRAND_PRIMARY;
        ctx.beginPath();
        ctx.moveTo(bx, by + r);
        ctx.arc(bx + r, by + r, r, Math.PI, Math.PI * 1.5);
        ctx.lineTo(bx + barW - r, by);
        ctx.arc(bx + barW - r, by + r, r, Math.PI * 1.5, 0);
        ctx.lineTo(bx + barW, by + bh);
        ctx.lineTo(bx, by + bh);
        ctx.closePath();
        ctx.fill();

        // Small white indicator dot near top inside black bar
        ctx.fillStyle = '#FFFFFF';
        ctx.beginPath();
        ctx.arc(bx + barW / 2, by + 11, 2.5, 0, Math.PI * 2);
        ctx.fill();

        // Floating pill above active bar
        const isHigh: boolean = score >= cutoff;
        const badgeText: string = isHigh ? 'Surge' : 'Normal';
        const pillW: number = 54;
        const pillH: number = 20;
        const px: number = Math.min(W - pillW - 4, Math.max(4, bx + barW / 2 - pillW / 2));
        const py: number = Math.max(2, by - pillH - 6);

        ctx.fillStyle = isHigh ? PhoneTheme.STATE_CRIT_BG : PhoneTheme.STATE_OK_BG;
        ctx.beginPath();
        ctx.arc(px + 10, py + 10, 10, Math.PI * 0.5, Math.PI * 1.5);
        ctx.lineTo(px + pillW - 10, py);
        ctx.arc(px + pillW - 10, py + 10, 10, Math.PI * 1.5, Math.PI * 0.5);
        ctx.closePath();
        ctx.fill();

        ctx.fillStyle = isHigh ? PhoneTheme.STATE_CRIT_TEXT : PhoneTheme.STATE_OK_TEXT;
        ctx.font = 'normal bold 10px sans-serif';
        ctx.textAlign = 'center';
        ctx.fillText(badgeText, px + pillW / 2, py + 13.5);
      } else {
        // Halftone dot matrix bar matching Screen 3 of the reference!
        ctx.fillStyle = '#1E2430';
        const step: number = 6;
        for (let dy: number = by + 4; dy < by + bh - 2; dy += step) {
          for (let dx: number = bx + 4; dx < bx + barW - 3; dx += step) {
            ctx.beginPath();
            ctx.arc(dx, dy, 1.35, 0, Math.PI * 2);
            ctx.fill();
          }
        }
      }

      // Day label at bottom
      ctx.fillStyle = isSelected ? PhoneTheme.TEXT_PRIMARY : PhoneTheme.TEXT_MUTED;
      ctx.font = isSelected ? 'normal bold 11px sans-serif' : 'normal normal 11px sans-serif';
      ctx.textAlign = 'center';
      ctx.fillText(rec.dayOfWeek, bx + barW / 2, H - 5);
    }
  }

  @Builder
  phasePill(phase: DetectionPhase, label: string) {
    Button(label)
      .fontSize(PhoneTheme.FONT_BODY)
      .fontWeight(this.activePhase === phase ? FontWeight.Bold : FontWeight.Medium)
      .height(40)
      .layoutWeight(1)
      .backgroundColor(this.activePhase === phase ? PhoneTheme.BRAND_PRIMARY : Color.Transparent)
      .fontColor(this.activePhase === phase ? PhoneTheme.TEXT_ON_DARK : PhoneTheme.TEXT_SECONDARY)
      .borderRadius(20)
      .onClick(() => {
        this.onSelectPhase(phase);
      })
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        // <- Reports -> Header
        Row() {
          Button() {
            SymbolGlyph($r('sys.symbol.arrow_left'))
              .fontSize(17)
              .fontColor([PhoneTheme.TEXT_PRIMARY])
          }
          .width(42)
          .height(42)
          .backgroundColor(PhoneTheme.BG_CARD)
          .borderRadius(21)
          .shadow({ radius: 10, color: 'rgba(17, 19, 24, 0.05)', offsetY: 2 })
          .onClick(() => {
            this.onBack();
          })

          Text('Reports')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(PhoneTheme.TEXT_PRIMARY)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)

          Button() {
            SymbolGlyph($r('sys.symbol.share'))
              .fontSize(17)
              .fontColor([PhoneTheme.TEXT_PRIMARY])
          }
          .width(42)
          .height(42)
          .backgroundColor(PhoneTheme.BG_CARD)
          .borderRadius(21)
          .shadow({ radius: 10, color: 'rgba(17, 19, 24, 0.05)', offsetY: 2 })
          .onClick(() => {
            this.exportToast = 'Summary copied';
          })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        if (this.exportToast.length > 0) {
          Text(this.exportToast)
            .fontSize(PhoneTheme.FONT_CAPTION)
            .fontColor(PhoneTheme.STATE_OK_TEXT)
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .backgroundColor(PhoneTheme.STATE_OK_BG)
            .borderRadius(PhoneTheme.PILL_RADIUS)
            .width('100%')
            .textAlign(TextAlign.Center)
        }

        // 3-Segment Phase Switcher Pill (P1 Warm-Up | P2 My Line | P3 1D-CNN)
        Row({ space: 4 }) {
          this.phasePill('P1', 'P1 Warm-Up')
          this.phasePill('P2', 'P2 My Line')
          this.phasePill('P3', 'P3 1D-CNN')
        }
        .width('100%')
        .height(48)
        .padding(4)
        .backgroundColor(PhoneTheme.BG_CARD)
        .borderRadius(24)
        .shadow({ radius: 10, color: 'rgba(17, 19, 24, 0.04)', offsetY: 2 })

        // Large Semicircle Multi-Color Arc Gauge
        Column({ space: 6 }) {
          Stack({ alignContent: Alignment.Bottom }) {
            Canvas(this.arcCtx)
              .width('100%')
              .height(180)
              .onAreaChange((_o: Area, n: Area) => {
                const w: number = Number(n.width);
                const h: number = Number(n.height);
                if (w > 0 && h > 0) {
                  this.arcW = w;
                  this.arcH = h;
                  this.drawArcGauge();
                }
              })
              .onReady(() => {
                this.arcReady = true;
                this.drawArcGauge();
              })

            Column({ space: 2 }) {
              Row({ space: 4 }) {
                Text(this.activePhase === 'P3' ? `${this.cnnRiskPct}` : `${this.symptomScore.toFixed(1)}`)
                  .fontSize(42)
                  .fontWeight(FontWeight.Bold)
                  .letterSpacing(-1.2)
                  .fontFeature('"tnum" on')
                  .fontColor(PhoneTheme.TEXT_PRIMARY)

                Text(this.activePhase === 'P3' ? '%' : 'score')
                  .fontSize(PhoneTheme.FONT_SUBTITLE)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(PhoneTheme.TEXT_MUTED)
                  .margin({ bottom: 7 })
              }
              .alignItems(VerticalAlign.Bottom)

              Text(this.bodyType)
                .fontSize(PhoneTheme.FONT_BODY)
                .fontColor(PhoneTheme.TEXT_SECONDARY)
            }
            .alignItems(HorizontalAlign.Center)
            .margin({ bottom: 18 })
          }
          .width('100%')

          // Colored breakdown legend matching reference
          Row({ space: 14 }) {
            Row({ space: 5 }) {
              Circle({ width: 7, height: 7 }).fill(PhoneTheme.BRAND_ACCENT)
              Text('Steady <3.0')
                .fontSize(PhoneTheme.FONT_CAPTION)
                .fontColor(PhoneTheme.TEXT_SECONDARY)
            }
            .alignItems(VerticalAlign.Center)

            Row({ space: 5 }) {
              Circle({ width: 7, height: 7 }).fill(PhoneTheme.STATE_WARN)
              Text('Rising 3.0–3.6')
                .fontSize(PhoneTheme.FONT_CAPTION)
                .fontColor(PhoneTheme.TEXT_SECONDARY)
            }
            .alignItems(VerticalAlign.Center)
          }
          .justifyContent(FlexAlign.Center)
          .width('100%')

          Row({ space: 5 }) {
            Circle({ width: 7, height: 7 }).fill(PhoneTheme.STATE_CRIT)
            Text(`Surge ≥${activeScoreThreshold(this.activePhase, this.calibration.personalCutoff).toFixed(1)}`)
              .fontSize(PhoneTheme.FONT_CAPTION)
              .fontColor(PhoneTheme.TEXT_SECONDARY)
          }
          .justifyContent(FlexAlign.Center)
          .width('100%')
        }
        .width('100%')

        // Dotted Bar Chart White Card (Average Symptom Score)
        Column({ space: 10 }) {
          Row() {
            Text('Nightly Score')
              .fontSize(PhoneTheme.FONT_SECTION)
              .fontWeight(FontWeight.Bold)
              .fontColor(PhoneTheme.TEXT_PRIMARY)
              .layoutWeight(1)

            Text(phaseDescription(this.activePhase, this.calibration.personalCutoff))
              .fontSize(PhoneTheme.FONT_CAPTION)
              .fontColor(PhoneTheme.TEXT_MUTED)
          }
          .width('100%')

          Canvas(this.barCtx)
            .width('100%')
            .height(168)
            .onAreaChange((_o: Area, n: Area) => {
              const w: number = Number(n.width);
              const h: number = Number(n.height);
              if (w > 0 && h > 0) {
                this.barW = w;
                this.barH = h;
                this.drawDottedBars();
              }
            })
            .onReady(() => {
              this.barReady = true;
              this.drawDottedBars();
            })
            .onClick((evt: ClickEvent) => {
              const count: number = this.chartRecords().length;
              if (count > 0 && this.barW > 0) {
                const idx: number = Math.min(count - 1, Math.max(0, Math.floor((evt.x / this.barW) * count)));
                this.selectedBarIdx = idx;
                this.drawDottedBars();
              }
            })
        }
        .width('100%')
        .padding(PhoneTheme.CARD_PADDING)
        .backgroundColor(PhoneTheme.BG_CARD)
        .borderRadius(PhoneTheme.CARD_RADIUS)
        .shadow({ radius: 12, color: 'rgba(17, 19, 24, 0.04)', offsetY: 3 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 104 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(PhoneTheme.BG_PAGE)
    .scrollBar(BarState.Off)
    .scrollable(ScrollDirection.Vertical)
  }
}
