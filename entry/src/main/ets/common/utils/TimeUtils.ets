/*
 * Copyright (c) 2026 HypoAlert.
 * Shared time and date formatting utilities.
 */

/**
 * Formats a Date object to HH:mm:ss string.
 */
export function formatLocalTime(d: Date): string {
  const hh: string = d.getHours() < 10 ? `0${d.getHours()}` : `${d.getHours()}`;
  const mm: string = d.getMinutes() < 10 ? `0${d.getMinutes()}` : `${d.getMinutes()}`;
  const ss: string = d.getSeconds() < 10 ? `0${d.getSeconds()}` : `${d.getSeconds()}`;
  return `${hh}:${mm}:${ss}`;
}

/**
 * Formats a Date object to HH:mm string for audit logs and check-ins.
 */
export function formatLogTime(d: Date): string {
  const hh: string = d.getHours() < 10 ? `0${d.getHours()}` : `${d.getHours()}`;
  const mm: string = d.getMinutes() < 10 ? `0${d.getMinutes()}` : `${d.getMinutes()}`;
  return `${hh}:${mm}`;
}

/**
 * Converts a 24-hour "HH:mm" string into 12-hour "H:mm AM/PM" format.
 */
export function format12H(hhmm: string): string {
  const parts: string[] = hhmm.split(':');
  if (parts.length < 2) {
    return hhmm;
  }
  const h: number = parseInt(parts[0]);
  const m: string = parts[1];
  const ampm: string = h >= 12 ? 'PM' : 'AM';
  let h12: number = h % 12;
  if (h12 === 0) {
    h12 = 12;
  }
  return `${h12}:${m} ${ampm}`;
}

/**
 * Formats hour and minute numbers to a 24-hour "HH:mm" string.
 */
export function formatHM(hour: number, minute: number): string {
  const hh: string = hour < 10 ? `0${hour}` : `${hour}`;
  const mm: string = minute < 10 ? `0${minute}` : `${minute}`;
  return `${hh}:${mm}`;
}
