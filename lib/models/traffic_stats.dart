class TrafficStats {
  final int totalRequests;
  final String avgResponseTime;
  final String improvementPercentage;

  TrafficStats({
    required this.totalRequests,
    required this.avgResponseTime,
    required this.improvementPercentage,
  });

  factory TrafficStats.fromJson(Map<String, dynamic> map) {
    return TrafficStats(
      totalRequests: map['totalRequests'] ?? 0,
      avgResponseTime: map['avgResponseTime'] ?? '0ms',
      improvementPercentage: map['improvementPercentage'] ?? '+0%',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalRequests': totalRequests,
      'avgResponseTime': avgResponseTime,
      'improvementPercentage': improvementPercentage,
    };
  }

  TrafficStats copyWith({
    int? totalRequests,
    String? avgResponseTime,
    String? improvementPercentage,
  }) {
    return TrafficStats(
      totalRequests: totalRequests ?? this.totalRequests,
      avgResponseTime: avgResponseTime ?? this.avgResponseTime,
      improvementPercentage:
          improvementPercentage ?? this.improvementPercentage,
    );
  }
}
