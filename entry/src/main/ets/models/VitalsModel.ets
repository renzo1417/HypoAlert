/*
 * Copyright (c) 2026 HypoAlert.
 * Wearable nocturnal hypoglycemia symptom engine (Phase 1 -> Phase 2 -> Phase 3).
 * Measures physiological symptom signals only (HR delta, HRV RMSSD/SDNN, 8-12 Hz tremor, motion gate).
 * Never displays or fabricates blood glucose or skin temperature readings from watch sensors.
 */

export enum AlertState {
  MONITORING = 'MONITORING',
  CRITICAL_ALERT = 'CRITICAL_ALERT'
}

export enum BodyPhenotype {
  ADRENERGIC = 'ADRENERGIC',
  BRADYCARDIC = 'BRADYCARDIC'
}

export type DetectionPhase = 1 | 2 | 3;

export type SymptomStatusTier =
  | 'STANDBY'
  | 'BASELINE'
  | 'STEADY'
  | 'WATCH'
  | 'ALERT'
  | 'MOVING'
  | 'COOLDOWN';

export interface UserProfile {
  age: number;
  t1dYears: number;
  phenotype: BodyPhenotype;
}

export interface GateProgress {
  buzzLinkedPricks: number;
  confirmedLows: number;
  fineNights: number;
  personalLine: number;
  hasPersonalLine: boolean;
  isCnnUnlocked: boolean;
  isA2Personalized: boolean;
}

export interface VitalsData {
  // Core physiological channels (matches PhysioCGM tcnn_version/data_prep.py)
  pulse: number;             // Current heart rate (bpm)
  deltaHr: number;           // Change from tonight's 75-min baseline (bpm)
  rmssd: number;             // Short-term HRV (ms) — heart calmness
  sdnn: number;              // Overall HRV (ms)
  tremorIndex: number;       // 8-12 Hz Tremor Power Index (TPI relative)
  isSedentary: boolean;      // Motion gate: true = lying still/asleep, false = moving (paused)

  // Nightly calibration & Phase 1-3 state
  baselineMinutes: number;   // 0..75 silent baseline warm-up (15 x 5-min slots)
  phase: DetectionPhase;     // 1 = Fixed 3.7 | 2 = Personal Line | 3 = 60-min 1D-CNN
  phenotype: BodyPhenotype;  // ADRENERGIC (3 checks in a row) | BRADYCARDIC (2 checks in a row)
  heuristicScore: number;    // Phase 1/2 score
  threshold: number;         // Active cutoff (3.7, personal line, or CNN threshold)
  symptomRiskPct: number;    // User-friendly 0-100% symptom risk index
  streakCount: number;       // Consecutive high 5-min checks
  streakRequired: number;    // 3 for Adrenergic, 2 for Bradycardic
  alertsTonight: number;     // 0..2 (max 2 alerts per night)
  cooldownMinutes: number;   // Remaining cooldown minutes (30 min after an alert)

  // User-readable status copy
  statusTier: SymptomStatusTier;
  statusWord: string;
  reasonSummary: string;
  timestamp: string;
}

export class VitalsEngine {
  public static readonly PHASE1_THRESHOLD: number = 3.7;
  public static readonly BASELINE_TOTAL_MINUTES: number = 75;
  public static readonly COOLDOWN_MINUTES: number = 30;
  public static readonly MAX_ALERTS_PER_NIGHT: number = 2;

  // Baseline floors matching PhysioCGM data_prep.py
  private static readonly FLOOR_DHR: number = 2.0;
  private static readonly FLOOR_RMSSD: number = 5.0;
  private static readonly FLOOR_SDNN: number = 5.0;
  private static readonly FLOOR_TPI: number = 0.02;

  // Reference resting baselines for simulation
  private static readonly BASE_HR: number = 62;
  private static readonly BASE_RMSSD: number = 42;
  private static readonly BASE_SDNN: number = 54;
  private static readonly BASE_TPI: number = 0.08;

  public static getStreakRequired(phenotype: BodyPhenotype): number {
    return phenotype === BodyPhenotype.ADRENERGIC ? 3 : 2;
  }

  public static getPhaseName(phase: DetectionPhase): string {
    if (phase === 1) {
      return 'Phase 1 • Warm-Up';
    }
    if (phase === 2) {
      return 'Phase 2 • Personal Line';
    }
    return 'Phase 3 • 1D-CNN';
  }

  public static getPhaseShort(phase: DetectionPhase): string {
    if (phase === 1) {
      return 'P1 Warm-Up';
    }
    if (phase === 2) {
      return 'P2 My Line';
    }
    return 'P3 1D-CNN';
  }

  public static getPhenotypeLabel(phenotype: BodyPhenotype): string {
    return phenotype === BodyPhenotype.ADRENERGIC
      ? 'Adrenergic (3 checks)'
      : 'Blunted (2 checks)';
  }

  private static clamp(v: number, lo: number, hi: number): number {
    if (v < lo) {
      return lo;
    }
    if (v > hi) {
      return hi;
    }
    return v;
  }

  private static round1(v: number): number {
    return Math.round(v * 10) / 10;
  }

  private static round2(v: number): number {
    return Math.round(v * 100) / 100;
  }

  /**
   * Computes clipped z-scores and Phase 1/2 heuristic score matching PhysioCGM data_prep.py.
   */
  public static computeHeuristicScore(
    deltaHr: number,
    rmssd: number,
    sdnn: number,
    tremorTpi: number,
    phenotype: BodyPhenotype
  ): number {
    const zDhr: number = VitalsEngine.clamp(deltaHr / 4.5, -3.0, 3.0);
    const zRmssd: number = VitalsEngine.clamp(
      (rmssd - VitalsEngine.BASE_RMSSD) / Math.max(8.0, VitalsEngine.FLOOR_RMSSD),
      -3.0,
      3.0
    );
    const zSdnn: number = VitalsEngine.clamp(
      (sdnn - VitalsEngine.BASE_SDNN) / Math.max(10.0, VitalsEngine.FLOOR_SDNN),
      -3.0,
      3.0
    );
    const zTpi: number = VitalsEngine.clamp(
      (tremorTpi - VitalsEngine.BASE_TPI) / Math.max(0.04, VitalsEngine.FLOOR_TPI),
      -3.0,
      3.0
    );

    if (phenotype === BodyPhenotype.ADRENERGIC) {
      return VitalsEngine.round2(zDhr - zRmssd + zTpi);
    }
    return VitalsEngine.round2(-zRmssd - zSdnn + zTpi);
  }

  /**
   * Converts score + phase into an understandable 0-100% symptom risk index.
   * Hot checks (>= threshold) map to >= 70% so users have one consistent scale across Phases 1-3.
   */
  public static computeSymptomRiskPct(
    score: number,
    threshold: number,
    phase: DetectionPhase,
    streakCount: number
  ): number {
    if (phase === 3) {
      // Phase 3 60-min 1D-CNN calibrated response
      const normalized: number = score / Math.max(threshold, 3.0);
      const streakBoost: number = streakCount * 6;
      const prob: number = Math.round(100 / (1 + Math.exp(-(normalized * 3.1 - 1.9))) + streakBoost);
      return VitalsEngine.clamp(prob, 4, 98);
    }
    const ratio: number = score / Math.max(threshold, 1.0);
    if (ratio <= 0) {
      return Math.round(VitalsEngine.clamp(8 + ratio * 4, 4, 15));
    }
    if (ratio < 1.0) {
      return Math.round(VitalsEngine.clamp(12 + ratio * 55, 10, 68));
    }
    return Math.round(VitalsEngine.clamp(72 + (ratio - 1.0) * 45, 72, 98));
  }

  public static describeSymptoms(
    deltaHr: number,
    rmssd: number,
    tremorTpi: number,
    phenotype: BodyPhenotype,
    isSedentary: boolean,
    baselineMinutes: number,
    streakCount: number,
    streakRequired: number
  ): string {
    if (baselineMinutes < VitalsEngine.BASELINE_TOTAL_MINUTES) {
      return `Learning tonight's normal sleep (${baselineMinutes}/75 min)`;
    }
    if (!isSedentary) {
      return 'Movement detected — check paused to avoid false buzz';
    }
    const clues: string[] = [];
    if (phenotype === BodyPhenotype.ADRENERGIC && deltaHr >= 12) {
      clues.push('Fast pulse');
    } else if (phenotype === BodyPhenotype.BRADYCARDIC && deltaHr <= -3) {
      clues.push('Flat/slow pulse');
    }
    if (rmssd <= 26) {
      clues.push('Drop in heart calmness');
    }
    if (tremorTpi >= 0.14) {
      clues.push('8-12 Hz wrist tremor');
    }
    if (clues.length === 0) {
      return 'All signals match tonight\'s calm sleep baseline';
    }
    const joined: string = clues.join(' + ');
    if (streakCount > 0 && streakCount < streakRequired) {
      return `${joined} (${streakCount}/${streakRequired} checks)`;
    }
    return joined;
  }

  public static createInitialVitals(
    phenotype: BodyPhenotype = BodyPhenotype.ADRENERGIC,
    phase: DetectionPhase = 1,
    personalLine: number = VitalsEngine.PHASE1_THRESHOLD
  ): VitalsData {
    return VitalsEngine.generateSteadyVitals(undefined, phenotype, phase, personalLine, 75, 0, 0);
  }

  public static generateBaselineVitals(
    prev: VitalsData | undefined,
    phenotype: BodyPhenotype,
    phase: DetectionPhase,
    threshold: number,
    nextBaselineMin: number
  ): VitalsData {
    const pulse: number = VitalsEngine.BASE_HR + Math.round((Math.random() - 0.5) * 3);
    const deltaHr: number = pulse - VitalsEngine.BASE_HR;
    const rmssd: number = Math.round(VitalsEngine.BASE_RMSSD + (Math.random() - 0.5) * 5);
    const sdnn: number = Math.round(VitalsEngine.BASE_SDNN + (Math.random() - 0.5) * 6);
    const tremorTpi: number = VitalsEngine.round2(VitalsEngine.BASE_TPI + Math.random() * 0.02);
    const baseMin: number = VitalsEngine.clamp(nextBaselineMin, 0, 74);

    return {
      pulse,
      deltaHr,
      rmssd,
      sdnn,
      tremorIndex: tremorTpi,
      isSedentary: true,
      baselineMinutes: baseMin,
      phase,
      phenotype,
      heuristicScore: 0.0,
      threshold,
      symptomRiskPct: 8,
      streakCount: 0,
      streakRequired: VitalsEngine.getStreakRequired(phenotype),
      alertsTonight: prev ? prev.alertsTonight : 0,
      cooldownMinutes: 0,
      statusTier: 'BASELINE',
      statusWord: 'Baseline',
      reasonSummary: `Learning tonight's normal sleep (${baseMin}/75 min)`,
      timestamp: VitalsEngine.formatCurrentTime()
    };
  }

  public static generateSteadyVitals(
    prev: VitalsData | undefined,
    phenotype: BodyPhenotype,
    phase: DetectionPhase,
    threshold: number,
    baselineMinutes: number = 75,
    alertsTonight: number = 0,
    cooldownMinutes: number = 0
  ): VitalsData {
    const basePulse: number = prev && prev.pulse >= 55 && prev.pulse <= 68 ? prev.pulse : VitalsEngine.BASE_HR;
    const pulse: number = VitalsEngine.clamp(Math.round(basePulse + (Math.random() - 0.5) * 2), 57, 66);
    const deltaHr: number = pulse - VitalsEngine.BASE_HR;
    const rmssd: number = VitalsEngine.clamp(Math.round(VitalsEngine.BASE_RMSSD + (Math.random() - 0.5) * 6), 36, 48);
    const sdnn: number = VitalsEngine.clamp(Math.round(VitalsEngine.BASE_SDNN + (Math.random() - 0.5) * 6), 46, 62);
    const tremorTpi: number = VitalsEngine.round2(0.07 + Math.random() * 0.03);

    const score: number = VitalsEngine.computeHeuristicScore(deltaHr, rmssd, sdnn, tremorTpi, phenotype);
    const riskPct: number = VitalsEngine.computeSymptomRiskPct(score, threshold, phase, 0);
    const streakRequired: number = VitalsEngine.getStreakRequired(phenotype);
    const isCooldown: boolean = cooldownMinutes > 0;

    return {
      pulse,
      deltaHr,
      rmssd,
      sdnn,
      tremorIndex: tremorTpi,
      isSedentary: true,
      baselineMinutes,
      phase,
      phenotype,
      heuristicScore: score,
      threshold,
      symptomRiskPct: riskPct,
      streakCount: 0,
      streakRequired,
      alertsTonight,
      cooldownMinutes,
      statusTier: isCooldown ? 'COOLDOWN' : 'STEADY',
      statusWord: isCooldown ? 'Resting' : 'Steady',
      reasonSummary: isCooldown
        ? `Cooldown active (${cooldownMinutes} min left before next alert)`
        : 'All signals match tonight\'s calm sleep baseline',
      timestamp: VitalsEngine.formatCurrentTime()
    };
  }

  public static generateMovingVitals(
    prev: VitalsData | undefined,
    phenotype: BodyPhenotype,
    phase: DetectionPhase,
    threshold: number
  ): VitalsData {
    const streakRequired: number = VitalsEngine.getStreakRequired(phenotype);
    const res: VitalsData = {
      pulse: 78,
      deltaHr: 16,
      rmssd: 31,
      sdnn: 45,
      tremorIndex: 0.11,
      isSedentary: false,
      baselineMinutes: 75,
      phase,
      phenotype,
      heuristicScore: 0.0,
      threshold,
      symptomRiskPct: 14,
      streakCount: 0,
      streakRequired,
      alertsTonight: prev ? prev.alertsTonight : 0,
      cooldownMinutes: prev ? prev.cooldownMinutes : 0,
      statusTier: 'MOVING',
      statusWord: 'Paused',
      reasonSummary: 'Movement detected — check skipped to avoid false buzz',
      timestamp: VitalsEngine.formatCurrentTime()
    };
    return res;
  }

  /**
   * Simulates one elevated 5-minute check (or escalates to full streak alert when step reaches streakRequired).
   * Demonstrates why a single 5-min spike does NOT wake the user.
   */
  public static generateElevatedStep(
    prev: VitalsData | undefined,
    phenotype: BodyPhenotype,
    phase: DetectionPhase,
    threshold: number,
    forceFullStreak: boolean = false
  ): VitalsData {
    const streakRequired: number = VitalsEngine.getStreakRequired(phenotype);
    const prevStreak: number = prev ? prev.streakCount : 0;
    const nextStreak: number = forceFullStreak
      ? streakRequired
      : Math.min(streakRequired, prevStreak + 1);
    const alertsTonight: number = prev ? prev.alertsTonight : 0;
    const cooldownMinutes: number = prev ? prev.cooldownMinutes : 0;

    let pulse: number = 96;
    let deltaHr: number = 34;
    let rmssd: number = 17;
    let sdnn: number = 28;
    let tremorTpi: number = 0.21;

    if (phenotype === BodyPhenotype.BRADYCARDIC) {
      // Blunted body type: HR stays flat or slightly slow while HRV drops and mild tremor appears
      pulse = 57;
      deltaHr = -5;
      rmssd = 15;
      sdnn = 22;
      tremorTpi = 0.18;
    } else if (nextStreak === 1 && !forceFullStreak) {
      pulse = 88;
      deltaHr = 26;
      rmssd = 21;
      sdnn = 34;
      tremorTpi = 0.17;
    }

    const score: number = VitalsEngine.computeHeuristicScore(deltaHr, rmssd, sdnn, tremorTpi, phenotype);
    const riskPct: number = Math.max(
      74,
      VitalsEngine.computeSymptomRiskPct(Math.max(score, threshold + 0.5), threshold, phase, nextStreak)
    );
    const canFire: boolean = nextStreak >= streakRequired && cooldownMinutes === 0 && alertsTonight < VitalsEngine.MAX_ALERTS_PER_NIGHT;

    let tier: SymptomStatusTier = 'WATCH';
    let word: string = 'Watch';
    if (canFire) {
      tier = 'ALERT';
      word = phase < 3 ? 'Possible low' : 'Surge alert';
    } else if (nextStreak >= streakRequired && alertsTonight >= VitalsEngine.MAX_ALERTS_PER_NIGHT) {
      tier = 'COOLDOWN';
      word = 'Cap 2/2';
    } else if (nextStreak >= streakRequired && cooldownMinutes > 0) {
      tier = 'COOLDOWN';
      word = 'Cooldown';
    }

    return {
      pulse,
      deltaHr,
      rmssd,
      sdnn,
      tremorIndex: tremorTpi,
      isSedentary: true,
      baselineMinutes: 75,
      phase,
      phenotype,
      heuristicScore: score,
      threshold,
      symptomRiskPct: riskPct,
      streakCount: nextStreak,
      streakRequired,
      alertsTonight,
      cooldownMinutes,
      statusTier: tier,
      statusWord: word,
      reasonSummary: VitalsEngine.describeSymptoms(
        deltaHr,
        rmssd,
        tremorTpi,
        phenotype,
        true,
        75,
        nextStreak,
        streakRequired
      ),
      timestamp: VitalsEngine.formatCurrentTime()
    };
  }

  public static shouldTriggerAlert(v: VitalsData): boolean {
    return (
      v.baselineMinutes >= VitalsEngine.BASELINE_TOTAL_MINUTES &&
      v.isSedentary &&
      v.streakCount >= v.streakRequired &&
      v.cooldownMinutes === 0 &&
      v.alertsTonight < VitalsEngine.MAX_ALERTS_PER_NIGHT &&
      v.statusTier === 'ALERT'
    );
  }

  public static formatCurrentTime(): string {
    const now: Date = new Date();
    const hours: string = now.getHours().toString().padStart(2, '0');
    const minutes: string = now.getMinutes().toString().padStart(2, '0');
    return `${hours}:${minutes}`;
  }

  public static formatFullTime(): string {
    const now: Date = new Date();
    const hours: string = now.getHours().toString().padStart(2, '0');
    const minutes: string = now.getMinutes().toString().padStart(2, '0');
    const seconds: string = now.getSeconds().toString().padStart(2, '0');
    return `${hours}:${minutes}:${seconds}`;
  }
}
