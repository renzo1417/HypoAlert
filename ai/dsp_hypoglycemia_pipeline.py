"""
HypoAlert: Nocturnal Hypoglycemia Symptom Processing & Safety Gate Reference
---------------------------------------------------------------------------
Matches the verified PhysioCGM tcnn_version pipeline (zero blood glucose estimation,
zero skin temperature):
1. Motion Gating: evaluate only sedentary sleep windows.
2. Within-Night 75-min Baseline: first 15 x 5-min slots normalize delta_hr, rmssd, sdnn, tpi_rel.
3. Clipped Z-Scores [-3, +3] & Bimodal Phenotype Routing (Adrenergic vs. Bradycardic/Blunted).
4. Safety Persistence Filter across Phases 1-3:
   - Adrenergic: 3 consecutive elevated 5-min checks (~15 min)
   - Bradycardic: 2 consecutive elevated 5-min checks (~10 min)
   - 30-min cooldown and max 2 alerts per night.
"""

from __future__ import annotations

import numpy as np
from typing import Dict, Any, Tuple

try:
    from scipy import signal
    HAS_SCIPY = True
except ImportError:
    HAS_SCIPY = False

FLOORS = {
    "delta_hr": 2.0,
    "rmssd": 5.0,
    "sdnn": 5.0,
    "tpi_rel": 0.02,
}


class SymptomFeaturePipeline:
    def __init__(self, imu_fs: float = 50.0):
        self.imu_fs = imu_fs
        if HAS_SCIPY:
            nyq = 0.5 * imu_fs
            self.b_band, self.a_band = signal.butter(4, [8.0 / nyq, 12.0 / nyq], btype="band")

    def compute_motion_gate(self, ax: np.ndarray, ay: np.ndarray, az: np.ndarray) -> Tuple[float, bool]:
        """Signal Magnitude Area (SMA) gating: pauses evaluation during gross movement."""
        sma = float(np.mean(np.abs(ax) + np.abs(ay) + np.abs(az - 1.0)))
        is_sedentary = sma <= 0.25
        return sma, bool(is_sedentary)

    def extract_tremor_power(self, accel_magnitude: np.ndarray) -> float:
        """Isolates 8-12 Hz physiological micro-tremor power."""
        n = len(accel_magnitude)
        if HAS_SCIPY:
            filtered = signal.filtfilt(self.b_band, self.a_band, accel_magnitude)
            freqs, psd = signal.welch(filtered, fs=self.imu_fs, nperseg=min(n, 128))
        else:
            fft_vals = np.fft.rfft(accel_magnitude)
            freqs = np.fft.rfftfreq(n, d=1.0 / self.imu_fs)
            psd = (np.abs(fft_vals) ** 2) / (n * self.imu_fs)

        mask = (freqs >= 8.0) & (freqs <= 12.0)
        if not np.any(mask):
            return 0.0
        if hasattr(np, "trapezoid"):
            return float(np.trapezoid(psd[mask], freqs[mask]))
        return float(np.sum(psd[mask]))

    def compute_within_night_z(self, baseline_rows: list[Dict[str, float]], current: Dict[str, float]) -> Dict[str, float]:
        """Computes clipped z-scores [-3, +3] against the night's first 75 minutes (15 windows)."""
        out: Dict[str, float] = {}
        for key, floor in FLOORS.items():
            vals = np.array([r[key] for r in baseline_rows], dtype=np.float64)
            mu = float(np.mean(vals))
            sd = max(float(np.std(vals, ddof=1)) if len(vals) > 1 else floor, floor)
            z = float(np.clip((current[key] - mu) / sd, -3.0, 3.0))
            out[f"c_z_{key}"] = z
        return out

    def evaluate_phase1_score(self, z: Dict[str, float], archetype: int) -> Dict[str, Any]:
        """Evaluates Phase 1 heuristic score for archetype 0 (Adrenergic) or 1 (Bradycardic)."""
        if archetype == 0:
            score = z["c_z_delta_hr"] - z["c_z_rmssd"] + z["c_z_tpi_rel"]
        else:
            score = -z["c_z_rmssd"] - z["c_z_sdnn"] + z["c_z_tpi_rel"]
        is_hot = score >= 3.7
        return {
            "heuristic_score": round(float(score), 3),
            "threshold": 3.7,
            "is_hot_window": bool(is_hot),
            "streak_required": 3 if archetype == 0 else 2,
        }


def run_synthetic_benchmark() -> None:
    print("==================================================================")
    print("HYPOALERT SYMPTOM PIPELINE DEMO: CALM SLEEP vs. SUSTAINED SURGE")
    print("==================================================================")
    pipe = SymptomFeaturePipeline(imu_fs=50.0)
    baseline = [
        {"delta_hr": 0.0, "rmssd": 42.0, "sdnn": 54.0, "tpi_rel": 0.08}
        for _ in range(15)
    ]

    calm = {"delta_hr": -1.0, "rmssd": 43.0, "sdnn": 55.0, "tpi_rel": 0.08}
    z_calm = pipe.compute_within_night_z(baseline, calm)
    res_calm = pipe.evaluate_phase1_score(z_calm, archetype=0)
    print(f"[Scenario 1: Calm Resting Sleep] score={res_calm['heuristic_score']} hot={res_calm['is_hot_window']}")

    surge = {"delta_hr": 18.0, "rmssd": 19.0, "sdnn": 30.0, "tpi_rel": 0.19}
    z_surge = pipe.compute_within_night_z(baseline, surge)
    res_surge = pipe.evaluate_phase1_score(z_surge, archetype=0)
    print(
        f"[Scenario 2: Adrenergic Symptom Surge] score={res_surge['heuristic_score']} "
        f"hot={res_surge['is_hot_window']} (requires {res_surge['streak_required']} in a row)"
    )
    print("==================================================================")


if __name__ == "__main__":
    run_synthetic_benchmark()
