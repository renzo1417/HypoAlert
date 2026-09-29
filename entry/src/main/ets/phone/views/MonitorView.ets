/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Screen 1: Bedside Nocturnal Guardian Monitor.
 * Icon hub: tap a biomarker to open its full detail page.
 */

import { PhoneHeroCard } from '../components/PhoneHeroCard';
import { MetricIconButton } from '../components/MetricIconButton';
import { MetricDetailPage } from './details/MetricDetailPage';
import { PhoneTheme } from '../utils/PhoneTheme';
import { tempColor, riskLevel, restlessShort } from '../utils/PhoneRiskUtils';

@Component
export struct MonitorView {
  @Prop glucose: number = 5.5;
  @Prop riskIndex: number = 12;
  @Prop currentTime: string = '00:00:00';
  @Prop heartRate: number = 62;
  @Prop watchBattery: number = 86;
  @Prop tremorPSD: number = 0.12;
  @Prop skinTemp: number = 36.0;
  @Prop bannerFlash: boolean = false;
  @Prop isWatchConnected: boolean = true;
  @Prop caregiverName: string = 'Maria Santos';
  @Prop caregiverPhone: string = '+63 917 123 4567';
  ppgContext: CanvasRenderingContext2D | null = null;
  onCanvasReady: () => void = () => {};
  onCallNow: () => void = () => {};
  onMarkWithThem: () => void = () => {};
  onConnectWatch: () => void = () => {};
  onNavigateTab: (index: number) => void = () => {};
  @State selectedMetric: string = '';

  private getTremorColor(): string {
    if (this.tremorPSD > 1.0) {
      return PhoneTheme.STATE_CRIT;
    }
    if (this.tremorPSD > 0.4) {
      return PhoneTheme.STATE_WARN;
    }
    return PhoneTheme.STATE_OK;
  }

  private getPulseColor(): string {
    const lvl: string = riskLevel(this.riskIndex);
    if (lvl === 'Critical') {
      return PhoneTheme.STATE_CRIT;
    }
    if (lvl === 'Warning' || this.heartRate > 80) {
      return PhoneTheme.STATE_WARN;
    }
    return PhoneTheme.STATE_OK;
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        // Watch offline reminder banner (only visible when BLE disconnected)
        if (!this.isWatchConnected) {
          Row({ space: 10 }) {
            Circle({ width: 7, height: 7 })
              .fill(PhoneTheme.STATE_WARN)

            Column({ space: 1 }) {
              Text('Watch Disconnected')
                .fontSize(PhoneTheme.FONT_SUBTITLE)
                .fontWeight(FontWeight.Bold)
                .fontColor(PhoneTheme.TEXT_PRIMARY)
              Text('Link watch stream to resume nocturnal monitoring')
                .fontSize(PhoneTheme.FONT_CAPTION)
                .fontColor(PhoneTheme.TEXT_MUTED)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Button('Connect')
              .fontSize(PhoneTheme.FONT_BODY)
              .fontWeight(FontWeight.Bold)
              .height(30)
              .padding({ left: 12, right: 12 })
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

        // Primary Hero Card — hub only, hidden in detail view
        if (this.selectedMetric.length === 0) {
          PhoneHeroCard({
            glucose: this.glucose,
            riskIndex: this.riskIndex,
            currentTime: this.currentTime,
            heartRate: this.heartRate,
            watchBattery: this.watchBattery,
            bannerFlash: this.bannerFlash,
            isWatchConnected: this.isWatchConnected,
            onCallNow: this.onCallNow,
            onMarkWithThem: this.onMarkWithThem
          })
        }

        // Core Sympathetic Biomarkers — icon hub, tap opens full detail page
        if (this.selectedMetric.length === 0) {
          Column({ space: 10 }) {
            Row() {
              Text('Biomarkers')
                .fontSize(PhoneTheme.FONT_SECTION)
                .fontWeight(FontWeight.Bold)
                .fontColor(PhoneTheme.TEXT_PRIMARY)
              Blank()
              Text('Tap icon for detail')
                .fontSize(PhoneTheme.FONT_CAPTION)
                .fontColor(PhoneTheme.TEXT_TERTIARY)
            }
            .width('100%')
            .padding({ left: 2, right: 2 })

            Grid() {
              GridItem() {
                MetricIconButton({
                  title: 'Micro-Tremor',
                  value: `${this.tremorPSD.toFixed(2)} PSD`,
                  hint: restlessShort(this.tremorPSD),
                  statusColor: this.getTremorColor(),
                  glyph: '≋',
                  onOpen: () => {
                    animateTo({ duration: 220, curve: Curve.EaseInOut }, () => {
                      this.selectedMetric = 'tremor';
                    });
                  }
                })
              }
              GridItem() {
                MetricIconButton({
                  title: 'Pulse & Tone',
                  value: `${this.heartRate} bpm`,
                  hint: 'PPG waveform',
                  statusColor: this.getPulseColor(),
                  glyph: '♥',
                  onOpen: () => {
                    animateTo({ duration: 220, curve: Curve.EaseInOut }, () => {
                      this.selectedMetric = 'pulse';
                    });
                  }
                })
              }
              GridItem() {
                MetricIconButton({
                  title: 'Skin Temp',
                  value: `${this.skinTemp.toFixed(1)}°C`,
                  hint: 'Thermal drift',
                  statusColor: tempColor(this.skinTemp),
                  glyph: '°',
                  onOpen: () => {
                    animateTo({ duration: 220, curve: Curve.EaseInOut }, () => {
                      this.selectedMetric = 'temp';
                    });
                  }
                })
              }
              GridItem() {
                MetricIconButton({
                  title: 'Baseline',
                  value: 'Calibrated',
                  hint: '45m window',
                  statusColor: PhoneTheme.BRAND_ACCENT,
                  glyph: '◉',
                  onOpen: () => {
                    animateTo({ duration: 220, curve: Curve.EaseInOut }, () => {
                      this.selectedMetric = 'baseline';
                    });
                  }
                })
              }
            }
            .columnsTemplate('1fr 1fr')
            .columnsGap(10)
            .rowsGap(10)
            .width('100%')
            .height(306)
          }
          .width('100%')
        } else {
          MetricDetailPage({
            metricId: this.selectedMetric,
            heartRate: this.heartRate,
            tremorPSD: this.tremorPSD,
            skinTemp: this.skinTemp,
            riskIndex: this.riskIndex,
            ppgContext: this.ppgContext,
            onCanvasReady: this.onCanvasReady,
            onBack: () => {
              animateTo({ duration: 220, curve: Curve.EaseInOut }, () => {
                this.selectedMetric = '';
              });
            }
          })
        }

        // Calming Bedside Safeguard Footer Notice
        if (this.selectedMetric.length === 0) {
        Row({ space: 6 }) {
          Circle({ width: 4, height: 4 }).fill(PhoneTheme.TEXT_TERTIARY)
          Text('Bedside Guardian: Haptic wrist alert sounds loud phone siren if unawakened')
            .fontSize(PhoneTheme.FONT_MICRO)
            .fontColor(PhoneTheme.TEXT_TERTIARY)
            .layoutWeight(1)
        }
        .width('100%')
        .padding({ left: 4, right: 4, top: 4, bottom: 20 })
        .alignItems(VerticalAlign.Center)
        }
      }
      .width('100%')
      .padding({ left: 18, right: 18, top: 6, bottom: 36 })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .scrollable(ScrollDirection.Vertical)
  }
}
