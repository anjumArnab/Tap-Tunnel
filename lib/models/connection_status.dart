class ConnectionStatus {
  final bool isConnected;
  final String deviceName;
  final String ipAddress;
  final String lastSync;

  ConnectionStatus({
    required this.isConnected,
    required this.deviceName,
    required this.ipAddress,
    required this.lastSync,
  });

  factory ConnectionStatus.fromJson(Map<String, dynamic> json) {
    return ConnectionStatus(
      isConnected: json['isConnected'] ?? false,
      deviceName: json['deviceName'] ?? '',
      ipAddress: json['ipAddress'] ?? '',
      lastSync: json['lastSync'] ?? '',
    );
  }
}
