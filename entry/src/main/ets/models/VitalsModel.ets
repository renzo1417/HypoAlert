/*
 * Copyright (c) 2026 HypoAlert.
 * Wearable nocturnal hypoglycemia symptom engine (Phase 1 -> Phase 2 -> Phase 3).
 * Measures physiological symptom signals only (HR delta, HRV RMSSD/SDNN, 8-12 Hz tremor, motion gate).
 * Phase 3 executes the trained 498-param DualHead_multitask_smoothap 1D-CNN on-device.
 * Never displays or fabricates blood glucose or skin temperature readings from watch sensors.
 */

import { TcnnEngine, TcnnNightState, TcnnStepResult } from './TcnnEngine';
import { COHORT_TCNN_BUNDLE, ReplayTestNight, TcnnModelBundle } from './TcnnWeights';

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

  // Phase 3 real 1D-CNN telemetry (undefined in Phases 1-2 or during silent baseline)
  tcnnRawLogit?: number;
  tcnnEma?: number;
  tcnnThr?: number;
  tcnnSlotsFilled?: number;
  replayLabel?: string;
}

export interface ReplayStepOutput {
  vitals: VitalsData;
  stepResult: TcnnStepResult;
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

  private static round3(v: number): number {
    return Math.round(v * 1000) / 1000;
  }

  public static createPhase3NightState(
    phenotype: BodyPhenotype = BodyPhenotype.ADRENERGIC,
    baselineReady: boolean = true,
    userAge: number = 28,
    userT1dYears: number = 8
  ): TcnnNightState {
    const night: TcnnNightState = new TcnnNightState();
    if (!baselineReady) {
      return night;
    }
    const isBrady: boolean = phenotype === BodyPhenotype.BRADYCARDIC;
    const cDhr: number = isBrady ? 0.5 : -0.2;
    const cRmssd: number = isBrady ? 1.0 : 0.2;
    const cSdnn: number = isBrady ? 0.8 : 0.1;
    const cTpi: number = isBrady ? -0.6 : 0.0;
    night.prefillBaseline(cDhr, cRmssd, cSdnn, cTpi);
    // Prime the first-3 causal night anchor from calm post-baseline windows
    for (let i: number = 0; i < 3; i++) {
      night.pushSlot(cDhr, cRmssd, cSdnn, cTpi, 1.0);
      TcnnEngine.stepNight(COHORT_TCNN_BUNDLE, night, userAge, userT1dYears, isBrady, false);
    }
    return night;
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
    personalLine: number = VitalsEngine.PHASE1_THRESHOLD,
    nightState?: TcnnNightState,
    userAge: number = 28,
    userT1dYears: number = 8
  ): VitalsData {
    return VitalsEngine.generateSteadyVitals(
      undefined,
      phenotype,
      phase,
      personalLine,
      75,
      0,
      0,
      nightState,
      userAge,
      userT1dYears
    );
  }

  public static generateBaselineVitals(
    prev: VitalsData | undefined,
    phenotype: BodyPhenotype,
    phase: DetectionPhase,
    threshold: number,
    nextBaselineMin: number,
    nightState?: TcnnNightState
  ): VitalsData {
    const pulse: number = VitalsEngine.BASE_HR + Math.round((Math.random() - 0.5) * 3);
    const deltaHr: number = pulse - VitalsEngine.BASE_HR;
    const rmssd: number = Math.round(VitalsEngine.BASE_RMSSD + (Math.random() - 0.5) * 5);
    const sdnn: number = Math.round(VitalsEngine.BASE_SDNN + (Math.random() - 0.5) * 6);
    const tremorTpi: number = VitalsEngine.round2(VitalsEngine.BASE_TPI + Math.random() * 0.02);
    const baseMin: number = VitalsEngine.clamp(nextBaselineMin, 0, 74);

    if (nightState && baseMin >= 20) {
      const isBrady: boolean = phenotype === BodyPhenotype.BRADYCARDIC;
      nightState.pushSlot(
        isBrady ? 0.5 : -0.2,
        isBrady ? 1.0 : 0.2,
        isBrady ? 0.8 : 0.1,
        isBrady ? -0.6 : 0.0,
        1.0
      );
    }

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
      timestamp: VitalsEngine.formatCurrentTime(),
      tcnnSlotsFilled: phase === 3 && nightState ? nightState.getValidSlotCount() : undefined
    };
  }

  public static generateSteadyVitals(
    prev: VitalsData | undefined,
    phenotype: BodyPhenotype,
    phase: DetectionPhase,
    threshold: number,
    baselineMinutes: number = 75,
    alertsTonight: number = 0,
    cooldownMinutes: number = 0,
    nightState?: TcnnNightState,
    userAge: number = 28,
    userT1dYears: number = 8
  ): VitalsData {
    const isBrady: boolean = phenotype === BodyPhenotype.BRADYCARDIC;
    const basePulse: number = prev && prev.pulse >= 55 && prev.pulse <= 68 ? prev.pulse : VitalsEngine.BASE_HR;
    const pulse: number = VitalsEngine.clamp(Math.round(basePulse + (Math.random() - 0.5) * 2), 57, 66);
    const deltaHr: number = pulse - VitalsEngine.BASE_HR;
    const rmssd: number = VitalsEngine.clamp(
      Math.round((isBrady ? 49 : VitalsEngine.BASE_RMSSD) + (Math.random() - 0.5) * 6),
      36,
      54
    );
    const sdnn: number = VitalsEngine.clamp(
      Math.round((isBrady ? 61 : VitalsEngine.BASE_SDNN) + (Math.random() - 0.5) * 6),
      46,
      68
    );
    const tremorTpi: number = VitalsEngine.round2((isBrady ? 0.06 : 0.07) + Math.random() * 0.03);

    const score: number = VitalsEngine.computeHeuristicScore(deltaHr, rmssd, sdnn, tremorTpi, phenotype);
    let activeThreshold: number = threshold;
    let riskPct: number = VitalsEngine.computeSymptomRiskPct(score, threshold, phase, 0);
    let tcnnRawLogit: number | undefined = undefined;
    let tcnnEma: number | undefined = undefined;
    let tcnnThr: number | undefined = undefined;
    let tcnnSlotsFilled: number | undefined = undefined;

    if (phase === 3) {
      const state: TcnnNightState = nightState
        ? nightState
        : VitalsEngine.createPhase3NightState(phenotype, true, userAge, userT1dYears);
      const jitterDhr: number = (deltaHr / 4.5) * 0.15;
      state.pushSlot(
        VitalsEngine.clamp((isBrady ? 0.5 : -0.2) + jitterDhr, -3.0, 3.0),
        isBrady ? 1.0 : 0.2,
        isBrady ? 0.8 : 0.1,
        isBrady ? -0.6 : 0.0,
        1.0
      );
      const stepRes: TcnnStepResult = TcnnEngine.stepNight(COHORT_TCNN_BUNDLE, state, userAge, userT1dYears, isBrady, false);
      tcnnRawLogit = VitalsEngine.round3(stepRes.rawLogit);
      tcnnEma = VitalsEngine.round3(stepRes.emaScore);
      tcnnThr = VitalsEngine.round3(stepRes.threshold97);
      tcnnSlotsFilled = state.getValidSlotCount();
      activeThreshold = VitalsEngine.round2(stepRes.threshold97);
      riskPct = stepRes.riskPct;
    }

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
      threshold: activeThreshold,
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
      timestamp: VitalsEngine.formatCurrentTime(),
      tcnnRawLogit,
      tcnnEma,
      tcnnThr,
      tcnnSlotsFilled
    };
  }

  public static generateMovingVitals(
    prev: VitalsData | undefined,
    phenotype: BodyPhenotype,
    phase: DetectionPhase,
    threshold: number,
    nightState?: TcnnNightState
  ): VitalsData {
    if (nightState) {
      nightState.pushSlot(0.0, 0.0, 0.0, 0.0, 0.0);
    }
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
      timestamp: VitalsEngine.formatCurrentTime(),
      tcnnSlotsFilled: phase === 3 && nightState ? nightState.getValidSlotCount() : undefined
    };
    return res;
  }

  /**
   * Simulates one elevated 5-minute check (or escalates to full streak alert when step reaches streakRequired).
   * In Phase 3, pushes real autonomic feature steps into the 60-min DualHead 1D-CNN sliding window.
   */
  public static generateElevatedStep(
    prev: VitalsData | undefined,
    phenotype: BodyPhenotype,
    phase: DetectionPhase,
    threshold: number,
    forceFullStreak: boolean = false,
    nightState?: TcnnNightState,
    userAge: number = 28,
    userT1dYears: number = 8
  ): VitalsData {
    const isBrady: boolean = phenotype === BodyPhenotype.BRADYCARDIC;
    const streakRequired: number = VitalsEngine.getStreakRequired(phenotype);
    const prevStreak: number = prev ? prev.streakCount : 0;
    const targetStep: number = forceFullStreak
      ? streakRequired
      : Math.min(streakRequired, prevStreak + 1);
    const alertsTonight: number = prev ? prev.alertsTonight : 0;
    const cooldownMinutes: number = prev ? prev.cooldownMinutes : 0;

    let pulse: number = 90;
    let deltaHr: number = 28;
    let rmssd: number = 18;
    let sdnn: number = 28;
    let tremorTpi: number = 0.19;

    if (isBrady) {
      pulse = 57;
      deltaHr = -5;
      rmssd = targetStep === 1 ? 16 : 14;
      sdnn = targetStep === 1 ? 24 : 20;
      tremorTpi = targetStep === 1 ? 0.19 : 0.21;
    } else if (targetStep === 1) {
      pulse = 82;
      deltaHr = 20;
      rmssd = 22;
      sdnn = 34;
      tremorTpi = 0.16;
    } else if (targetStep === 2) {
      pulse = 89;
      deltaHr = 27;
      rmssd = 19;
      sdnn = 30;
      tremorTpi = 0.19;
    } else {
      pulse = 96;
      deltaHr = 34;
      rmssd = 16;
      sdnn = 26;
      tremorTpi = 0.21;
    }

    const score: number = VitalsEngine.computeHeuristicScore(deltaHr, rmssd, sdnn, tremorTpi, phenotype);
    let nextStreak: number = targetStep;
    let activeThreshold: number = threshold;
    let riskPct: number = Math.max(
      74,
      VitalsEngine.computeSymptomRiskPct(Math.max(score, threshold + 0.5), threshold, phase, nextStreak)
    );
    let tcnnRawLogit: number | undefined = undefined;
    let tcnnEma: number | undefined = undefined;
    let tcnnThr: number | undefined = undefined;
    let tcnnSlotsFilled: number | undefined = undefined;

    if (phase === 3) {
      const state: TcnnNightState = nightState
        ? nightState
        : VitalsEngine.createPhase3NightState(phenotype, true, userAge, userT1dYears);

      if (prevStreak === 0) {
        // Push realistic physiological onset ramp before the elevated check so 12-slot Conv1d sees trend
        const onsetRows: number[][] = isBrady
          ? [
              [-0.2, -1.8, -1.7, 2.3, 1.0],
              [-0.25, -1.95, -1.85, 2.5, 1.0],
              [-0.3, -2.1, -2.0, 2.7, 1.0]
            ]
          : [[1.3, -1.1, -1.0, 0.8, 1.0]];
        for (let r: number = 0; r < onsetRows.length; r++) {
          const row: number[] = onsetRows[r];
          state.pushSlot(row[0], row[1], row[2], row[3], row[4]);
          TcnnEngine.stepNight(COHORT_TCNN_BUNDLE, state, userAge, userT1dYears, isBrady, false);
        }
      }

      const startIdx: number = forceFullStreak ? Math.max(1, prevStreak + 1) : targetStep;
      let hotCount: number = prevStreak;
      let lastRes: TcnnStepResult | undefined = undefined;

      for (let s: number = startIdx; s <= targetStep; s++) {
        let feat: number[];
        if (isBrady) {
          feat = s === 1
            ? [-0.35, -2.2, -2.1, 2.8, 1.0]
            : [-0.4, -2.3, -2.2, 2.9, 1.0];
        } else if (s === 1) {
          feat = [1.8, -1.5, -1.4, 1.2, 1.0];
        } else if (s === 2) {
          feat = [2.1, -1.7, -1.6, 1.5, 1.0];
        } else {
          feat = [2.3, -1.9, -1.7, 1.7, 1.0];
        }
        state.pushSlot(feat[0], feat[1], feat[2], feat[3], feat[4]);
        lastRes = TcnnEngine.stepNight(COHORT_TCNN_BUNDLE, state, userAge, userT1dYears, isBrady, false);
        hotCount = lastRes.isHot ? Math.min(streakRequired, hotCount + 1) : 0;
      }

      if (lastRes !== undefined) {
        nextStreak = hotCount;
        activeThreshold = VitalsEngine.round2(lastRes.threshold97);
        riskPct = lastRes.riskPct;
        tcnnRawLogit = VitalsEngine.round3(lastRes.rawLogit);
        tcnnEma = VitalsEngine.round3(lastRes.emaScore);
        tcnnThr = VitalsEngine.round3(lastRes.threshold97);
        tcnnSlotsFilled = state.getValidSlotCount();
      }
    }

    const isHotCheck: boolean = phase === 3 ? (tcnnEma !== undefined && tcnnThr !== undefined ? tcnnEma >= tcnnThr : false) : true;
    const canFire: boolean = isHotCheck && nextStreak >= streakRequired && cooldownMinutes === 0 && alertsTonight < VitalsEngine.MAX_ALERTS_PER_NIGHT;

    let tier: SymptomStatusTier = isHotCheck ? 'WATCH' : 'STEADY';
    let word: string = isHotCheck ? 'Watch' : 'Steady';
    if (canFire) {
      tier = 'ALERT';
      word = phase < 3 ? 'Possible low' : '1D-CNN alert';
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
      threshold: activeThreshold,
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
      timestamp: VitalsEngine.formatCurrentTime(),
      tcnnRawLogit,
      tcnnEma,
      tcnnThr,
      tcnnSlotsFilled
    };
  }

  /**
   * Replays one real held-out PhysioCGM night frame (strict LOSO) through the exact on-device TcnnEngine.
   */
  public static replayStepFromNight(
    replay: ReplayTestNight,
    bundle: TcnnModelBundle,
    nightState: TcnnNightState,
    frameIdx: number,
    prevAlertsTonight: number,
    prevCooldownMin: number,
    prevStreak: number
  ): ReplayStepOutput {
    if (frameIdx === 0) {
      nightState.loadPrefixRows(replay.baselinePrefixZ);
    } else {
      const slotDiff: number = replay.framesSlot[frameIdx] - replay.framesSlot[frameIdx - 1];
      if (slotDiff > 1) {
        nightState.pushGapSlots(slotDiff - 1);
      }
    }

    const z: number[] = replay.framesZ[frameIdx];
    const rawVec: number[] = replay.framesRaw[frameIdx];
    const isBrady: boolean = replay.archetype === 1;
    const phenotype: BodyPhenotype = isBrady ? BodyPhenotype.BRADYCARDIC : BodyPhenotype.ADRENERGIC;
    const streakRequired: number = VitalsEngine.getStreakRequired(phenotype);

    nightState.pushSlot(z[0], z[1], z[2], z[3], z[4]);
    const stepRes: TcnnStepResult = TcnnEngine.stepNight(
      bundle,
      nightState,
      replay.age,
      replay.t1dDuration,
      isBrady,
      true
    );

    const nextCooldown: number = prevCooldownMin > 0 ? Math.max(0, prevCooldownMin - 5) : 0;
    const nextStreak: number = stepRes.isHot ? prevStreak + 1 : 0;
    let nextAlerts: number = prevAlertsTonight;

    const canFire: boolean =
      stepRes.isHot &&
      nextStreak >= streakRequired &&
      nextCooldown === 0 &&
      nextAlerts < VitalsEngine.MAX_ALERTS_PER_NIGHT;

    let tier: SymptomStatusTier = stepRes.isHot ? 'WATCH' : 'STEADY';
    let word: string = stepRes.isHot ? 'Watch' : 'Steady';
    if (canFire) {
      tier = 'ALERT';
      word = '1D-CNN alert';
      nextAlerts += 1;
    } else if (stepRes.isHot && nextAlerts >= VitalsEngine.MAX_ALERTS_PER_NIGHT) {
      tier = 'COOLDOWN';
      word = 'Cap 2/2';
    } else if (nextCooldown > 0) {
      tier = 'COOLDOWN';
      word = 'Resting';
    }

    const hrDisplay: number = rawVec[0] >= 30 ? Math.round(rawVec[0]) : 60;
    const rmssdDisplay: number = Math.round(rawVec[2]);
    const sdnnDisplay: number = Math.round(rawVec[3]);
    const tpiDisplay: number = VitalsEngine.round2(rawVec[4]);
    const slotNum: number = replay.framesSlot[frameIdx];

    const vitals: VitalsData = {
      pulse: hrDisplay,
      deltaHr: VitalsEngine.round1(rawVec[1]),
      rmssd: rmssdDisplay,
      sdnn: sdnnDisplay,
      tremorIndex: tpiDisplay,
      isSedentary: true,
      baselineMinutes: 75,
      phase: 3,
      phenotype,
      heuristicScore: VitalsEngine.round2(stepRes.rawLogit),
      threshold: VitalsEngine.round2(stepRes.threshold97),
      symptomRiskPct: stepRes.riskPct,
      streakCount: Math.min(streakRequired, nextStreak),
      streakRequired,
      alertsTonight: prevAlertsTonight,
      cooldownMinutes: nextCooldown,
      statusTier: tier,
      statusWord: word,
      reasonSummary: canFire
        ? `LOSO Replay ${replay.nightUid} • ${nextStreak}/${streakRequired} checks >= ${stepRes.threshold97.toFixed(2)}`
        : stepRes.isHot
          ? `LOSO Replay ${replay.nightUid} • Hot check (${Math.min(streakRequired, nextStreak)}/${streakRequired})`
          : `LOSO Replay ${replay.nightUid} • Slot ${slotNum} steady`,
      timestamp: `Slot ${slotNum}`,
      tcnnRawLogit: VitalsEngine.round3(stepRes.rawLogit),
      tcnnEma: VitalsEngine.round3(stepRes.emaScore),
      tcnnThr: VitalsEngine.round3(stepRes.threshold97),
      tcnnSlotsFilled: nightState.getValidSlotCount(),
      replayLabel: `${replay.nightUid} (${frameIdx + 1}/${replay.framesZ.length})`
    };

    return { vitals, stepResult: stepRes };
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
