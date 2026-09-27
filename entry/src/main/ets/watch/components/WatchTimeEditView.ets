/*
 * Copyright (c) 2026 HypoAlert.
 * Wearable — Screen 3: Alarm-style roller time picker for sleep schedule start/end.
 */

import { format12H } from '../../common/utils/TimeUtils';
import { hourRange, minuteRange } from '../utils/WatchUtils';

@Component
export struct WatchTimeEditView {
  @Prop editingStart: boolean = true;
  @Prop activeTime: string = '22:00';
  @Link editHourIdx: number;
  @Link editMinIdx: number;
  @Link editAmpmIdx: number;
  onApplyTime: () => void = () => {};
  onDone: () => void = () => {};

  build() {
    Column() {
      Column({ space: 4 }) {
        Text(this.editingStart ? 'Sleep on' : 'Sleep off')
          .fontSize(10)
          .fontWeight(FontWeight.Medium)
          .fontColor('#8A8F98')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.Center)
          .width('100%')

        Text(format12H(this.activeTime))
          .fontSize(22)
          .fontWeight(FontWeight.Bolder)
          .fontColor('#FFFFFF')
          .textAlign(TextAlign.Center)
          .width('100%')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row({ space: 2 }) {
          TextPicker({ range: hourRange(), selected: this.editHourIdx })
            .layoutWeight(1)
            .height(104)
            .onChange((value: string | string[], index: number | number[]) => {
              const i: number = typeof index === 'number' ? index : index[0];
              this.editHourIdx = i;
              this.onApplyTime();
            })

          Text(':')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#5B616B')

          TextPicker({ range: minuteRange(), selected: this.editMinIdx })
            .layoutWeight(1)
            .height(104)
            .onChange((value: string | string[], index: number | number[]) => {
              const i: number = typeof index === 'number' ? index : index[0];
              this.editMinIdx = i;
              this.onApplyTime();
            })

          TextPicker({ range: ['AM', 'PM'], selected: this.editAmpmIdx })
            .layoutWeight(1)
            .height(104)
            .onChange((value: string | string[], index: number | number[]) => {
              const i: number = typeof index === 'number' ? index : index[0];
              this.editAmpmIdx = i;
              this.onApplyTime();
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Text('Roll to set hours : minutes')
          .fontSize(8)
          .fontColor('#5B616B')
          .textAlign(TextAlign.Center)
          .width('100%')

        Button('Done')
          .fontSize(9)
          .fontWeight(FontWeight.Bold)
          .width('90')
          .height(30)
          .backgroundColor('#00E5FF')
          .fontColor('#000000')
          .borderRadius(20)
          .onClick(() => {
            this.onDone();
          })
      }
      .width(180)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .padding({ top: 30, bottom: 26 })
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#000000')
  }
}

@Preview({ title: 'Watch Time Picker', width: 466, height: 466 })
@Component
struct WatchTimeEditViewPreview {
  @State editHourIdx: number = 9;
  @State editMinIdx: number = 0;
  @State editAmpmIdx: number = 1;

  build() {
    WatchTimeEditView({
      editingStart: true,
      activeTime: '22:00',
      editHourIdx: $editHourIdx,
      editMinIdx: $editMinIdx,
      editAmpmIdx: $editAmpmIdx
    })
  }
}
