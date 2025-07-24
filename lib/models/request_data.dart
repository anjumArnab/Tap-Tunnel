class RequestData {
  final String method;
  final String endpoint;
  final int statusCode;
  final String responseTime;
  final String timeAgo;
  final String? timestamp;
  final String? id;

  RequestData({
    required this.method,
    required this.endpoint,
    required this.statusCode,
    required this.responseTime,
    required this.timeAgo,
    this.timestamp,
    this.id,
  });

  factory RequestData.fromJson(Map<String, dynamic> map) {
    return RequestData(
      method: map['method'] ?? '',
      endpoint: map['endpoint'] ?? '',
      statusCode: map['statusCode'] ?? 0,
      responseTime: map['responseTime'] ?? '',
      timeAgo: map['timeAgo'] ?? '',
      timestamp: map['timestamp'] ?? '',
      id: map['id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'method': method,
      'endpoint': endpoint,
      'statusCode': statusCode,
      'responseTime': responseTime,
      'timeAgo': timeAgo,
      'timestamp': timestamp,
      'id': id,
    };
  }

  RequestData copyWith({
    String? method,
    String? endpoint,
    int? statusCode,
    String? responseTime,
    String? timeAgo,
    String? timestamp,
    String? id,
  }) {
    return RequestData(
      method: method ?? this.method,
      endpoint: endpoint ?? this.endpoint,
      statusCode: statusCode ?? this.statusCode,
      responseTime: responseTime ?? this.responseTime,
      timeAgo: timeAgo ?? this.timeAgo,
      timestamp: timestamp ?? this.timestamp,
      id: id ?? this.id,
    );
  }
}
