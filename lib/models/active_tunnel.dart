import 'package:flutter/material.dart';

class ActiveTunnel {
  final String tunnelName;
  final String tunnelUrl;
  final int tunnelPort;
  final int requests;
  final bool isActive;

  const ActiveTunnel({
    required this.tunnelName,
    required this.tunnelUrl,
    required this.tunnelPort,
    required this.requests,
    this.isActive = true,
  });

  factory ActiveTunnel.fromMap(Map<String, dynamic> map) {
    return ActiveTunnel(
      tunnelName: map['tunnelName'] ?? '',
      tunnelUrl: map['tunnelUrl'] ?? '',
      tunnelPort: map['tunnelPort'] ?? 0,
      requests: map['requests'] ?? 0,
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tunnelName': tunnelName,
      'tunnelUrl': tunnelUrl,
      'tunnelPort': tunnelPort,
      'requests': requests,
      'isActive': isActive,
    };
  }

  ActiveTunnel copyWith({
    String? tunnelName,
    String? tunnelUrl,
    int? tunnelPort,
    int? requests,
    bool? isActive,
  }) {
    return ActiveTunnel(
      tunnelName: tunnelName ?? this.tunnelName,
      tunnelUrl: tunnelUrl ?? this.tunnelUrl,
      tunnelPort: tunnelPort ?? this.tunnelPort,
      requests: requests ?? this.requests,
      isActive: isActive ?? this.isActive,
    );
  }

  Color get statusColor {
    if (!isActive) return const Color(0xFF9CA3AF);
    if (requests == 0) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  String get requestsText {
    if (requests == 0) return 'Idle';
    return '$requests requests';
  }

  @override
  String toString() {
    return 'ActiveTunnel(tunnelName: $tunnelName, tunnelUrl: $tunnelUrl, tunnelPort: $tunnelPort, requests: $requests, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ActiveTunnel &&
        other.tunnelName == tunnelName &&
        other.tunnelUrl == tunnelUrl &&
        other.tunnelPort == tunnelPort &&
        other.requests == requests &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return tunnelName.hashCode ^
        tunnelUrl.hashCode ^
        tunnelPort.hashCode ^
        requests.hashCode ^
        isActive.hashCode;
  }
}
