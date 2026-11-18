import { describe, it, expect } from '@ohos/hypium';
import { HistoryRepository } from '../main/ets/models/HistoryModel';
import {
  activeScoreThreshold,
  evaluateSymptomState,
  requiredStreakForBody
} from '../main/ets/phone/utils/PhoneRiskUtils';

export default function localUnitTest() {
  describe('HypoAlertSymptomTests', () => {
    it('evaluatesPhaseAndStreakSafetyFilter', 0, () => {
      expect(requiredStreakForBody('Adrenergic')).assertEqual(3);
      expect(requiredStreakForBody('Blunted')).assertEqual(2);
      expect(activeScoreThreshold('P1', 4.3)).assertEqual(3.7);
      expect(activeScoreThreshold('P2', 4.3)).assertEqual(4.3);
      expect(activeScoreThreshold('P2', 3.2)).assertEqual(3.7);

      expect(evaluateSymptomState(1.2, 14, 'P1', 4.3, 0, 'Adrenergic', false, 15)).assertEqual('Normal');
      expect(evaluateSymptomState(4.5, 40, 'P1', 4.3, 2, 'Adrenergic', false, 15)).assertEqual('Warning');
      expect(evaluateSymptomState(4.5, 40, 'P1', 4.3, 3, 'Adrenergic', false, 15)).assertEqual('Critical');
      expect(evaluateSymptomState(4.5, 40, 'P1', 4.3, 2, 'Blunted', false, 15)).assertEqual('Critical');
      expect(evaluateSymptomState(5.4, 86, 'P3', 4.3, 3, 'Adrenergic', true, 15)).assertEqual('Gated');
      expect(evaluateSymptomState(5.4, 86, 'P1', 4.3, 3, 'Adrenergic', false, 11)).assertEqual('Learning');
    });

    it('unlocksPhase2AndPhase3ViaFingerPricksAndPreservesWatchHistory', 0, () => {
      const watchHistory = HistoryRepository.getWatchHistory(5);
      expect(watchHistory.length).assertEqual(5);
      expect(watchHistory[0].lowestGlucose > 0).assertTrue();

      const start = HistoryRepository.getCalibration();
      expect(start.buzzPricks).assertEqual(2);
      expect(start.confirmedLows).assertEqual(0);
      expect(start.fineNights).assertEqual(6);
      expect(start.phase2Unlocked).assertFalse();
      expect(start.phase3Unlocked).assertFalse();

      const afterLow = HistoryRepository.logFingerPrick(54, true, '02:50');
      expect(afterLow.buzzPricks).assertEqual(3);
      expect(afterLow.confirmedLows).assertEqual(1);
      expect(afterLow.phase2Unlocked).assertTrue();
      expect(afterLow.phase3Unlocked).assertFalse();

      HistoryRepository.logFingerPrick(108, false, '07:10');
      HistoryRepository.logFingerPrick(108, false, '07:12');
      HistoryRepository.logFingerPrick(108, false, '07:14');
      const afterFine = HistoryRepository.logFingerPrick(108, false, '07:16');
      expect(afterFine.fineNights).assertEqual(10);
      expect(afterFine.phase3Unlocked).assertTrue();
    });
  });
}
