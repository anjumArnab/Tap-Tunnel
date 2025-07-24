import 'package:flutter/material.dart';

class TunnelPreset {
  final String id;
  final String name;
  final String description;
  final int port;
  final bool isHotReloadEnabled;
  final Color accentColor;
  final String? protocol;
  final String? createdAt;

  TunnelPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.port,
    required this.isHotReloadEnabled,
    required this.accentColor,
    this.protocol,
    this.createdAt,
  });

  factory TunnelPreset.fromJson(Map<String, dynamic> map) {
    return TunnelPreset(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      port: map['port'] ?? 0,
      isHotReloadEnabled: map['isHotReloadEnabled'] ?? false,
      accentColor: _parseColor(map['accentColor'] ?? '#4CAF50'),
      protocol: map['protocol'],
      createdAt: map['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'port': port,
      'isHotReloadEnabled': isHotReloadEnabled,
      'accentColor': _colorToHex(accentColor),
      'protocol': protocol,
      'createdAt': createdAt,
    };
  }

  TunnelPreset copyWith({
    String? id,
    String? name,
    String? description,
    int? port,
    bool? isHotReloadEnabled,
    Color? accentColor,
    String? protocol,
    String? createdAt,
  }) {
    return TunnelPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      port: port ?? this.port,
      isHotReloadEnabled: isHotReloadEnabled ?? this.isHotReloadEnabled,
      accentColor: accentColor ?? this.accentColor,
      protocol: protocol ?? this.protocol,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static Color _parseColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  static String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }
}
