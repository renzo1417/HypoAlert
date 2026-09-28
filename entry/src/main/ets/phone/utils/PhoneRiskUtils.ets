/*
 * Copyright (c) 2026 HypoAlert.
 * Mathematical risk modeling and telemetry evaluation functions for Phone Companion.
 */

import { TremorBand, OvernightPoint } from '../models/PhoneTypes';

/**
 * Computes a synthetic photoplethysmogram (PPG) pulse waveform sample with dicrotic notch.
 */
export function ppgSample(phase: number): number {
  const sys: number = Math.exp(-Math.pow((phase - 0.18) / 0.07, 2));
  const notch: number = 0.35 * Math.exp(-Math.pow((phase - 0.38) / 0.05, 2));
  const drift: number = 0.05 * Math.sin(phase * Math.PI * 2.0);
  return sys + notch + drift;
}

/**
 * Calculates the combined hypoglycemia risk index (0 - 100) from glucose and autonomic tremor PSD.
 */
export function computeRiskIndex(glucose: number, tremorPSD: number): number {
  const gPart: number = (5.8 - glucose) * 28.0;
  const tPart: number = tremorPSD * 22.0;
  let r: number = Math.round(gPart + tPart);
  if (r < 0) {
    r = 0;
  }
  if (r > 100) {
    r = 100;
  }
  return r;
}

export function riskLevel(risk: number): string {
  if (risk > 70) {
    return 'Critical';
  }
  if (risk >= 30) {
    return 'Warning';
  }
  return 'Normal';
}

export function riskColor(risk: number): string {
  if (risk > 70) {
    return '#FF3B30';
  }
  if (risk >= 30) {
    return '#FF9500';
  }
  return '#34C759';
}

export function heroSentence(riskIndex: number): string {
  const lvl: string = riskLevel(riskIndex);
  if (lvl === 'Critical') {
    return 'Critical emergency — urgent help alerted';
  }
  if (lvl === 'Warning') {
    return 'Glucose dropping — check on them';
  }
  return 'All vitals steady throughout the night';
}

export function trendWord(riskIndex: number): string {
  const lvl: string = riskLevel(riskIndex);
  if (lvl === 'Critical') {
    return 'Dropping fast';
  }
  if (lvl === 'Warning') {
    return 'Trending down';
  }
  return 'Stable';
}

export function heartSub(riskIndex: number): string {
  const lvl: string = riskLevel(riskIndex);
  if (lvl === 'Critical') {
    return 'Elevated — urgent';
  }
  if (lvl === 'Warning') {
    return 'Slightly fast';
  }
  return 'Resting normal';
}

export function heartWords(riskIndex: number, heartRate: number): string {
  const lvl: string = riskLevel(riskIndex);
  if (lvl === 'Critical') {
    return `Rapid pulse • ${heartRate} bpm`;
  }
  if (lvl === 'Warning') {
    return `Elevated pulse • ${heartRate} bpm`;
  }
  return `Resting pulse • ${heartRate} bpm`;
}

export function restlessShort(tremorPSD: number): string {
  if (tremorPSD > 1.2) {
    return 'Restless';
  }
  if (tremorPSD > 0.5) {
    return 'Active';
  }
  return 'Calm';
}

export function restlessHint(tremorPSD: number): string {
  if (tremorPSD > 1.2) {
    return 'Frequent nocturnal movement';
  }
  if (tremorPSD > 0.5) {
    return 'Minor position shifts';
  }
  return 'Restful, peaceful sleep';
}

export function tempStatus(skinTemp: number): string {
  if (skinTemp < 35.2) {
    return 'Cooling & clammy';
  }
  if (skinTemp < 35.8) {
    return 'Slightly cool';
  }
  return 'Normal warmth';
}

export function tempColor(skinTemp: number): string {
  if (skinTemp < 35.2) {
    return '#FF3B30';
  }
  if (skinTemp < 35.8) {
    return '#FF9500';
  }
  return '#34C759';
}

export function computeTremorBands(tremorPSD: number): TremorBand[] {
  let b0: number = 0.25;
  let b1: number = 0.2;
  let b2: number = 0.1;
  if (tremorPSD > 0.5 && tremorPSD <= 1.2) {
    b0 = 0.3;
    b1 = 0.55;
    b2 = 0.45;
  } else if (tremorPSD > 1.2) {
    b0 = 0.3;
    b1 = 0.6;
    b2 = 0.95;
  }
  return [
    { label: 'Calm', range: '0-4', power: b0, color: '#34C759' },
    { label: 'Moving', range: '4-8', power: b1, color: '#FF9500' },
    { label: 'Shaky', range: '8-12', power: b2, color: '#FF3B30' }
  ];
}

export function riskShort(riskIndex: number): string {
  const lvl: string = riskLevel(riskIndex);
  if (lvl === 'Critical') {
    return 'High';
  }
  if (lvl === 'Warning') {
    return 'Watch';
  }
  return 'Low';
}

export function riskHint(riskIndex: number): string {
  const lvl: string = riskLevel(riskIndex);
  if (lvl === 'Critical') {
    return 'Act now — help needed';
  }
  if (lvl === 'Warning') {
    return 'Stay close tonight';
  }
  return 'No action needed';
}

export function riskWords(riskIndex: number): string {
  const lvl: string = riskLevel(riskIndex);
  if (lvl === 'Critical') {
    return `Risk ${riskIndex}% — very high`;
  }
  if (lvl === 'Warning') {
    return `Risk ${riskIndex}% — watch closely`;
  }
  return `Risk ${riskIndex}% — low`;
}

export function statusPillText(riskIndex: number): string {
  const lvl: string = riskLevel(riskIndex);
  if (lvl === 'Critical') {
    return 'Emergency';
  }
  if (lvl === 'Warning') {
    return 'Watch';
  }
  return 'Steady';
}

export function computeOvernightPoints(glucose: number): OvernightPoint[] {
  const base: number[] = [5.6, 5.4, 5.0, 4.7, 5.1];
  const hours: string[] = ['12am', '2am', '4am', '6am', '8am'];
  const shift: number = (glucose - 5.2) * 0.45;
  const pts: OvernightPoint[] = [];
  for (let i: number = 0; i < base.length; i++) {
    let v: number = base[i] + shift;
    if (v < 2.8) {
      v = 2.8;
    }
    if (v > 6.5) {
      v = 6.5;
    }
    v = Math.round(v * 10) / 10;
    pts.push({ hour: hours[i], value: v });
  }
  return pts;
}

export function getOvernightBarColor(v: number): string {
  if (v < 3.9) {
    return '#FF3B30';
  }
  if (v < 4.4) {
    return '#FF9500';
  }
  return '#2E86DE';
}

export function computeOvernightEvents(tremorPSD: number, riskIndex: number): string[] {
  const lvl: string = riskLevel(riskIndex);
  let checkMsg: string = 'Check-ins — quiet so far';
  if (tremorPSD > 1.2 || lvl === 'Critical') {
    checkMsg = 'Check-ins — restless, keep watching';
  } else if (tremorPSD > 0.5 || lvl === 'Warning') {
    checkMsg = 'Check-ins — some movement, all okay';
  }
  let alertMsg: string = 'Alerts — none tonight';
  if (lvl === 'Critical') {
    alertMsg = 'Alerts — 1 emergency tonight';
  } else if (lvl === 'Warning') {
    alertMsg = 'Alerts — 1 watch warning';
  }
  return [
    'Bedtime 10:30pm — settled to sleep',
    checkMsg,
    alertMsg
  ];
}
