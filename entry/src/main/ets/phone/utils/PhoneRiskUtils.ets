/*
 * Copyright (c) 2026 HypoAlert.
 * Plain-language symptom telemetry and risk formatting helpers for Phone Companion.
 * Binds directly to VitalsData and DetectionPhase (no duplicated thresholds or Skin Temp).
 */

import { BodyPhenotype, DetectionPhase, GateProgress, VitalsData, VitalsEngine } from '../../models/VitalsModel';
import { PhoneTheme } from './PhoneTheme';

/**
 * Generates an optical photoplethysmogram (PPG) waveform sample with dicrotic notch.
 */
export function ppgSample(phase: number): number {
  const sys: number = Math.exp(-Math.pow((phase - 0.18) / 0.07, 2));
  const notch: number = 0.36 * Math.exp(-Math.pow((phase - 0.38) / 0.055, 2));
  const drift: number = 0.04 * Math.sin(phase * Math.PI * 2.0);
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

export function phenotypeShortLabel(phenotype: BodyPhenotype): string {
  return phenotype === BodyPhenotype.BRADYCARDIC ? 'Blunted' : 'Adrenergic';
}

export function phaseShortLabel(phase: DetectionPhase): string {
  return VitalsEngine.getPhaseShort(phase);
}

export function phaseDescription(phase: DetectionPhase, gate: GateProgress): string {
  if (phase === 1) {
    return `Fixed score ≥ ${VitalsEngine.PHASE1_THRESHOLD.toFixed(1)}`;
  }
  if (phase === 2) {
    const line: number = gate.hasPersonalLine ? gate.personalLine : 5.44;
    return `Personal cutoff ≥ ${line.toFixed(2)}`;
  }
  return '60-min 1D-CNN · 0.49 KB';
}

export function statusBadgeLabel(vitals: VitalsData): string {
  if (vitals.baselineMinutes < VitalsEngine.BASELINE_TOTAL_MINUTES) {
    return 'Calibrating';
  }
  if (!vitals.isSedentary) {
    return 'Motion paused';
  }
  if (vitals.statusTier === 'ALERT') {
    return 'Alert';
  }
  if (vitals.statusTier === 'WATCH') {
    return 'Rising';
  }
  if (vitals.cooldownMinutes > 0) {
    return `${vitals.cooldownMinutes}m rest`;
  }
  return 'Steady';
}

export function heroHeadline(vitals: VitalsData): string {
  if (vitals.baselineMinutes < VitalsEngine.BASELINE_TOTAL_MINUTES) {
    return 'Learning baseline';
  }
  if (!vitals.isSedentary) {
    return 'Paused while moving';
  }
  if (vitals.statusTier === 'ALERT') {
    return vitals.phase === 3 ? '1D-CNN surge — check now' : 'Check blood sugar now';
  }
  if (vitals.statusTier === 'WATCH') {
    return `${vitals.streakCount}/${vitals.streakRequired} elevated · confirming`;
  }
  if (vitals.cooldownMinutes > 0) {
    return `30m cooldown (${vitals.cooldownMinutes}m left)`;
  }
  return 'Quiet sleep';
}

export function hrvStatusLabel(rmssd: number, isSedentary: boolean): string {
  if (!isSedentary) {
    return 'Gated';
  }
  if (rmssd <= 22) {
    return 'Strained';
  }
  if (rmssd <= 32) {
    return 'Dipping';
  }
  return 'Calm';
}

export function tremorStatusLabel(tremorIndex: number, isSedentary: boolean): string {
  if (!isSedentary) {
    return 'Gated';
  }
  if (tremorIndex >= 0.17) {
    return 'Surge';
  }
  if (tremorIndex >= 0.13) {
    return 'Elevated';
  }
  return 'Calm';
}

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

export function riskColor(riskPct: number): string {
  if (riskPct >= 70) {
    return PhoneTheme.STATE_CRIT;
  }
  if (riskPct >= 35) {
    return PhoneTheme.STATE_WARN;
  }
  return PhoneTheme.STATE_OK;
}
