/*
 * Copyright (c) 2026 HypoAlert.
 * Wearable utility functions and range generators for watch picker and time math.
 */

export function hourRange(): string[] {
  const r: string[] = [];
  for (let h: number = 1; h <= 12; h++) {
    r.push(`${h}`);
  }
  return r;
}

export function minuteRange(): string[] {
  const r: string[] = [];
  for (let m: number = 0; m < 60; m++) {
    r.push(m < 10 ? `0${m}` : `${m}`);
  }
  return r;
}

export function parseTimeToDate(timeStr: string): Date {
  const d: Date = new Date();
  const parts: string[] = timeStr.split(':');
  if (parts.length > 0) {
    d.setHours(parseInt(parts[0]));
  }
  if (parts.length > 1) {
    d.setMinutes(parseInt(parts[1]));
  }
  d.setSeconds(0);
  return d;
}
