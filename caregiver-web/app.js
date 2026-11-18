(function () {
  "use strict";

  // =========================================================================
  // Pure Causal 1D-CNN Inference Engine (DualHead_multitask_smoothap, 498p)
  // Mirrors entry/src/main/ets/models/TcnnEngine.ets & health-companion-demo/app.js
  // Drives Phase 3 scenarios & c2s02_7 replay behind plain-English caregiver copy.
  // =========================================================================
  function createEmptyTcnnBuffer() {
    return Array.from({ length: 5 }, function () {
      return new Array(12).fill(0);
    });
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
    for (var c = 0; c < 5; c += 1) {
      for (var t = 0; t < 11; t += 1) {
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

  function loadTcnnPrefixRows(night, prefixRows) {
    night.windowBuf = createEmptyTcnnBuffer();
    night.firstThreePlatt = [];
    night.prevEma = 0;
    night.stepCount = 0;
    for (var i = 0; i < prefixRows.length; i += 1) {
      var r = prefixRows[i];
      if (r && r.length >= 5) {
        pushTcnnSlot(night, r[0], r[1], r[2], r[3], r[4]);
      }
    }
  }

  function pushTcnnGapSlots(night, gapCount) {
    var clamped = Math.min(12, Math.max(0, gapCount));
    for (var g = 0; g < clamped; g += 1) {
      pushTcnnSlot(night, 0, 0, 0, 0, 0);
    }
  }

  function runTcnnSingleSeed(mw, buf, age, t1dDuration, isBradycardic) {
    var h1 = Array.from({ length: 8 }, function () {
      return new Float64Array(12);
    });
    for (var o = 0; o < 8; o += 1) {
      for (var t = 0; t < 12; t += 1) {
        var s = mw.conv1_b[o];
        for (var c = 0; c < 5; c += 1) {
          for (var k = 0; k < 3; k += 1) {
            var idx = t - 2 + k;
            if (idx >= 0) s += mw.conv1_w[o][c][k] * buf[c][idx];
          }
        }
        h1[o][t] = s > 0 ? s : 0;
      }
    }

    var h2 = Array.from({ length: 8 }, function () {
      return new Float64Array(12);
    });
    for (var o2 = 0; o2 < 8; o2 += 1) {
      for (var t2 = 0; t2 < 12; t2 += 1) {
        var s2 = mw.conv2_b[o2];
        for (var c2 = 0; c2 < 8; c2 += 1) {
          for (var k2 = 0; k2 < 3; k2 += 1) {
            var idx2 = t2 - 4 + 2 * k2;
            if (idx2 >= 0) s2 += mw.conv2_w[o2][c2][k2] * h1[c2][idx2];
          }
        }
        h2[o2][t2] = s2 > 0 ? s2 : 0;
      }
    }

    var feat = new Float64Array(18);
    for (var f = 0; f < 8; f += 1) {
      var sum = 0;
      for (var tt = 0; tt < 12; tt += 1) sum += h2[f][tt];
      feat[f] = sum / 12.0;
      feat[8 + f] = h2[f][11];
    }
    feat[16] = age / 50.0;
    feat[17] = t1dDuration / 20.0;

    var hidden = new Float64Array(8);
    for (var i = 0; i < 8; i += 1) {
      var hs = mw.fc1_b[i];
      for (var j = 0; j < 18; j += 1) hs += mw.fc1_w[i][j] * feat[j];
      hidden[i] = hs > 0 ? hs : 0;
    }

    var logit = isBradycardic ? mw.hb_b[0] : mw.ha_b[0];
    var hw = isBradycardic ? mw.hb_w[0] : mw.ha_w[0];
    for (var m = 0; m < 8; m += 1) logit += hw[m] * hidden[m];
    return logit;
  }

  function runTcnnEnsembleLogit(bundle, buf, age, t1dDuration, isBradycardic) {
    var total = 0;
    var n = bundle.models.length;
    for (var s = 0; s < n; s += 1) {
      total += runTcnnSingleSeed(bundle.models[s], buf, age, t1dDuration, isBradycardic);
    }
    return total / Math.max(1, n);
  }

  function stepTcnnNight(bundle, night, age, t1dDuration, isBradycardic, useGlobalThr) {
    var rawLogit = runTcnnEnsembleLogit(bundle, night.windowBuf, age, t1dDuration, isBradycardic);
    var pl = bundle.platt[isBradycardic ? "1" : "0"];
    var zPlatt = pl.a * rawLogit + pl.b;

    var anc = zPlatt;
    if (night.stepCount > 0 && night.firstThreePlatt.length > 0) {
      var sumAnc = 0;
      for (var i = 0; i < night.firstThreePlatt.length; i += 1) {
        sumAnc += night.firstThreePlatt[i];
      }
      anc = sumAnc / night.firstThreePlatt.length;
    }
    if (night.firstThreePlatt.length < 3) {
      night.firstThreePlatt.push(zPlatt);
    }

    var zAnc = zPlatt - 0.25 * anc;
    var emaScore = night.stepCount === 0 ? zAnc : (0.5 * zAnc + 0.5 * night.prevEma);
    night.prevEma = emaScore;
    night.stepCount += 1;

    var threshold97 = useGlobalThr
      ? bundle.thr_97pct
      : (isBradycardic ? bundle.thr_97_brady : bundle.thr_97_adr);
    var isHot = emaScore >= threshold97;
    var scaled = (emaScore - threshold97) * 1.15 + 0.95;
    var riskPct = Math.round(100.0 / (1.0 + Math.exp(-scaled)));
    riskPct = Math.max(4, Math.min(98, riskPct));

    return { emaScore: emaScore, threshold97: threshold97, isHot: isHot, riskPct: riskPct };
  }

  var tcnnBundleData = (typeof window !== "undefined" && window.HYPOALERT_TCNN_BUNDLE)
    ? window.HYPOALERT_TCNN_BUNDLE
    : null;

  var state = {
    preset: "calm",
    phase: 1,              // 1 | 2 | 3 (simulated behind Demo Scenario, never jargonized in main UI)
    bodyType: "Adrenergic", // "Adrenergic" | "Blunted"
    watchConnected: true,
    watchBattery: 86,
    nightMinutes: 135,      // 02:15 AM inside the 22:00-06:00 window
    symptomScore: 1.2,
    streakCount: 0,
    alertsTonight: 0,
    cooldownMinutes: 0,     // 30m post-alert safety rest rule matching Watch/Phone
    pendingPrickCheck: false,
    buzzLinkedPricks: 2,
    confirmedLows: 0,
    fineNights: 6,
    hasPersonalLine: false,
    isCnnUnlocked: false,
    isMotionGated: false,
    baselineMinutes: 75,
    heartRate: 60,
    hrvMs: 40,
    tremorLevel: "calm",    // calm | mild | surge
    morningCheckText: "Waiting for morning blood sugar check",
    morningCheckTone: "neutral",
    calmWeekNights: 6,
    lowWeekNights: 0,
    smnSentTime: "",
    caregiverCheckedIn: false,
    replayTimer: null,
    replayClip: null,
    replayFrameIdx: -1,
    replayPrevSlot: null,
    tcnnNight: createTcnnNightState(),
    hourlyLabels: ["12 AM", "1 AM", "2 AM", "3 AM", "4 AM", "5 AM", "6 AM", "7 AM"],
    hourlyScores: [1.0, 1.2, 1.4, 1.3, 1.1, 1.2, 1.1, 1.2],
    events: [
      { time: "01:42 AM", title: "Normal turn in bed ignored", detail: "Brief movement — no false alert", tone: "info" },
      { time: "01:15 AM", title: "Normal turn in bed ignored", detail: "Brief movement — no false alert", tone: "info" },
      { time: "10:00 PM", title: "Night monitoring started", detail: "Resting baseline learned at 61 bpm", tone: "ok" }
    ],
    ppgPhase: 0,
    ppgData: []
  };

  function el(id) {
    return document.getElementById(id);
  }

  function formatNightTime(minutesAfterTenPm) {
    var total = (22 * 60 + minutesAfterTenPm) % (24 * 60);
    var hh = Math.floor(total / 60);
    var mm = total % 60;
    var suffix = hh >= 12 ? "PM" : "AM";
    var h12 = hh % 12;
    if (h12 === 0) h12 = 12;
    return String(h12).padStart(2, "0") + ":" + String(mm).padStart(2, "0") + " " + suffix;
  }

  function advanceNightStamp() {
    state.nightMinutes = Math.min(460, state.nightMinutes + 1);
    return formatNightTime(state.nightMinutes);
  }

  function requiredStreak() {
    return state.bodyType === "Blunted" ? 2 : 3;
  }

  function evaluateMode() {
    if (state.baselineMinutes < 75) return "Learning";
    if (state.isMotionGated) return "Gated";
    if (state.symptomScore >= 3.7 && state.streakCount >= requiredStreak()) {
      if (state.cooldownMinutes > 0 || state.alertsTonight >= 2) {
        return state.cooldownMinutes > 0 ? "Cooldown" : "Warning";
      }
      return "Critical";
    }
    if (state.cooldownMinutes > 0) return "Cooldown";
    if (state.symptomScore >= 3.7 || state.streakCount > 0) return "Warning";
    return "Normal";
  }

  function ppgSample(phase) {
    var sys = Math.exp(-Math.pow((phase - 0.18) / 0.07, 2));
    var notch = 0.36 * Math.exp(-Math.pow((phase - 0.38) / 0.055, 2));
    var drift = 0.035 * Math.sin(phase * Math.PI * 2.0);
    return sys + notch + drift;
  }

  function initPpg() {
    for (var i = 0; i < 96; i++) {
      state.ppgData.push(ppgSample(i / 96));
    }
  }

  function stopReplayTimer() {
    if (state.replayTimer) {
      clearInterval(state.replayTimer);
      state.replayTimer = null;
    }
  }

  function stepTelemetry() {
    if (!state.watchConnected) return;

    var step = 0.04 + state.heartRate / 4400;
    for (var k = 0; k < 2; k++) {
      state.ppgPhase += step;
      if (state.ppgPhase >= 1) state.ppgPhase -= 1;
      var jitter = (Math.random() - 0.5) * (state.isMotionGated ? 0.065 : 0.02);
      state.ppgData.push(ppgSample(state.ppgPhase) + jitter);
      if (state.ppgData.length > 96) state.ppgData.shift();
    }

    if (state.replayClip && state.replayTimer) {
      return;
    }

    var mode = evaluateMode();
    if (mode === "Critical") {
      state.heartRate = state.bodyType === "Blunted"
        ? 56 + Math.round((Math.random() - 0.5) * 2)
        : 95 + Math.round((Math.random() - 0.5) * 4);
      state.hrvMs = 19 + Math.round(Math.random() * 3);
    } else if (mode === "Warning") {
      state.heartRate = state.bodyType === "Blunted" ? 59 : 76 + Math.round((Math.random() - 0.5) * 3);
      state.hrvMs = 28 + Math.round(Math.random() * 3);
    } else if (mode === "Gated") {
      state.heartRate = 69 + Math.round((Math.random() - 0.5) * 3);
      state.hrvMs = 36;
    } else {
      state.heartRate = 60 + Math.round((Math.random() - 0.5) * 2);
      state.hrvMs = 40 + Math.round(Math.random() * 3);
    }
  }

  function setupHiDpiCanvas(canvas) {
    var dpr = window.devicePixelRatio || 1;
    var rect = canvas.getBoundingClientRect();
    var cssW = Math.max(120, Math.round(rect.width || canvas.clientWidth || 210));
    var cssH = Math.max(60, Math.round(rect.height || canvas.clientHeight || 88));
    if (canvas.width !== Math.round(cssW * dpr) || canvas.height !== Math.round(cssH * dpr)) {
      canvas.width = Math.round(cssW * dpr);
      canvas.height = Math.round(cssH * dpr);
    }
    var ctx = canvas.getContext("2d");
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    return { ctx: ctx, w: cssW, h: cssH };
  }

  function drawHeroBars(mode) {
    var canvas = el("hero-bars-canvas");
    if (!canvas) return;
    var res = setupHiDpiCanvas(canvas);
    var ctx = res.ctx;
    var W = res.w;
    var H = res.h;
    ctx.clearRect(0, 0, W, H);

    var heights = mode === "Critical"
      ? [0.46, 0.78, 0.62, 0.94, 0.76, 0.98, 0.86, 0.68, 0.92, 0.74, 0.84, 0.66]
      : mode === "Warning"
        ? [0.34, 0.52, 0.44, 0.70, 0.60, 0.78, 0.54, 0.48, 0.66, 0.48, 0.54, 0.42]
        : [0.30, 0.46, 0.36, 0.60, 0.50, 0.38, 0.56, 0.44, 0.62, 0.38, 0.46, 0.34];

    var colors = mode === "Critical"
      ? ["#ffffff", "#fecaca", "#ffffff", "#fca5a5", "#ffffff", "#ffffff", "#fecaca", "#ffffff", "#fca5a5", "#ffffff", "#fecaca", "#ffffff"]
      : ["#111318", "#2a82f0", "#111318", "#111318", "#2a82f0", "#111318", "#111318", "#2a82f0", "#111318", "#111318", "#2a82f0", "#111318"];

    ctx.lineCap = "round";
    ctx.lineWidth = 5;
    var padX = 6;
    var step = (W - padX * 2) / (heights.length - 1);
    for (var i = 0; i < heights.length; i++) {
      var x = padX + i * step;
      var len = Math.max(12, heights[i] * (H - 12));
      var top = (H - len) / 2;
      ctx.strokeStyle = colors[i];
      ctx.beginPath();
      ctx.moveTo(x, top);
      ctx.lineTo(x, top + len);
      ctx.stroke();
    }
  }

  function drawPpg(mode) {
    var canvas = el("ppg-canvas");
    if (!canvas) return;
    var res = setupHiDpiCanvas(canvas);
    var ctx = res.ctx;
    var W = res.w;
    var H = res.h;
    ctx.clearRect(0, 0, W, H);

    var n = state.ppgData.length;
    if (n < 2) return;

    var stroke = mode === "Critical" ? "#dc2626" : mode === "Warning" ? "#d97706" : "#7c3aed";
    var pts = [];
    for (var i = 0; i < n; i++) {
      var v = Math.min(1.15, Math.max(-0.1, state.ppgData[i]));
      pts.push({
        x: (i / (n - 1)) * W,
        y: H - 12 - (v / 1.15) * (H - 26)
      });
    }

    var grad = ctx.createLinearGradient(0, 10, 0, H);
    grad.addColorStop(0, mode === "Critical" ? "rgba(220,38,38,0.22)" : "rgba(124,58,237,0.22)");
    grad.addColorStop(1, "rgba(124,58,237,0.02)");

    ctx.beginPath();
    ctx.moveTo(pts[0].x, H);
    for (var j = 0; j < n; j++) ctx.lineTo(pts[j].x, pts[j].y);
    ctx.lineTo(pts[n - 1].x, H);
    ctx.closePath();
    ctx.fillStyle = grad;
    ctx.fill();

    ctx.beginPath();
    ctx.strokeStyle = stroke;
    ctx.lineWidth = 2.4;
    ctx.lineCap = "round";
    ctx.lineJoin = "round";
    for (var k = 0; k < n; k++) {
      if (k === 0) ctx.moveTo(pts[k].x, pts[k].y);
      else ctx.lineTo(pts[k].x, pts[k].y);
    }
    ctx.stroke();

    var marker = pts[Math.floor(n * 0.72)];
    ctx.fillStyle = stroke;
    ctx.beginPath();
    ctx.arc(marker.x, marker.y, 4.5, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = "#ffffff";
    ctx.beginPath();
    ctx.arc(marker.x, marker.y, 2, 0, Math.PI * 2);
    ctx.fill();
  }

  function svgEl(tag, attrs) {
    var node = document.createElementNS("http://www.w3.org/2000/svg", tag);
    for (var k in attrs) {
      if (Object.prototype.hasOwnProperty.call(attrs, k)) {
        node.setAttribute(k, String(attrs[k]));
      }
    }
    return node;
  }

  function drawOvernightSvg() {
    var svg = el("overnight-svg");
    if (!svg) return;
    while (svg.firstChild) svg.removeChild(svg.firstChild);

    var W = 620;
    var H = 220;
    var padL = 74;
    var padR = 16;
    var topPad = 24;
    var botPad = 28;
    var chartH = H - topPad - botPad;
    var maxScore = 6.0;
    var alertLevel = 3.7;

    [
      { label: "Calm", val: 1.5 },
      { label: "Watch", val: 2.8 }
    ].forEach(function (band) {
      var y = topPad + chartH - (band.val / maxScore) * chartH;
      svg.appendChild(svgEl("line", {
        x1: padL, y1: y, x2: W - padR, y2: y,
        stroke: "rgba(17,19,24,0.06)", "stroke-width": 1
      }));
      var t = svgEl("text", {
        x: 6, y: y + 4, fill: "#4b5563",
        "font-size": 12, "font-weight": 600
      });
      t.textContent = band.label;
      svg.appendChild(t);
    });

    var cutY = topPad + chartH - (alertLevel / maxScore) * chartH;
    svg.appendChild(svgEl("line", {
      x1: padL, y1: cutY, x2: W - padR, y2: cutY,
      stroke: "#d97706", "stroke-width": 1.6, "stroke-dasharray": "5 5"
    }));
    var alertLabel = svgEl("text", {
      x: 6, y: cutY + 4, fill: "#92400e",
      "font-size": 12, "font-weight": 700
    });
    alertLabel.textContent = "Alert Line";
    svg.appendChild(alertLabel);

    var scores = state.hourlyScores;
    var peakScore = Math.max.apply(null, scores);
    var slotW = (W - padL - padR) / scores.length;
    var barW = Math.min(40, slotW * 0.56);

    for (var i = 0; i < scores.length; i++) {
      (function (idx) {
        var val = scores[idx];
        var h = Math.max(16, (Math.min(maxScore, val) / maxScore) * chartH);
        var x = padL + idx * slotW + (slotW - barW) / 2;
        var y = topPad + chartH - h;
        var isAlert = val >= alertLevel;
        var isWatch = !isAlert && val >= 2.6;
        var fill = isAlert ? "#dc2626" : isWatch ? "#d97706" : val >= peakScore ? "#111318" : "#cfd8e6";

        var bar = svgEl("rect", {
          x: x, y: y, width: barW, height: h, rx: 9,
          fill: fill, style: "cursor:pointer"
        });

        var desc = isAlert ? "Alert sent — check needed" : isWatch ? "Watch closely" : "Calm rest";
        bar.addEventListener("mouseenter", function () {
          var tip = el("chart-tooltip");
          tip.textContent = state.hourlyLabels[idx] + " · " + desc;
          tip.hidden = false;
        });
        bar.addEventListener("mouseleave", function () {
          el("chart-tooltip").hidden = true;
        });
        svg.appendChild(bar);

        var lbl = svgEl("text", {
          x: x + barW / 2, y: H - 6, "text-anchor": "middle",
          fill: "#4b5563", "font-size": 12, "font-weight": 600
        });
        lbl.textContent = state.hourlyLabels[idx];
        svg.appendChild(lbl);
      })(i);
    }
  }

  function renderEvents() {
    var ul = el("event-list");
    if (!ul) return;
    ul.innerHTML = "";
    var list = state.events.slice(0, 6);
    for (var i = 0; i < list.length; i++) {
      var ev = list[i];
      var li = document.createElement("li");
      li.className = "timeline-row";

      var left = document.createElement("div");
      left.className = "timeline-left";

      var dot = document.createElement("span");
      dot.className = "dot " + (ev.tone === "crit" ? "dot-crit" : ev.tone === "warn" ? "dot-warn" : "dot-ok");

      var copy = document.createElement("div");
      var title = document.createElement("div");
      title.className = "timeline-title";
      title.textContent = ev.title;
      var detail = document.createElement("div");
      detail.className = "timeline-detail";
      detail.textContent = ev.detail;
      copy.appendChild(title);
      copy.appendChild(detail);

      left.appendChild(dot);
      left.appendChild(copy);

      var time = document.createElement("span");
      time.className = "timeline-time tnum";
      time.textContent = ev.time;

      li.appendChild(left);
      li.appendChild(time);
      ul.appendChild(li);
    }
  }

  function render() {
    var mode = evaluateMode();
    el("clock-pill").textContent = formatNightTime(state.nightMinutes);
    el("live-dot").className = "dot " + (mode === "Critical" ? "dot-crit" : state.watchConnected ? "dot-ok" : "dot-warn");
    el("watch-link-label").textContent = state.watchConnected ? "· Watch " + state.watchBattery + "%" : "· Offline";
    el("offline-banner").hidden = state.watchConnected;

    var cloudChip = el("cloud-sync-pill");
    cloudChip.textContent = state.watchConnected ? "Connected" : "Paused";
    cloudChip.className = "soft-chip " + (state.watchConnected ? "ok-chip" : "warn-chip");

    var hero = el("hero-card");
    hero.className = "hero-card" + (mode === "Critical" ? " is-critical" : mode === "Warning" ? " is-warning" : "");

    var pill = el("hero-pill");
    pill.textContent = mode === "Critical"
      ? "Alert Sent"
      : mode === "Warning"
        ? "Needs Check"
        : mode === "Gated"
          ? "Turn in Bed"
          : mode === "Cooldown"
            ? "Rest (" + state.cooldownMinutes + "m)"
            : mode === "Learning"
              ? "Learning Sleep"
              : "Sleeping Steady";
    pill.className = "status-pill " + (
      mode === "Critical"
        ? "state-crit"
        : mode === "Warning"
          ? "state-warn"
          : (mode === "Gated" || mode === "Learning" || mode === "Cooldown")
            ? "state-info"
            : "state-ok"
    );
    el("hero-sync-tag").textContent = state.watchConnected ? "Synced 1m ago (22:00–06:00)" : "Last synced 4m ago (22:00–06:00)";

    if (mode === "Critical") {
      el("hero-headline").textContent = "Urgent: Check on Renzo now";
      el("hero-explanation").textContent = state.bodyType === "Blunted"
        ? "Overnight heart rate dip and wrist shaking continued. Watch is buzzing beside the bed."
        : "Fast pulse and wrist shaking continued. Watch is buzzing beside the bed.";
    } else if (mode === "Cooldown") {
      el("hero-headline").textContent = "Checked on Renzo — resting steady";
      el("hero-explanation").textContent = "30-minute quiet rest period active after your check-in. Monitoring continues normally.";
    } else if (mode === "Warning") {
      el("hero-headline").textContent = "Early changes noticed";
      el("hero-explanation").textContent = state.alertsTonight >= 2
        ? "Tonight's 2-alert limit was reached. Keeping quiet watch on bedside signals."
        : "Pulse and restlessness are slightly higher. Monitoring before texting an urgent alert.";
    } else if (mode === "Gated") {
      el("hero-headline").textContent = "Normal turn in bed ignored";
      el("hero-explanation").textContent = "Brief roll in sleep detected and filtered safely. No alert needed.";
    } else if (mode === "Learning") {
      el("hero-headline").textContent = "Learning tonight's calm sleep";
      el("hero-explanation").textContent = "Watch is learning Renzo's normal resting pulse for the first 75 minutes.";
    } else {
      el("hero-headline").textContent = state.caregiverCheckedIn ? "Checked on Renzo — sleeping steady" : "Renzo is sleeping steady";
      el("hero-explanation").textContent = "Calm heart rate and still rest. No signs of a nighttime drop.";
    }

    el("hero-body-state").textContent = mode === "Critical"
      ? "Alert Sent"
      : mode === "Cooldown"
        ? "Resting"
        : mode === "Warning"
          ? "Needs Check"
          : mode === "Gated"
            ? "Moving Briefly"
            : mode === "Learning"
              ? "Learning"
              : "Calm";
    el("hero-alerts-val").textContent = state.alertsTonight + " of 2 max";
    el("hero-watch-val").textContent = state.watchBattery + "% · " + (state.watchConnected ? "Connected" : "Cached");

    el("baseline-wrap").hidden = mode !== "Learning";
    el("baseline-count").textContent = state.baselineMinutes + " of 75 min";
    el("baseline-fill").style.width = Math.round((state.baselineMinutes / 75) * 100) + "%";
    el("hero-crisis-bar").hidden = mode !== "Critical";

    el("prick-sync-text").textContent = state.morningCheckText;
    var prickTag = el("prick-sync-badge");
    prickTag.textContent = state.morningCheckTone === "low" ? "Low (<70)" : state.morningCheckTone === "fine" ? "Normal" : "Synced";
    prickTag.className = "mini-tag " + (state.morningCheckTone === "low" ? "crit-tag" : state.morningCheckTone === "fine" ? "ok-tag" : "");

    el("smn-channel-status").textContent = state.alertsTonight >= 2
      ? "Daily safety limit reached (" + state.alertsTonight + " of 2 tonight)"
      : state.smnSentTime
        ? "Alert text sent to Maria at " + state.smnSentTime
        : "Active — texts only if symptoms persist";
    var smnTag = el("smn-state-tag");
    smnTag.textContent = state.smnSentTime ? "Sent" : "Active";
    smnTag.className = "mini-tag " + (state.smnSentTime ? "crit-tag" : "ok-tag");

    el("route-caption").textContent = state.watchConnected ? "Quiet rest · Live" : "Paused · Cached";

    if (mode === "Critical") {
      el("hr-interp").textContent = state.bodyType === "Blunted" ? "Dipping Low" : "Fast";
      el("hrv-interp").textContent = "Strained";
      el("tremor-interp").textContent = "Wrist Shaking";
      el("tremor-sub").textContent = "Noticeable hand shaking detected";
    } else if (mode === "Warning") {
      el("hr-interp").textContent = state.bodyType === "Blunted" ? "Slight Dip" : "Rising";
      el("hrv-interp").textContent = "Dipping";
      el("tremor-interp").textContent = "Light Restlessness";
      el("tremor-sub").textContent = "Mild wrist movement seen";
    } else if (mode === "Gated") {
      el("hr-interp").textContent = "Active Turn";
      el("hrv-interp").textContent = "Settling";
      el("tremor-interp").textContent = "Turn in Bed";
      el("tremor-sub").textContent = "Brief roll in sleep — ignored";
    } else {
      el("hr-interp").textContent = "Steady";
      el("hrv-interp").textContent = "Calm";
      el("tremor-interp").textContent = "Calm & Still";
      el("tremor-sub").textContent = "No shaking or restlessness";
    }
    el("hr-val-row").textContent = state.heartRate + " bpm";
    el("hrv-val-row").textContent = state.hrvMs + " ms";

    var peak = Math.max.apply(null, state.hourlyScores);
    var chartChip = el("chart-status-chip");
    chartChip.textContent = peak >= 3.7 ? "Alert Level" : peak >= 2.6 ? "Mild Watch" : "Calm Night";
    chartChip.className = "soft-chip " + (peak >= 3.7 ? "crit-chip" : peak >= 2.6 ? "warn-chip" : "ok-chip");

    el("sum-sleep").textContent = mode === "Critical" ? "Needs Check" : mode === "Warning" ? "Light Restless" : "Deep & Calm";
    el("sum-movement").textContent = mode === "Critical" ? "Shaking noted" : mode === "Gated" ? "Turned briefly" : mode === "Warning" ? "Shifting lightly" : "Resting still";
    el("sum-week").textContent = state.lowWeekNights > 0
      ? state.calmWeekNights + " calm · " + state.lowWeekNights + " low"
      : state.calmWeekNights + " calm nights";

    // Presenter menu state sync (hidden from caregiver UI)
    el("btn-sim-body").textContent = state.bodyType === "Blunted" ? "Pattern: Blunted" : "Pattern: Typical";
    el("btn-sim-link").textContent = state.watchConnected ? "Phone Link: On" : "Phone Link: Off";
    el("btn-sim-phase").textContent = "Model: Phase " + state.phase;
    el("btn-reset-night").textContent = "Reset Night (" + state.alertsTonight + "/2)";
    var presets = document.querySelectorAll(".preset-btn");
    for (var i = 0; i < presets.length; i++) {
      presets[i].classList.toggle("is-selected", presets[i].getAttribute("data-preset") === state.preset);
    }

    drawHeroBars(mode);
    drawPpg(mode);
    drawOvernightSvg();
    renderEvents();
  }

  function showSmsToast(msg) {
    el("sms-toast-body").textContent = msg;
    el("sms-toast").hidden = false;
  }

  function stepReplayFrame() {
    if (!state.replayClip || !tcnnBundleData) {
      stopReplayTimer();
      return;
    }
    var clip = state.replayClip;
    var nextIdx = state.replayFrameIdx + 1;
    if (nextIdx >= clip.frames.length) {
      stopReplayTimer();
      render();
      return;
    }

    var f = clip.frames[nextIdx];
    var slotStep = state.replayPrevSlot !== null ? Math.max(1, f.slot - state.replayPrevSlot) : 1;
    if (state.replayPrevSlot !== null && f.slot > state.replayPrevSlot + 1) {
      pushTcnnGapSlots(state.tcnnNight, f.slot - state.replayPrevSlot - 1);
    }
    if (state.cooldownMinutes > 0) {
      state.cooldownMinutes = Math.max(0, state.cooldownMinutes - slotStep * 5);
    }

    pushTcnnSlot(state.tcnnNight, f.c_z[0], f.c_z[1], f.c_z[2], f.c_z[3], f.c_z[4]);
    var res = stepTcnnNight(
      clip.loso_bundle,
      state.tcnnNight,
      clip.age,
      clip.t1d_duration,
      clip.archetype === 1,
      true
    );

    var req = requiredStreak();
    state.replayFrameIdx = nextIdx;
    state.replayPrevSlot = f.slot;
    if (f.hr_bpm >= 30) state.heartRate = Math.round(f.hr_bpm);
    state.hrvMs = Math.max(10, Math.round(f.rmssd));
    state.streakCount = res.isHot ? Math.min(req, state.streakCount + 1) : 0;
    state.symptomScore = res.isHot ? 5.1 : 1.4;

    if (res.isHot && state.streakCount >= req && state.cooldownMinutes === 0 && state.alertsTonight < 2) {
      state.alertsTonight += 1;
      state.pendingPrickCheck = true;
      state.smnSentTime = advanceNightStamp();
      state.hourlyScores = [1.1, 1.5, 2.8, 5.2, 3.0, 1.7, 1.3, 1.2];
      stopReplayTimer();
      state.events.unshift({
        time: state.smnSentTime,
        title: "SMS alert sent to Maria",
        detail: "Sustained overnight changes detected — check beside bed",
        tone: "crit"
      });
      showSmsToast("HypoAlert: Renzo needs a bedside check. Sustained overnight changes detected.");
    }
    render();
  }

  function startReplayNight() {
    if (!tcnnBundleData || !tcnnBundleData.replay_clips || tcnnBundleData.replay_clips.length === 0) {
      applyPreset("surge");
      return;
    }
    stopReplayTimer();
    var clip = tcnnBundleData.replay_clips[0]; // c2s02_7
    state.preset = "replay";
    state.phase = 3;
    state.bodyType = clip.archetype === 1 ? "Blunted" : "Adrenergic";
    state.baselineMinutes = 75;
    state.isMotionGated = false;
    state.streakCount = 0;
    state.cooldownMinutes = 0;
    state.replayClip = clip;
    state.replayFrameIdx = -1;
    state.replayPrevSlot = null;
    state.tcnnNight = createTcnnNightState();
    loadTcnnPrefixRows(state.tcnnNight, clip.baseline_prefix_z || []);

    state.events.unshift({
      time: advanceNightStamp(),
      title: "Live overnight review started",
      detail: "Checking continuous sleep patterns against baseline",
      tone: "info"
    });
    stepReplayFrame();
    state.replayTimer = setInterval(stepReplayFrame, 520);
  }

  function applyPreset(preset) {
    if (preset === "replay") {
      startReplayNight();
      return;
    }

    stopReplayTimer();
    state.replayClip = null;
    state.preset = preset;
    state.caregiverCheckedIn = false;
    var stamp = advanceNightStamp();

    if (preset === "calm") {
      state.isMotionGated = false;
      state.baselineMinutes = 75;
      state.cooldownMinutes = 0;
      state.symptomScore = 1.2;
      state.streakCount = 0;
      state.tremorLevel = "calm";
      state.hourlyScores = [1.0, 1.2, 1.4, 1.3, 1.1, 1.2, 1.1, 1.2];
      el("sms-toast").hidden = true;
    } else if (preset === "motion") {
      state.isMotionGated = true;
      state.baselineMinutes = 75;
      state.symptomScore = 1.8;
      state.streakCount = 0;
      state.tremorLevel = "calm";
      state.events.unshift({ time: stamp, title: "Normal turn in bed ignored", detail: "Brief movement — no false alert", tone: "info" });
    } else if (preset === "baseline") {
      state.isMotionGated = false;
      state.baselineMinutes = 55;
      state.symptomScore = 0.9;
      state.streakCount = 0;
      state.tremorLevel = "calm";
    } else if (preset === "warning") {
      state.isMotionGated = false;
      state.baselineMinutes = 75;
      state.cooldownMinutes = 0;
      state.symptomScore = 3.9;
      state.streakCount = 1;
      state.tremorLevel = "mild";
      state.hourlyScores = [1.0, 1.3, 2.2, 2.9, 3.3, 2.1, 1.5, 1.2];
    } else if (preset === "surge") {
      state.isMotionGated = false;
      state.baselineMinutes = 75;
      state.symptomScore = 5.4;
      state.streakCount = requiredStreak();
      state.tremorLevel = "surge";
      state.hourlyScores = [1.1, 1.5, 2.6, 5.2, 3.0, 1.7, 1.3, 1.2];

      if (state.alertsTonight < 2 && state.cooldownMinutes === 0) {
        state.alertsTonight += 1;
        state.pendingPrickCheck = true;
        state.smnSentTime = stamp;
        state.events.unshift({ time: stamp, title: "SMS alert sent to Maria", detail: "Sustained pulse & shaking signs — check beside bed", tone: "crit" });
        showSmsToast("HypoAlert: Renzo needs a bedside check. Sustained pulse & shaking signs detected.");
      } else {
        state.events.unshift({
          time: stamp,
          title: state.alertsTonight >= 2 ? "Night alert limit reached (2 of 2)" : "30-min rest active — alert paused",
          detail: "Extra repeated texts paused safely",
          tone: "info"
        });
      }
    }
    stepTelemetry();
    render();
  }

  function simulatePhonePrick(mgDl) {
    var stamp = advanceNightStamp();
    var isLow = mgDl < 70;
    if (state.pendingPrickCheck) {
      state.buzzLinkedPricks += 1;
      state.pendingPrickCheck = false;
    }
    if (isLow) state.confirmedLows += 1;
    else state.fineNights += 1;

    if (state.buzzLinkedPricks >= 3 && !state.hasPersonalLine) {
      state.hasPersonalLine = true;
      state.phase = Math.max(state.phase, 2);
    }
    if (state.confirmedLows >= 1 && state.fineNights >= 10) {
      state.isCnnUnlocked = true;
      state.phase = 3;
    }

    if (isLow) state.lowWeekNights += 1;
    else state.calmWeekNights += 1;

    state.morningCheckTone = isLow ? "low" : "fine";
    state.morningCheckText = mgDl + " mg/dL · " + (isLow ? "Low confirmed" : "Normal range");
    state.events.unshift({
      time: stamp,
      title: "Morning check synced: " + mgDl + " mg/dL",
      detail: isLow ? "Confirmed low (<70 mg/dL) from Renzo's phone" : "Confirmed normal morning reading",
      tone: isLow ? "crit" : "ok"
    });
    render();
  }

  function caregiverAck() {
    stopReplayTimer();
    var stamp = advanceNightStamp();
    var wasAlert = evaluateMode() === "Critical";
    state.preset = "calm";
    state.caregiverCheckedIn = true;
    state.symptomScore = 1.4;
    state.streakCount = 0;
    state.tremorLevel = "calm";
    if (wasAlert) {
      state.cooldownMinutes = 30;
    }
    el("sms-toast").hidden = true;
    state.events.unshift({
      time: stamp,
      title: wasAlert ? "Checked in · 30m rest started" : "Caregiver checked in",
      detail: "Maria Santos acknowledged bedside status",
      tone: "ok"
    });
    render();
  }

  function resetNightState() {
    stopReplayTimer();
    state.replayClip = null;
    state.alertsTonight = 0;
    state.cooldownMinutes = 0;
    state.streakCount = 0;
    state.smnSentTime = "";
    state.pendingPrickCheck = false;
    applyPreset("calm");
  }

  function wireEvents() {
    var btnDemo = el("btn-demo-menu");
    var popover = el("demo-popover");
    btnDemo.addEventListener("click", function (e) {
      e.stopPropagation();
      popover.hidden = !popover.hidden;
      btnDemo.setAttribute("aria-expanded", String(!popover.hidden));
    });

    document.addEventListener("click", function (e) {
      if (!popover.hidden && !popover.contains(e.target) && e.target !== btnDemo) {
        popover.hidden = true;
        btnDemo.setAttribute("aria-expanded", "false");
      }
    });

    var presets = document.querySelectorAll(".preset-btn");
    for (var i = 0; i < presets.length; i++) {
      presets[i].addEventListener("click", function () {
        applyPreset(this.getAttribute("data-preset"));
        popover.hidden = true;
        btnDemo.setAttribute("aria-expanded", "false");
      });
    }

    el("btn-sim-body").addEventListener("click", function () {
      state.bodyType = state.bodyType === "Adrenergic" ? "Blunted" : "Adrenergic";
      if (evaluateMode() === "Critical") state.streakCount = requiredStreak();
      render();
    });

    el("btn-sim-link").addEventListener("click", function () {
      state.watchConnected = !state.watchConnected;
      render();
    });

    el("btn-sim-phase").addEventListener("click", function () {
      state.phase = state.phase === 1 ? 2 : (state.phase === 2 ? 3 : 1);
      render();
    });

    el("btn-reset-night").addEventListener("click", resetNightState);

    el("btn-sim-low").addEventListener("click", function () {
      simulatePhonePrick(54);
    });
    el("btn-sim-fine").addEventListener("click", function () {
      simulatePhonePrick(108);
    });

    el("btn-im-with-renzo").addEventListener("click", caregiverAck);
    el("btn-check-in").addEventListener("click", caregiverAck);

    var triggerCall = function () {
      state.events.unshift({
        time: advanceNightStamp(),
        title: "Calling Renzo's bedside",
        detail: "Placed call to Mate 70 Pro (+63 917 555 0142)",
        tone: "info"
      });
      render();
    };
    el("btn-nav-call").addEventListener("click", triggerCall);
    el("btn-call-bedside").addEventListener("click", triggerCall);
    el("btn-hero-call").addEventListener("click", triggerCall);

    el("btn-preview-sms").addEventListener("click", function () {
      state.smnSentTime = advanceNightStamp();
      showSmsToast("Test alert verified for Maria Santos (+63 917 123 4567).");
      render();
    });
    el("sms-toast-close").addEventListener("click", function () {
      el("sms-toast").hidden = true;
    });

    window.addEventListener("resize", function () {
      var mode = evaluateMode();
      drawHeroBars(mode);
      drawPpg(mode);
    });
  }

  initPpg();
  wireEvents();
  render();
  setInterval(function () {
    stepTelemetry();
    var mode = evaluateMode();
    el("hr-val-row").textContent = state.heartRate + " bpm";
    el("hrv-val-row").textContent = state.hrvMs + " ms";
    drawPpg(mode);
  }, 180);
})();
