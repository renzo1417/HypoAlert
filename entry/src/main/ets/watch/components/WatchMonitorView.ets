/*
 * Copyright (c) 2026 HypoAlert.
 * Wearable — Screen 1: Primary Monitor dial showing symptom risk, 75-min baseline, and streak state.
 */

import { BodyPhenotype, VitalsData, VitalsEngine } from '../../models/VitalsModel';
import { format12H } from '../../common/utils/TimeUtils';
import { WatchPageDots } from './WatchPageDots';

@Component
export struct WatchMonitorView {
  @Prop isMonitoringActive: boolean = false;
  @Prop vitals: VitalsData = VitalsEngine.createInitialVitals(BodyPhenotype.ADRENERGIC, 1, 3.7);
  @Prop ringScale: number = 1.0;
  @Prop ringOpacity: number = 0.9;
  @Prop simStatus: string = 'Standby - tap START';
  @Prop hapticStatus: string = 'Checks 0/3 • Max 2/night';
  @Prop currentPage: number = 0;
  @Prop isPhoneConnected: boolean = true;
  onToggleMonitoring: () => void = () => {};
  onSelectPage: (page: number) => void = () => {};

  private getRingStrokeColor(): string {
    if (!this.isMonitoringActive) {
      return '#23262B';
    }
    if (this.vitals.statusTier === 'WATCH') {
      return '#FFB74D';
    }
    if (this.vitals.statusTier === 'MOVING') {
      return '#6E747D';
    }
    return '#00A9CE';
  }

  private getStatusColor(): string {
    if (this.vitals.statusTier === 'ALERT') {
      return '#FF5252';
    }
    if (this.vitals.statusTier === 'WATCH') {
      return '#FFB74D';
    }
    if (this.vitals.statusTier === 'MOVING') {
      return '#9AA0A8';
    }
    if (this.vitals.statusTier === 'BASELINE' || this.vitals.statusTier === 'COOLDOWN') {
      return '#00E5FF';
    }
    return '#00E676';
  }

  private getSubVitalLabel(): string {
    if (!this.vitals.isSedentary) {
      return `${this.vitals.pulse} BPM • Moving`;
    }
    if (this.vitals.tremorIndex >= 0.14) {
      return `${this.vitals.pulse} BPM • Tremor`;
    }
    return `${this.vitals.pulse} BPM • HRV ${this.vitals.rmssd}`;
  }

  build() {
    Column() {
      Column({ space: 3 }) {
        Row() {
          Row({ space: 4 }) {
            Circle({ width: 5, height: 5 })
              .fill(this.isPhoneConnected ? '#00E676' : '#5B616B')
            Text('HYPOALERT')
              .fontSize(9)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.isMonitoringActive ? '#00E5FF' : '#8A8F98')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .layoutWeight(1)
          .alignItems(VerticalAlign.Center)
          .margin({ left: 15 })

          Text(format12H(this.vitals.timestamp))
            .fontSize(9)
            .fontColor('#8A8F98')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .textAlign(TextAlign.End)
            .margin({ right: 15 })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Stack({ alignContent: Alignment.Center }) {
          Circle({ width: 116, height: 116 })
            .fill(Color.Transparent)
            .stroke(this.getRingStrokeColor())
            .strokeWidth(3)
            .opacity(this.isMonitoringActive ? this.ringOpacity : 0.7)
            .scale({ x: this.ringScale, y: this.ringScale })

          Button() {
            Column({ space: 2 }) {
              if (!this.isMonitoringActive) {
                Text('START')
                  .fontSize(14)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FFFFFF')
                  .textAlign(TextAlign.Center)

                Text('Tap to monitor')
                  .fontSize(9)
                  .fontColor('#6E747D')
                  .textAlign(TextAlign.Center)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              } else if (this.vitals.baselineMinutes < VitalsEngine.BASELINE_TOTAL_MINUTES) {
                Text(`${this.vitals.baselineMinutes}m`)
                  .fontSize(21)
                  .fontWeight(FontWeight.Bolder)
                  .fontColor('#FFFFFF')
                  .textAlign(TextAlign.Center)

                Text('OF 75M SETUP')
                  .fontSize(8)
                  .fontColor('#9AA0A8')
                  .textAlign(TextAlign.Center)

                Text('Learning sleep')
                  .fontSize(9)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#00E5FF')
                  .textAlign(TextAlign.Center)

                Text(`${this.vitals.pulse} BPM • Still`)
                  .fontSize(9)
                  .fontColor('#9AA0A8')
                  .textAlign(TextAlign.Center)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              } else if (!this.vitals.isSedentary) {
                Text('PAUSED')
                  .fontSize(15)
                  .fontWeight(FontWeight.Bolder)
                  .fontColor('#FFB74D')
                  .textAlign(TextAlign.Center)

                Text('MOVING')
                  .fontSize(8)
                  .fontColor('#9AA0A8')
                  .textAlign(TextAlign.Center)

                Text('Wait till still')
                  .fontSize(9)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#9AA0A8')
                  .textAlign(TextAlign.Center)

                Text(`${this.vitals.pulse} BPM • Awake`)
                  .fontSize(9)
                  .fontColor('#6E747D')
                  .textAlign(TextAlign.Center)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              } else {
                Text(`${this.vitals.symptomRiskPct}%`)
                  .fontSize(22)
                  .fontWeight(FontWeight.Bolder)
                  .fontColor('#FFFFFF')
                  .textAlign(TextAlign.Center)

                Text('SYMPTOM RISK')
                  .fontSize(7.5)
                  .fontColor('#9AA0A8')
                  .textAlign(TextAlign.Center)

                Text(this.vitals.statusWord)
                  .fontSize(10)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.getStatusColor())
                  .textAlign(TextAlign.Center)

                Text(this.getSubVitalLabel())
                  .fontSize(9)
                  .fontColor('#9AA0A8')
                  .textAlign(TextAlign.Center)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
          }
          .width(106)
          .height(106)
          .borderRadius(53)
          .backgroundColor('#101318')
          .shadow(this.isMonitoringActive ? {
            radius: 12,
            color: this.getRingStrokeColor(),
            offsetX: 0,
            offsetY: 0,
            fill: false
          } : {
            radius: 0,
            color: Color.Transparent,
            offsetX: 0,
            offsetY: 0,
            fill: false
          })
          .onClick(() => {
            this.onToggleMonitoring();
          })
        }
        .width(124)
        .height(124)

        Column({ space: 1 }) {
          Text(this.simStatus)
            .fontSize(9)
            .fontColor('#8A8F98')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .textAlign(TextAlign.Center)
            .width('100%')

          Text(this.hapticStatus)
            .fontSize(9)
            .fontColor('#5B616B')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .textAlign(TextAlign.Center)
            .width('100%')
        }
        .width('100%')

        Divider()
          .color('#2E333B')
          .strokeWidth(1)
          .width('100%')

        WatchPageDots({
          currentPage: this.currentPage,
          totalPages: 3,
          onSelectPage: this.onSelectPage
        })
      }
      .width(180)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .padding({ top: 40, bottom: 26 })
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#000000')
  }
}

@Preview({ title: 'Watch Monitor Screen', width: 466, height: 466 })
@Component
struct WatchMonitorViewPreview {
  build() {
    WatchMonitorView({
      isMonitoringActive: true,
      vitals: VitalsEngine.createInitialVitals(BodyPhenotype.ADRENERGIC, 3, 3.7),
      simStatus: 'P3 1D-CNN • Base OK',
      hapticStatus: 'Checks 0/3 • 0/2 alerts'
    })
  }
}
