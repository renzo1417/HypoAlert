/*
 * Copyright (c) 2026 HypoAlert.
 * Wearable nocturnal hypoglycemia alerting engine.
 */

export enum AlertState {
  MONITORING = 'MONITORING',
  CRITICAL_ALERT = 'CRITICAL_ALERT'
}

export interface VitalsData {
  pulse: number;       // BPM: 58-64 normal sleep, 98-115 in nocturnal hypoglycemia tachycardia
  skinTemp: number;    // °C: 35.8-36.2 normal sleep, 34.5-35.1 cold diaphoresis
  tremorIndex: number; // ATI: 0.1-0.3 baseline, 7.5-9.4 neuroglycopenic micro-tremor
  glucose: number;     // mmol/L: 5.1-5.7 normal, 2.7-3.2 critical alert (< 3.9 threshold)
  timestamp: string;   // Local time string
}

export class VitalsEngine {
  public static readonly GLUCOSE_THRESHOLD: number = 3.9;

  public static isCritical(glucose: number): boolean {
    return glucose < VitalsEngine.GLUCOSE_THRESHOLD;
  }

  /**
   * Single-step drop towards hypoglycemia for gradual simulation.
   * Drops ~0.6 mmol/L per call so preview/emulator can watch auto-trigger.
   */
  public static dropTowardsHypo(prev?: VitalsData): VitalsData {
    const base: VitalsData = prev ?? VitalsEngine.generateNormalVitals();
    const nextGlucose = Math.round((base.glucose - 0.6) * 10) / 10;
    if (nextGlucose <= 3.2) {
      return VitalsEngine.generateCriticalVitals(base);
    }
    return {
      pulse: Math.min(116, base.pulse + 6),
      skinTemp: Math.max(34.5, Math.round((base.skinTemp - 0.2) * 10) / 10),
      tremorIndex: Math.round((base.tremorIndex + 1.2) * 10) / 10,
      glucose: nextGlucose,
      timestamp: VitalsEngine.formatCurrentTime()
    };
  }

  /**
   * Generates realistic nocturnal baseline vitals with natural physiological fluctuation.
   */
  public static generateNormalVitals(prev?: VitalsData): VitalsData {
    // Pulse: 58-64 BPM with smooth ±1 bpm fluctuation
    let basePulse = prev ? prev.pulse : 61;
    const pulseDelta = (Math.random() - 0.5) * 2;
    let newPulse = Math.round(basePulse + pulseDelta);
    if (newPulse < 58) {
      newPulse = 58;
    } else if (newPulse > 64) {
      newPulse = 64;
    }

    // Skin Temp: 35.8-36.2 °C
    let baseTemp = prev ? prev.skinTemp : 36.0;
    const tempDelta = (Math.random() - 0.5) * 0.1;
    let newTemp = Math.round((baseTemp + tempDelta) * 10) / 10;
    if (newTemp < 35.8) {
      newTemp = 35.8;
    } else if (newTemp > 36.2) {
      newTemp = 36.2;
    }

    // Autonomic Tremor Index: 0.1 - 0.3
    const newTremor = Math.round((0.15 + Math.random() * 0.15) * 10) / 10;

    // Normal Glucose: 5.2 - 5.6 mmol/L
    let baseGlucose = prev ? prev.glucose : 5.4;
    const glucoseDelta = (Math.random() - 0.5) * 0.1;
    let newGlucose = Math.round((baseGlucose + glucoseDelta) * 10) / 10;
    if (newGlucose < 5.0) {
      newGlucose = 5.0;
    } else if (newGlucose > 5.8) {
      newGlucose = 5.8;
    }

    return {
      pulse: newPulse,
      skinTemp: newTemp,
      tremorIndex: newTremor,
      glucose: newGlucose,
      timestamp: VitalsEngine.formatCurrentTime()
    };
  }

  /**
   * Generates critical hypoglycemia vitals (tachycardia, cold diaphoresis, autonomic tremor).
   */
  public static generateCriticalVitals(prev?: VitalsData): VitalsData {
    // Pulse tachycardia: 98 - 114 BPM
    let basePulse = (prev && prev.pulse >= 90) ? prev.pulse : 104;
    const pulseDelta = (Math.random() - 0.5) * 4;
    let newPulse = Math.round(basePulse + pulseDelta);
    if (newPulse < 98) {
      newPulse = 98;
    } else if (newPulse > 116) {
      newPulse = 116;
    }

    // Cold sweat drop: 34.6 - 35.1 °C
    let baseTemp = (prev && prev.skinTemp <= 35.5) ? prev.skinTemp : 34.9;
    const tempDelta = (Math.random() - 0.5) * 0.15;
    let newTemp = Math.round((baseTemp + tempDelta) * 10) / 10;
    if (newTemp < 34.5) {
      newTemp = 34.5;
    } else if (newTemp > 35.2) {
      newTemp = 35.2;
    }

    // Severe autonomic tremor: 7.8 - 9.2
    const newTremor = Math.round((8.0 + (Math.random() - 0.5) * 1.2) * 10) / 10;

    // Severe hypoglycemia: 2.8 - 3.2 mmol/L (< 3.9 mmol/L)
    const newGlucose = Math.round((2.8 + Math.random() * 0.4) * 10) / 10;

    return {
      pulse: newPulse,
      skinTemp: newTemp,
      tremorIndex: newTremor,
      glucose: newGlucose,
      timestamp: VitalsEngine.formatCurrentTime()
    };
  }

  /**
   * Current time formatted as HH:mm:ss for Wearable UI display.
   */
  public static formatCurrentTime(): string {
    const now = new Date();
    const hours = now.getHours().toString().padStart(2, '0');
    const minutes = now.getMinutes().toString().padStart(2, '0');
    return `${hours}:${minutes}`;
  }

  /**
   * Full time with seconds for audit logging.
   */
  public static formatFullTime(): string {
    const now = new Date();
    const hours = now.getHours().toString().padStart(2, '0');
    const minutes = now.getMinutes().toString().padStart(2, '0');
    const seconds = now.getSeconds().toString().padStart(2, '0');
    return `${hours}:${minutes}:${seconds}`;
  }
}
