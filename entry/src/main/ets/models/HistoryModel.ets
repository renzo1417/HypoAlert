/*
 * Copyright (c) 2026 HypoAlert.
 * Multi-night symptom history, finger-prick verification, and Phase 1-3 gate tracking.
 */

import { DetectionPhase, GateProgress } from './VitalsModel';

export interface ActionTakenEntry {
  time: string;
  type: 'haptic' | 'alarm' | 'sms' | 'call' | 'prick' | 'resolve';
  title: string;
  detail: string;
  target?: string;
  status: 'Sent' | 'Delivered' | 'Active' | 'Acknowledged' | 'Completed';
}

export type FingerPrickVerdict = 'Confirmed Low' | 'Fine Night' | 'Pending Check' | 'None';

export interface NightHistoryRecord {
  id: string;
  dateLabel: string;
  dateShort: string;
  dayOfWeek: string;
  status: 'NORMAL' | 'WARNING' | 'CRITICAL';
  phaseUsed: DetectionPhase;
  peakRiskPct: number;
  peakScore: number;
  avgHr: number;
  minRmssd: number;
  durationHours: number;
  episodesCount: number;
  fingerPrickMgDl?: number;
  fingerPrickVerdict: FingerPrickVerdict;
  actionsSummary: string;
  hourlyRiskPct: number[]; // 12am, 2am, 4am, 6am, 8am symptom risk %
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
  private static gateState: GateProgress = {
    buzzLinkedPricks: 2,
    confirmedLows: 0,
    fineNights: 6,
    personalLine: 3.7,
    hasPersonalLine: false,
    isCnnUnlocked: false,
    isA2Personalized: false
  };

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

  private static defaultHistory: NightHistoryRecord[] = [
    {
      id: 'night_0',
      dateLabel: 'Tonight (Live Session)',
      dateShort: 'Tonight',
      dayOfWeek: 'Sun',
      status: 'NORMAL',
      phaseUsed: 1,
      peakRiskPct: 14,
      peakScore: 0.9,
      avgHr: 62,
      minRmssd: 41,
      durationHours: 6.5,
      episodesCount: 0,
      fingerPrickVerdict: 'None',
      actionsSummary: 'Calm sleep • 0 alerts',
      hourlyRiskPct: [10, 12, 14, 11, 9],
      actionsTaken: [
        {
          time: '10:00 PM',
          type: 'resolve',
          title: '75-Min Silent Baseline Started',
          detail: 'Learning normal resting heart rate, HRV, and wrist stillness.',
          status: 'Acknowledged'
        },
        {
          time: '11:15 PM',
          type: 'resolve',
          title: 'Baseline Ready — Checking Every 5 Min',
          detail: 'Quiet sleep confirmed. Single spikes ignored; 3-in-a-row safety rule active.',
          status: 'Acknowledged'
        }
      ]
    },
    {
      id: 'night_1',
      dateLabel: 'Night 6 (Yesterday)',
      dateShort: 'Night 6',
      dayOfWeek: 'Sat',
      status: 'CRITICAL',
      phaseUsed: 1,
      peakRiskPct: 86,
      peakScore: 4.4,
      avgHr: 74,
      minRmssd: 16,
      durationHours: 7.8,
      episodesCount: 1,
      fingerPrickMgDl: 52,
      fingerPrickVerdict: 'Confirmed Low',
      actionsSummary: 'Buzz + 1 text sent • Confirmed 52 mg/dL',
      hourlyRiskPct: [12, 48, 86, 28, 14],
      actionsTaken: [
        {
          time: '02:45 AM',
          type: 'haptic',
          title: 'Possible Low Buzz (3 Checks in a Row)',
          detail: 'Sustained fast pulse and 8-12 Hz tremor triggered gentle wrist buzz.',
          status: 'Active'
        },
        {
          time: '02:45 AM',
          type: 'sms',
          title: 'Check-In Text Sent (1/2 Tonight)',
          detail: 'Possible nocturnal low symptoms detected — please check in.',
          target: 'Maria Santos (+63 917 123 4567)',
          status: 'Delivered'
        },
        {
          time: '02:48 AM',
          type: 'resolve',
          title: 'Awake & Resting (30-Min Cooldown)',
          detail: 'User tapped I\'m Awake. Alarms paused for 30 minutes.',
          status: 'Acknowledged'
        },
        {
          time: '07:10 AM',
          type: 'prick',
          title: 'Finger-Prick Logged: 52 mg/dL (Confirmed Low)',
          detail: 'Saved to calibration store. Helps unlock Phase 3 1D-CNN.',
          status: 'Completed'
        }
      ]
    },
    {
      id: 'night_2',
      dateLabel: 'Night 5',
      dateShort: 'Night 5',
      dayOfWeek: 'Fri',
      status: 'WARNING',
      phaseUsed: 1,
      peakRiskPct: 58,
      peakScore: 3.1,
      avgHr: 67,
      minRmssd: 28,
      durationHours: 8.0,
      episodesCount: 0,
      fingerPrickMgDl: 104,
      fingerPrickVerdict: 'Fine Night',
      actionsSummary: 'Single spike ignored • Fine 104 mg/dL',
      hourlyRiskPct: [14, 58, 22, 16, 12],
      actionsTaken: [
        {
          time: '03:20 AM',
          type: 'resolve',
          title: 'Single Elevated Check Ignored',
          detail: '1 of 3 checks rose during dream sleep, then returned to baseline. Zero false wakeup.',
          status: 'Acknowledged'
        },
        {
          time: '07:25 AM',
          type: 'prick',
          title: 'Morning Finger-Prick: 104 mg/dL (Fine)',
          detail: 'Marked as normal night (70+ mg/dL).',
          status: 'Completed'
        }
      ]
    },
    {
      id: 'night_3',
      dateLabel: 'Night 4',
      dateShort: 'Night 4',
      dayOfWeek: 'Thu',
      status: 'NORMAL',
      phaseUsed: 1,
      peakRiskPct: 16,
      peakScore: 1.1,
      avgHr: 60,
      minRmssd: 43,
      durationHours: 7.4,
      episodesCount: 0,
      fingerPrickMgDl: 112,
      fingerPrickVerdict: 'Fine Night',
      actionsSummary: 'Calm sleep • Fine 112 mg/dL',
      hourlyRiskPct: [10, 14, 16, 13, 11],
      actionsTaken: [
        {
          time: '07:15 AM',
          type: 'prick',
          title: 'Morning Finger-Prick: 112 mg/dL (Fine)',
          detail: 'Normal night recorded.',
          status: 'Completed'
        }
      ]
    },
    {
      id: 'night_4',
      dateLabel: 'Night 3',
      dateShort: 'Night 3',
      dayOfWeek: 'Wed',
      status: 'CRITICAL',
      phaseUsed: 1,
      peakRiskPct: 79,
      peakScore: 3.9,
      avgHr: 71,
      minRmssd: 22,
      durationHours: 7.5,
      episodesCount: 1,
      fingerPrickMgDl: 84,
      fingerPrickVerdict: 'Fine Night',
      actionsSummary: 'Buzz + 1 text sent • Fine 84 mg/dL',
      hourlyRiskPct: [15, 24, 79, 20, 12],
      actionsTaken: [
        {
          time: '04:10 AM',
          type: 'haptic',
          title: 'Possible Low Buzz (3 Checks in a Row)',
          detail: 'Gentle wrist buzz + check-in alert sent.',
          status: 'Active'
        },
        {
          time: '04:14 AM',
          type: 'resolve',
          title: 'User Confirmed Awake',
          detail: 'Alert silenced on Huawei Watch.',
          status: 'Acknowledged'
        },
        {
          time: '04:20 AM',
          type: 'prick',
          title: 'Buzz Finger-Prick: 84 mg/dL (Fine)',
          detail: 'Teaches personal cutoff to stay quieter on benign shifts.',
          status: 'Completed'
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

  public static getGateProgress(): GateProgress {
    return {
      buzzLinkedPricks: HistoryRepository.gateState.buzzLinkedPricks,
      confirmedLows: HistoryRepository.gateState.confirmedLows,
      fineNights: HistoryRepository.gateState.fineNights,
      personalLine: HistoryRepository.gateState.personalLine,
      hasPersonalLine: HistoryRepository.gateState.hasPersonalLine,
      isCnnUnlocked: HistoryRepository.gateState.isCnnUnlocked,
      isA2Personalized: HistoryRepository.gateState.isA2Personalized
    };
  }

  public static updateTonightCrisis(
    riskPct: number,
    score: number,
    reasonSummary: string,
    alertsTonight: number,
    caregiverName: string,
    caregiverPhone: string,
    phase: DetectionPhase
  ): void {
    const tonight: NightHistoryRecord = HistoryRepository.defaultHistory[0];
    tonight.status = 'CRITICAL';
    tonight.phaseUsed = phase;
    tonight.peakRiskPct = Math.max(tonight.peakRiskPct, riskPct);
    tonight.peakScore = Math.max(tonight.peakScore, score);
    tonight.episodesCount = alertsTonight;
    tonight.fingerPrickVerdict = 'Pending Check';
    tonight.actionsSummary = `Buzz + ${alertsTonight}/2 texts • Log finger-prick`;
    tonight.hourlyRiskPct = [12, 34, riskPct, 28, 16];
    tonight.actionsTaken.unshift({
      time: 'Just now',
      type: 'sms',
      title: `Check-In Text Sent (${alertsTonight}/2 Tonight)`,
      detail: `Possible low symptoms: ${reasonSummary}`,
      target: `${caregiverName} (${caregiverPhone})`,
      status: 'Delivered'
    });
    tonight.actionsTaken.unshift({
      time: 'Just now',
      type: 'haptic',
      title: phase < 3 ? 'Possible Low Wrist Buzz' : '1D-CNN Symptom Alert Buzz',
      detail: `${reasonSummary}. Log a finger-prick check when awake.`,
      status: 'Active'
    });
  }

  public static updateTonightResolved(): void {
    const tonight: NightHistoryRecord = HistoryRepository.defaultHistory[0];
    tonight.actionsTaken.unshift({
      time: 'Just now',
      type: 'resolve',
      title: 'Awake Confirmed • 30-Min Cooldown',
      detail: 'Alarm silenced. Log a finger-prick check to calibrate your watch.',
      status: 'Acknowledged'
    });
  }

  public static recordFingerPrick(mgDl: number, linkedToBuzz: boolean): GateProgress {
    const tonight: NightHistoryRecord = HistoryRepository.defaultHistory[0];
    const isLow: boolean = mgDl < 70;
    tonight.fingerPrickMgDl = mgDl;
    tonight.fingerPrickVerdict = isLow ? 'Confirmed Low' : 'Fine Night';
    tonight.actionsSummary = `${tonight.episodesCount} alert(s) • Prick ${mgDl} mg/dL (${isLow ? 'Low' : 'Fine'})`;
    tonight.actionsTaken.unshift({
      time: 'Just now',
      type: 'prick',
      title: `Finger-Prick: ${mgDl} mg/dL (${isLow ? 'Confirmed Low <70' : 'Fine 70+'})`,
      detail: linkedToBuzz
        ? 'Buzz-linked check saved — helps personalize your cutoff line.'
        : 'Morning check saved to calibration history.',
      status: 'Completed'
    });

    if (linkedToBuzz) {
      HistoryRepository.gateState.buzzLinkedPricks += 1;
    }
    if (isLow) {
      HistoryRepository.gateState.confirmedLows += 1;
    } else {
      HistoryRepository.gateState.fineNights += 1;
    }
    if (HistoryRepository.gateState.buzzLinkedPricks >= 3 && !HistoryRepository.gateState.hasPersonalLine) {
      HistoryRepository.gateState.hasPersonalLine = true;
      HistoryRepository.gateState.personalLine = 5.44;
    }
    if (HistoryRepository.gateState.confirmedLows >= 1 && HistoryRepository.gateState.fineNights >= 10) {
      HistoryRepository.gateState.isCnnUnlocked = true;
    }
    return HistoryRepository.getGateProgress();
  }
}
