/*
 * Copyright (c) 2026 HypoAlert.
 * Cross-device demo connection and state manager.
 */

export interface ConnectionState {
  isConnected: boolean;
  deviceName: string;
  batteryLevel: number;
  signalStrength: string;
  lastSyncTime: string;
  packetsPerSec: number;
}

export type ConnectionListener = (state: ConnectionState) => void;

export class DeviceConnectionManager {
  private static instance: DeviceConnectionManager | null = null;
  private state: ConnectionState = {
    isConnected: true,
    deviceName: 'HUAWEI WATCH 4 Pro',
    batteryLevel: 86,
    signalStrength: '-52 dBm',
    lastSyncTime: 'Just now',
    packetsPerSec: 10
  };
  private listeners: ConnectionListener[] = [];

  public static getInstance(): DeviceConnectionManager {
    if (!DeviceConnectionManager.instance) {
      DeviceConnectionManager.instance = new DeviceConnectionManager();
    }
    return DeviceConnectionManager.instance;
  }

  public getState(): ConnectionState {
    return this.state;
  }

  public isConnected(): boolean {
    return this.state.isConnected;
  }

  public setConnected(connected: boolean): void {
    this.state.isConnected = connected;
    this.state.lastSyncTime = connected ? 'Just now' : 'Disconnected';
    this.notifyListeners();
  }

  public toggleConnection(): boolean {
    this.setConnected(!this.state.isConnected);
    return this.state.isConnected;
  }

  public setBattery(battery: number): void {
    this.state.batteryLevel = battery;
    this.notifyListeners();
  }

  public addListener(listener: ConnectionListener): void {
    if (this.listeners.indexOf(listener) === -1) {
      this.listeners.push(listener);
    }
  }

  public removeListener(listener: ConnectionListener): void {
    const idx = this.listeners.indexOf(listener);
    if (idx !== -1) {
      this.listeners.splice(idx, 1);
    }
  }

  private notifyListeners(): void {
    const s: ConnectionState = {
      isConnected: this.state.isConnected,
      deviceName: this.state.deviceName,
      batteryLevel: this.state.batteryLevel,
      signalStrength: this.state.signalStrength,
      lastSyncTime: this.state.lastSyncTime,
      packetsPerSec: this.state.packetsPerSec
    };
    for (let i = 0; i < this.listeners.length; i++) {
      this.listeners[i](s);
    }
  }
}
