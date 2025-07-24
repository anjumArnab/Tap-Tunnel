class ChartData {
  final String time;
  final double value;

  ChartData({required this.time, required this.value});

  factory ChartData.fromMap(Map<String, dynamic> map) {
    return ChartData(time: map['time'] ?? '', value: map['value'] ?? 0);
  }

  Map<String, dynamic> toMap() {
    return {'time': time, 'value': value};
  }

  ChartData copyWith({String? time, num? value}) {
    return ChartData(
      time: time ?? this.time,
      value: value != null ? value.toDouble() : this.value,
    );
  }

  @override
  String toString() {
    return 'ChartData(time: $time, value: $value)';
  }
}
