'use strict';

// =========================================================================
// Pure Causal 1D-CNN Inference Engine (DualHead_multitask_smoothap, 498p)
// Mirrors ai/export_tcnn_weights.py and entry/src/main/ets/models/TcnnEngine.ets
// =========================================================================
function createEmptyTcnnBuffer() {
  return Array.from({ length: 5 }, () => new Array(12).fill(0));
}

function createTcnnNightState() {
  return {
    windowBuf: createEmptyTcnnBuffer(),
    firstThreePlatt: [],
    prevEma: 0,
    stepCount: 0
  };
}

function pushTcnnSlot(night, cZDhr, cZRmssd, cZSdnn, cZTpi, validMask) {
  for (let c = 0; c < 5; c += 1) {
    for (let t = 0; t < 11; t += 1) {
      night.windowBuf[c][t] = night.windowBuf[c][t + 1];
    }
  }
  if (validMask > 0.5) {
    night.windowBuf[0][11] = cZDhr;
    night.windowBuf[1][11] = cZRmssd;
    night.windowBuf[2][11] = cZSdnn;
    night.windowBuf[3][11] = cZTpi;
    night.windowBuf[4][11] = 1.0;
  } else {
    night.windowBuf[0][11] = 0.0;
    night.windowBuf[1][11] = 0.0;
    night.windowBuf[2][11] = 0.0;
    night.windowBuf[3][11] = 0.0;
    night.windowBuf[4][11] = 0.0;
  }
}

function prefillTcnnBaseline(night, cZDhr, cZRmssd, cZSdnn, cZTpi) {
  night.windowBuf = createEmptyTcnnBuffer();
  night.firstThreePlatt = [];
  night.prevEma = 0;
  night.stepCount = 0;
  for (let t = 0; t < 12; t += 1) {
    night.windowBuf[0][t] = cZDhr;
    night.windowBuf[1][t] = cZRmssd;
    night.windowBuf[2][t] = cZSdnn;
    night.windowBuf[3][t] = cZTpi;
    night.windowBuf[4][t] = 1.0;
  }
}

function loadTcnnPrefixRows(night, prefixRows) {
  night.windowBuf = createEmptyTcnnBuffer();
  night.firstThreePlatt = [];
  night.prevEma = 0;
  night.stepCount = 0;
  for (let i = 0; i < prefixRows.length; i += 1) {
    const r = prefixRows[i];
    if (r && r.length >= 5) {
      pushTcnnSlot(night, r[0], r[1], r[2], r[3], r[4]);
    }
  }
}

function pushTcnnGapSlots(night, gapCount) {
  const clamped = Math.min(12, Math.max(0, gapCount));
  for (let g = 0; g < clamped; g += 1) {
    pushTcnnSlot(night, 0, 0, 0, 0, 0);
  }
}

function getTcnnValidSlotCount(night) {
  let count = 0;
  for (let t = 0; t < 12; t += 1) {
    if (night.windowBuf[4][t] > 0.5) count += 1;
  }
  return count;
}

function runTcnnSingleSeed(mw, buf, age, t1dDuration, isBradycardic) {
  const h1 = Array.from({ length: 8 }, () => new Float64Array(12));
  for (let o = 0; o < 8; o += 1) {
    for (let t = 0; t < 12; t += 1) {
      let s = mw.conv1_b[o];
      for (let c = 0; c < 5; c += 1) {
        for (let k = 0; k < 3; k += 1) {
          const idx = t - 2 + k;
          if (idx >= 0) s += mw.conv1_w[o][c][k] * buf[c][idx];
        }
      }
      h1[o][t] = s > 0 ? s : 0;
    }
  }

  const h2 = Array.from({ length: 8 }, () => new Float64Array(12));
  for (let o = 0; o < 8; o += 1) {
    for (let t = 0; t < 12; t += 1) {
      let s = mw.conv2_b[o];
      for (let c = 0; c < 8; c += 1) {
        for (let k = 0; k < 3; k += 1) {
          const idx = t - 4 + 2 * k;
          if (idx >= 0) s += mw.conv2_w[o][c][k] * h1[c][idx];
        }
      }
      h2[o][t] = s > 0 ? s : 0;
    }
  }

  const feat = new Float64Array(18);
  for (let o = 0; o < 8; o += 1) {
    let sum = 0;
    for (let t = 0; t < 12; t += 1) sum += h2[o][t];
    feat[o] = sum / 12.0;
    feat[8 + o] = h2[o][11];
  }
  feat[16] = age / 50.0;
  feat[17] = t1dDuration / 20.0;

  let logit = isBradycardic ? mw.head_brady_b : mw.head_adr_b;
  const hw = isBradycardic ? mw.head_brady_w : mw.head_adr_w;
  for (let o = 0; o < 8; o += 1) {
    let z = mw.fc1_b[o];
    for (let j = 0; j < 18; j += 1) z += mw.fc1_w[o][j] * feat[j];
    if (z > 0) logit += hw[o] * z;
  }
  return logit;
}

function runTcnnEnsembleLogit(bundle, buf, age, t1dDuration, isBradycardic) {
  let total = 0;
  const n = bundle.models.length;
  for (let s = 0; s < n; s += 1) {
    total += runTcnnSingleSeed(bundle.models[s], buf, age, t1dDuration, isBradycardic);
  }
  return total / Math.max(1, n);
}

function stepTcnnNight(bundle, night, age, t1dDuration, isBradycardic, useGlobalThr = false) {
  const rawLogit = runTcnnEnsembleLogit(bundle, night.windowBuf, age, t1dDuration, isBradycardic);
  const pl = bundle.platt[isBradycardic ? '1' : '0'];
  const zPlatt = pl.a * rawLogit + pl.b;

  let anc = zPlatt;
  if (night.stepCount > 0 && night.firstThreePlatt.length > 0) {
    let sumAnc = 0;
    for (let i = 0; i < night.firstThreePlatt.length; i += 1) {
      sumAnc += night.firstThreePlatt[i];
    }
    anc = sumAnc / night.firstThreePlatt.length;
  }
  if (night.firstThreePlatt.length < 3) {
    night.firstThreePlatt.push(zPlatt);
  }

  const zAnc = zPlatt - 0.25 * anc;
  const emaScore = night.stepCount === 0 ? zAnc : (0.5 * zAnc + 0.5 * night.prevEma);
  night.prevEma = emaScore;
  night.stepCount += 1;

  const threshold97 = useGlobalThr
    ? bundle.thr_97pct
    : (isBradycardic ? bundle.thr_97_brady : bundle.thr_97_adr);
  const isHot = emaScore >= threshold97;
  const scaled = (emaScore - threshold97) * 1.15 + 0.95;
  let riskPct = Math.round(100.0 / (1.0 + Math.exp(-scaled)));
  riskPct = Math.max(4, Math.min(98, riskPct));

  return { rawLogit, plattLogit: zPlatt, anchoredLogit: zAnc, emaScore, threshold97, isHot, riskPct };
}

function createPhase3CohortNight(phenotype, baselineReady, age, t1dYears) {
  const night = createTcnnNightState();
  if (!baselineReady || typeof window === 'undefined' || !window.HYPOALERT_TCNN_BUNDLE) {
    return night;
  }
  const bundle = window.HYPOALERT_TCNN_BUNDLE.cohort_bundle;
  const isBrady = phenotype === 'BRADYCARDIC';
  const cDhr = isBrady ? 0.5 : -0.2;
  const cRmssd = isBrady ? 1.0 : 0.2;
  const cSdnn = isBrady ? 0.8 : 0.1;
  const cTpi = isBrady ? -0.6 : 0.0;
  prefillTcnnBaseline(night, cDhr, cRmssd, cSdnn, cTpi);
  for (let i = 0; i < 3; i += 1) {
    pushTcnnSlot(night, cDhr, cRmssd, cSdnn, cTpi, 1.0);
    stepTcnnNight(bundle, night, age, t1dYears, isBrady, false);
  }
  return night;
}

if (typeof document !== 'undefined') {
  const supportsNativeSwitch = 'switch' in HTMLInputElement.prototype;
  document.querySelectorAll('input[type="checkbox"][switch]').forEach((el) => {
    el.setAttribute('role', 'switch');
    if (!supportsNativeSwitch) {
      el.classList.add('switch-fallback');
    }
  });
}

const tcnnBundleData = (typeof window !== 'undefined' && window.HYPOALERT_TCNN_BUNDLE)
  ? window.HYPOALERT_TCNN_BUNDLE
  : null;

const state = {
  age: 28,
  t1dYears: 8,
  phenotype: 'ADRENERGIC', // 'ADRENERGIC' (3 checks) | 'BRADYCARDIC' (2 checks)
  phase: 1,                // 1 | 2 | 3
  personalLine: 3.7,
  hasPersonalLine: false,
  buzzLinkedPricks: 2,
  confirmedLows: 0,
  fineNights: 6,
  isCnnUnlocked: false,

  baselineMinutes: 75,
  isSedentary: true,
  hrBpm: 62,
  deltaHr: 0,
  rmssd: 42,
  sdnn: 54,
  tremorTpi: 0.08,
  riskPct: 12,
  score: 0.8,
  streakCount: 0,
  alertsTonight: 0,
  cooldownMinutes: 0,
  tier: 'STEADY', // 'BASELINE' | 'STEADY' | 'WATCH' | 'ALERT' | 'MOVING' | 'COOLDOWN'
  reason: 'Within baseline',
  pendingPrick: false,
  hourlyRisk: [10, 12, 14, 11, 9],
  caregiverName: 'Maria Santos',
  caregiverPhone: '+63 917 123 4567',
  smsEnabled: true,

  // Phase 3 real 1D-CNN & held-out replay state
  tcnnNight: createTcnnNightState(),
  tcnnRawLogit: null,
  tcnnEma: null,
  tcnnThr: null,
  tcnnSlots: 12,
  tcnnDiffText: 'Cohort 498p live',
  replayClip: null,
  replayFrameIdx: -1,
  replayPrevSlot: null,
  replayTimer: null,
  replayCgmMgdl: null,
  replayTimeLabel: null,
  showHiddenCgm: false,

  timeline: [
    { time: '10:00 PM', text: '75-min silent baseline started — learning normal sleep.', tone: 'info' },
    { time: '11:15 PM', text: 'Baseline ready — checking HR, HRV, and tremor every 5 min.', tone: 'ok' }
  ]
};

function clamp(v, lo, hi) {
  return Math.max(lo, Math.min(hi, v));
}

function streakRequired() {
  return state.phenotype === 'ADRENERGIC' ? 3 : 2;
}

function activeThreshold() {
  if (state.phase === 1) return 3.7;
  if (state.phase === 2) return state.hasPersonalLine ? state.personalLine : 5.44;
  return state.phenotype === 'BRADYCARDIC' ? -2.62 : -1.48;
}

function computeHeuristicScore(deltaHr, rmssd, sdnn, tpi, phenotype) {
  const zDhr = clamp(deltaHr / 4.5, -3, 3);
  const zRmssd = clamp((rmssd - 42) / 8, -3, 3);
  const zSdnn = clamp((sdnn - 54) / 10, -3, 3);
  const zTpi = clamp((tpi - 0.08) / 0.04, -3, 3);
  if (phenotype === 'ADRENERGIC') {
    return Number((zDhr - zRmssd + zTpi).toFixed(2));
  }
  return Number((-zRmssd - zSdnn + zTpi).toFixed(2));
}

function computeRiskPct(score, thr, phase, streak) {
  if (phase === 3) {
    const norm = score / Math.max(thr, 3.0);
    const p = Math.round(100 / (1 + Math.exp(-(norm * 3.1 - 1.9))) + streak * 6);
    return clamp(p, 4, 98);
  }
  const ratio = score / Math.max(thr, 1.0);
  if (ratio <= 0) return Math.round(clamp(8 + ratio * 4, 4, 15));
  if (ratio < 1) return Math.round(clamp(12 + ratio * 55, 10, 68));
  return Math.round(clamp(72 + (ratio - 1) * 45, 72, 98));
}

function phaseName(p) {
  if (p === 1) return 'Phase 1 • Warm-Up';
  if (p === 2) return 'Phase 2 • Personal Line';
  return 'Phase 3 • 1D-CNN';
}

function phaseShort(p) {
  if (p === 1) return 'P1 Warm-Up';
  if (p === 2) return 'P2 My Line';
  return 'P3 1D-CNN';
}

function addTimeline(text, tone = 'info') {
  const now = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  state.timeline.unshift({ time: now, text, tone });
  if (state.timeline.length > 8) state.timeline.pop();
}

function announce(msg) {
  document.getElementById('status-announcer').textContent = msg;
}

function stopReplayTimer() {
  if (state.replayTimer) {
    clearInterval(state.replayTimer);
    state.replayTimer = null;
  }
}

function exitReplayMode() {
  stopReplayTimer();
  state.replayClip = null;
  state.replayFrameIdx = -1;
  state.replayPrevSlot = null;
  state.replayCgmMgdl = null;
  state.replayTimeLabel = null;
}

function setScenarioBaseline() {
  exitReplayMode();
  state.baselineMinutes = 40;
  state.isSedentary = true;
  state.hrBpm = 62;
  state.deltaHr = 0;
  state.rmssd = 42;
  state.sdnn = 54;
  state.tremorTpi = 0.08;
  state.streakCount = 0;
  state.score = 0.2;
  state.riskPct = 8;
  state.tier = 'BASELINE';
  state.reason = 'Learning normal sleep (40/75m)';
  state.tcnnNight = createTcnnNightState();
  state.tcnnRawLogit = null;
  state.tcnnEma = null;
  state.tcnnThr = null;
  state.tcnnSlots = 4;
  addTimeline('Silent 75-min baseline warm-up (40/75m) — alerts held.', 'info');
  announce('Baseline warm-up mode active.');
  render();
}

function setScenarioSteady() {
  exitReplayMode();
  const isBrady = state.phenotype === 'BRADYCARDIC';
  state.baselineMinutes = 75;
  state.isSedentary = true;
  state.hrBpm = isBrady ? 63 : 61;
  state.deltaHr = isBrady ? 1 : -1;
  state.rmssd = isBrady ? 49 : 43;
  state.sdnn = isBrady ? 61 : 55;
  state.tremorTpi = isBrady ? 0.06 : 0.08;
  state.streakCount = 0;
  state.score = computeHeuristicScore(state.deltaHr, state.rmssd, state.sdnn, state.tremorTpi, state.phenotype);
  state.riskPct = computeRiskPct(state.score, activeThreshold(), state.phase, 0);

  if (state.phase === 3 && tcnnBundleData) {
    state.tcnnNight = createPhase3CohortNight(state.phenotype, true, state.age, state.t1dYears);
    const stepRes = stepTcnnNight(tcnnBundleData.cohort_bundle, state.tcnnNight, state.age, state.t1dYears, isBrady, false);
    state.tcnnRawLogit = stepRes.rawLogit;
    state.tcnnEma = stepRes.emaScore;
    state.tcnnThr = stepRes.threshold97;
    state.tcnnSlots = getTcnnValidSlotCount(state.tcnnNight);
    state.tcnnDiffText = 'Cohort 498p live';
    state.riskPct = stepRes.riskPct;
  } else {
    state.tcnnRawLogit = null;
    state.tcnnEma = null;
    state.tcnnThr = null;
  }

  state.tier = state.cooldownMinutes > 0 ? 'COOLDOWN' : 'STEADY';
  state.reason = 'Within baseline';
  announce('Calm normal sleep restored.');
  render();
}

function setScenarioMoving() {
  exitReplayMode();
  state.baselineMinutes = 75;
  state.isSedentary = false;
  state.hrBpm = 78;
  state.deltaHr = 16;
  state.rmssd = 31;
  state.sdnn = 45;
  state.tremorTpi = 0.11;
  state.streakCount = 0;
  state.score = 0.0;
  state.riskPct = 14;
  if (state.phase === 3) {
    pushTcnnSlot(state.tcnnNight, 0, 0, 0, 0, 0);
    state.tcnnSlots = getTcnnValidSlotCount(state.tcnnNight);
  }
  state.tier = 'MOVING';
  state.reason = 'Motion gate paused';
  addTimeline('Gross movement detected — checks paused & streak reset.', 'info');
  announce('Motion gate paused checks.');
  render();
}

function applyElevatedCheck(forceFull) {
  exitReplayMode();
  state.baselineMinutes = 75;
  state.isSedentary = true;
  const isBrady = state.phenotype === 'BRADYCARDIC';
  const req = streakRequired();
  const prevStreak = state.streakCount;
  const targetStep = forceFull ? req : Math.min(req, prevStreak + 1);

  if (state.phenotype === 'ADRENERGIC') {
    state.hrBpm = targetStep === 1 ? 82 : (targetStep === 2 ? 89 : 96);
    state.deltaHr = state.hrBpm - 62;
    state.rmssd = targetStep === 1 ? 22 : (targetStep === 2 ? 19 : 16);
    state.sdnn = targetStep === 1 ? 34 : (targetStep === 2 ? 30 : 26);
    state.tremorTpi = targetStep === 1 ? 0.16 : (targetStep === 2 ? 0.19 : 0.21);
    state.reason = 'Fast pulse + wrist tremor';
  } else {
    state.hrBpm = 57;
    state.deltaHr = -5;
    state.rmssd = targetStep === 1 ? 16 : 14;
    state.sdnn = targetStep === 1 ? 24 : 20;
    state.tremorTpi = targetStep === 1 ? 0.19 : 0.21;
    state.reason = 'HRV drop + wrist tremor';
  }

  let isHotCheck = true;
  if (state.phase === 3 && tcnnBundleData) {
    if (!state.tcnnNight || state.tcnnNight.stepCount === 0) {
      state.tcnnNight = createPhase3CohortNight(state.phenotype, true, state.age, state.t1dYears);
    }
    if (prevStreak === 0) {
      const onset = isBrady
        ? [[-0.2, -1.8, -1.7, 2.3, 1], [-0.25, -1.95, -1.85, 2.5, 1], [-0.3, -2.1, -2.0, 2.7, 1]]
        : [[1.3, -1.1, -1.0, 0.8, 1]];
      onset.forEach((row) => {
        pushTcnnSlot(state.tcnnNight, row[0], row[1], row[2], row[3], row[4]);
        stepTcnnNight(tcnnBundleData.cohort_bundle, state.tcnnNight, state.age, state.t1dYears, isBrady, false);
      });
    }
    const startIdx = forceFull ? Math.max(1, prevStreak + 1) : targetStep;
    let hotCount = prevStreak;
    let lastRes = null;
    for (let s = startIdx; s <= targetStep; s += 1) {
      const feat = isBrady
        ? (s === 1 ? [-0.35, -2.2, -2.1, 2.8, 1] : [-0.4, -2.3, -2.2, 2.9, 1])
        : (s === 1 ? [1.8, -1.5, -1.4, 1.2, 1] : (s === 2 ? [2.1, -1.7, -1.6, 1.5, 1] : [2.3, -1.9, -1.7, 1.7, 1]));
      pushTcnnSlot(state.tcnnNight, feat[0], feat[1], feat[2], feat[3], feat[4]);
      lastRes = stepTcnnNight(tcnnBundleData.cohort_bundle, state.tcnnNight, state.age, state.t1dYears, isBrady, false);
      hotCount = lastRes.isHot ? Math.min(req, hotCount + 1) : 0;
    }
    if (lastRes) {
      isHotCheck = lastRes.isHot;
      state.streakCount = hotCount;
      state.tcnnRawLogit = lastRes.rawLogit;
      state.tcnnEma = lastRes.emaScore;
      state.tcnnThr = lastRes.threshold97;
      state.tcnnSlots = getTcnnValidSlotCount(state.tcnnNight);
      state.tcnnDiffText = 'Cohort 498p live';
      state.riskPct = lastRes.riskPct;
      state.score = Number(lastRes.rawLogit.toFixed(2));
    }
  } else {
    state.streakCount = targetStep;
    const thr = activeThreshold();
    state.score = Math.max(thr + 0.5, computeHeuristicScore(state.deltaHr, state.rmssd, state.sdnn, state.tremorTpi, state.phenotype));
    state.riskPct = Math.max(76, computeRiskPct(state.score, thr, state.phase, state.streakCount));
  }

  if (isHotCheck && state.streakCount >= req) {
    if (state.alertsTonight >= 2) {
      state.tier = 'COOLDOWN';
      addTimeline('Sustained surge held — max 2 alerts/night already reached.', 'info');
      announce('Max 2 alerts per night reached.');
    } else if (state.cooldownMinutes > 0) {
      state.tier = 'COOLDOWN';
      addTimeline(`Sustained surge held — ${state.cooldownMinutes}m cooldown active.`, 'info');
      announce('Alert held by 30-minute cooldown.');
    } else {
      state.alertsTonight += 1;
      state.tier = 'ALERT';
      state.pendingPrick = true;
      state.hourlyRisk = [12, 36, state.riskPct, 28, 16];
      const smsMsg = state.smsEnabled ? `Text queued to ${state.caregiverName}` : 'SMS disabled';
      addTimeline(
        `${state.phase < 3 ? 'Possible low' : '1D-CNN alert'} (${state.streakCount}/${req} checks) • ${smsMsg} (${state.alertsTonight}/2).`,
        'alert'
      );
      announce('Symptom alert triggered on watch and Huawei Health.');
    }
  } else if (isHotCheck || state.streakCount > 0) {
    state.tier = 'WATCH';
    addTimeline(`Elevated check ${state.streakCount}/${req} — waiting for repeat before waking.`, 'info');
    announce(`Elevated check ${state.streakCount} of ${req}.`);
  } else {
    state.tier = 'STEADY';
    addTimeline('1D-CNN score stayed below 97th-percentile cutoff for your profile.', 'info');
  }
  render();
}

function startReplayNight(nightUid) {
  if (!tcnnBundleData) return;
  const clip = tcnnBundleData.replay_clips.find((c) => c.night_uid === nightUid);
  if (!clip) return;
  stopReplayTimer();

  state.phase = 3;
  state.phenotype = clip.archetype === 1 ? 'BRADYCARDIC' : 'ADRENERGIC';
  state.baselineMinutes = 75;
  state.isSedentary = true;
  state.streakCount = 0;
  state.alertsTonight = 0;
  state.cooldownMinutes = 0;
  state.replayClip = clip;
  state.replayFrameIdx = -1;
  state.replayPrevSlot = null;
  state.tcnnNight = createTcnnNightState();
  loadTcnnPrefixRows(state.tcnnNight, clip.baseline_prefix_z || []);

  addTimeline(`Loaded real held-out LOSO replay ${clip.night_uid} (${clip.frames.length} x 5m frames).`, 'info');
  stepReplayFrame();
}

function stepReplayFrame() {
  if (!state.replayClip) {
    startReplayNight('c2s02_7');
    return;
  }
  const clip = state.replayClip;
  const nextIdx = state.replayFrameIdx + 1;
  if (nextIdx >= clip.frames.length) {
    stopReplayTimer();
    addTimeline(`Completed ${clip.night_uid} replay (${clip.frames.length}/${clip.frames.length} frames).`, 'ok');
    render();
    return;
  }

  const f = clip.frames[nextIdx];
  const slotStep = state.replayPrevSlot !== null ? Math.max(1, f.slot - state.replayPrevSlot) : 1;
  if (state.replayPrevSlot !== null && f.slot > state.replayPrevSlot + 1) {
    pushTcnnGapSlots(state.tcnnNight, f.slot - state.replayPrevSlot - 1);
  }
  if (state.cooldownMinutes > 0) {
    state.cooldownMinutes = Math.max(0, state.cooldownMinutes - slotStep * 5);
  }

  pushTcnnSlot(state.tcnnNight, f.c_z[0], f.c_z[1], f.c_z[2], f.c_z[3], f.c_z[4]);
  const res = stepTcnnNight(
    clip.loso_bundle,
    state.tcnnNight,
    clip.age,
    clip.t1d_duration,
    clip.archetype === 1,
    true
  );

  const req = streakRequired();
  state.replayFrameIdx = nextIdx;
  state.replayPrevSlot = f.slot;
  state.replayTimeLabel = `${f.t} (Slot ${f.slot})`;
  state.replayCgmMgdl = f.ref_glucose_mgdl;
  state.hrBpm = f.hr_bpm >= 30 ? Math.round(f.hr_bpm) : '--';
  state.deltaHr = f.delta_hr;
  state.rmssd = Math.round(f.rmssd);
  state.sdnn = Math.round(f.sdnn);
  state.tremorTpi = Number(f.tpi_rel.toFixed(2));
  state.riskPct = res.riskPct;
  state.score = Number(res.rawLogit.toFixed(2));
  state.tcnnRawLogit = res.rawLogit;
  state.tcnnEma = res.emaScore;
  state.tcnnThr = res.threshold97;
  state.tcnnSlots = getTcnnValidSlotCount(state.tcnnNight);

  const rawDiff = Math.abs(res.rawLogit - f.ref_raw_logit);
  const emaDiff = Math.abs(res.emaScore - f.ref_ema);
  const maxD = Math.max(rawDiff, emaDiff);
  state.tcnnDiffText = maxD < 0.0001 ? `Exact (${maxD.toExponential(1)})` : `Diff ${maxD.toFixed(4)}`;

  state.streakCount = res.isHot ? Math.min(req, state.streakCount + 1) : 0;
  if (res.isHot && state.streakCount >= req && state.cooldownMinutes === 0 && state.alertsTonight < 2) {
    state.alertsTonight += 1;
    state.tier = 'ALERT';
    state.pendingPrick = true;
    state.reason = `LOSO ${clip.night_uid} ${state.streakCount}/${req}`;
    state.hourlyRisk = [14, 42, state.riskPct, 35, 18];
    stopReplayTimer();
    addTimeline(`${clip.night_uid} @ ${f.t}: 1D-CNN triggered alert (${state.alertsTonight}/2, EMA ${res.emaScore.toFixed(2)} >= ${res.threshold97.toFixed(2)}).`, 'alert');
    announce(`Real patient replay ${clip.night_uid} triggered Phase 3 1D-CNN alert.`);
  } else if (res.isHot) {
    state.tier = state.alertsTonight >= 2 || state.cooldownMinutes > 0 ? 'COOLDOWN' : 'WATCH';
    state.reason = `Hot check ${state.streakCount}/${req}`;
    if (state.alertsTonight >= 2 || state.cooldownMinutes > 0) {
      // Blocked cleanly by cap or cooldown
    } else {
      addTimeline(`${clip.night_uid} @ ${f.t}: Hot check ${state.streakCount}/${req} (EMA ${res.emaScore.toFixed(2)}).`, 'info');
    }
  } else {
    state.tier = state.cooldownMinutes > 0 ? 'COOLDOWN' : 'STEADY';
    state.reason = `${clip.night_uid} (${nextIdx + 1}/${clip.frames.length})`;
  }
  render();
}

function toggleReplayAuto() {
  if (!state.replayClip) {
    startReplayNight('c2s02_7');
  }
  if (state.replayTimer) {
    stopReplayTimer();
    render();
    return;
  }
  state.replayTimer = setInterval(() => {
    stepReplayFrame();
  }, 550);
  render();
}

function dismissToCooldown() {
  if (state.tier === 'ALERT') {
    state.cooldownMinutes = 30;
  }
  state.streakCount = 0;
  state.tier = 'COOLDOWN';
  state.hrBpm = 64;
  state.deltaHr = 2;
  state.rmssd = 40;
  state.sdnn = 52;
  state.tremorTpi = 0.08;
  state.riskPct = 15;
  state.reason = '30m cooldown active';
  addTimeline('User tapped I\'m awake — watch paused 30 min; log finger-prick check.', 'ok');
  announce('Alert dismissed. 30-minute cooldown active.');
  render();
}

function handleFingerPrick(mgDl) {
  const isLow = mgDl < 70;
  if (state.pendingPrick) {
    state.buzzLinkedPricks += 1;
    state.pendingPrick = false;
  }
  if (isLow) {
    state.confirmedLows += 1;
  } else {
    state.fineNights += 1;
  }
  if (state.buzzLinkedPricks >= 3 && !state.hasPersonalLine) {
    state.hasPersonalLine = true;
    state.personalLine = 5.44;
    state.phase = 2;
    addTimeline(`Finger-prick ${mgDl} mg/dL saved. Gate 1 passed — Phase 2 personal cutoff (5.44) unlocked!`, 'ok');
  } else if (state.confirmedLows >= 1 && state.fineNights >= 10 && !state.isCnnUnlocked) {
    state.isCnnUnlocked = true;
    state.phase = 3;
    addTimeline(`Finger-prick ${mgDl} mg/dL saved. Gate 2 passed — Phase 3 1D-CNN brain unlocked!`, 'ok');
    announce(`Finger-prick ${mgDl} mg/dL saved. Phase 3 1D-CNN unlocked.`);
    setScenarioSteady();
    return;
  } else {
    addTimeline(`Finger-prick logged: ${mgDl} mg/dL (${isLow ? 'Confirmed Low <70' : 'Fine 70+'}).`, 'ok');
  }
  announce(`Finger-prick ${mgDl} mg/dL saved.`);
  render();
}

function render() {
  const req = streakRequired();

  // Control active highlights
  document.getElementById('btn-type-adr').classList.toggle('active', state.phenotype === 'ADRENERGIC');
  document.getElementById('btn-type-adr').setAttribute('aria-pressed', String(state.phenotype === 'ADRENERGIC'));
  document.getElementById('btn-type-brady').classList.toggle('active', state.phenotype === 'BRADYCARDIC');
  document.getElementById('btn-type-brady').setAttribute('aria-pressed', String(state.phenotype === 'BRADYCARDIC'));

  [1, 2, 3].forEach((p) => {
    const btn = document.getElementById(`btn-phase-${p}`);
    btn.classList.toggle('active', state.phase === p);
    btn.setAttribute('aria-pressed', String(state.phase === p));
  });

  // Watch Mirror
  const ring = document.getElementById('watch-ring');
  ring.className = 'watch-ring';
  const watchOverlay = document.getElementById('watch-alert-overlay');

  if (state.tier === 'ALERT') {
    watchOverlay.hidden = false;
    document.getElementById('watch-alert-title').textContent = state.phase < 3 ? 'POSSIBLE LOW' : 'SYMPTOM ALERT';
    document.getElementById('watch-alert-risk').textContent = `${state.riskPct}% RISK`;
    document.getElementById('watch-alert-reason').textContent = state.phenotype === 'ADRENERGIC'
      ? 'Fast pulse & wrist tremor'
      : 'HRV calmness drop & tremor';
    document.getElementById('watch-alert-sms').textContent = state.smsEnabled
      ? `SMS: ${state.caregiverName} (${state.alertsTonight}/2 tonight)`
      : `SMS paused (${state.alertsTonight}/2 tonight)`;
    document.getElementById('watch-alert-vitals').textContent = `${state.hrBpm} BPM • HRV ${state.rmssd}ms`;
  } else {
    watchOverlay.hidden = true;
    if (state.tier === 'BASELINE') {
      ring.classList.add('state-baseline');
      document.getElementById('watch-hero-value').textContent = `${state.baselineMinutes}m`;
      document.getElementById('watch-hero-unit').textContent = 'OF 75M SETUP';
      document.getElementById('watch-hero-state').textContent = 'Learning sleep';
      document.getElementById('watch-hero-vitals').textContent = `${state.hrBpm} BPM • Still`;
    } else if (state.tier === 'MOVING') {
      ring.classList.add('state-paused');
      document.getElementById('watch-hero-value').textContent = 'PAUSED';
      document.getElementById('watch-hero-unit').textContent = 'MOVING';
      document.getElementById('watch-hero-state').textContent = 'Wait till still';
      document.getElementById('watch-hero-vitals').textContent = `${state.hrBpm} BPM • Awake`;
    } else {
      if (state.tier === 'WATCH') ring.classList.add('state-watch');
      document.getElementById('watch-hero-value').textContent = `${state.riskPct}%`;
      document.getElementById('watch-hero-unit').textContent = 'SYMPTOM RISK';
      document.getElementById('watch-hero-state').textContent = state.tier === 'WATCH'
        ? 'Watch'
        : (state.cooldownMinutes > 0 ? 'Resting' : 'Steady');
      document.getElementById('watch-hero-vitals').textContent = `${state.hrBpm} BPM • ${state.tremorTpi >= 0.14 ? 'Tremor' : `HRV ${state.rmssd}`}`;
    }
  }

  document.getElementById('watch-line-1').textContent = `${phaseShort(state.phase)} • ${state.baselineMinutes < 75 ? 'Warming up' : 'Base OK'}`;
  document.getElementById('watch-line-2').textContent = state.cooldownMinutes > 0
    ? `Cooldown ${state.cooldownMinutes}m • ${state.alertsTonight}/2 alerts`
    : `Checks ${state.streakCount}/${req} • ${state.alertsTonight}/2 alerts`;

  // Huawei Health Header & Hero Card
  document.getElementById('nav-phase-chip').textContent = phaseName(state.phase);
  const heroCard = document.getElementById('hh-hero-card');
  heroCard.className = 'alert-card';
  const alertBanner = document.getElementById('hh-alert-banner');

  if (state.tier === 'ALERT') {
    heroCard.classList.add('state-low');
    alertBanner.hidden = false;
    document.getElementById('hh-sms-badge').textContent = state.smsEnabled ? 'SMS QUEUED' : 'ALERT ACTIVE';
    document.getElementById('hh-risk-val').textContent = `${state.riskPct}%`;
    document.getElementById('hh-risk-unit').textContent = 'symptom risk';
    document.getElementById('hh-hero-msg').textContent = state.phase < 3
      ? 'Possible nocturnal low — sustained symptom checks, please verify.'
      : '1D-CNN detected sustained low-sugar symptoms — check sleeper now.';
  } else if (state.tier === 'WATCH') {
    heroCard.classList.add('state-watch');
    alertBanner.hidden = true;
    document.getElementById('hh-sms-badge').textContent = 'Watching';
    document.getElementById('hh-risk-val').textContent = `${state.riskPct}%`;
    document.getElementById('hh-risk-unit').textContent = 'symptom risk';
    document.getElementById('hh-hero-msg').textContent = `${state.streakCount} of ${req} elevated checks — ignoring isolated spikes until sustained.`;
  } else if (state.tier === 'BASELINE' || state.tier === 'MOVING') {
    heroCard.classList.add('state-paused');
    alertBanner.hidden = true;
    document.getElementById('hh-sms-badge').textContent = state.tier === 'BASELINE' ? 'Warm-Up' : 'Motion Gate';
    document.getElementById('hh-risk-val').textContent = state.tier === 'BASELINE' ? `${state.baselineMinutes}/75m` : 'Paused';
    document.getElementById('hh-risk-unit').textContent = state.tier === 'BASELINE' ? 'silent baseline' : 'moving';
    document.getElementById('hh-hero-msg').textContent = state.tier === 'BASELINE'
      ? 'Watch is silently learning tonight\'s normal sleep baseline before alerting.'
      : 'Movement detected — checks pause while tossing or awake to prevent false alarms.';
  } else {
    alertBanner.hidden = true;
    document.getElementById('hh-sms-badge').textContent = state.cooldownMinutes > 0 ? `Cooldown ${state.cooldownMinutes}m` : 'Monitoring';
    document.getElementById('hh-risk-val').textContent = `${state.riskPct}%`;
    document.getElementById('hh-risk-unit').textContent = 'symptom risk';
    document.getElementById('hh-hero-msg').textContent = state.cooldownMinutes > 0
      ? `30-minute safety rest active (${state.cooldownMinutes} min left).`
      : 'All steady — pulse, heart calmness, and wrist stillness match tonight\'s sleep.';
  }

  document.getElementById('hh-streak-pill').textContent = `Checks: ${state.streakCount}/${req}`;
  document.getElementById('hh-cap-pill').textContent = `Alerts: ${state.alertsTonight}/2 tonight`;
  document.getElementById('hh-reason-pill').textContent = state.reason;
  document.getElementById('hh-live-time').textContent = state.replayClip && state.replayTimeLabel
    ? `${state.replayClip.night_uid} • ${state.replayTimeLabel}`
    : '02:45 AM • Live 5m';
  document.getElementById('watch-clock').textContent = state.replayClip && state.replayTimeLabel
    ? state.replayTimeLabel.split(' ')[0]
    : '02:45 AM';

  // Phase 3 Live 1D-CNN Telemetry Box
  const tcnnBox = document.getElementById('hh-tcnn-box');
  const showTcnn = state.phase === 3 || state.replayClip !== null;
  tcnnBox.hidden = !showTcnn;
  if (showTcnn) {
    document.getElementById('hh-tcnn-slots').textContent = `${state.tcnnSlots}/12 slots`;
    document.getElementById('hh-tcnn-raw').textContent = state.tcnnRawLogit !== null ? state.tcnnRawLogit.toFixed(3) : '—';
    document.getElementById('hh-tcnn-ema').textContent = state.tcnnEma !== null ? state.tcnnEma.toFixed(3) : '—';
    document.getElementById('hh-tcnn-thr').textContent = state.tcnnThr !== null ? state.tcnnThr.toFixed(3) : '—';
    document.getElementById('hh-tcnn-diff').textContent = state.tcnnDiffText;

    const cgmRow = document.getElementById('hh-replay-cgm-row');
    const showCgm = Boolean(state.replayClip && state.showHiddenCgm && state.replayCgmMgdl !== null);
    cgmRow.hidden = !showCgm;
    if (showCgm) {
      const lowTag = state.replayCgmMgdl < 70 ? ' (HYPO <70)' : ' (Normal >=70)';
      document.getElementById('hh-replay-cgm').textContent = `${state.replayCgmMgdl} mg/dL${lowTag}`;
    }
  }

  // Replay clip selector states
  const rpMap = { 'rp-c2s02': 'c2s02_7', 'rp-c2s03': 'c2s03_3', 'rp-c1s05': 'c1s05_7' };
  Object.keys(rpMap).forEach((btnId) => {
    const active = state.replayClip && state.replayClip.night_uid === rpMap[btnId];
    const el = document.getElementById(btnId);
    if (el) {
      el.classList.toggle('active', Boolean(active));
      el.setAttribute('aria-pressed', String(Boolean(active)));
    }
  });
  const playBtn = document.getElementById('rp-play');
  if (playBtn) {
    playBtn.textContent = state.replayTimer ? 'Pause' : 'Auto-Play';
  }

  // Vitals grid
  const motionBadge = document.getElementById('hh-motion-badge');
  motionBadge.className = `badge-pill ${state.isSedentary ? 'ok' : 'warn'}`;
  motionBadge.textContent = state.isSedentary ? 'Lying still • Active' : 'Moving • Paused';

  document.getElementById('hh-hr-val').textContent = state.hrBpm;
  document.getElementById('hh-hr-sub').textContent = state.deltaHr >= 12
    ? `+${state.deltaHr} vs baseline`
    : (state.deltaHr <= -3 ? 'Flat / slow' : 'Resting normal');
  document.getElementById('hh-hrv-val').textContent = state.rmssd;
  document.getElementById('hh-hrv-sub').textContent = `SDNN ${state.sdnn} ms`;
  document.getElementById('hh-tremor-val').textContent = state.tremorTpi >= 0.16 ? 'Surge' : (state.tremorTpi >= 0.13 ? 'Mild' : 'Calm');
  document.getElementById('hh-tremor-sub').textContent = `TPI ${state.tremorTpi.toFixed(2)}`;

  // Finger-prick card & gates
  document.getElementById('prick-heading').textContent = state.pendingPrick
    ? 'Buzz finger-prick check needed'
    : 'Morning finger-prick check';
  document.getElementById('prick-gate-badge').textContent = state.isCnnUnlocked
    ? '1D-CNN Unlocked'
    : (state.hasPersonalLine ? 'Personal Line Ready' : `Gate 1: ${Math.min(3, state.buzzLinkedPricks)}/3 pricks`);

  document.getElementById('gate1-label').textContent = `${Math.min(3, state.buzzLinkedPricks)} / 3 buzz pricks`;
  document.getElementById('gate1-bar').value = Math.min(3, state.buzzLinkedPricks);
  document.getElementById('gate2-label').textContent = `${Math.min(1, state.confirmedLows)} / 1 low • ${Math.min(10, state.fineNights)} / 10 fine`;
  document.getElementById('gate2-bar').value = Math.min(10, state.fineNights) + (state.confirmedLows > 0 ? 1 : 0);
  document.getElementById('active-cutoff-note').textContent = state.phase === 1
    ? 'Active cutoff: Fixed formula score >= 3.7 (Phase 1 Warm-Up)'
    : (state.phase === 2
      ? `Active cutoff: Personal quiet-night line >= ${state.hasPersonalLine ? state.personalLine : 5.44} (Phase 2)`
      : 'Active brain: 60-min DualHead 1D-CNN (498 params, 97th-pct cutoff, Phase 3)');

  // Overnight bars
  const hours = ['12am', '2am', '4am', '6am', '8am'];
  const barsHost = document.getElementById('overnight-bars');
  barsHost.innerHTML = state.hourlyRisk.map((val, idx) => {
    const color = val >= 70 ? '#e1251b' : (val >= 35 ? '#d97706' : '#2f6fed');
    return `
      <div class="bar-col">
        <span class="bar-val">${val}%</span>
        <div class="bar-track"><div class="bar-fill" style="height:${Math.max(8, val)}%;background:${color}"></div></div>
        <span class="bar-time">${hours[idx]}</span>
      </div>
    `;
  }).join('');

  // Timeline
  const list = document.getElementById('hh-history-list');
  list.innerHTML = state.timeline.map((item) => {
    const dotClass = item.tone === 'alert' ? '' : (item.tone === 'ok' ? 'ok' : 'info');
    return `<li><span class="dot ${dotClass}" aria-hidden="true"></span><div><strong>${item.time}</strong> — ${item.text}</div></li>`;
  }).join('');
}

if (typeof document !== 'undefined') {
  // Accessible Tab Switching with Keyboard Arrows (per modern-web-guidance tabs guide)
  const tabs = Array.from(document.querySelectorAll('[role="tab"]'));
  const panels = Array.from(document.querySelectorAll('[role="tabpanel"]'));

  function activateTab(tab) {
    tabs.forEach((t, i) => {
      const selected = t === tab;
      t.setAttribute('aria-selected', String(selected));
      t.tabIndex = selected ? 0 : -1;
      panels[i].hidden = !selected;
    });
  }

  tabs.forEach((tab, idx) => {
    tab.addEventListener('click', () => activateTab(tab));
    tab.addEventListener('keydown', (e) => {
      if (e.key === 'ArrowRight' || e.key === 'ArrowLeft') {
        const next = e.key === 'ArrowRight' ? (idx + 1) % tabs.length : (idx - 1 + tabs.length) % tabs.length;
        tabs[next].focus();
        activateTab(tabs[next]);
      }
    });
  });

  // Simulator Button Bindings
  document.getElementById('btn-type-adr').addEventListener('click', () => {
    state.phenotype = 'ADRENERGIC';
    document.querySelector('input[name="phenotype"][value="ADRENERGIC"]').checked = true;
    setScenarioSteady();
  });
  document.getElementById('btn-type-brady').addEventListener('click', () => {
    state.phenotype = 'BRADYCARDIC';
    document.querySelector('input[name="phenotype"][value="BRADYCARDIC"]').checked = true;
    setScenarioSteady();
  });
  [1, 2, 3].forEach((p) => {
    document.getElementById(`btn-phase-${p}`).addEventListener('click', () => {
      state.phase = p;
      setScenarioSteady();
    });
  });

  document.getElementById('sc-baseline').addEventListener('click', setScenarioBaseline);
  document.getElementById('sc-steady').addEventListener('click', setScenarioSteady);
  document.getElementById('sc-spike').addEventListener('click', () => {
    state.streakCount = 0;
    applyElevatedCheck(false);
  });
  document.getElementById('sc-step').addEventListener('click', () => applyElevatedCheck(false));
  document.getElementById('sc-surge').addEventListener('click', () => applyElevatedCheck(true));
  document.getElementById('sc-moving').addEventListener('click', setScenarioMoving);
  document.getElementById('sc-reset-night').addEventListener('click', () => {
    state.alertsTonight = 0;
    state.cooldownMinutes = 0;
    state.hourlyRisk = [10, 12, 14, 11, 9];
    setScenarioSteady();
    addTimeline('Night counters reset (0/2 alerts, cooldown cleared).', 'info');
    render();
  });

  // Real Held-Out Patient Night Replay Bindings (Phase 3 1D-CNN)
  document.getElementById('rp-c2s02').addEventListener('click', () => startReplayNight('c2s02_7'));
  document.getElementById('rp-c2s03').addEventListener('click', () => startReplayNight('c2s03_3'));
  document.getElementById('rp-c1s05').addEventListener('click', () => startReplayNight('c1s05_7'));
  document.getElementById('rp-step').addEventListener('click', stepReplayFrame);
  document.getElementById('rp-play').addEventListener('click', toggleReplayAuto);
  document.getElementById('rp-stop').addEventListener('click', () => {
    exitReplayMode();
    setScenarioSteady();
    addTimeline('Exited real night replay — back to interactive simulator.', 'info');
    render();
  });
  document.getElementById('rp-show-cgm').addEventListener('change', (e) => {
    state.showHiddenCgm = Boolean(e.target.checked);
    render();
  });

  document.getElementById('watch-awake-btn').addEventListener('click', dismissToCooldown);
  document.getElementById('hh-awake-btn').addEventListener('click', dismissToCooldown);
  document.getElementById('hh-call-btn').addEventListener('click', () => {
    addTimeline(`Caregiver call triggered to ${state.caregiverName} (${state.caregiverPhone}).`, 'info');
    announce(`Calling ${state.caregiverName}.`);
    render();
  });

  // Accessible Finger-Prick Form Validation (validate on submit/blur, clear on input)
  const prickForm = document.getElementById('prick-form');
  const prickInput = document.getElementById('prick-input');
  const prickError = document.getElementById('prick-error');

  function validatePrickValue() {
    const raw = prickInput.value.trim();
    const num = Number(raw);
    if (!raw || !/^\d{2,3}$/.test(raw) || num < 20 || num > 600) {
      prickInput.setAttribute('aria-invalid', 'true');
      prickError.textContent = 'Please enter a valid finger-prick blood sugar between 20 and 600 mg/dL.';
      prickError.hidden = false;
      return null;
    }
    prickInput.removeAttribute('aria-invalid');
    prickError.hidden = true;
    return num;
  }

  prickInput.addEventListener('input', () => {
    prickInput.removeAttribute('aria-invalid');
    prickError.hidden = true;
  });

  prickInput.addEventListener('blur', () => {
    if (prickInput.value.trim().length > 0) {
      validatePrickValue();
    }
  });

  prickForm.addEventListener('submit', (e) => {
    e.preventDefault();
    const val = validatePrickValue();
    if (val === null) {
      prickInput.focus();
      return;
    }
    prickInput.value = '';
    handleFingerPrick(val);
  });

  document.getElementById('quick-prick-low').addEventListener('click', () => handleFingerPrick(54));
  document.getElementById('quick-prick-fine').addEventListener('click', () => handleFingerPrick(108));

  // Settings Form & Test SMS
  document.getElementById('btn-test-sms').addEventListener('click', () => {
    const feedback = document.getElementById('settings-feedback');
    addTimeline(`Test alert SMS simulated for ${state.caregiverName} (${state.caregiverPhone}).`, 'ok');
    feedback.textContent = `Test SMS simulated to ${state.caregiverPhone} (Huawei Cloud SMN wired in Cloud phase).`;
    render();
  });

  document.getElementById('settings-form').addEventListener('submit', (e) => {
    e.preventDefault();
    const ageVal = parseInt(document.getElementById('set-age').value.trim(), 10);
    const t1dVal = parseInt(document.getElementById('set-t1d').value.trim(), 10);
    if (!Number.isNaN(ageVal) && ageVal > 0 && ageVal < 120) state.age = ageVal;
    if (!Number.isNaN(t1dVal) && t1dVal >= 0 && t1dVal < 100) state.t1dYears = t1dVal;

    const selectedPheno = document.querySelector('input[name="phenotype"]:checked');
    if (selectedPheno) state.phenotype = selectedPheno.value;

    const cgName = document.getElementById('set-caregiver-name').value.trim();
    const cgPhone = document.getElementById('set-caregiver-phone').value.trim();
    if (cgName) state.caregiverName = cgName;
    if (cgPhone) state.caregiverPhone = cgPhone;
    state.smsEnabled = document.getElementById('set-sms-switch').checked;

    document.getElementById('settings-feedback').textContent = 'Settings saved and synced to Watch mirror.';
    addTimeline(`Profile updated (${state.phenotype === 'ADRENERGIC' ? 'Adrenergic 3x' : 'Blunted 2x'}).`, 'ok');
    setScenarioSteady();
  });

  render();
}

if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    createTcnnNightState,
    pushTcnnSlot,
    pushTcnnGapSlots,
    loadTcnnPrefixRows,
    getTcnnValidSlotCount,
    runTcnnSingleSeed,
    runTcnnEnsembleLogit,
    stepTcnnNight
  };
}
