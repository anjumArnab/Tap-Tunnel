class RequestData {
  final String method;
  final String endpoint;
  final int statusCode;
  final String responseTime;
  final String timeAgo;

  RequestData({
    required this.method,
    required this.endpoint,
    required this.statusCode,
    required this.responseTime,
    required this.timeAgo,
  });
}

class TrafficStats {
  final int totalRequests;
  final String avgResponseTime;
  final String improvementPercentage;

  TrafficStats({
    required this.totalRequests,
    required this.avgResponseTime,
    required this.improvementPercentage,
  });
}

class ChartData {
  final String time;
  final double value;

  ChartData({required this.time, required this.value});
}
