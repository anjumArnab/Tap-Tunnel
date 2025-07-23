import 'package:flutter/material.dart';

class WebhookStatus {
  final String status;
  final String description;
  final String url;
  final bool isListening;

  const WebhookStatus({
    required this.status,
    required this.description,
    required this.url,
    this.isListening = true,
  });

  factory WebhookStatus.fromMap(Map<String, dynamic> map) {
    return WebhookStatus(
      status: map['status'] ?? '',
      description: map['description'] ?? '',
      url: map['url'] ?? '',
      isListening: map['isListening'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'description': description,
      'url': url,
      'isListening': isListening,
    };
  }

  WebhookStatus copyWith({
    String? status,
    String? description,
    String? url,
    bool? isListening,
  }) {
    return WebhookStatus(
      status: status ?? this.status,
      description: description ?? this.description,
      url: url ?? this.url,
      isListening: isListening ?? this.isListening,
    );
  }

  Color get statusColor {
    return isListening ? const Color(0xFF10B981) : const Color(0xFFEF4444);
  }

  @override
  String toString() {
    return 'WebhookStatus(status: $status, description: $description, url: $url, isListening: $isListening)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WebhookStatus &&
        other.status == status &&
        other.description == description &&
        other.url == url &&
        other.isListening == isListening;
  }

  @override
  int get hashCode {
    return status.hashCode ^
        description.hashCode ^
        url.hashCode ^
        isListening.hashCode;
  }
}

// Data Model for Recent Webhook
class RecentWebhook {
  final String service;
  final String event;
  final String amount;
  final String customerId;
  final DateTime timestamp;
  final WebhookEventStatus status;
  final String details;

  const RecentWebhook({
    required this.service,
    required this.event,
    required this.amount,
    required this.customerId,
    required this.timestamp,
    required this.status,
    required this.details,
  });

  factory RecentWebhook.fromMap(Map<String, dynamic> map) {
    return RecentWebhook(
      service: map['service'] ?? '',
      event: map['event'] ?? '',
      amount: map['amount'] ?? '',
      customerId: map['customerId'] ?? '',
      timestamp: DateTime.parse(
        map['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      status: WebhookEventStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => WebhookEventStatus.processed,
      ),
      details: map['details'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'service': service,
      'event': event,
      'amount': amount,
      'customerId': customerId,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'details': details,
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
  }) {
    return RecentWebhook(
      service: service ?? this.service,
      event: event ?? this.event,
      amount: amount ?? this.amount,
      customerId: customerId ?? this.customerId,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      details: details ?? this.details,
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

  @override
  String toString() {
    return 'RecentWebhook(service: $service, event: $event, amount: $amount, customerId: $customerId, timestamp: $timestamp, status: $status, details: $details)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecentWebhook &&
        other.service == service &&
        other.event == event &&
        other.amount == amount &&
        other.customerId == customerId &&
        other.timestamp == timestamp &&
        other.status == status &&
        other.details == details;
  }

  @override
  int get hashCode {
    return service.hashCode ^
        event.hashCode ^
        amount.hashCode ^
        customerId.hashCode ^
        timestamp.hashCode ^
        status.hashCode ^
        details.hashCode;
  }
}

enum WebhookEventStatus { processed, failed, triggered }
