/*
 * Copyright (c) 2026 HypoAlert.
 * Pure ArkTS Causal 1D Temporal CNN Inference Engine (DualHead_multitask_smoothap + Cal).
 * Executes the exact 498-parameter L=12 (60-minute) model + Platt + causal anchor + EMA on-watch.
 */

import { TcnnModelBundle, TcnnSeedWeights } from './TcnnWeights';

export interface TcnnStepResult {
  rawLogit: number;
  plattLogit: number;
  anchoredLogit: number;
  emaScore: number;
  threshold97: number;
  isHot: boolean;
  riskPct: number;
}

export class TcnnNightState {
  public windowBuf: number[][]; // [5][12]
  public firstThreePlatt: number[] = [];
  public prevEma: number = 0.0;
  public stepCount: number = 0;

  constructor() {
    this.windowBuf = TcnnNightState.createEmptyBuffer();
  }

  public static createEmptyBuffer(): number[][] {
    const buf: number[][] = [];
    for (let c: number = 0; c < 5; c++) {
      const row: number[] = [];
      for (let t: number = 0; t < 12; t++) {
        row.push(0.0);
      }
      buf.push(row);
    }
    return buf;
  }

  public reset(): void {
    this.windowBuf = TcnnNightState.createEmptyBuffer();
    this.firstThreePlatt = [];
    this.prevEma = 0.0;
    this.stepCount = 0;
  }

  public pushSlot(cZDhr: number, cZRmssd: number, cZSdnn: number, cZTpi: number, validMask: number): void {
    for (let c: number = 0; c < 5; c++) {
      for (let t: number = 0; t < 11; t++) {
        this.windowBuf[c][t] = this.windowBuf[c][t + 1];
      }
    }
    if (validMask > 0.5) {
      this.windowBuf[0][11] = cZDhr;
      this.windowBuf[1][11] = cZRmssd;
      this.windowBuf[2][11] = cZSdnn;
      this.windowBuf[3][11] = cZTpi;
      this.windowBuf[4][11] = 1.0;
    } else {
      this.windowBuf[0][11] = 0.0;
      this.windowBuf[1][11] = 0.0;
      this.windowBuf[2][11] = 0.0;
      this.windowBuf[3][11] = 0.0;
      this.windowBuf[4][11] = 0.0;
    }
  }

  public getValidSlotCount(): number {
    let count: number = 0;
    for (let t: number = 0; t < 12; t++) {
      if (this.windowBuf[4][t] > 0.5) {
        count += 1;
      }
    }
    return count;
  }

  public prefillBaseline(cZDhr: number, cZRmssd: number, cZSdnn: number, cZTpi: number): void {
    this.reset();
    for (let t: number = 0; t < 12; t++) {
      this.windowBuf[0][t] = cZDhr;
      this.windowBuf[1][t] = cZRmssd;
      this.windowBuf[2][t] = cZSdnn;
      this.windowBuf[3][t] = cZTpi;
      this.windowBuf[4][t] = 1.0;
    }
  }

  public loadPrefixRows(prefixRows: number[][]): void {
    this.reset();
    for (let i: number = 0; i < prefixRows.length; i++) {
      const r: number[] = prefixRows[i];
      if (r.length >= 5) {
        this.pushSlot(r[0], r[1], r[2], r[3], r[4]);
      }
    }
  }

  public pushGapSlots(gapCount: number): void {
    const clamped: number = Math.min(12, Math.max(0, gapCount));
    for (let g: number = 0; g < clamped; g++) {
      this.pushSlot(0.0, 0.0, 0.0, 0.0, 0.0);
    }
  }
}

export class TcnnEngine {
  public static readonly LOOKBACK: number = 12;

  private static createZero2D(rows: number, cols: number): number[][] {
    const mat: number[][] = [];
    for (let r: number = 0; r < rows; r++) {
      const row: number[] = [];
      for (let c: number = 0; c < cols; c++) {
        row.push(0.0);
      }
      mat.push(row);
    }
    return mat;
  }

  public static runSingleSeed(
    seed: TcnnSeedWeights,
    xSeq: number[][],
    age: number,
    t1dDuration: number,
    isBradycardic: boolean
  ): number {
    const L: number = TcnnEngine.LOOKBACK;

    // Layer 1: Causal Conv1d(5 -> 8, k=3, dilation=1, leftPad=2) + ReLU
    const h1: number[][] = TcnnEngine.createZero2D(8, L);
    for (let o: number = 0; o < 8; o++) {
      const bias: number = seed.conv1B[o];
      for (let t: number = 0; t < L; t++) {
        let sum: number = bias;
        for (let k: number = 0; k < 3; k++) {
          const srcT: number = t + k - 2;
          if (srcT >= 0 && srcT < L) {
            for (let c: number = 0; c < 5; c++) {
              sum += xSeq[c][srcT] * seed.conv1W[o][c][k];
            }
          }
        }
        h1[o][t] = sum > 0.0 ? sum : 0.0;
      }
    }

    // Layer 2: Causal Conv1d(8 -> 8, k=3, dilation=2, leftPad=4) + ReLU
    const h2: number[][] = TcnnEngine.createZero2D(8, L);
    for (let o: number = 0; o < 8; o++) {
      const bias: number = seed.conv2B[o];
      for (let t: number = 0; t < L; t++) {
        let sum: number = bias;
        for (let k: number = 0; k < 3; k++) {
          const srcT: number = t + k * 2 - 4;
          if (srcT >= 0 && srcT < L) {
            for (let c: number = 0; c < 8; c++) {
              sum += h1[c][srcT] * seed.conv2W[o][c][k];
            }
          }
        }
        h2[o][t] = sum > 0.0 ? sum : 0.0;
      }
    }

    // Concat [mean(h2), last(h2), age/50, t1d/20] -> 18 floats
    const feat: number[] = [];
    for (let c: number = 0; c < 8; c++) {
      let s: number = 0.0;
      for (let t: number = 0; t < L; t++) {
        s += h2[c][t];
      }
      feat.push(s / L);
    }
    for (let c: number = 0; c < 8; c++) {
      feat.push(h2[c][L - 1]);
    }
    feat.push(age / 50.0);
    feat.push(t1dDuration / 20.0);

    // fc1: Linear(18 -> 8) + ReLU
    const z1: number[] = [];
    for (let o: number = 0; o < 8; o++) {
      let sum: number = seed.fc1B[o];
      for (let i: number = 0; i < 18; i++) {
        sum += feat[i] * seed.fc1W[o][i];
      }
      z1.push(sum > 0.0 ? sum : 0.0);
    }

    // Active archetype head: Linear(8 -> 1) (9 params)
    const headW: number[] = isBradycardic ? seed.headBradyW : seed.headAdrW;
    let out: number = isBradycardic ? seed.headBradyB : seed.headAdrB;
    for (let i: number = 0; i < 8; i++) {
      out += z1[i] * headW[i];
    }
    return out;
  }

  public static runEnsembleLogit(
    bundle: TcnnModelBundle,
    xSeq: number[][],
    age: number,
    t1dDuration: number,
    isBradycardic: boolean
  ): number {
    let total: number = 0.0;
    const n: number = bundle.seeds.length;
    for (let s: number = 0; s < n; s++) {
      total += TcnnEngine.runSingleSeed(bundle.seeds[s], xSeq, age, t1dDuration, isBradycardic);
    }
    return total / Math.max(1, n);
  }

  public static stepNight(
    bundle: TcnnModelBundle,
    night: TcnnNightState,
    age: number,
    t1dDuration: number,
    isBradycardic: boolean,
    useGlobalThr: boolean = false
  ): TcnnStepResult {
    const rawLogit: number = TcnnEngine.runEnsembleLogit(bundle, night.windowBuf, age, t1dDuration, isBradycardic);
    const platt = isBradycardic ? bundle.plattBrady : bundle.plattAdr;
    const zPlatt: number = platt.a * rawLogit + platt.b;

    // Strictly causal first-3 anchor matching exp_auprc_champion.py
    let anc: number = zPlatt;
    if (night.stepCount > 0 && night.firstThreePlatt.length > 0) {
      let sumAnc: number = 0.0;
      for (let i: number = 0; i < night.firstThreePlatt.length; i++) {
        sumAnc += night.firstThreePlatt[i];
      }
      anc = sumAnc / night.firstThreePlatt.length;
    }
    if (night.firstThreePlatt.length < 3) {
      night.firstThreePlatt.push(zPlatt);
    }

    const zAnc: number = zPlatt - 0.25 * anc;
    const ema: number = night.stepCount === 0 ? zAnc : (0.5 * zAnc + 0.5 * night.prevEma);
    night.prevEma = ema;
    night.stepCount += 1;

    const thr: number = useGlobalThr
      ? bundle.thr97Pct
      : (isBradycardic ? bundle.thr97Brady : bundle.thr97Adr);
    const isHot: boolean = ema >= thr;
    const scaled: number = (ema - thr) * 1.15 + 0.95;
    let riskPct: number = Math.round(100.0 / (1.0 + Math.exp(-scaled)));
    if (riskPct < 4) {
      riskPct = 4;
    } else if (riskPct > 98) {
      riskPct = 98;
    }

    return {
      rawLogit,
      plattLogit: zPlatt,
      anchoredLogit: zAnc,
      emaScore: ema,
      threshold97: thr,
      isHot,
      riskPct
    };
  }
}
