/*
 * Copyright (c) 2026 HypoAlert.
 * Wearable Alert & Hardware Integration Service.
 */

import vibrator from '@ohos.vibrator';
import { BusinessError } from '@ohos.base';

export class AlertService {
  private static instance: AlertService | null = null;
  private isAlerting: boolean = false;
  private hapticIntervalId: number = -1;
  private buzzerIntervalId: number = -1;
  private buzzerStep: number = 0;
  private statusListener: ((active: boolean, message: string) => void) | null = null;

  private constructor() {
    // Singleton
  }

  public static getInstance(): AlertService {
    if (!AlertService.instance) {
      AlertService.instance = new AlertService();
    }
    return AlertService.instance;
  }

  public setStatusListener(listener: ((active: boolean, message: string) => void) | null): void {
    this.statusListener = listener;
  }

  private notifyStatus(message: string): void {
    if (this.statusListener) {
      try {
        this.statusListener(this.isAlerting, message);
      } catch (e) {
        console.info(`[HypoAlert][AlertService] listener error: ${JSON.stringify(e)}`);
      }
    }
  }

  /**
   * Starts the continuous critical emergency alert:
   * 1. Repeating high-intensity haptic vibration pulses via @ohos.vibrator.
   * 2. Repeating simulated acoustic emergency buzzer notification.
   */
  public startEmergencyAlert(): void {
    if (this.isAlerting) {
      return;
    }
    this.isAlerting = true;
    console.info('[HypoAlert][AlertService] >>> CRITICAL EMERGENCY ALERT TRIGGERED <<<');
    this.notifyStatus('Alert started - haptic + buzzer on');

    // 1. Initial haptic trigger
    this.triggerHapticPulse();

    // Set recurring haptic pulse loop (every 1000ms)
    this.hapticIntervalId = setInterval(() => {
      if (this.isAlerting) {
        this.triggerHapticPulse();
      }
    }, 1000);

    // 2. Audio Buzzer Stub loop (every 1200ms)
    this.buzzerStep = 0;
    this.triggerAudioBuzzer();
    this.buzzerIntervalId = setInterval(() => {
      if (this.isAlerting) {
        this.triggerAudioBuzzer();
      }
    }, 1200);
  }

  /**
   * Stops and dismisses all active emergency alerts (vibrator and audio).
   */
  public stopEmergencyAlert(): void {
    if (!this.isAlerting) {
      return;
    }
    this.isAlerting = false;
    console.info('[HypoAlert][AlertService] >>> EMERGENCY ALERT DISMISSED / SNOOZED <<<');
    this.notifyStatus('Alert stopped');

    // Stop haptic interval
    if (this.hapticIntervalId !== -1) {
      clearInterval(this.hapticIntervalId);
      this.hapticIntervalId = -1;
    }

    // Stop physical vibrator
    try {
      vibrator.stopVibration().then(() => {
        console.info('[HypoAlert][Haptics] Vibrator hardware stopped successfully.');
      }).catch((err: BusinessError) => {
        console.info(`[HypoAlert][Haptics] Stop vibration note (safe in emulator): ${err.message} (${err.code})`);
      });
    } catch (error) {
      console.info(`[HypoAlert][Haptics] Stop vibration bypass (emulator safe): ${JSON.stringify(error)}`);
    }

    // Stop audio buzzer interval
    if (this.buzzerIntervalId !== -1) {
      clearInterval(this.buzzerIntervalId);
      this.buzzerIntervalId = -1;
    }
    console.info('[HypoAlert][AudioBuzzer] Emergency acoustic buzzer silenced.');
  }

  /**
   * Hardware Vibrator invocation with full try/catch safety for DevEco Emulator.
   */
  private triggerHapticPulse(): void {
    try {
      // 600ms high-intensity emergency pulse for waking user from sleep
      vibrator.startVibration({
        type: 'time',
        duration: 600
      }, {
        id: 0,
        usage: 'alarm'
      }).then(() => {
        console.info('[HypoAlert][Haptics] Haptic pulse executed (600ms, usage: alarm).');
      }).catch((err: BusinessError) => {
        // Expected when running on standard DevEco Emulator without physical motor
        console.info(`[HypoAlert][Haptics] Vibrator emulator note: ${err.message} (code: ${err.code})`);
      });
    } catch (err) {
      console.info(`[HypoAlert][Haptics] Vibrator invocation caught safely: ${JSON.stringify(err)}`);
    }
  }

  /**
   * Audio Buzzer Notification Stub (with realistic acoustic logs & ready for sound kit).
   */
  private triggerAudioBuzzer(): void {
    this.buzzerStep++;
    const tonePattern = this.buzzerStep % 2 === 0 ? 'HIGH-PITCH-ALERT [3000Hz]' : 'WARBLE-ALARM [2400Hz]';
    console.info(`[HypoAlert][AudioBuzzer] Playing emergency buzzer pulse #${this.buzzerStep}: ${tonePattern} (85dB SPL mock)`);
  }

  public getIsAlerting(): boolean {
    return this.isAlerting;
  }
}
