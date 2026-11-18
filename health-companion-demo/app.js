'use strict';

// Progressive fallback for browsers without native <input type="checkbox" switch> support
const supportsNativeSwitch = 'switch' in HTMLInputElement.prototype;
document.querySelectorAll('input[type="checkbox"][switch]').forEach((el) => {
  el.setAttribute('role', 'switch');
  if (!supportsNativeSwitch) {
    el.classList.add('switch-fallback');
  }
});

const state = {
  age: 26,
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
  return 3.7;
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

function setScenarioBaseline() {
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
  addTimeline('Silent 75-min baseline warm-up (40/75m) — alerts held.', 'info');
  announce('Baseline warm-up mode active.');
  render();
}

function setScenarioSteady() {
  state.baselineMinutes = 75;
  state.isSedentary = true;
  state.hrBpm = 61;
  state.deltaHr = -1;
  state.rmssd = 43;
  state.sdnn = 55;
  state.tremorTpi = 0.08;
  state.streakCount = 0;
  state.score = computeHeuristicScore(-1, 43, 55, 0.08, state.phenotype);
  state.riskPct = computeRiskPct(state.score, activeThreshold(), state.phase, 0);
  state.tier = state.cooldownMinutes > 0 ? 'COOLDOWN' : 'STEADY';
  state.reason = 'Within baseline';
  announce('Calm normal sleep restored.');
  render();
}

function setScenarioMoving() {
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
  state.tier = 'MOVING';
  state.reason = 'Motion gate paused';
  addTimeline('Gross movement detected — checks paused & streak reset.', 'info');
  announce('Motion gate paused checks.');
  render();
}

function applyElevatedCheck(forceFull) {
  state.baselineMinutes = 75;
  state.isSedentary = true;
  const req = streakRequired();
  state.streakCount = forceFull ? req : Math.min(req, state.streakCount + 1);

  if (state.phenotype === 'ADRENERGIC') {
    state.hrBpm = forceFull || state.streakCount > 1 ? 98 : 89;
    state.deltaHr = state.hrBpm - 62;
    state.rmssd = 17;
    state.sdnn = 28;
    state.tremorTpi = 0.21;
    state.reason = 'Fast pulse + wrist tremor';
  } else {
    state.hrBpm = 57;
    state.deltaHr = -5;
    state.rmssd = 15;
    state.sdnn = 22;
    state.tremorTpi = 0.18;
    state.reason = 'HRV drop + wrist tremor';
  }

  const thr = activeThreshold();
  state.score = Math.max(thr + 0.5, computeHeuristicScore(state.deltaHr, state.rmssd, state.sdnn, state.tremorTpi, state.phenotype));
  state.riskPct = Math.max(76, computeRiskPct(state.score, thr, state.phase, state.streakCount));

  if (state.streakCount >= req) {
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
  } else {
    state.tier = 'WATCH';
    addTimeline(`Elevated check ${state.streakCount}/${req} — waiting for repeat before waking.`, 'info');
    announce(`Elevated check ${state.streakCount} of ${req}.`);
  }
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
  render();
});

render();
