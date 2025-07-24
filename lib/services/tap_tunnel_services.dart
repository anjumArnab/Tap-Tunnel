import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import '../models/connection_status.dart';
import '../models/request_data.dart';
import '../models/traffic_stats.dart';
import '../models/tunnel_preset.dart';
import '../models/active_tunnel.dart';
import '../models/recent_webhook.dart';
import '../models/api_response.dart';

class TapTunnelService {
  String? _baseUrl;
  String? _wsUrl;
  WebSocketChannel? _channel;

  // Stream controllers for real-time updates
  final StreamController<List<ActiveTunnel>> _tunnelsController =
      StreamController<List<ActiveTunnel>>.broadcast();
  final StreamController<RequestData> _requestsController =
      StreamController<RequestData>.broadcast();
  final StreamController<RecentWebhook> _webhooksController =
      StreamController<RecentWebhook>.broadcast();
  final StreamController<ConnectionStatus> _connectionController =
      StreamController<ConnectionStatus>.broadcast();
  final StreamController<TrafficStats> _statsController =
      StreamController<TrafficStats>.broadcast();

  // Stream getters
  Stream<List<ActiveTunnel>> get tunnelsStream => _tunnelsController.stream;
  Stream<RequestData> get requestsStream => _requestsController.stream;
  Stream<RecentWebhook> get webhooksStream => _webhooksController.stream;
  Stream<ConnectionStatus> get connectionStream => _connectionController.stream;
  Stream<TrafficStats> get statsStream => _statsController.stream;

  // Connection state
  ConnectionStatus? _currentConnectionStatus;
  bool _isConnecting = false;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;

  ConnectionStatus? get connectionStatus => _currentConnectionStatus;
  bool get isConnected => _currentConnectionStatus?.isConnected ?? false;
  bool get isConnecting => _isConnecting;

  // Connect to the agent
  Future<bool> connect(String ipAddress, {int port = 3001}) async {
    if (_isConnecting) return false;

    _isConnecting = true;
    _baseUrl = 'http://$ipAddress:$port';
    _wsUrl = 'ws://$ipAddress:$port';

    try {
      // Test HTTP connection first
      final response = await http
          .get(
            Uri.parse('$_baseUrl/health'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final healthData = json.decode(response.body);
        _currentConnectionStatus = ConnectionStatus.fromJson(healthData);

        // Establish WebSocket connection
        await _connectWebSocket();

        _isConnecting = false;
        _connectionController.add(_currentConnectionStatus!);

        // Start heartbeat
        _startHeartbeat();

        return true;
      }
    } catch (e) {
      print('Connection failed: $e');
      _isConnecting = false;
      _currentConnectionStatus = ConnectionStatus(
        isConnected: false,
        deviceName: 'Unknown',
        ipAddress: ipAddress,
        lastSync: DateTime.now().toIso8601String(),
      );
      _connectionController.add(_currentConnectionStatus!);
    }

    return false;
  }

  // WebSocket connection
  Future<void> _connectWebSocket() async {
    try {
      _channel?.sink.close();
      _channel = IOWebSocketChannel.connect(_wsUrl!);

      _channel!.stream.listen(
        (message) => _handleWebSocketMessage(message),
        onError: (error) => _handleWebSocketError(error),
        onDone: () => _handleWebSocketDisconnect(),
      );

      print('WebSocket connected to $_wsUrl');
    } catch (e) {
      print('WebSocket connection failed: $e');
      _scheduleReconnect();
    }
  }

  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = json.decode(message);
      final type = data['type'];
      final payload = data['data'];

      switch (type) {
        case 'connection_status':
          _currentConnectionStatus = ConnectionStatus.fromJson(payload);
          _connectionController.add(_currentConnectionStatus!);
          break;

        case 'tunnels_update':
          final tunnels =
              (payload as List).map((t) => ActiveTunnel.fromJson(t)).toList();
          _tunnelsController.add(tunnels);
          break;

        case 'tunnel_started':
        case 'tunnel_stopped':
          // Fetch latest tunnels
          getTunnels();
          break;

        case 'new_request':
          final request = RequestData.fromJson(payload);
          _requestsController.add(request);
          break;

        case 'webhook_received':
          final webhook = RecentWebhook.fromJson(payload);
          _webhooksController.add(webhook);
          break;

        case 'stats_update':
          final stats = TrafficStats.fromJson(payload);
          _statsController.add(stats);
          break;

        case 'pong':
          // Heartbeat response received
          break;
      }
    } catch (e) {
      print('Error handling WebSocket message: $e');
    }
  }

  void _handleWebSocketError(error) {
    print('WebSocket error: $error');
    _scheduleReconnect();
  }

  void _handleWebSocketDisconnect() {
    print('WebSocket disconnected');
    _currentConnectionStatus =
        _currentConnectionStatus?.copyWith(isConnected: false) ??
        ConnectionStatus(
          isConnected: false,
          deviceName: 'Unknown',
          ipAddress: '',
          lastSync: DateTime.now().toIso8601String(),
        );
    _connectionController.add(_currentConnectionStatus!);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (_baseUrl != null) {
        final uri = Uri.parse(_baseUrl!);
        connect(uri.host, port: uri.port);
      }
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_channel != null) {
        _channel!.sink.add(
          json.encode({
            'type': 'ping',
            'timestamp': DateTime.now().toIso8601String(),
          }),
        );
      }
    });
  }

  // API Methods
  Future<List<ActiveTunnel>?> getTunnels() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/tunnels'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse.fromJson(
          json.decode(response.body),
          null,
        );

        if (apiResponse.success && apiResponse.data != null) {
          final tunnels =
              (apiResponse.data as List)
                  .map((t) => ActiveTunnel.fromJson(t))
                  .toList();
          _tunnelsController.add(tunnels);
          return tunnels;
        }
      }
    } catch (e) {
      print('Error fetching tunnels: $e');
    }
    return null;
  }

  Future<ActiveTunnel?> startTunnel({
    required int port,
    String? name,
    String? subdomain,
    String protocol = 'http',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/tunnels/start'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'port': port,
          'name': name,
          'subdomain': subdomain,
          'protocol': protocol,
        }),
      );

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse.fromJson(
          json.decode(response.body),
          null,
        );

        if (apiResponse.success && apiResponse.data != null) {
          return ActiveTunnel.fromJson(apiResponse.data);
        }
      }
    } catch (e) {
      print('Error starting tunnel: $e');
    }
    return null;
  }

  Future<bool> stopTunnel(String tunnelName) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/tunnels/$tunnelName'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse.fromJson(
          json.decode(response.body),
          null,
        );
        return apiResponse.success;
      }
    } catch (e) {
      print('Error stopping tunnel: $e');
    }
    return false;
  }

  Future<List<RequestData>?> getRequests({int limit = 50}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/requests?limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse.fromJson(
          json.decode(response.body),
          null,
        );

        if (apiResponse.success && apiResponse.data != null) {
          return (apiResponse.data as List)
              .map((r) => RequestData.fromJson(r))
              .toList();
        }
      }
    } catch (e) {
      print('Error fetching requests: $e');
    }
    return null;
  }

  Future<TrafficStats?> getStats() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/stats'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse.fromJson(
          json.decode(response.body),
          null,
        );

        if (apiResponse.success && apiResponse.data != null) {
          final stats = TrafficStats.fromJson(apiResponse.data);
          _statsController.add(stats);
          return stats;
        }
      }
    } catch (e) {
      print('Error fetching stats: $e');
    }
    return null;
  }

  Future<List<RecentWebhook>?> getWebhooks() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/webhooks'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse.fromJson(
          json.decode(response.body),
          null,
        );

        if (apiResponse.success && apiResponse.data != null) {
          return (apiResponse.data as List)
              .map((w) => RecentWebhook.fromJson(w))
              .toList();
        }
      }
    } catch (e) {
      print('Error fetching webhooks: $e');
    }
    return null;
  }

  Future<List<TunnelPreset>?> getPresets() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/presets'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse.fromJson(
          json.decode(response.body),
          null,
        );

        if (apiResponse.success && apiResponse.data != null) {
          return (apiResponse.data as List)
              .map((p) => TunnelPreset.fromJson(p))
              .toList();
        }
      }
    } catch (e) {
      print('Error fetching presets: $e');
    }
    return null;
  }

  Future<TunnelPreset?> createPreset(TunnelPreset preset) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/presets'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(preset.toJson()),
      );

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse.fromJson(
          json.decode(response.body),
          null,
        );

        if (apiResponse.success && apiResponse.data != null) {
          return TunnelPreset.fromJson(apiResponse.data);
        }
      }
    } catch (e) {
      print('Error creating preset: $e');
    }
    return null;
  }

  Future<ActiveTunnel?> startTunnelFromPreset(String presetId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/presets/$presetId/start'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse.fromJson(
          json.decode(response.body),
          null,
        );

        if (apiResponse.success && apiResponse.data != null) {
          return ActiveTunnel.fromJson(apiResponse.data);
        }
      }
    } catch (e) {
      print('Error starting tunnel from preset: $e');
    }
    return null;
  }

  // Cleanup
  void dispose() {
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _channel?.sink.close();
    _tunnelsController.close();
    _requestsController.close();
    _webhooksController.close();
    _connectionController.close();
    _statsController.close();
  }
}

// Extension to help with connection status updates
extension ConnectionStatusExtension on ConnectionStatus {
  ConnectionStatus copyWith({
    bool? isConnected,
    String? deviceName,
    String? ipAddress,
    String? lastSync,
  }) {
    return ConnectionStatus(
      isConnected: isConnected ?? this.isConnected,
      deviceName: deviceName ?? this.deviceName,
      ipAddress: ipAddress ?? this.ipAddress,
      lastSync: lastSync ?? this.lastSync,
    );
  }
}
