/*
 * Copyright (c) 2026 HypoAlert.
 * Wearable — Screen 2: Settings, simulation triggers, and sleep schedule configuration.
 */

import { format12H } from '../../common/utils/TimeUtils';
import { WatchPageDots } from './WatchPageDots';

@Component
export struct WatchSettingsView {
  @Link testToolsOpen: boolean;
  @Link autoScheduleEnabled: boolean;
  @Prop scheduleStartTime: string = '22:00';
  @Prop scheduleEndTime: string = '06:00';
  @Prop currentPage: number = 1;
  onGoToPage: (page: number) => void = () => {};
  onDropStep: () => void = () => {};
  onTriggerCrisis: () => void = () => {};
  onOpenTimeEdit: (isStart: boolean) => void = () => {};

  build() {
    Column() {
      Column({ space: 3 }) {
        Row() {
          Button('Back')
            .fontSize(9)
            .fontColor('#8A8F98')
            .backgroundColor(Color.Transparent)
            .width(52)
            .height(28)
            .padding(0)
            .onClick(() => {
              this.onGoToPage(0);
            })

          Text('Settings')
            .fontSize(9)
            .fontWeight(FontWeight.Medium)
            .fontColor('#9AA0A8')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
            .textAlign(TextAlign.Center)

          Blank()
            .width(52)
            .color(Color.Transparent)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        // Test tools demo dropdown: "+" collapsed, "–" expanded.
        Column({ space: 3 }) {
          Button() {
            Row() {
              Text('Test tools')
                .fontSize(10)
                .fontColor('#C7CCD4')
                .layoutWeight(1)
                .textAlign(TextAlign.Start)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })

              Text(this.testToolsOpen ? '–' : '+')
                .fontSize(11)
                .fontColor('#5B616B')
                .width(20)
                .textAlign(TextAlign.End)
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
          }
          .width('100%')
          .height(28)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.testToolsOpen = !this.testToolsOpen;
          })

          if (this.testToolsOpen) {
            Row({ space: 8 }) {
              Button('Drop')
                .fontSize(10)
                .height(32)
                .layoutWeight(1)
                .backgroundColor('#232A34')
                .fontColor('#9AA0A8')
                .borderRadius(18)
                .onClick(() => {
                  this.onDropStep();
                })

              Button('Crisis')
                .fontSize(10)
                .height(32)
                .layoutWeight(1)
                .backgroundColor('#232A34')
                .fontColor('#9AA0A8')
                .borderRadius(18)
                .onClick(() => {
                  this.onTriggerCrisis();
                })
            }
            .width('100%')
          }
        }
        .width('100%')
        .padding({ top: 6, bottom: 6, left: 8, right: 8 })
        .backgroundColor('#14181F')
        .borderRadius(12)

        // Sleep schedule card.
        Column({ space: 3 }) {
          Row() {
            Text('Sleep schedule')
              .fontSize(10)
              .fontColor('#E8EBEF')
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            Toggle({ type: ToggleType.Switch, isOn: this.autoScheduleEnabled })
              .selectedColor('#FFFFFF')
              .switchPointColor('#000000')
              .width(34)
              .height(20)
              .onChange((isOn: boolean) => {
                this.autoScheduleEnabled = isOn;
              })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Row() {
            Column({ space: 1 }) {
              Text('On')
                .fontSize(9)
                .fontColor('#5B616B')
                .textAlign(TextAlign.Start)
                .width('100%')

              Text(format12H(this.scheduleStartTime))
                .fontSize(12)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
                .textAlign(TextAlign.Start)
                .width('100%')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
            .padding({ top: 4, bottom: 4 })
            .onClick(() => {
              this.onOpenTimeEdit(true);
            })

            Column({ space: 1 }) {
              Text('Off')
                .fontSize(9)
                .fontColor('#5B616B')
                .textAlign(TextAlign.End)
                .width('100%')

              Text(format12H(this.scheduleEndTime))
                .fontSize(12)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
                .textAlign(TextAlign.End)
                .width('100%')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.End)
            .padding({ top: 4, bottom: 4 })
            .onClick(() => {
              this.onOpenTimeEdit(false);
            })
          }
          .width('100%')
        }
        .width('100%')
        .padding({ top: 6, bottom: 6, left: 8, right: 8 })
        .backgroundColor('#14181F')
        .borderRadius(12)

        // Spacer to lift dots onto matching alignment
        Blank().height(24)

        WatchPageDots({
          currentPage: this.currentPage,
          onSelectPage: this.onGoToPage
        })
      }
      .width(180)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .padding({ top: 26, bottom: 26 })
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#000000')
  }
}

@Preview({ title: 'Watch Settings Screen', width: 466, height: 466 })
@Component
struct WatchSettingsViewPreview {
  @State testToolsOpen: boolean = true;
  @State autoScheduleEnabled: boolean = true;

  build() {
    WatchSettingsView({
      testToolsOpen: $testToolsOpen,
      autoScheduleEnabled: $autoScheduleEnabled,
      scheduleStartTime: '22:00',
      scheduleEndTime: '06:00',
      currentPage: 1
    })
  }
}
