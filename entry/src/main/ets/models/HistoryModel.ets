/*
 * Copyright (c) 2026 HypoAlert.
 * Multi-night history data model and audit trail contracts for Watch and Phone.
 */

export interface ActionTakenEntry {
  time: string;
  type: 'haptic' | 'alarm' | 'sms' | 'call' | 'snooze' | 'resolve';
  title: string;
  detail: string;
  target?: string;
  status: 'Sent' | 'Delivered' | 'Active' | 'Acknowledged' | 'Completed';
}

export interface NightHistoryRecord {
  id: string;
  dateLabel: string;
  dateShort: string;
  dayOfWeek: string;
  status: 'NORMAL' | 'WARNING' | 'CRITICAL';
  lowestGlucose: number;
  peakRiskIndex: number;
  avgPulse: number;
  minSkinTemp: number;
  durationHours: number;
  episodesCount: number;
  actionsSummary: string;
  hourlyPoints: number[];
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

  private static defaultHistory: NightHistoryRecord[] = [
    {
      id: 'night_0',
      dateLabel: 'Tonight (Live Session)',
      dateShort: 'Tonight',
      dayOfWeek: 'Sun',
      status: 'NORMAL',
      lowestGlucose: 5.2,
      peakRiskIndex: 12,
      avgPulse: 62,
      minSkinTemp: 35.9,
      durationHours: 6.5,
      episodesCount: 0,
      actionsSummary: 'Calm Sleep • 0 Episodes',
      hourlyPoints: [5.6, 5.4, 5.2, 5.3, 5.5],
      actionsTaken: [
        {
          time: '10:00 PM',
          type: 'resolve',
          title: 'Night Guardian Activated',
          detail: 'Bedtime monitoring engaged. Baseline calibrated (HR: 61 bpm, Temp: 36.0°C).',
          status: 'Acknowledged'
        },
        {
          time: '01:15 AM',
          type: 'resolve',
          title: 'Autonomous System Heartbeat',
          detail: 'Telemetry stable, no sympathetic surges detected.',
          status: 'Acknowledged'
        }
      ]
    },
    {
      id: 'night_1',
      dateLabel: 'Sep 27 (Yesterday)',
      dateShort: 'Sep 27',
      dayOfWeek: 'Sat',
      status: 'CRITICAL',
      lowestGlucose: 3.1,
      peakRiskIndex: 88,
      avgPulse: 74,
      minSkinTemp: 34.8,
      durationHours: 7.8,
      episodesCount: 1,
      actionsSummary: 'Wrist Haptics • 2 SMS Dispatched • Call Placed',
      hourlyPoints: [5.5, 4.4, 3.1, 4.6, 5.2],
      actionsTaken: [
        {
          time: '02:45 AM',
          type: 'haptic',
          title: 'Wrist Haptic Wake-Up Pulse',
          detail: 'Continuous 600ms high-intensity emergency vibration activated on Huawei Watch.',
          status: 'Active'
        },
        {
          time: '02:45 AM',
          type: 'alarm',
          title: 'Bedside Auditory Siren',
          detail: '85dB acoustic buzzer sounded on phone to awaken sleeper.',
          status: 'Active'
        },
        {
          time: '02:45 AM',
          type: 'sms',
          title: 'Emergency SMS Dispatched (SMN)',
          detail: 'Urgent Alert: Nocturnal hypoglycemia (3.1 mmol/L) detected!',
          target: 'Maria Santos (+63 917 123 4567)',
          status: 'Delivered'
        },
        {
          time: '02:46 AM',
          type: 'sms',
          title: 'Secondary Emergency SMS (SMN)',
          detail: 'Medical Alert: Nocturnal hypoglycemia crisis notification.',
          target: 'Dr. Ramirez (+63 918 987 6543)',
          status: 'Delivered'
        },
        {
          time: '02:47 AM',
          type: 'call',
          title: 'Direct Emergency Call Initiated',
          detail: 'Phone auto-dialed caregiver for urgent bedside assistance.',
          target: 'Maria Santos (+63 917 123 4567)',
          status: 'Completed'
        },
        {
          time: '02:49 AM',
          type: 'resolve',
          title: 'Bedside Presence Confirmed',
          detail: 'Caregiver tapped "I\'m with them". Alarms snoozed, glucose rescue administered.',
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
      avgPulse: 68,
      minSkinTemp: 35.5,
      durationHours: 8.0,
      episodesCount: 1,
      actionsSummary: 'Early Warning • Watch Haptic Check',
      hourlyPoints: [5.7, 5.1, 4.1, 4.8, 5.4],
      actionsTaken: [
        {
          time: '03:20 AM',
          type: 'haptic',
          title: 'Mild Restlessness Haptic Check',
          detail: 'Single pulse delivered to check sleeper response as glucose dipped to 4.1 mmol/L.',
          status: 'Delivered'
        },
        {
          time: '03:40 AM',
          type: 'resolve',
          title: 'Vitals Re-stabilized',
          detail: 'Sympathetic tone calmed without requiring full siren dispatch.',
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
      avgPulse: 60,
      minSkinTemp: 36.1,
      durationHours: 7.2,
      episodesCount: 0,
      actionsSummary: 'Calm Sleep • 0 Episodes',
      hourlyPoints: [5.8, 5.6, 5.4, 5.5, 5.7],
      actionsTaken: [
        {
          time: '10:15 PM',
          type: 'resolve',
          title: 'Night Guardian Activated',
          detail: 'Normal sleep settling detected.',
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
      avgPulse: 72,
      minSkinTemp: 34.9,
      durationHours: 7.5,
      episodesCount: 1,
      actionsSummary: 'Wrist Haptics • SMS Dispatched',
      hourlyPoints: [5.4, 4.8, 3.3, 4.7, 5.3],
      actionsTaken: [
        {
          time: '04:10 AM',
          type: 'haptic',
          title: 'Critical Alarm Triggered',
          detail: 'Wrist vibration and bedside siren activated.',
          status: 'Active'
        },
        {
          time: '04:10 AM',
          type: 'sms',
          title: 'SMN Alert Dispatched',
          detail: 'Emergency text delivered to primary caregiver.',
          target: 'Maria Santos (+63 917 123 4567)',
          status: 'Delivered'
        },
        {
          time: '04:14 AM',
          type: 'resolve',
          title: 'Alert Silenced by User',
          detail: 'User confirmed "I\'m awake" on Huawei Watch.',
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
      avgPulse: 61,
      minSkinTemp: 36.0,
      durationHours: 8.2,
      episodesCount: 0,
      actionsSummary: 'Calm Sleep • 0 Episodes',
      hourlyPoints: [5.5, 5.3, 5.1, 5.2, 5.6],
      actionsTaken: [
        {
          time: '10:00 PM',
          type: 'resolve',
          title: 'Night Guardian Activated',
          detail: 'Undisturbed sleep all night.',
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
      avgPulse: 63,
      minSkinTemp: 36.0,
      durationHours: 7.0,
      episodesCount: 0,
      actionsSummary: 'Calm Sleep • 0 Episodes',
      hourlyPoints: [5.6, 5.4, 5.3, 5.4, 5.5],
      actionsTaken: [
        {
          time: '10:30 PM',
          type: 'resolve',
          title: 'Night Guardian Activated',
          detail: 'Baseline stable.',
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

  public static updateTonightCrisis(glucose: number, risk: number, caregiverName: string, caregiverPhone: string): void {
    const tonight = HistoryRepository.defaultHistory[0];
    tonight.status = 'CRITICAL';
    tonight.lowestGlucose = glucose;
    tonight.peakRiskIndex = risk;
    tonight.episodesCount = 1;
    tonight.actionsSummary = `Haptics Active • SMS sent to ${caregiverName}`;
    tonight.hourlyPoints = [5.6, 4.8, glucose, 4.2, 5.0];
    tonight.actionsTaken.unshift({
      time: 'Just now',
      type: 'sms',
      title: 'Emergency SMS Dispatched (SMN)',
      detail: `Hypoglycemia alert (${glucose.toFixed(1)} mmol/L) dispatched.`,
      target: `${caregiverName} (${caregiverPhone})`,
      status: 'Delivered'
    });
    tonight.actionsTaken.unshift({
      time: 'Just now',
      type: 'haptic',
      title: 'Wrist Haptic Pulses Activated',
      detail: 'Continuous emergency vibration pulses on watch.',
      status: 'Active'
    });
  }

  public static updateTonightResolved(): void {
    const tonight = HistoryRepository.defaultHistory[0];
    tonight.actionsTaken.unshift({
      time: 'Just now',
      type: 'resolve',
      title: 'Assistance Confirmed',
      detail: 'Alarm silenced. Caregiver confirmed bedside presence.',
      status: 'Acknowledged'
    });
  }
}
