/*
 * Copyright (c) 2026 HypoAlert.
 * Symptom-first risk evaluation, Phase 1-3 calibration logic, and body-type routing helpers.
 * Never fabricates blood glucose values; scores autonomic symptoms only.
 */

import { BodyType, DetectionPhase } from '../models/PhoneTypes';
import { PhoneTheme } from './PhoneTheme';

/**
 * Generates a realistic optical photoplethysmogram (PPG) pulse sample with dicrotic notch.
 */
export function ppgSample(phase: number): number {
  const sys: number = Math.exp(-Math.pow((phase - 0.18) / 0.07, 2));
  const notch: number = 0.36 * Math.exp(-Math.pow((phase - 0.38) / 0.055, 2));
  const drift: number = 0.04 * Math.sin(phase * Math.PI * 2.0);
  return sys + notch + drift;
}

/**
 * Evaluates current symptom risk state: 'Normal' | 'Warning' | 'Critical' | 'Gated' | 'Learning'
 */
export function evaluateSymptomState(
  symptomScore: number,
  cnnRiskPct: number,
  phase: DetectionPhase,
  personalCutoff: number,
  streakCount: number,
  bodyType: BodyType,
  isMotionGated: boolean,
  baselineSlots: number
): string {
  if (baselineSlots < 15) {
    return 'Learning';
  }
  if (isMotionGated) {
    return 'Gated';
  }
  const requiredStreak: number = requiredStreakForBody(bodyType);
  const cutoff: number = activeScoreThreshold(phase, personalCutoff);
  const aboveThreshold: boolean = phase === 'P3' ? cnnRiskPct >= 65 : symptomScore >= cutoff;

  if (aboveThreshold && streakCount >= requiredStreak) {
    return 'Critical';
  }
  if (aboveThreshold || streakCount > 0) {
    return 'Warning';
  }
  return 'Normal';
}

export function requiredStreakForBody(bodyType: BodyType): number {
  return bodyType === 'Blunted' ? 2 : 3;
}

export function activeScoreThreshold(phase: DetectionPhase, personalCutoff: number): number {
  if (phase === 'P2') {
    return Math.max(3.7, personalCutoff);
  }
  return 3.7;
}

export function phaseDisplayName(phase: DetectionPhase): string {
  if (phase === 'P1') {
    return 'P1 · Warm-Up';
  }
  if (phase === 'P2') {
    return 'P2 · My Line';
  }
  return 'P3 · 1D-CNN';
}

export function phaseShortLabel(phase: DetectionPhase): string {
  if (phase === 'P1') {
    return 'P1 Warm-Up';
  }
  if (phase === 'P2') {
    return 'P2 My Line';
  }
  return 'P3 1D-CNN';
}

export function phaseDescription(phase: DetectionPhase, personalCutoff: number): string {
  if (phase === 'P1') {
    return `Fixed score ≥ 3.7`;
  }
  if (phase === 'P2') {
    return `Personal cutoff ≥ ${personalCutoff.toFixed(1)}`;
  }
  return '60-min 1D-CNN · 0.49 KB';
}

export function heroHeadline(state: string, _phase: DetectionPhase): string {
  if (state === 'Critical') {
    return 'Check blood sugar now';
  }
  if (state === 'Warning') {
    return 'Confirming symptom rise';
  }
  if (state === 'Gated') {
    return 'Paused while moving';
  }
  if (state === 'Learning') {
    return 'Learning baseline';
  }
  return 'Quiet sleep';
}

export function statusBadgeLabel(state: string): string {
  if (state === 'Critical') {
    return 'Alert';
  }
  if (state === 'Warning') {
    return 'Rising';
  }
  if (state === 'Gated') {
    return 'Motion paused';
  }
  if (state === 'Learning') {
    return 'Calibrating';
  }
  return 'Steady';
}

export function hrvStatusLabel(variabilityMs: number, isMotionGated: boolean): string {
  if (isMotionGated) {
    return 'Gated';
  }
  if (variabilityMs < 22) {
    return 'Strained';
  }
  if (variabilityMs < 32) {
    return 'Dipping';
  }
  return 'Calm';
}

export function tremorStatusLabel(tremorPSD: number, isMotionGated: boolean): string {
  if (isMotionGated) {
    return 'Gated';
  }
  if (tremorPSD >= 1.0) {
    return 'Surge';
  }
  if (tremorPSD >= 0.45) {
    return 'Elevated';
  }
  return 'Calm';
}

export function scoreBarColor(score: number, cutoff: number): string {
  if (score >= cutoff) {
    return PhoneTheme.STATE_CRIT;
  }
  if (score >= cutoff * 0.75) {
    return PhoneTheme.STATE_WARN;
  }
  return PhoneTheme.BRAND_ACCENT;
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

export function riskLevel(risk: number): string {
  if (risk > 70) {
    return 'Critical';
  }
  if (risk >= 30) {
    return 'Warning';
  }
  return 'Normal';
}
