/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Top-level Phone entry page for DevEco Studio preview and direct routing.
 */

import { PhonePage } from '../phone/PhonePage';

@Component
export struct Phone {
  build() {
    PhonePage()
  }
}

@Preview({ title: 'HypoAlert Phone Preview', width: 411, height: 841 })
@Component
struct PhonePreviewDirect {
  build() {
    PhonePage()
  }
}
