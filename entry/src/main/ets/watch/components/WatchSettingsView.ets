/*
 * Copyright (c) 2026 HypoAlert.
 * Wearable — Screen 3: Settings, Phase 1-3 profile view, demo tools, and sleep schedule.
 */

import { BodyPhenotype, DetectionPhase, VitalsEngine } from '../../models/VitalsModel';
import { format12H } from '../../common/utils/TimeUtils';
import { WatchPageDots } from './WatchPageDots';

@Component
export struct WatchSettingsView {
  @Link testToolsOpen: boolean;
  @Link autoScheduleEnabled: boolean;
  @Prop isPhoneConnected: boolean = true;
  @Prop phenotype: BodyPhenotype = BodyPhenotype.ADRENERGIC;
  @Prop activePhase: DetectionPhase = 1;
  @Prop replayActive: boolean = false;
  @Prop scheduleStartTime: string = '22:00';
  @Prop scheduleEndTime: string = '06:00';
  @Prop currentPage: number = 2;
  onGoToPage: (page: number) => void = () => {};
  onStepCheck: () => void = () => {};
  onTriggerCrisis: () => void = () => {};
  onToggleMotion: () => void = () => {};
  onStartBaseline: () => void = () => {};
  onReplayReal: () => void = () => {};
  onTogglePhenotype: () => void = () => {};
  onCyclePhase: () => void = () => {};
  onOpenTimeEdit: (isStart: boolean) => void = () => {};
  onTogglePhoneConnection: () => void = () => {};

  build() {
    Scroll() {
      Column({ space: 4 }) {
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

        // Phone connection card
        Column({ space: 2 }) {
          Row() {
            Row({ space: 4 }) {
              Circle({ width: 6, height: 6 })
                .fill(this.isPhoneConnected ? '#00E676' : '#5B616B')
              Text(this.isPhoneConnected ? 'Phone linked' : 'Phone offline')
                .fontSize(9)
                .fontColor(this.isPhoneConnected ? '#E8EBEF' : '#8A8F98')
            }
            .layoutWeight(1)

            Button(this.isPhoneConnected ? 'Unlink' : 'Link')
              .fontSize(9)
              .height(22)
              .padding({ left: 8, right: 8 })
              .backgroundColor(this.isPhoneConnected ? '#232A34' : '#00A9CE')
              .fontColor(this.isPhoneConnected ? '#C7CCD4' : '#FFFFFF')
              .borderRadius(11)
              .onClick(() => {
                this.onTogglePhoneConnection();
              })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .padding({ top: 4, bottom: 4, left: 8, right: 8 })
        .backgroundColor('#14181F')
        .borderRadius(12)

        // Detection Profile & Active Phase Card
        Column({ space: 4 }) {
          Row() {
            Text('Body Type')
              .fontSize(8)
              .fontColor('#8A8F98')
              .layoutWeight(1)
            Button(this.phenotype === BodyPhenotype.ADRENERGIC ? 'Adren. (3x)' : 'Blunted (2x)')
              .fontSize(8)
              .height(20)
              .padding({ left: 7, right: 7 })
              .backgroundColor('#232A34')
              .fontColor('#00E5FF')
              .borderRadius(10)
              .onClick(() => {
                this.onTogglePhenotype();
              })
          }
          .width('100%')

          Row() {
            Text('Phase')
              .fontSize(8)
              .fontColor('#8A8F98')
              .layoutWeight(1)
            Button(VitalsEngine.getPhaseShort(this.activePhase))
              .fontSize(8)
              .height(20)
              .padding({ left: 7, right: 7 })
              .backgroundColor('#232A34')
              .fontColor('#E8EBEF')
              .borderRadius(10)
              .onClick(() => {
                this.onCyclePhase();
              })
          }
          .width('100%')

          Text('75m baseline • 30m rest • max 2/night')
            .fontSize(7)
            .fontColor('#6E747D')
            .width('100%')
        }
        .width('100%')
        .padding({ top: 6, bottom: 6, left: 8, right: 8 })
        .backgroundColor('#14181F')
        .borderRadius(12)

        // Test tools demo dropdown
        Column({ space: 4 }) {
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
          .height(26)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.testToolsOpen = !this.testToolsOpen;
          })

          if (this.testToolsOpen) {
            Row({ space: 6 }) {
              Button('+1 Check')
                .fontSize(9)
                .height(28)
                .layoutWeight(1)
                .backgroundColor('#232A34')
                .fontColor('#FFB74D')
                .borderRadius(14)
                .onClick(() => {
                  this.onStepCheck();
                })

              Button('Surge')
                .fontSize(9)
                .height(28)
                .layoutWeight(1)
                .backgroundColor('#3A191D')
                .fontColor('#FF6B6B')
                .borderRadius(14)
                .onClick(() => {
                  this.onTriggerCrisis();
                })
            }
            .width('100%')

            Row({ space: 6 }) {
              Button('Moving')
                .fontSize(9)
                .height(26)
                .layoutWeight(1)
                .backgroundColor('#232A34')
                .fontColor('#9AA0A8')
                .borderRadius(13)
                .onClick(() => {
                  this.onToggleMotion();
                })

              Button('75m Base')
                .fontSize(9)
                .height(26)
                .layoutWeight(1)
                .backgroundColor('#232A34')
                .fontColor('#00E5FF')
                .borderRadius(13)
                .onClick(() => {
                  this.onStartBaseline();
                })
            }
            .width('100%')

            Button(this.replayActive ? 'Stop c2s02 Replay' : 'Replay c2s02 (1D-CNN)')
              .fontSize(9)
              .height(26)
              .width('100%')
              .backgroundColor('#132B33')
              .fontColor('#00E5FF')
              .borderRadius(13)
              .onClick(() => {
                this.onReplayReal();
              })
          }
        }
        .width('100%')
        .padding({ top: 6, bottom: 6, left: 8, right: 8 })
        .backgroundColor('#14181F')
        .borderRadius(12)

        // Night Guardian Feature Activation Card
        Column({ space: 3 }) {
          Row() {
            Column({ space: 1 }) {
              Text('Night Guardian')
                .fontSize(10)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
                .textAlign(TextAlign.Start)
              Text(this.autoScheduleEnabled ? 'Monitoring Active' : 'Paused')
                .fontSize(8)
                .fontColor(this.autoScheduleEnabled ? '#00E676' : '#8A8F98')
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            Toggle({ type: ToggleType.Switch, isOn: this.autoScheduleEnabled })
              .selectedColor('#00E5FF')
              .switchPointColor('#FFFFFF')
              .width(34)
              .height(20)
              .onChange((isOn: boolean) => {
                this.autoScheduleEnabled = isOn;
              })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Divider().color('#232A34').strokeWidth(1).margin({ top: 2, bottom: 2 })

          Row() {
            Column({ space: 1 }) {
              Text('Bedtime Schedule')
                .fontSize(8)
                .fontColor('#5B616B')
                .textAlign(TextAlign.Start)
                .width('100%')

              Text(`${format12H(this.scheduleStartTime)} - ${format12H(this.scheduleEndTime)}`)
                .fontSize(10)
                .fontWeight(FontWeight.Bold)
                .fontColor('#C7CCD4')
                .textAlign(TextAlign.Start)
                .width('100%')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .onClick(() => {
            this.onOpenTimeEdit(true);
          })

          Text('Configured via Phone Companion')
            .fontSize(7)
            .fontColor('#6E747D')
            .width('100%')
        }
        .width('100%')
        .padding({ top: 6, bottom: 6, left: 8, right: 8 })
        .backgroundColor('#14181F')
        .borderRadius(12)

        Blank().height(8)

        WatchPageDots({
          currentPage: this.currentPage,
          totalPages: 3,
          onSelectPage: this.onGoToPage
        })
      }
      .width(180)
      .padding({ top: 28, bottom: 48 })
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .scrollable(ScrollDirection.Vertical)
    .align(Alignment.Top)
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
      currentPage: 2
    })
  }
}
