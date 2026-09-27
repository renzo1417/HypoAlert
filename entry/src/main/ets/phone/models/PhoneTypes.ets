/*
 * Copyright (c) 2026 HypoAlert.
 * Type definitions and interfaces for the Phone Companion module.
 */

export interface AuditEntry {
  time: string;
  message: string;
  level: string; // 'ok' | 'warn' | 'crit' | 'info'
}

export interface TremorBand {
  label: string;
  range: string;
  power: number;
  color: string;
}

export interface OvernightPoint {
  hour: string;
  value: number;
}
