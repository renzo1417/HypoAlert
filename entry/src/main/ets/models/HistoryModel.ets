/*
 * Copyright (c) 2026 HypoAlert.
 * Multi-night history data model and audit trail contracts for Watch and Phone.
 */

export interface ActionTakenEntry {
  time: string;
  type: 'haptic' | 'alarm' | 'sms' | 'call' | 'snooze' | 'resolve' | 'prick';
  title: string;
  detail: string;
  target?: string;
  status: 'Sent' | 'Delivered' | 'Active' | 'Acknowledged' | 'Completed';
}

export interface FingerPrickEntry {
  time: string;
  mgDl: number;
  label: 'Low' | 'Fine';
  linkedToBuzz: boolean;
}

export interface CalibrationProgress {
  buzzPricks: number;
  buzzPricksTarget: number;
  confirmedLows: number;
  confirmedLowsTarget: number;
  fineNights: number;
  fineNightsTarget: number;
  personalCutoff: number;
  phase2Unlocked: boolean;
  phase3Unlocked: boolean;
  lastCheckSummary: string;
}

export interface NightHistoryRecord {
  id: string;
  dateLabel: string;
  dateShort: string;
  dayOfWeek: string;
  status: 'NORMAL' | 'WARNING' | 'CRITICAL';
  lowestGlucose: number;
  peakRiskIndex: number;
  peakSymptomScore: number;
  avgPulse: number;
  minSkinTemp: number;
  durationHours: number;
  episodesCount: number;
  actionsSummary: string;
  fingerPrickNote: string;
  hourlyPoints: number[];
  hourlySymptomScores: number[];
  actionsTaken: ActionTakenEntry[];
}

export interface EmergencyContact {
  id: string;
  name: string;
  phone: string;
  relation: string;
  isPrimary: boolean;
  smnEnabled: boolean;
}

export class HistoryRepository {
  private static defaultContacts: EmergencyContact[] = [
    {
      id: 'c1',
      name: 'Maria Santos',
      phone: '+63 917 123 4567',
      relation: 'Mother / Primary Caregiver',
      isPrimary: true,
      smnEnabled: true
    },
    {
      id: 'c2',
      name: 'Dr. Roberto Ramirez',
      phone: '+63 918 987 6543',
      relation: 'Endocrinologist',
      isPrimary: false,
      smnEnabled: true
    },
    {
      id: 'c3',
      name: 'Carlo Santos',
      phone: '+63 920 555 8899',
      relation: 'Guardian / Brother',
      isPrimary: false,
      smnEnabled: false
    }
  ];

  private static calibration: CalibrationProgress = {
    buzzPricks: 2,
    buzzPricksTarget: 3,
    confirmedLows: 0,
    confirmedLowsTarget: 1,
    fineNights: 6,
    fineNightsTarget: 10,
    personalCutoff: 4.3,
    phase2Unlocked: false,
    phase3Unlocked: false,
    lastCheckSummary: ''
  };

  private static fingerPricks: FingerPrickEntry[] = [];

  private static defaultHistory: NightHistoryRecord[] = [
    {
      id: 'night_0',
      dateLabel: 'Tonight',
      dateShort: 'Tonight',
      dayOfWeek: 'Sun',
      status: 'NORMAL',
      lowestGlucose: 5.2,
      peakRiskIndex: 12,
      peakSymptomScore: 1.4,
      avgPulse: 62,
      minSkinTemp: 35.9,
      durationHours: 6.5,
      episodesCount: 0,
      actionsSummary: 'Quiet sleep',
      fingerPrickNote: 'Pending',
      hourlyPoints: [5.6, 5.4, 5.2, 5.3, 5.5],
      hourlySymptomScores: [1.1, 1.3, 1.4, 1.2, 1.1],
      actionsTaken: [
        {
          time: '10:00 PM',
          type: 'resolve',
          title: 'Baseline Locked',
          detail: '15 quiet slots · 61 bpm',
          status: 'Acknowledged'
        },
        {
          time: '01:15 AM',
          type: 'resolve',
          title: 'Motion Gated',
          detail: '0.31g turn ignored',
          status: 'Acknowledged'
        }
      ]
    },
    {
      id: 'night_1',
      dateLabel: 'Sep 27',
      dateShort: 'Sep 27',
      dayOfWeek: 'Sat',
      status: 'CRITICAL',
      lowestGlucose: 3.1,
      peakRiskIndex: 88,
      peakSymptomScore: 5.4,
      avgPulse: 74,
      minSkinTemp: 34.8,
      durationHours: 7.8,
      episodesCount: 1,
      actionsSummary: 'Surge · 58 mg/dL',
      fingerPrickNote: '58 mg/dL',
      hourlyPoints: [5.5, 4.4, 3.1, 4.6, 5.2],
      hourlySymptomScores: [1.2, 3.2, 5.4, 2.3, 1.3],
      actionsTaken: [
        {
          time: '02:45 AM',
          type: 'haptic',
          title: 'Surge Alert',
          detail: '3/3 streak · Watch buzz',
          status: 'Active'
        },
        {
          time: '02:45 AM',
          type: 'sms',
          title: 'SMS Sent',
          detail: 'Maria Santos',
          target: 'Maria Santos (+63 917 123 4567)',
          status: 'Delivered'
        },
        {
          time: '02:47 AM',
          type: 'call',
          title: 'Caregiver Call',
          detail: 'Maria Santos',
          target: 'Maria Santos (+63 917 123 4567)',
          status: 'Completed'
        },
        {
          time: '02:51 AM',
          type: 'prick',
          title: '58 mg/dL · Low',
          detail: 'Confirmed low',
          status: 'Acknowledged'
        }
      ]
    },
    {
      id: 'night_2',
      dateLabel: 'Sep 26',
      dateShort: 'Sep 26',
      dayOfWeek: 'Fri',
      status: 'WARNING',
      lowestGlucose: 4.1,
      peakRiskIndex: 42,
      peakSymptomScore: 4.0,
      avgPulse: 68,
      minSkinTemp: 35.5,
      durationHours: 8.0,
      episodesCount: 1,
      actionsSummary: 'Buzz · 108 mg/dL',
      fingerPrickNote: '108 mg/dL',
      hourlyPoints: [5.7, 5.1, 4.1, 4.8, 5.4],
      hourlySymptomScores: [1.3, 2.8, 4.0, 2.1, 1.4],
      actionsTaken: [
        {
          time: '03:20 AM',
          type: 'haptic',
          title: 'Buzz Prompt',
          detail: 'Possible low check',
          status: 'Delivered'
        },
        {
          time: '03:24 AM',
          type: 'prick',
          title: '108 mg/dL · Fine',
          detail: 'Saved to Phase 2',
          status: 'Acknowledged'
        }
      ]
    },
    {
      id: 'night_3',
      dateLabel: 'Sep 25',
      dateShort: 'Sep 25',
      dayOfWeek: 'Thu',
      status: 'NORMAL',
      lowestGlucose: 5.4,
      peakRiskIndex: 10,
      peakSymptomScore: 1.5,
      avgPulse: 60,
      minSkinTemp: 36.1,
      durationHours: 7.2,
      episodesCount: 0,
      actionsSummary: 'Quiet · 112 mg/dL',
      fingerPrickNote: '112 mg/dL',
      hourlyPoints: [5.8, 5.6, 5.4, 5.5, 5.7],
      hourlySymptomScores: [1.0, 1.2, 1.5, 1.2, 1.1],
      actionsTaken: [
        {
          time: '10:15 PM',
          type: 'resolve',
          title: 'Baseline Locked',
          detail: '0 alerts tonight',
          status: 'Acknowledged'
        }
      ]
    },
    {
      id: 'night_4',
      dateLabel: 'Sep 24',
      dateShort: 'Sep 24',
      dayOfWeek: 'Wed',
      status: 'CRITICAL',
      lowestGlucose: 3.3,
      peakRiskIndex: 82,
      peakSymptomScore: 4.9,
      avgPulse: 72,
      minSkinTemp: 34.9,
      durationHours: 7.5,
      episodesCount: 1,
      actionsSummary: 'Surge · 104 mg/dL',
      fingerPrickNote: '104 mg/dL',
      hourlyPoints: [5.4, 4.8, 3.3, 4.7, 5.3],
      hourlySymptomScores: [1.5, 2.9, 4.9, 2.4, 1.4],
      actionsTaken: [
        {
          time: '04:10 AM',
          type: 'haptic',
          title: 'Surge Alert',
          detail: 'Watch buzz + SMS',
          status: 'Active'
        },
        {
          time: '04:14 AM',
          type: 'resolve',
          title: "Dismissed (I'm awake)",
          detail: 'Confirmed on watch',
          status: 'Acknowledged'
        }
      ]
    },
    {
      id: 'night_5',
      dateLabel: 'Sep 23',
      dateShort: 'Sep 23',
      dayOfWeek: 'Tue',
      status: 'NORMAL',
      lowestGlucose: 5.1,
      peakRiskIndex: 14,
      peakSymptomScore: 1.7,
      avgPulse: 61,
      minSkinTemp: 36.0,
      durationHours: 8.2,
      episodesCount: 0,
      actionsSummary: 'Quiet · 110 mg/dL',
      fingerPrickNote: '110 mg/dL',
      hourlyPoints: [5.5, 5.3, 5.1, 5.2, 5.6],
      hourlySymptomScores: [1.2, 1.4, 1.7, 1.3, 1.1],
      actionsTaken: [
        {
          time: '10:00 PM',
          type: 'resolve',
          title: 'Baseline Locked',
          detail: 'Calm sleep',
          status: 'Acknowledged'
        }
      ]
    },
    {
      id: 'night_6',
      dateLabel: 'Sep 22',
      dateShort: 'Sep 22',
      dayOfWeek: 'Mon',
      status: 'NORMAL',
      lowestGlucose: 5.3,
      peakRiskIndex: 11,
      peakSymptomScore: 1.3,
      avgPulse: 63,
      minSkinTemp: 36.0,
      durationHours: 7.0,
      episodesCount: 0,
      actionsSummary: 'Quiet · 106 mg/dL',
      fingerPrickNote: '106 mg/dL',
      hourlyPoints: [5.6, 5.4, 5.3, 5.4, 5.5],
      hourlySymptomScores: [1.1, 1.3, 1.3, 1.2, 1.0],
      actionsTaken: [
        {
          time: '10:30 PM',
          type: 'resolve',
          title: 'Baseline Locked',
          detail: 'Calm sleep',
          status: 'Acknowledged'
        }
      ]
    }
  ];

  public static getContacts(): EmergencyContact[] {
    return HistoryRepository.defaultContacts;
  }

  public static getHistory(): NightHistoryRecord[] {
    return HistoryRepository.defaultHistory;
  }

  public static getWatchHistory(maxDays: number = 5): NightHistoryRecord[] {
    return HistoryRepository.defaultHistory.slice(0, maxDays);
  }

  public static getCalibration(): CalibrationProgress {
    return {
      buzzPricks: HistoryRepository.calibration.buzzPricks,
      buzzPricksTarget: HistoryRepository.calibration.buzzPricksTarget,
      confirmedLows: HistoryRepository.calibration.confirmedLows,
      confirmedLowsTarget: HistoryRepository.calibration.confirmedLowsTarget,
      fineNights: HistoryRepository.calibration.fineNights,
      fineNightsTarget: HistoryRepository.calibration.fineNightsTarget,
      personalCutoff: HistoryRepository.calibration.personalCutoff,
      phase2Unlocked: HistoryRepository.calibration.phase2Unlocked,
      phase3Unlocked: HistoryRepository.calibration.phase3Unlocked,
      lastCheckSummary: HistoryRepository.calibration.lastCheckSummary
    };
  }

  public static getFingerPricks(): FingerPrickEntry[] {
    return HistoryRepository.fingerPricks;
  }

  public static logFingerPrick(mgDl: number, linkedToBuzz: boolean, timeStr: string): CalibrationProgress {
    const isLow: boolean = mgDl < 70;
    HistoryRepository.fingerPricks.unshift({
      time: timeStr,
      mgDl: mgDl,
      label: isLow ? 'Low' : 'Fine',
      linkedToBuzz: linkedToBuzz
    });

    if (linkedToBuzz) {
      HistoryRepository.calibration.buzzPricks += 1;
    }
    if (isLow) {
      HistoryRepository.calibration.confirmedLows += 1;
    } else {
      HistoryRepository.calibration.fineNights += 1;
    }

    if (HistoryRepository.calibration.buzzPricks >= HistoryRepository.calibration.buzzPricksTarget) {
      HistoryRepository.calibration.phase2Unlocked = true;
    }
    if (
      HistoryRepository.calibration.confirmedLows >= HistoryRepository.calibration.confirmedLowsTarget &&
      HistoryRepository.calibration.fineNights >= HistoryRepository.calibration.fineNightsTarget
    ) {
      HistoryRepository.calibration.phase3Unlocked = true;
    }

    HistoryRepository.calibration.lastCheckSummary =
      `Saved ${mgDl} mg/dL (${isLow ? 'Low' : 'Fine'}) · ${timeStr}`;

    const tonight = HistoryRepository.defaultHistory[0];
    tonight.fingerPrickNote = `${mgDl} mg/dL`;
    tonight.actionsTaken.unshift({
      time: timeStr,
      type: 'prick',
      title: `${mgDl} mg/dL · ${isLow ? 'Low' : 'Fine'}`,
      detail: linkedToBuzz ? 'Buzz check saved' : 'Morning check saved',
      status: 'Acknowledged'
    });

    return HistoryRepository.getCalibration();
  }

  public static updateTonightSymptomCrisis(score: number, riskPct: number, caregiverName: string, caregiverPhone: string): void {
    const tonight = HistoryRepository.defaultHistory[0];
    tonight.status = 'CRITICAL';
    tonight.peakSymptomScore = Math.max(tonight.peakSymptomScore, score);
    tonight.peakRiskIndex = Math.max(tonight.peakRiskIndex, riskPct);
    tonight.episodesCount += 1;
    tonight.actionsSummary = `Surge · SMS sent`;
    tonight.hourlySymptomScores = [1.1, 2.8, Math.round(score * 10) / 10, 2.1, 1.3];
    tonight.actionsTaken.unshift({
      time: 'Just now',
      type: 'sms',
      title: 'SMS Sent',
      detail: `${caregiverName} · Score ${score.toFixed(1)}`,
      target: `${caregiverName} (${caregiverPhone})`,
      status: 'Delivered'
    });
    tonight.actionsTaken.unshift({
      time: 'Just now',
      type: 'haptic',
      title: 'Surge Alert',
      detail: 'Watch haptics active',
      status: 'Active'
    });
  }

  public static updateTonightCrisis(glucose: number, risk: number, caregiverName: string, caregiverPhone: string): void {
    HistoryRepository.updateTonightSymptomCrisis(4.8, risk, caregiverName, caregiverPhone);
    const tonight = HistoryRepository.defaultHistory[0];
    tonight.lowestGlucose = glucose;
  }

  public static updateTonightResolved(): void {
    const tonight = HistoryRepository.defaultHistory[0];
    tonight.actionsTaken.unshift({
      time: 'Just now',
      type: 'resolve',
      title: "Dismissed (I'm awake)",
      detail: 'Ready for finger-prick',
      status: 'Acknowledged'
    });
  }
}
