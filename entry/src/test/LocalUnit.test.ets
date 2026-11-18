import { describe, it, expect } from '@ohos/hypium';
import { BodyPhenotype, VitalsData, VitalsEngine } from '../main/ets/models/VitalsModel';
import { HistoryRepository } from '../main/ets/models/HistoryModel';

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
  });
}
