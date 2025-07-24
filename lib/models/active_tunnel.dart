import 'package:flutter/material.dart';

class ActiveTunnel {
  final String tunnelName;
  final String tunnelUrl;
  final int tunnelPort;
  final int requests;
  final bool isActive;
  final String? protocol;
  final String? createdAt;
  final Map<String, dynamic>? metrics;

  const ActiveTunnel({
    required this.tunnelName,
    required this.tunnelUrl,
    required this.tunnelPort,
    required this.requests,
    this.isActive = true,
    this.protocol,
    this.createdAt,
    this.metrics,
  });

  factory ActiveTunnel.fromJson(Map<String, dynamic> map) {
    return ActiveTunnel(
      tunnelName: map['tunnelName'] ?? '',
      tunnelUrl: map['tunnelUrl'] ?? '',
      tunnelPort: map['tunnelPort'] ?? 0,
      requests: map['requests'] ?? 0,
      isActive: map['isActive'] ?? true,
      protocol: map['protocol'],
      createdAt: map['createdAt'],
      metrics: map['metrics'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tunnelName': tunnelName,
      'tunnelUrl': tunnelUrl,
      'tunnelPort': tunnelPort,
      'requests': requests,
      'isActive': isActive,
      'protocol': protocol,
      'createdAt': createdAt,
      'metrics': metrics,
    };
  }

  ActiveTunnel copyWith({
    String? tunnelName,
    String? tunnelUrl,
    int? tunnelPort,
    int? requests,
    bool? isActive,
    String? protocol,
    String? createdAt,
    Map<String, dynamic>? metrics,
  }) {
    return ActiveTunnel(
      tunnelName: tunnelName ?? this.tunnelName,
      tunnelUrl: tunnelUrl ?? this.tunnelUrl,
      tunnelPort: tunnelPort ?? this.tunnelPort,
      requests: requests ?? this.requests,
      isActive: isActive ?? this.isActive,
      protocol: protocol ?? this.protocol,
      createdAt: createdAt ?? this.createdAt,
      metrics: metrics ?? this.metrics,
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
}
