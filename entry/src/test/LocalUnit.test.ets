import { describe, it, expect } from '@ohos/hypium';
import { BodyPhenotype, ReplayStepOutput, VitalsData, VitalsEngine } from '../main/ets/models/VitalsModel';
import { HistoryRepository } from '../main/ets/models/HistoryModel';
import { TcnnNightState } from '../main/ets/models/TcnnEngine';
import {
  LOSO_C2S02_BUNDLE,
  LOSO_C2S03_BUNDLE,
  REPLAY_C2S02_NIGHT,
  REPLAY_C2S03_NIGHT
} from '../main/ets/models/TcnnWeights';

export default function localUnitTest() {
  describe('HypoAlertSymptomEngineTest', () => {
    it('doesNotAlertDuring75MinBaseline', 0, () => {
      const base: VitalsData = VitalsEngine.generateBaselineVitals(
        undefined,
        BodyPhenotype.ADRENERGIC,
        1,
        VitalsEngine.PHASE1_THRESHOLD,
        40
      );
      expect(base.baselineMinutes).assertEqual(40);
      expect(base.statusTier).assertEqual('BASELINE');
      expect(VitalsEngine.shouldTriggerAlert(base)).assertFalse();
    });

    it('requires3ConsecutiveChecksForAdrenergicAndIgnoresSingleSpike', 0, () => {
      let v: VitalsData = VitalsEngine.createInitialVitals(BodyPhenotype.ADRENERGIC, 1, 3.7);
      v = VitalsEngine.generateElevatedStep(v, BodyPhenotype.ADRENERGIC, 1, 3.7, false);
      expect(v.streakCount).assertEqual(1);
      expect(VitalsEngine.shouldTriggerAlert(v)).assertFalse();

      v = VitalsEngine.generateElevatedStep(v, BodyPhenotype.ADRENERGIC, 1, 3.7, false);
      expect(v.streakCount).assertEqual(2);
      expect(VitalsEngine.shouldTriggerAlert(v)).assertFalse();

      v = VitalsEngine.generateElevatedStep(v, BodyPhenotype.ADRENERGIC, 1, 3.7, false);
      expect(v.streakCount).assertEqual(3);
      expect(VitalsEngine.shouldTriggerAlert(v)).assertTrue();
    });

    it('requires2ConsecutiveChecksForBradycardic', 0, () => {
      let v: VitalsData = VitalsEngine.createInitialVitals(BodyPhenotype.BRADYCARDIC, 1, 3.7);
      v = VitalsEngine.generateElevatedStep(v, BodyPhenotype.BRADYCARDIC, 1, 3.7, false);
      expect(v.streakCount).assertEqual(1);
      expect(VitalsEngine.shouldTriggerAlert(v)).assertFalse();

      v = VitalsEngine.generateElevatedStep(v, BodyPhenotype.BRADYCARDIC, 1, 3.7, false);
      expect(v.streakCount).assertEqual(2);
      expect(VitalsEngine.shouldTriggerAlert(v)).assertTrue();
    });

    it('motionGatePausesAndResetsStreak', 0, () => {
      let v: VitalsData = VitalsEngine.createInitialVitals(BodyPhenotype.ADRENERGIC, 1, 3.7);
      v = VitalsEngine.generateElevatedStep(v, BodyPhenotype.ADRENERGIC, 1, 3.7, false);
      expect(v.streakCount).assertEqual(1);

      v = VitalsEngine.generateMovingVitals(v, BodyPhenotype.ADRENERGIC, 1, 3.7);
      expect(v.isSedentary).assertFalse();
      expect(v.streakCount).assertEqual(0);
      expect(VitalsEngine.shouldTriggerAlert(v)).assertFalse();
    });

    it('enforcesCooldownAndMax2AlertsPerNight', 0, () => {
      let v: VitalsData = VitalsEngine.createInitialVitals(BodyPhenotype.ADRENERGIC, 3, 3.7);
      v.alertsTonight = 2;
      v = VitalsEngine.generateElevatedStep(v, BodyPhenotype.ADRENERGIC, 3, 3.7, true);
      expect(VitalsEngine.shouldTriggerAlert(v)).assertFalse();
      expect(v.statusWord).assertEqual('Cap 2/2');

      v.alertsTonight = 1;
      v.cooldownMinutes = 20;
      v = VitalsEngine.generateElevatedStep(v, BodyPhenotype.ADRENERGIC, 3, 3.7, true);
      expect(VitalsEngine.shouldTriggerAlert(v)).assertFalse();
      expect(v.statusWord).assertEqual('Cooldown');
    });

    it('unlocksPersonalLineAndCnnViaFingerPricks', 0, () => {
      let g = HistoryRepository.recordFingerPrick(82, true);
      expect(g.hasPersonalLine).assertTrue();
      expect(g.isCnnUnlocked).assertFalse();

      g = HistoryRepository.recordFingerPrick(54, false);
      g = HistoryRepository.recordFingerPrick(104, false);
      g = HistoryRepository.recordFingerPrick(108, false);
      g = HistoryRepository.recordFingerPrick(112, false);
      g = HistoryRepository.recordFingerPrick(110, false);
      expect(g.confirmedLows >= 1).assertTrue();
      expect(g.fineNights >= 10).assertTrue();
      expect(g.isCnnUnlocked).assertTrue();
    });

    it('matchesPyTorchParityOnLosoC2s02Replay', 0, () => {
      const night: TcnnNightState = new TcnnNightState();
      let maxRawDiff: number = 0.0;
      let maxEmaDiff: number = 0.0;
      let alertsFired: number = 0;
      let cooldownMin: number = 0;
      let streak: number = 0;

      for (let i: number = 0; i < REPLAY_C2S02_NIGHT.framesZ.length; i++) {
        const out: ReplayStepOutput = VitalsEngine.replayStepFromNight(
          REPLAY_C2S02_NIGHT,
          LOSO_C2S02_BUNDLE,
          night,
          i,
          alertsFired,
          cooldownMin,
          streak
        );
        const rawDiff: number = Math.abs(out.stepResult.rawLogit - REPLAY_C2S02_NIGHT.refRawLogit[i]);
        const emaDiff: number = Math.abs(out.stepResult.emaScore - REPLAY_C2S02_NIGHT.refEma[i]);
        if (rawDiff > maxRawDiff) {
          maxRawDiff = rawDiff;
        }
        if (emaDiff > maxEmaDiff) {
          maxEmaDiff = emaDiff;
        }
        streak = out.stepResult.isHot ? streak + 1 : 0;
        cooldownMin = out.vitals.cooldownMinutes;
        if (VitalsEngine.shouldTriggerAlert(out.vitals)) {
          alertsFired += 1;
          cooldownMin = VitalsEngine.COOLDOWN_MINUTES;
        }
      }

      expect(maxRawDiff < 0.0001).assertTrue();
      expect(maxEmaDiff < 0.0001).assertTrue();
      expect(alertsFired >= 1).assertTrue();
      expect(alertsFired <= 2).assertTrue();
    });

    it('matchesPyTorchParityOnLosoC2s03Replay', 0, () => {
      const night: TcnnNightState = new TcnnNightState();
      let maxRawDiff: number = 0.0;
      let maxEmaDiff: number = 0.0;
      let cooldownMin: number = 0;
      let streak: number = 0;

      for (let i: number = 0; i < REPLAY_C2S03_NIGHT.framesZ.length; i++) {
        const out: ReplayStepOutput = VitalsEngine.replayStepFromNight(
          REPLAY_C2S03_NIGHT,
          LOSO_C2S03_BUNDLE,
          night,
          i,
          0,
          cooldownMin,
          streak
        );
        const rawDiff: number = Math.abs(out.stepResult.rawLogit - REPLAY_C2S03_NIGHT.refRawLogit[i]);
        const emaDiff: number = Math.abs(out.stepResult.emaScore - REPLAY_C2S03_NIGHT.refEma[i]);
        if (rawDiff > maxRawDiff) {
          maxRawDiff = rawDiff;
        }
        if (emaDiff > maxEmaDiff) {
          maxEmaDiff = emaDiff;
        }
        streak = out.stepResult.isHot ? streak + 1 : 0;
        cooldownMin = out.vitals.cooldownMinutes;
      }

      expect(maxRawDiff < 0.0001).assertTrue();
      expect(maxEmaDiff < 0.0001).assertTrue();
    });

    it('phase3TcnnRunsRealWeightsAndRequires3ConsecutiveAdrenergicChecks', 0, () => {
      const night: TcnnNightState = VitalsEngine.createPhase3NightState(BodyPhenotype.ADRENERGIC, true);
      let v: VitalsData = VitalsEngine.generateSteadyVitals(
        undefined,
        BodyPhenotype.ADRENERGIC,
        3,
        -1.48,
        75,
        0,
        0,
        night
      );
      expect(v.tcnnEma !== undefined).assertTrue();
      expect(v.tcnnSlotsFilled).assertEqual(12);
      expect(VitalsEngine.shouldTriggerAlert(v)).assertFalse();

      v = VitalsEngine.generateElevatedStep(v, BodyPhenotype.ADRENERGIC, 3, -1.48, false, night);
      expect(v.streakCount).assertEqual(1);
      expect(VitalsEngine.shouldTriggerAlert(v)).assertFalse();

      v = VitalsEngine.generateElevatedStep(v, BodyPhenotype.ADRENERGIC, 3, -1.48, false, night);
      expect(v.streakCount).assertEqual(2);
      expect(VitalsEngine.shouldTriggerAlert(v)).assertFalse();

      v = VitalsEngine.generateElevatedStep(v, BodyPhenotype.ADRENERGIC, 3, -1.48, false, night);
      expect(v.streakCount).assertEqual(3);
      expect(VitalsEngine.shouldTriggerAlert(v)).assertTrue();
    });

    it('phase3TcnnRequires2ConsecutiveBradycardicChecks', 0, () => {
      const night: TcnnNightState = VitalsEngine.createPhase3NightState(BodyPhenotype.BRADYCARDIC, true);
      let v: VitalsData = VitalsEngine.generateSteadyVitals(
        undefined,
        BodyPhenotype.BRADYCARDIC,
        3,
        -2.62,
        75,
        0,
        0,
        night
      );
      expect(v.tcnnEma !== undefined).assertTrue();
      expect(VitalsEngine.shouldTriggerAlert(v)).assertFalse();

      v = VitalsEngine.generateElevatedStep(v, BodyPhenotype.BRADYCARDIC, 3, -2.62, false, night);
      expect(v.streakCount).assertEqual(1);
      expect(VitalsEngine.shouldTriggerAlert(v)).assertFalse();

      v = VitalsEngine.generateElevatedStep(v, BodyPhenotype.BRADYCARDIC, 3, -2.62, false, night);
      expect(v.streakCount).assertEqual(2);
      expect(VitalsEngine.shouldTriggerAlert(v)).assertTrue();
    });
  });
}
