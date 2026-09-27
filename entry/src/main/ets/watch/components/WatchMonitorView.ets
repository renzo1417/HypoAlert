/*
 * Copyright (c) 2026 HypoAlert.
 * Wearable — Screen 1: Primary Monitor dial with real-time vitals and pulsating ring.
 */

import { VitalsData } from '../../models/VitalsModel';
import { format12H } from '../../common/utils/TimeUtils';
import { WatchPageDots } from './WatchPageDots';

@Component
export struct WatchMonitorView {
  @Prop isMonitoringActive: boolean = false;
  @Prop vitals: VitalsData = {
    pulse: 62,
    skinTemp: 36.0,
    tremorIndex: 0.2,
    glucose: 5.4,
    timestamp: '12:23 PM'
  };
  @Prop ringScale: number = 1.0;
  @Prop ringOpacity: number = 0.9;
  @Prop simStatus: string = 'Standby - tap START';
  @Prop hapticStatus: string = 'Haptic: idle';
  @Prop currentPage: number = 0;
  onToggleMonitoring: () => void = () => {};
  onSelectPage: (page: number) => void = () => {};

  build() {
    Column() {
      Column({ space: 3 }) {
        Row() {
          Text('HYPOALERT')
            .fontSize(9)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.isMonitoringActive ? '#00E5FF' : '#8A8F98')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
            .textAlign(TextAlign.Start)
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
            .stroke(this.isMonitoringActive ? '#00A9CE' : '#23262B')
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
              } else {
                Text(`${this.vitals.glucose.toFixed(1)}`)
                  .fontSize(22)
                  .fontWeight(FontWeight.Bolder)
                  .fontColor('#FFFFFF')
                  .textAlign(TextAlign.Center)

                Text('mmol/L')
                  .fontSize(9)
                  .fontColor('#9AA0A8')
                  .textAlign(TextAlign.Center)

                Text('Stable')
                  .fontSize(10)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#00E676')
                  .textAlign(TextAlign.Center)

                Text(`${this.vitals.pulse} BPM`)
                  .fontSize(10)
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
            color: '#00E5FF',
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
      vitals: {
        pulse: 61,
        skinTemp: 36.0,
        tremorIndex: 0.2,
        glucose: 5.4,
        timestamp: '23:30'
      }
    })
  }
}
