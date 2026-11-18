/*
 * Copyright (c) 2026 HypoAlert.
 * Plain-language symptom telemetry and risk formatting helpers for Phone Companion.
 */

import { BodyPhenotype, DetectionPhase, VitalsData, VitalsEngine } from '../../models/VitalsModel';
import { TremorBand } from '../models/PhoneTypes';
import { PhoneTheme } from './PhoneTheme';

/**
 * Computes a synthetic photoplethysmogram (PPG) pulse waveform sample for visual cardiac feedback.
 */
export function ppgSample(phase: number): number {
  const sys: number = Math.exp(-Math.pow((phase - 0.18) / 0.07, 2));
  const notch: number = 0.35 * Math.exp(-Math.pow((phase - 0.38) / 0.05, 2));
  const drift: number = 0.05 * Math.sin(phase * Math.PI * 2.0);
  return sys + notch + drift;
}

export function riskLevel(vitals: VitalsData): string {
  if (vitals.statusTier === 'ALERT') {
    return 'Critical';
  }
  if (vitals.statusTier === 'WATCH' || vitals.symptomRiskPct >= 35) {
    return 'Warning';
  }
  return 'Normal';
}

export function riskColor(riskPct: number): string {
  if (riskPct >= 70) {
    return PhoneTheme.STATE_CRIT;
  }
  if (riskPct >= 35) {
    return PhoneTheme.STATE_WARN;
  }
  return PhoneTheme.STATE_OK;
}

export function statusBadgeText(vitals: VitalsData): string {
  if (vitals.baselineMinutes < VitalsEngine.BASELINE_TOTAL_MINUTES) {
    return 'LEARNING';
  }
  if (!vitals.isSedentary) {
    return 'PAUSED';
  }
  if (vitals.statusTier === 'ALERT') {
    return vitals.phase < 3 ? 'POSSIBLE LOW' : 'ALERT';
  }
  if (vitals.statusTier === 'WATCH') {
    return 'WATCH';
  }
  if (vitals.cooldownMinutes > 0) {
    return 'RESTING';
  }
  return 'STEADY';
}

export function heroSentence(vitals: VitalsData): string {
  if (vitals.baselineMinutes < VitalsEngine.BASELINE_TOTAL_MINUTES) {
    return `Silent 75-min sleep baseline (${vitals.baselineMinutes}/75 min) — no alerts yet`;
  }
  if (!vitals.isSedentary) {
    return 'Movement detected — checks pause while tossing or awake';
  }
  if (vitals.statusTier === 'ALERT') {
    return vitals.phase < 3
      ? 'Possible nocturnal low — sustained symptom checks, please verify'
      : '1D-CNN detected sustained low-sugar symptoms — check sleeper now';
  }
  if (vitals.statusTier === 'WATCH') {
    return `${vitals.streakCount} of ${vitals.streakRequired} elevated checks — ignoring isolated spikes`;
  }
  if (vitals.cooldownMinutes > 0) {
    return `30-min safety rest active (${vitals.cooldownMinutes} min left)`;
  }
  return 'All steady — pulse, heart calmness, and wrist stillness match tonight\'s sleep';
}

export function heartStatusLabel(vitals: VitalsData): string {
  if (!vitals.isSedentary) {
    return 'Awake / moving';
  }
  if (vitals.phenotype === BodyPhenotype.ADRENERGIC) {
    if (vitals.deltaHr >= 18) {
      return `+${vitals.deltaHr} bpm vs baseline`;
    }
    if (vitals.deltaHr >= 8) {
      return `Slightly up (+${vitals.deltaHr})`;
    }
    return 'Resting normal';
  }
  if (vitals.deltaHr <= -4) {
    return 'Flat / slow response';
  }
  return 'Quiet resting pulse';
}

export function hrvStatusLabel(rmssd: number): string {
  if (rmssd <= 22) {
    return 'Stressed — HRV dropped';
  }
  if (rmssd <= 32) {
    return 'Slightly tense';
  }
  return 'Calm & relaxed';
}

export function hrvColor(rmssd: number): string {
  if (rmssd <= 22) {
    return PhoneTheme.STATE_CRIT;
  }
  if (rmssd <= 32) {
    return PhoneTheme.STATE_WARN;
  }
  return PhoneTheme.STATE_OK;
}

export function tremorLabel(tremorTpi: number, isSedentary: boolean): string {
  if (!isSedentary) {
    return 'Moving';
  }
  if (tremorTpi >= 0.17) {
    return 'Tremor surge';
  }
  if (tremorTpi >= 0.13) {
    return 'Mild tremor';
  }
  return 'Still & calm';
}

export function tremorHint(tremorTpi: number, isSedentary: boolean): string {
  if (!isSedentary) {
    return 'Motion gate paused checks';
  }
  if (tremorTpi >= 0.17) {
    return 'Strong 8–12 Hz wrist tremor';
  }
  if (tremorTpi >= 0.13) {
    return 'Light 8–12 Hz micro-tremor';
  }
  return 'Lying still — checking every 5m';
}

export function tremorColor(tremorTpi: number, isSedentary: boolean): string {
  if (!isSedentary) {
    return PhoneTheme.TEXT_TERTIARY;
  }
  if (tremorTpi >= 0.17) {
    return PhoneTheme.STATE_CRIT;
  }
  if (tremorTpi >= 0.13) {
    return PhoneTheme.STATE_WARN;
  }
  return PhoneTheme.STATE_OK;
}

export function computeTremorBands(tremorTpi: number): TremorBand[] {
  let b0: number = 0.25;
  let b1: number = 0.18;
  let b2: number = 0.10;
  if (tremorTpi >= 0.13 && tremorTpi < 0.17) {
    b0 = 0.28;
    b1 = 0.50;
    b2 = 0.48;
  } else if (tremorTpi >= 0.17) {
    b0 = 0.25;
    b1 = 0.55;
    b2 = 0.94;
  }
  return [
    { label: 'Still', range: '0-4Hz', power: b0, color: PhoneTheme.STATE_OK },
    { label: 'Roll', range: '4-8Hz', power: b1, color: PhoneTheme.STATE_WARN },
    { label: 'Tremor', range: '8-12Hz', power: b2, color: PhoneTheme.STATE_CRIT }
  ];
}

export function getOvernightBarColor(riskPct: number): string {
  if (riskPct >= 70) {
    return PhoneTheme.STATE_CRIT;
  }
  if (riskPct >= 35) {
    return PhoneTheme.STATE_WARN;
  }
  return PhoneTheme.BRAND_ACCENT;
}

export function riskShort(riskPct: number): string {
  if (riskPct >= 70) {
    return 'High';
  }
  if (riskPct >= 35) {
    return 'Watch';
  }
  return 'Low';
}

export function riskHint(riskPct: number): string {
  if (riskPct >= 70) {
    return 'Check sleeper & log finger-prick';
  }
  if (riskPct >= 35) {
    return 'Watching for repeat checks';
  }
  return 'Calm sleep — no action needed';
}

export function phaseBadgeLabel(phase: DetectionPhase, personalLine: number): string {
  if (phase === 1) {
    return 'Phase 1 • Fixed 3.7';
  }
  if (phase === 2) {
    return `Phase 2 • My Line ${personalLine.toFixed(2)}`;
  }
  return 'Phase 3 • 60m 1D-CNN';
}
