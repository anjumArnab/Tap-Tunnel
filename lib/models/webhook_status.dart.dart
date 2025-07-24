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
}
