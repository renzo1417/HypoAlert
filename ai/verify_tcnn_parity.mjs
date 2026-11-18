#!/usr/bin/env node
'use strict';

/**
 * Verifies numerical parity (< 1e-4) between PyTorch DualHead_multitask_smoothap
 * reference vectors and the production JS inference engine in health-companion-demo/app.js,
 * plus full end-to-end Phase 3 alert / zero-false-positive episode checks.
 */

import { createRequire } from 'node:module';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { fileURLToPath } from 'node:url';

const require = createRequire(import.meta.url);
const __dirname = path.dirname(fileURLToPath(import.meta.url));

const repoRoot = path.resolve(__dirname, '..');
const jsonBundle = JSON.parse(
  fs.readFileSync(path.join(repoRoot, 'ai', 'dualhead_tcnn_bundle.json'), 'utf8')
);

const sandboxWindow = {};
const bundleCode = fs.readFileSync(path.join(repoRoot, 'health-companion-demo', 'tcnn-bundle.js'), 'utf8');
vm.runInNewContext(bundleCode, { window: sandboxWindow });
const jsBundle = sandboxWindow.HYPOALERT_TCNN_BUNDLE;

const appEngine = require(path.join(repoRoot, 'health-companion-demo', 'app.js'));

assert.equal(jsonBundle.cohort_bundle.infer_params, 498, 'Expected 498 inference parameters');
assert.equal(jsBundle.cohort_bundle.infer_params, 498, 'Expected 498 inference parameters in JS bundle');
assert.equal(
  Math.abs(jsonBundle.cohort_bundle.thr_97pct - jsBundle.cohort_bundle.thr_97pct) < 1e-6,
  true,
  'JSON and JS cohort thresholds must match'
);

let globalMaxRawDiff = 0;
let globalMaxEmaDiff = 0;
let totalFramesChecked = 0;

for (const clip of jsBundle.replay_clips) {
  const night = appEngine.createTcnnNightState();
  appEngine.loadTcnnPrefixRows(night, clip.baseline_prefix_z || []);

  let maxRawDiff = 0;
  let maxEmaDiff = 0;
  let prevSlot = null;
  let streak = 0;
  let cooldownMin = 0;
  let alerts = 0;
  const req = clip.archetype === 1 ? 2 : 3;

  for (let i = 0; i < clip.frames.length; i += 1) {
    const f = clip.frames[i];
    const slotStep = prevSlot !== null ? Math.max(1, f.slot - prevSlot) : 1;
    if (prevSlot !== null && f.slot > prevSlot + 1) {
      appEngine.pushTcnnGapSlots(night, f.slot - prevSlot - 1);
    }
    if (cooldownMin > 0) {
      cooldownMin = Math.max(0, cooldownMin - slotStep * 5);
    }

    appEngine.pushTcnnSlot(night, f.c_z[0], f.c_z[1], f.c_z[2], f.c_z[3], f.c_z[4]);
    const res = appEngine.stepTcnnNight(
      clip.loso_bundle,
      night,
      clip.age,
      clip.t1d_duration,
      clip.archetype === 1,
      true
    );

    const rawDiff = Math.abs(res.rawLogit - f.ref_raw_logit);
    const emaDiff = Math.abs(res.emaScore - f.ref_ema);
    maxRawDiff = Math.max(maxRawDiff, rawDiff);
    maxEmaDiff = Math.max(maxEmaDiff, emaDiff);
    prevSlot = f.slot;
    totalFramesChecked += 1;

    assert.equal(rawDiff < 1e-4, true, `${clip.night_uid} frame ${i} raw diff=${rawDiff}`);
    assert.equal(emaDiff < 1e-4, true, `${clip.night_uid} frame ${i} ema diff=${emaDiff}`);

    streak = res.isHot ? streak + 1 : 0;
    if (res.isHot && streak >= req && cooldownMin === 0 && alerts < 2) {
      alerts += 1;
      cooldownMin = 30;
    }
  }

  globalMaxRawDiff = Math.max(globalMaxRawDiff, maxRawDiff);
  globalMaxEmaDiff = Math.max(globalMaxEmaDiff, maxEmaDiff);

  if (clip.night_uid === 'c2s02_7') {
    assert.equal(alerts >= 1 && alerts <= 2, true, `Expected 1-2 alerts on c2s02_7, got ${alerts}`);
  } else if (clip.night_uid === 'c1s05_7') {
    assert.equal(alerts, 0, `Expected 0 false alarms on control c1s05_7, got ${alerts}`);
  }

  console.log(
    `[PASS] ${clip.night_uid} (${clip.frames.length} frames): ` +
    `max_raw_diff=${maxRawDiff.toExponential(2)}, max_ema_diff=${maxEmaDiff.toExponential(2)}, alerts=${alerts}`
  );
}

// Verify cohort bundle interactive Phase 3 calm vs 3-step ADR and 2-step BRADY trajectories
for (const cfg of [
  {
    name: 'Cohort ADR (3x)',
    isBrady: false,
    age: 28,
    t1d: 8,
    calm: [-0.2, 0.2, 0.1, 0.0],
    onset: [[1.3, -1.1, -1.0, 0.8]],
    steps: [[1.8, -1.5, -1.4, 1.2], [2.1, -1.7, -1.6, 1.5], [2.3, -1.9, -1.7, 1.7]],
    req: 3
  },
  {
    name: 'Cohort BRADY (2x)',
    isBrady: true,
    age: 28,
    t1d: 8,
    calm: [0.5, 1.0, 0.8, -0.6],
    onset: [[-0.2, -1.8, -1.7, 2.3], [-0.25, -1.95, -1.85, 2.5], [-0.3, -2.1, -2.0, 2.7]],
    steps: [[-0.35, -2.2, -2.1, 2.8], [-0.4, -2.3, -2.2, 2.9]],
    req: 2
  }
]) {
  const night = appEngine.createTcnnNightState();
  for (let t = 0; t < 12; t += 1) {
    appEngine.pushTcnnSlot(night, cfg.calm[0], cfg.calm[1], cfg.calm[2], cfg.calm[3], 1.0);
  }
  for (let i = 0; i < 3; i += 1) {
    appEngine.pushTcnnSlot(night, cfg.calm[0], cfg.calm[1], cfg.calm[2], cfg.calm[3], 1.0);
    const calmRes = appEngine.stepTcnnNight(jsBundle.cohort_bundle, night, cfg.age, cfg.t1d, cfg.isBrady, false);
    assert.equal(calmRes.isHot, false, `${cfg.name} should stay below cutoff in calm baseline`);
  }
  for (const r of cfg.onset) {
    appEngine.pushTcnnSlot(night, r[0], r[1], r[2], r[3], 1.0);
    appEngine.stepTcnnNight(jsBundle.cohort_bundle, night, cfg.age, cfg.t1d, cfg.isBrady, false);
  }
  let streak = 0;
  for (const s of cfg.steps) {
    appEngine.pushTcnnSlot(night, s[0], s[1], s[2], s[3], 1.0);
    const stepRes = appEngine.stepTcnnNight(jsBundle.cohort_bundle, night, cfg.age, cfg.t1d, cfg.isBrady, false);
    assert.equal(stepRes.isHot, true, `${cfg.name} surge step should exceed 97th-pct cutoff`);
    streak += 1;
  }
  assert.equal(streak, cfg.req);
  console.log(`[PASS] ${cfg.name}: calm=false -> ${streak}/${cfg.req} hot checks confirmed`);
}

console.log(
  `ALL PARITY CHECKS PASSED (${totalFramesChecked} frames across 3 real nights; ` +
  `max_raw_diff=${globalMaxRawDiff.toExponential(2)}, max_ema_diff=${globalMaxEmaDiff.toExponential(2)})`
);
