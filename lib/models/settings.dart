import 'package:flutter/material.dart';

class ConnectionStatus {
  final bool isConnected;
  final String deviceName;
  final String ipAddress;
  final DateTime lastSync;

  ConnectionStatus({
    required this.isConnected,
    required this.deviceName,
    required this.ipAddress,
    required this.lastSync,
  });
}

class TunnelPreset {
  final String id;
  final String name;
  final String description;
  final int port;
  final bool isHotReloadEnabled;
  final Color accentColor;

  TunnelPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.port,
    required this.isHotReloadEnabled,
    required this.accentColor,
  });
}
