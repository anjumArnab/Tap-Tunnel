class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final String? message;
  final int? count;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.message,
    this.count,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      data:
          json['data'] != null && fromJsonT != null
              ? fromJsonT(json['data'])
              : json['data'],
      error: json['error'],
      message: json['message'],
      count: json['count'],
    );
  }
}
