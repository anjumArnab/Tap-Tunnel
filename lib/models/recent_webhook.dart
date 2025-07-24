import 'dart:convert';
import 'package:flutter/material.dart';

enum WebhookEventStatus { processed, failed, triggered }

class RecentWebhook {
  final String service;
  final String event;
  final String? amount;
  final String? customerId;
  final DateTime timestamp;
  final WebhookEventStatus status;
  final String details;
  final String? repository;
  final String? action;
  final String? channel;
  final String? user;

  const RecentWebhook({
    required this.service,
    required this.event,
    required this.amount,
    required this.customerId,
    required this.timestamp,
    required this.status,
    required this.details,
    this.repository,
    this.action,
    this.channel,
    this.user,
  });

  factory RecentWebhook.fromJson(Map<String, dynamic> map) {
    return RecentWebhook(
      service: map['service'] ?? '',
      event: map['event'] ?? '',
      amount: map['amount'],
      customerId: map['customerId'],
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      status: WebhookEventStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => WebhookEventStatus.processed,
      ),
      details:
          map['details'] is String
              ? map['details']
              : jsonEncode(map['details'] ?? {}),
      repository: map['repository'],
      action: map['action'],
      channel: map['channel'],
      user: map['user'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'service': service,
      'event': event,
      'amount': amount,
      'customerId': customerId,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'details': details,
      'repository': repository,
      'action': action,
      'channel': channel,
      'user': user,
    };
  }

  RecentWebhook copyWith({
    String? service,
    String? event,
    String? amount,
    String? customerId,
    DateTime? timestamp,
    WebhookEventStatus? status,
    String? details,
    String? repository,
    String? action,
    String? channel,
    String? user,
  }) {
    return RecentWebhook(
      service: service ?? this.service,
      event: event ?? this.event,
      amount: amount ?? this.amount,
      customerId: customerId ?? this.customerId,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      details: details ?? this.details,
      repository: repository ?? this.repository,
      action: action ?? this.action,
      channel: channel ?? this.channel,
      user: user ?? this.user,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  Color get serviceColor {
    switch (service.toLowerCase()) {
      case 'stripe':
        return const Color(0xFF635BFF);
      case 'github':
        return const Color(0xFF24292E);
      case 'slack':
        return const Color(0xFF4A154B);
      default:
        return const Color(0xFF6366F1);
    }
  }

  Color get statusColor {
    switch (status) {
      case WebhookEventStatus.processed:
        return const Color(0xFF10B981);
      case WebhookEventStatus.failed:
        return const Color(0xFFEF4444);
      case WebhookEventStatus.triggered:
        return const Color(0xFF3B82F6);
    }
  }

  String get statusText {
    switch (status) {
      case WebhookEventStatus.processed:
        return 'Processed';
      case WebhookEventStatus.failed:
        return 'Failed';
      case WebhookEventStatus.triggered:
        return 'Build triggered';
    }
  }
}
