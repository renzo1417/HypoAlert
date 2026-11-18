#!/usr/bin/env python3
"""Train, export, and verify DualHead_multitask_smoothap + Cal (498 inference params)
for HarmonyOS ArkTS and the Huawei Health Browser Demo.

Exports:
1. ai/dualhead_tcnn_bundle.json         (full cohort 3-seed ensemble + calibration + LOSO replay clips)
2. entry/src/main/ets/models/TcnnWeights.ets   (ArkTS typed constants + reference parity vectors)
3. health-companion-demo/tcnn-bundle.js        (browser global bundle + LOSO replay clips)
"""

from __future__ import annotations

import json
import math
import subprocess
import sys
from pathlib import Path
from typing import Any

import numpy as np
import torch
import torch.nn as nn
import torch.nn.functional as F

PHYSIO_ROOT = Path("/Users/gianne/Downloads/PhysioCGMv2")
sys.path.insert(0, str(PHYSIO_ROOT))

from tcnn_version.data_prep import auc_pr, auc_roc, load_phase3_sequences  # noqa: E402
from tcnn_version.exp_auprc_champion import (  # noqa: E402
    BATCH_SIZE,
    EPOCHS,
    LR,
    LOOKBACK,
    SEEDS,
    WEIGHT_DECAY,
    DualHeadMultiTaskTCN,
    apply_causal_ema,
    apply_causal_night_anchor,
    compute_ordinal_margin_loss,
    fit_platt_params,
    smooth_ap_hybrid_loss,
)

HUAWEI_ROOT = Path("/Users/gianne/Development/Huawei")
OUT_JSON = HUAWEI_ROOT / "ai" / "dualhead_tcnn_bundle.json"
OUT_ETS = HUAWEI_ROOT / "entry" / "src" / "main" / "ets" / "models" / "TcnnWeights.ets"
OUT_JS = HUAWEI_ROOT / "health-companion-demo" / "tcnn-bundle.js"


def train_dualhead_seed(
    x_seq_tr: np.ndarray,
    x_st_tr: np.ndarray,
    y_sev_tr: np.ndarray,
    y_hypo_tr: np.ndarray,
    seed: int,
) -> DualHeadMultiTaskTCN:
    np.random.seed(seed)
    torch.manual_seed(seed)
    model = DualHeadMultiTaskTCN()
    opt = torch.optim.AdamW(model.parameters(), lr=LR, weight_decay=WEIGHT_DECAY)

    pos_sev = float(y_sev_tr.sum())
    neg_sev = float(len(y_sev_tr) - pos_sev)
    pw_sev_t = torch.tensor([float(np.clip(neg_sev / max(pos_sev, 1.0), 1.0, 10.0))], dtype=torch.float32)

    pos_hyp = float(y_hypo_tr.sum())
    neg_hyp = float(len(y_hypo_tr) - pos_hyp)
    pw_hyp_t = torch.tensor([float(np.clip(neg_hyp / max(pos_hyp, 1.0), 1.0, 15.0))], dtype=torch.float32)

    xt_seq = torch.from_numpy(x_seq_tr)
    xt_stat = torch.from_numpy(x_st_tr)
    yt_sev = torch.from_numpy(y_sev_tr)
    yt_hyp = torch.from_numpy(y_hypo_tr)
    n_tr = len(y_sev_tr)
    gen = torch.Generator().manual_seed(seed)

    model.train()
    for _ in range(EPOCHS):
        perm = torch.randperm(n_tr, generator=gen)
        for start in range(0, n_tr, BATCH_SIZE):
            idx = perm[start : start + BATCH_SIZE]
            opt.zero_grad()
            l_sev, l_hyp = model(xt_seq[idx], xt_stat[idx])
            loss = smooth_ap_hybrid_loss(l_sev, yt_sev[idx], pw_sev_t)
            loss = loss + F.binary_cross_entropy_with_logits(l_hyp, yt_hyp[idx], pos_weight=pw_hyp_t)
            loss = loss + 0.25 * compute_ordinal_margin_loss(l_sev, yt_sev[idx], yt_hyp[idx])
            loss.backward()
            opt.step()
    model.eval()
    return model


def extract_model_weights(model: DualHeadMultiTaskTCN) -> dict[str, Any]:
    """Extract strictly inference parameters (498 params, stripping training-only hypo heads)."""
    sd = model.state_dict()
    weights = {
        "conv1_w": np.round(sd["block1.conv.weight"].cpu().numpy(), 6).tolist(),  # [8, 5, 3]
        "conv1_b": np.round(sd["block1.conv.bias"].cpu().numpy(), 6).tolist(),    # [8]
        "conv2_w": np.round(sd["block2.conv.weight"].cpu().numpy(), 6).tolist(),  # [8, 8, 3]
        "conv2_b": np.round(sd["block2.conv.bias"].cpu().numpy(), 6).tolist(),    # [8]
        "fc1_w": np.round(sd["fc1.weight"].cpu().numpy(), 6).tolist(),            # [8, 18]
        "fc1_b": np.round(sd["fc1.bias"].cpu().numpy(), 6).tolist(),              # [8]
        "head_adr_w": np.round(sd["head_adr_sev.weight"].cpu().numpy()[0], 6).tolist(),    # [8]
        "head_adr_b": round(float(sd["head_adr_sev.bias"].cpu().numpy()[0]), 6),
        "head_brady_w": np.round(sd["head_brady_sev.weight"].cpu().numpy()[0], 6).tolist(), # [8]
        "head_brady_b": round(float(sd["head_brady_sev.bias"].cpu().numpy()[0]), 6),
    }
    n_params = (
        8 * 5 * 3 + 8
        + 8 * 8 * 3 + 8
        + 8 * 18 + 8
        + 8 + 1
        + 8 + 1
    )
    assert n_params == 498, f"Expected 498 infer params, got {n_params}"
    return weights


def forward_ensemble_raw(
    models: list[DualHeadMultiTaskTCN],
    x_seq: np.ndarray,
    x_st: np.ndarray,
) -> np.ndarray:
    outs = []
    xs = torch.from_numpy(x_seq)
    xst = torch.from_numpy(x_st)
    with torch.no_grad():
        for m in models:
            z, _ = m(xs, xst)
            outs.append(z.numpy().astype(np.float64))
    return np.mean(outs, axis=0)


def fit_ensemble_bundle(
    P_df,
    x_seq: np.ndarray,
    x_st: np.ndarray,
    y_sev: np.ndarray,
    y_hypo: np.ndarray,
    mask_tr: np.ndarray,
) -> tuple[list[DualHeadMultiTaskTCN], dict[str, Any]]:
    models = [
        train_dualhead_seed(x_seq[mask_tr], x_st[mask_tr], y_sev[mask_tr], y_hypo[mask_tr], s)
        for s in SEEDS
    ]
    z_tr = forward_ensemble_raw(models, x_seq[mask_tr], x_st[mask_tr])
    arch_tr = P_df.loc[mask_tr, "archetype"].values
    df_tr = P_df.loc[mask_tr].reset_index(drop=True)

    platt = {}
    z_platt_tr = np.zeros_like(z_tr)
    for arch in [0, 1]:
        am = arch_tr == arch
        a, b = fit_platt_params(z_tr[am], y_sev[mask_tr][am])
        platt[str(arch)] = {"a": round(a, 6), "b": round(b, 6)}
        z_platt_tr[am] = a * z_tr[am] + b

    z_anc = apply_causal_night_anchor(df_tr, z_platt_tr, lam=0.25)
    ema_tr = apply_causal_ema(df_tr, z_anc, alpha=0.50)
    thr_97 = float(np.quantile(ema_tr, 0.97))
    thr_97_adr = float(np.quantile(ema_tr[arch_tr == 0], 0.97))
    thr_97_brady = float(np.quantile(ema_tr[arch_tr == 1], 0.97))

    bundle = {
        "arch": "DualHead_multitask_smoothap",
        "infer_params": 498,
        "lookback": LOOKBACK,
        "seeds": list(SEEDS),
        "anchor_lambda": 0.25,
        "ema_alpha": 0.50,
        "thr_97pct": round(thr_97, 6),
        "thr_97_adr": round(thr_97_adr, 6),
        "thr_97_brady": round(thr_97_brady, 6),
        "ema_mean": round(float(np.mean(ema_tr)), 6),
        "ema_std": round(max(float(np.std(ema_tr)), 1e-6), 6),
        "platt": platt,
        "models": [extract_model_weights(m) for m in models],
    }
    return models, bundle


def run_bundle_forward_py(bundle: dict[str, Any], x_seq: np.ndarray, x_st: np.ndarray) -> np.ndarray:
    """Pure numpy reference implementing exact inference from exported JSON weights."""
    n = len(x_seq)
    seed_logits = []
    for mw in bundle["models"]:
        c1w = np.array(mw["conv1_w"], dtype=np.float64)
        c1b = np.array(mw["conv1_b"], dtype=np.float64)
        c2w = np.array(mw["conv2_w"], dtype=np.float64)
        c2b = np.array(mw["conv2_b"], dtype=np.float64)
        fc1w = np.array(mw["fc1_w"], dtype=np.float64)
        fc1b = np.array(mw["fc1_b"], dtype=np.float64)
        haw = np.array(mw["head_adr_w"], dtype=np.float64)
        hab = float(mw["head_adr_b"])
        hbw = np.array(mw["head_brady_w"], dtype=np.float64)
        hbb = float(mw["head_brady_b"])

        # Conv1: [N, 5, 12] -> left pad 2 -> [N, 5, 14] -> [N, 8, 12]
        x_pad = np.pad(x_seq.astype(np.float64), ((0, 0), (0, 0), (2, 0)))
        h1 = np.zeros((n, 8, LOOKBACK), dtype=np.float64)
        for t in range(LOOKBACK):
            sl = x_pad[:, :, t : t + 3]  # [N, 5, 3]
            h1[:, :, t] = np.maximum(0.0, np.einsum("nck,ock->no", sl, c1w) + c1b)

        # Conv2: [N, 8, 12], dilation=2 -> left pad 4 -> [N, 8, 16] -> [N, 8, 12]
        h1_pad = np.pad(h1, ((0, 0), (0, 0), (4, 0)))
        h2 = np.zeros((n, 8, LOOKBACK), dtype=np.float64)
        for t in range(LOOKBACK):
            sl = h1_pad[:, :, t : t + 5 : 2]  # [N, 8, 3]
            h2[:, :, t] = np.maximum(0.0, np.einsum("nck,ock->no", sl, c2w) + c2b)

        feat = np.concatenate([h2.mean(axis=-1), h2[:, :, -1], x_st[:, :2].astype(np.float64)], axis=-1)
        z1 = np.maximum(0.0, feat @ fc1w.T + fc1b)

        is_brady = x_st[:, 2] > 0.5
        out = np.where(is_brady, z1 @ hbw + hbb, z1 @ haw + hab)
        seed_logits.append(out)
    return np.mean(seed_logits, axis=0)


def build_replay_clip(
    night_uid: str,
    title: str,
    subtitle: str,
    P_df,
    x_seq: np.ndarray,
    x_st: np.ndarray,
    y_sev: np.ndarray,
    y_hypo: np.ndarray,
) -> tuple[dict[str, Any], dict[str, Any]]:
    """Train strict LOSO fold (holding out this night's subject) and export real night frames + reference outputs."""
    mask_n = (P_df["night_uid"].values == night_uid)
    subj = str(P_df.loc[mask_n, "subject_id"].iloc[0])
    mask_tr = (P_df["subject_id"].values != subj)

    models, fold_bundle = fit_ensemble_bundle(P_df, x_seq, x_st, y_sev, y_hypo, mask_tr)

    # Verify numpy JSON weights match PyTorch model exactly
    pt_logits = forward_ensemble_raw(models, x_seq[mask_n], x_st[mask_n])
    np_logits = run_bundle_forward_py(fold_bundle, x_seq[mask_n], x_st[mask_n])
    max_diff = float(np.max(np.abs(pt_logits - np_logits)))
    assert max_diff < 1e-4, f"Weight export mismatch for {night_uid}: {max_diff}"

    sub_df = P_df.loc[mask_n].copy().reset_index(drop=True)
    x_seq_night = x_seq[mask_n]
    baseline_prefix_z = [
        [round(float(x_seq_night[0, c, t]), 5) for c in range(5)]
        for t in range(LOOKBACK - 1)
    ]
    arch = int(sub_df["archetype"].iloc[0])
    a = fold_bundle["platt"][str(arch)]["a"]
    b = fold_bundle["platt"][str(arch)]["b"]
    z_platt = a * pt_logits + b
    z_anc = apply_causal_night_anchor(sub_df, z_platt, lam=0.25)
    ema = apply_causal_ema(sub_df, z_anc, alpha=0.50)

    frames = []
    for i, row in sub_df.iterrows():
        frames.append({
            "t": str(row["timestamp"])[11:16],
            "hr_bpm": round(float(62.0 + row["delta_hr"]), 1),
            "delta_hr": round(float(row["delta_hr"]), 2),
            "rmssd": round(float(row["rmssd"]), 1),
            "sdnn": round(float(row["sdnn"]), 1),
            "tpi_rel": round(float(row["tpi_rel"]), 4),
            "c_z": [
                round(float(row["c_z_dhr"]), 5),
                round(float(row["c_z_rmssd"]), 5),
                round(float(row["c_z_sdnn"]), 5),
                round(float(row["c_z_tpi"]), 5),
                1.0,
            ],
            "slot": int(row["slot"]),
            "ref_raw_logit": round(float(pt_logits[i]), 6),
            "ref_ema": round(float(ema[i]), 6),
            "ref_is_severe": int(row["is_severe_hypo"]),
            "ref_glucose_mgdl": round(float(row["glucose"]), 1),
        })

    clip = {
        "night_uid": night_uid,
        "subject_id": subj,
        "title": title,
        "subtitle": subtitle,
        "archetype": arch,
        "age": round(float(sub_df["age"].iloc[0]), 1),
        "t1d_duration": round(float(sub_df["t1d_duration"].iloc[0]), 1),
        "loso_bundle": fold_bundle,
        "baseline_prefix_z": baseline_prefix_z,
        "frames": frames,
        "parity_max_diff": round(max_diff, 8),
    }
    return clip, fold_bundle


def write_arkts_weights(bundle: dict[str, Any], replay_clips: list[dict[str, Any]]) -> None:
    """Generate clean, strictly-typed ArkTS weights & parity test vectors."""
    # Pick a compact 12-step window slice from c2s02_7 and c2s03_3 for ArkTS parity unit tests
    c2s02 = next(c for c in replay_clips if c["night_uid"] == "c2s02_7")
    c2s03 = next(c for c in replay_clips if c["night_uid"] == "c2s03_3")

    def clip_ref_payload(clip: dict[str, Any], max_frames: int = 40) -> dict[str, Any]:
        return {
            "night_uid": clip["night_uid"],
            "archetype": clip["archetype"],
            "age": clip["age"],
            "t1d_duration": clip["t1d_duration"],
            "thr_97pct": clip["loso_bundle"]["thr_97pct"],
            "platt_a": clip["loso_bundle"]["platt"][str(clip["archetype"])]["a"],
            "platt_b": clip["loso_bundle"]["platt"][str(clip["archetype"])]["b"],
            "baseline_prefix_z": clip["baseline_prefix_z"],
            "frames_z": [f["c_z"] for f in clip["frames"][:max_frames]],
            "frames_raw": [[f["hr_bpm"], f["delta_hr"], f["rmssd"], f["sdnn"], f["tpi_rel"]] for f in clip["frames"][:max_frames]],
            "frames_slot": [f["slot"] for f in clip["frames"][:max_frames]],
            "ref_ema": [f["ref_ema"] for f in clip["frames"][:max_frames]],
            "ref_raw_logit": [f["ref_raw_logit"] for f in clip["frames"][:max_frames]],
        }

    # Include the cohort bundle + LOSO models for c2s02_7 and c2s03_3 so ArkTS can test exact LOSO replay too
    lines = [
        "/*",
        " * Copyright (c) 2026 HypoAlert.",
        " * Auto-generated by ai/export_tcnn_weights.py — DO NOT EDIT BY HAND.",
        " * Trained DualHead_multitask_smoothap (498 inference params, L=12 / 60-min causal Conv1d)",
        " * plus strict LOSO replay test vectors from physiocgm_phenotyped_v2.csv.",
        " */",
        "",
        "export interface TcnnSeedWeights {",
        "  conv1W: number[][][];",
        "  conv1B: number[];",
        "  conv2W: number[][][];",
        "  conv2B: number[];",
        "  fc1W: number[][];",
        "  fc1B: number[];",
        "  headAdrW: number[];",
        "  headAdrB: number;",
        "  headBradyW: number[];",
        "  headBradyB: number;",
        "}",
        "",
        "export interface PlattPair {",
        "  a: number;",
        "  b: number;",
        "}",
        "",
        "export interface TcnnModelBundle {",
        "  thr97Pct: number;",
        "  thr97Adr: number;",
        "  thr97Brady: number;",
        "  emaMean: number;",
        "  emaStd: number;",
        "  plattAdr: PlattPair;",
        "  plattBrady: PlattPair;",
        "  seeds: TcnnSeedWeights[];",
        "}",
        "",
        "export interface ReplayTestNight {",
        "  nightUid: string;",
        "  archetype: number;",
        "  age: number;",
        "  t1dDuration: number;",
        "  thr97Pct: number;",
        "  plattA: number;",
        "  plattB: number;",
        "  baselinePrefixZ: number[][];",
        "  framesZ: number[][];",
        "  framesRaw: number[][];",
        "  framesSlot: number[];",
        "  refEma: number[];",
        "  refRawLogit: number[];",
        "}",
        "",
    ]

    def format_seed(mw: dict[str, Any]) -> str:
        return (
            "{\n"
            f"  conv1W: {json.dumps(mw['conv1_w'])},\n"
            f"  conv1B: {json.dumps(mw['conv1_b'])},\n"
            f"  conv2W: {json.dumps(mw['conv2_w'])},\n"
            f"  conv2B: {json.dumps(mw['conv2_b'])},\n"
            f"  fc1W: {json.dumps(mw['fc1_w'])},\n"
            f"  fc1B: {json.dumps(mw['fc1_b'])},\n"
            f"  headAdrW: {json.dumps(mw['head_adr_w'])},\n"
            f"  headAdrB: {mw['head_adr_b']},\n"
            f"  headBradyW: {json.dumps(mw['head_brady_w'])},\n"
            f"  headBradyB: {mw['head_brady_b']}\n"
            "}"
        )

    def format_bundle(name: str, b: dict[str, Any]) -> str:
        seeds_str = ",\n".join(format_seed(s) for s in b["models"])
        return (
            f"export const {name}: TcnnModelBundle = {{\n"
            f"  thr97Pct: {b['thr_97pct']},\n"
            f"  thr97Adr: {b['thr_97_adr']},\n"
            f"  thr97Brady: {b['thr_97_brady']},\n"
            f"  emaMean: {b['ema_mean']},\n"
            f"  emaStd: {b['ema_std']},\n"
            f"  plattAdr: {{ a: {b['platt']['0']['a']}, b: {b['platt']['0']['b']} }},\n"
            f"  plattBrady: {{ a: {b['platt']['1']['a']}, b: {b['platt']['1']['b']} }},\n"
            f"  seeds: [\n{seeds_str}\n  ]\n"
            "};\n"
        )

    lines.append(format_bundle("COHORT_TCNN_BUNDLE", bundle))
    lines.append(format_bundle("LOSO_C2S02_BUNDLE", c2s02["loso_bundle"]))
    lines.append(format_bundle("LOSO_C2S03_BUNDLE", c2s03["loso_bundle"]))

    for cname, clip in [("REPLAY_C2S02_NIGHT", c2s02), ("REPLAY_C2S03_NIGHT", c2s03)]:
        p = clip_ref_payload(clip, max_frames=53)
        lines.append(
            f"export const {cname}: ReplayTestNight = {{\n"
            f"  nightUid: '{p['night_uid']}',\n"
            f"  archetype: {p['archetype']},\n"
            f"  age: {p['age']},\n"
            f"  t1dDuration: {p['t1d_duration']},\n"
            f"  thr97Pct: {p['thr_97pct']},\n"
            f"  plattA: {p['platt_a']},\n"
            f"  plattB: {p['platt_b']},\n"
            f"  baselinePrefixZ: {json.dumps(p['baseline_prefix_z'])},\n"
            f"  framesZ: {json.dumps(p['frames_z'])},\n"
            f"  framesRaw: {json.dumps(p['frames_raw'])},\n"
            f"  framesSlot: {json.dumps(p['frames_slot'])},\n"
            f"  refEma: {json.dumps(p['ref_ema'])},\n"
            f"  refRawLogit: {json.dumps(p['ref_raw_logit'])}\n"
            "};\n"
        )

    OUT_ETS.write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    print("Loading physiocgm_phenotyped_v2.csv sequences...")
    P_canon, X_seq_full, X_st_canon, y_sev_canon = load_phase3_sequences(max_lookback=18)
    y_hypo_canon = P_canon["is_hypo"].values.astype(np.float32)

    sort_idx = P_canon.sort_values(["night_uid", "timestamp"]).index.to_numpy()
    P_sorted = P_canon.loc[sort_idx].reset_index(drop=True)
    X_seq_12 = X_seq_full[sort_idx, :, -LOOKBACK:]
    X_st_sorted = X_st_canon[sort_idx]
    y_sev_sorted = y_sev_canon[sort_idx]
    y_hypo_sorted = y_hypo_canon[sort_idx]

    print("Training 3-seed DualHead_multitask_smoothap cohort bundle (498 infer params)...")
    all_tr = np.ones(len(P_sorted), dtype=bool)
    cohort_models, cohort_bundle = fit_ensemble_bundle(
        P_sorted, X_seq_12, X_st_sorted, y_sev_sorted, y_hypo_sorted, all_tr
    )
    pt_cohort = forward_ensemble_raw(cohort_models, X_seq_12, X_st_sorted)
    np_cohort = run_bundle_forward_py(cohort_bundle, X_seq_12, X_st_sorted)
    cohort_diff = float(np.max(np.abs(pt_cohort - np_cohort)))
    print(
        f"Cohort bundle trained | thr_97pct={cohort_bundle['thr_97pct']:.4f} | "
        f"PyTorch vs exported JSON max diff={cohort_diff:.2e}"
    )
    assert cohort_diff < 1e-4

    print("Building strict LOSO held-out replay nights (c2s02_7, c2s03_3, c1s05_7)...")
    clips = []
    for nuid, title, sub in [
        ("c2s02_7", "Real Adrenergic Episode (c2s02)", "Held-out subject • 27 severe <54 mg/dL windows"),
        ("c2s03_3", "Real Blunted Episode (c2s03)", "Held-out bradycardic subject • 5 severe windows"),
        ("c1s05_7", "Real Calm Sleep Night (c1s05)", "Held-out zero-hypo subject • tests false-alarm control"),
    ]:
        clip, _ = build_replay_clip(
            nuid, title, sub, P_sorted, X_seq_12, X_st_sorted, y_sev_sorted, y_hypo_sorted
        )
        clips.append(clip)
        print(
            f"  Exported {nuid}: {len(clip['frames'])} slots, "
            f"max_ema={max(f['ref_ema'] for f in clip['frames']):.3f}, "
            f"thr97={clip['loso_bundle']['thr_97pct']:.3f}, "
            f"parity_diff={clip['parity_max_diff']:.2e}"
        )

    full_payload = {
        "cohort_bundle": cohort_bundle,
        "replay_clips": clips,
    }
    OUT_JSON.write_text(json.dumps(full_payload, indent=2), encoding="utf-8")
    OUT_JS.write_text(
        "// Auto-generated by ai/export_tcnn_weights.py\n"
        f"window.HYPOALERT_TCNN_BUNDLE = {json.dumps(full_payload)};\n",
        encoding="utf-8",
    )
    write_arkts_weights(cohort_bundle, clips)

    print(f"Wrote {OUT_JSON}")
    print(f"Wrote {OUT_JS}")
    print(f"Wrote {OUT_ETS}")


if __name__ == "__main__":
    main()
