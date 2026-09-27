/*
 * Copyright (c) 2026 HypoAlert.
 * Wearable — Pagination dots for swiping between Monitor and Settings.
 */

@Component
export struct WatchPageDots {
  @Prop currentPage: number = 0;
  onSelectPage: (page: number) => void = () => {};

  build() {
    Row({ space: 2 }) {
      Button() {
        Circle({ width: 6, height: 6 })
          .fill(this.currentPage === 0 ? '#FFFFFF' : '#4A4F57')
      }
      .width(26)
      .height(26)
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        this.onSelectPage(0);
      })

      Button() {
        Circle({ width: 6, height: 6 })
          .fill(this.currentPage === 1 ? '#FFFFFF' : '#4A4F57')
      }
      .width(26)
      .height(22)
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        this.onSelectPage(1);
      })
    }
    .justifyContent(FlexAlign.Center)
  }
}

@Preview({ title: 'Watch Page Dots' })
@Component
struct WatchPageDotsPreview {
  build() {
    WatchPageDots({ currentPage: 0 })
  }
}
