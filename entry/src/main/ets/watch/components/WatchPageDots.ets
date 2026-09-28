/*
 * Copyright (c) 2026 HypoAlert.
 * Wearable — Pagination dots for swiping between Monitor, History, and Settings.
 */

@Component
export struct WatchPageDots {
  @Prop currentPage: number = 0;
  @Prop totalPages: number = 3;
  onSelectPage: (page: number) => void = () => {};

  build() {
    Row({ space: 4 }) {
      Button() {
        Circle({ width: this.currentPage === 0 ? 7 : 5, height: this.currentPage === 0 ? 7 : 5 })
          .fill(this.currentPage === 0 ? '#00E5FF' : '#4A4F57')
      }
      .width(20)
      .height(20)
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        this.onSelectPage(0);
      })

      Button() {
        Circle({ width: this.currentPage === 1 ? 7 : 5, height: this.currentPage === 1 ? 7 : 5 })
          .fill(this.currentPage === 1 ? '#00E5FF' : '#4A4F57')
      }
      .width(20)
      .height(20)
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        this.onSelectPage(1);
      })

      Button() {
        Circle({ width: this.currentPage === 2 ? 7 : 5, height: this.currentPage === 2 ? 7 : 5 })
          .fill(this.currentPage === 2 ? '#00E5FF' : '#4A4F57')
      }
      .width(20)
      .height(20)
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        this.onSelectPage(2);
      })
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
  }
}

@Preview({ title: 'Watch Page Dots' })
@Component
struct WatchPageDotsPreview {
  build() {
    WatchPageDots({ currentPage: 0 })
  }
}
