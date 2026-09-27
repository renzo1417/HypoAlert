/*
 * Copyright (c) 2026 HypoAlert.
 * Device router: wearable -> WatchPage, phone/default -> PhonePage.
 * EntryAbility loads pages/Index; this file picks the right screen
 * so the watch never shows the phone dashboard.
 */

import { deviceInfo } from '@kit.BasicServicesKit';
import { display } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { PhonePage } from '../phone/PhonePage';
import { WatchPage } from '../watch/WatchPage';

const DOMAIN = 0x0000;

@Entry
@Component
struct Index {
  @State isWatch: boolean = false;

  aboutToAppear(): void {
    this.isWatch = this.detectWatch();
  }

  /**
   * Real devices/emulators: deviceInfo.deviceType is accurate.
   * Previewer: system APIs are NOT reliably mocked per preview device,
   * so the display fallback requires a square-ish small screen
   * (watch ~= 466x466). Anything else (tall phone, 0x0 unmocked)
   * defaults to phone. To preview each UI, open that file directly:
   * Phone.ets on a Phone device, Watch.ets on a Wearable device.
   */
  private detectWatch(): boolean {
    try {
      const t: string = deviceInfo.deviceType;
      hilog.info(DOMAIN, 'HypoAlert', 'router deviceType=%{public}s', t);
      if (t === 'wearable' || t === 'liteWearable') {
        return true;
      }
      if (t === 'phone' || t === 'tablet' || t === '2in1' || t === 'tv' || t === 'car') {
        return false;
      }
    } catch {
      hilog.info(DOMAIN, 'HypoAlert', 'router deviceInfo unavailable, trying display');
    }
    try {
      const d = display.getDefaultDisplaySync();
      hilog.info(DOMAIN, 'HypoAlert', 'router display=%{public}d x %{public}d', d.width, d.height);
      if (d.width <= 0 || d.height <= 0) {
        return false;
      }
      const ratio: number = d.width / d.height;
      // Watch is square-ish (0.85-1.15) and small; phone is tall (ratio ~0.5).
      if (d.width <= 600 && d.height <= 600 && ratio > 0.85 && ratio < 1.15) {
        return true;
      }
      return false;
    } catch {
      return false;
    }
  }

  build() {
    if (this.isWatch) {
      WatchPage()
    } else {
      PhonePage()
    }
  }
}

@Preview({ title: 'HypoAlert Router Phone', width: 411, height: 841 })
@Component
struct IndexPreviewPhone {
  build() {
    PhonePage()
  }
}

@Preview({ title: 'HypoAlert Router Watch', width: 466, height: 466 })
@Component
struct IndexPreviewWatch {
  build() {
    WatchPage()
  }
}
