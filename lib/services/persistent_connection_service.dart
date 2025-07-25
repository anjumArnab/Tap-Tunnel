import 'dart:async';
import 'tap_tunnel_services.dart';
import '../models/connection_status.dart';
import '../models/tunnel_preset.dart';
import '../models/active_tunnel.dart';
import '../models/request_data.dart';
import '../models/recent_webhook.dart';
import '../models/traffic_stats.dart';

class PersistentConnectionService {
  // Singleton instance
  static final PersistentConnectionService _instance =
      PersistentConnectionService._internal();

  factory PersistentConnectionService() {
    return _instance;
  }

  PersistentConnectionService._internal();

  // The actual tunnel service instance
  TapTunnelService? _tunnelService;

  // Connection state
  bool _isInitialized = false;
  String? _lastConnectedIP;
  int? _lastConnectedPort;

  // Stream controllers for broadcasting to all pages
  final StreamController<ConnectionStatus> _globalConnectionController =
      StreamController<ConnectionStatus>.broadcast();
  final StreamController<List<ActiveTunnel>> _globalTunnelsController =
      StreamController<List<ActiveTunnel>>.broadcast();
  final StreamController<RequestData> _globalRequestsController =
      StreamController<RequestData>.broadcast();
  final StreamController<RecentWebhook> _globalWebhooksController =
      StreamController<RecentWebhook>.broadcast();
  final StreamController<TrafficStats> _globalStatsController =
      StreamController<TrafficStats>.broadcast();

  // Stream subscriptions to forward data from tunnel service
  StreamSubscription<ConnectionStatus>? _connectionSubscription;
  StreamSubscription<List<ActiveTunnel>>? _tunnelsSubscription;
  StreamSubscription<RequestData>? _requestsSubscription;
  StreamSubscription<RecentWebhook>? _webhooksSubscription;
  StreamSubscription<TrafficStats>? _statsSubscription;

  // Public stream getters
  Stream<ConnectionStatus> get connectionStream =>
      _globalConnectionController.stream;
  Stream<List<ActiveTunnel>> get tunnelsStream =>
      _globalTunnelsController.stream;
  Stream<RequestData> get requestsStream => _globalRequestsController.stream;
  Stream<RecentWebhook> get webhooksStream => _globalWebhooksController.stream;
  Stream<TrafficStats> get statsStream => _globalStatsController.stream;

  // Getters for current state
  ConnectionStatus? get connectionStatus => _tunnelService?.connectionStatus;
  bool get isConnected => _tunnelService?.isConnected ?? false;
  bool get isConnecting => _tunnelService?.isConnecting ?? false;
  bool get isInitialized => _isInitialized;

  // Initialize the service (call this in main.dart or app startup)
  Future<void> initialize() async {
    if (_isInitialized) return;

    _tunnelService = TapTunnelService();
    _setupStreamForwarding();
    _isInitialized = true;

    // Try to reconnect to last known connection if available
    if (_lastConnectedIP != null && _lastConnectedPort != null) {
      await connect(_lastConnectedIP!, port: _lastConnectedPort!);
    }
  }

  // Setup stream forwarding from tunnel service to global streams
  void _setupStreamForwarding() {
    if (_tunnelService == null) return;

    // Forward connection status
    _connectionSubscription?.cancel();
    _connectionSubscription = _tunnelService!.connectionStream.listen(
      (status) => _globalConnectionController.add(status),
      onError: (error) => print('Connection stream error: $error'),
    );

    // Forward tunnels updates
    _tunnelsSubscription?.cancel();
    _tunnelsSubscription = _tunnelService!.tunnelsStream.listen(
      (tunnels) => _globalTunnelsController.add(tunnels),
      onError: (error) => print('Tunnels stream error: $error'),
    );

    // Forward requests
    _requestsSubscription?.cancel();
    _requestsSubscription = _tunnelService!.requestsStream.listen(
      (request) => _globalRequestsController.add(request),
      onError: (error) => print('Requests stream error: $error'),
    );

    // Forward webhooks
    _webhooksSubscription?.cancel();
    _webhooksSubscription = _tunnelService!.webhooksStream.listen(
      (webhook) => _globalWebhooksController.add(webhook),
      onError: (error) => print('Webhooks stream error: $error'),
    );

    // Forward stats
    _statsSubscription?.cancel();
    _statsSubscription = _tunnelService!.statsStream.listen(
      (stats) => _globalStatsController.add(stats),
      onError: (error) => print('Stats stream error: $error'),
    );
  }

  // Connect to the agent
  Future<bool> connect(String ipAddress, {int port = 3001}) async {
    if (!_isInitialized) {
      await initialize();
    }

    final success = await _tunnelService!.connect(ipAddress, port: port);

    if (success) {
      _lastConnectedIP = ipAddress;
      _lastConnectedPort = port;
    }

    return success;
  }

  // Disconnect from the agent
  Future<void> disconnect() async {
    if (_tunnelService != null) {
      _tunnelService!.dispose();
      _tunnelService = TapTunnelService();
      _setupStreamForwarding();
    }

    _lastConnectedIP = null;
    _lastConnectedPort = null;
  }

  // Delegate all other methods to the tunnel service
  Future<List<ActiveTunnel>?> getTunnels() async {
    return _tunnelService?.getTunnels();
  }

  Future<ActiveTunnel?> startTunnel({
    required int port,
    String? name,
    String? subdomain,
    String protocol = 'http',
  }) async {
    return _tunnelService?.startTunnel(
      port: port,
      name: name,
      subdomain: subdomain,
      protocol: protocol,
    );
  }

  Future<bool> stopTunnel(String tunnelName) async {
    return _tunnelService?.stopTunnel(tunnelName) ?? false;
  }

  Future<List<RequestData>?> getRequests({int limit = 50}) async {
    return _tunnelService?.getRequests(limit: limit);
  }

  Future<TrafficStats?> getStats() async {
    return _tunnelService?.getStats();
  }

  Future<List<RecentWebhook>?> getWebhooks() async {
    return _tunnelService?.getWebhooks();
  }

  Future<List<TunnelPreset>?> getPresets() async {
    return _tunnelService?.getPresets();
  }

  Future<TunnelPreset?> createPreset(TunnelPreset preset) async {
    return _tunnelService?.createPreset(preset);
  }

  Future<ActiveTunnel?> startTunnelFromPreset(String presetId) async {
    return _tunnelService?.startTunnelFromPreset(presetId);
  }

  // Cleanup method (call this when app is being destroyed)
  void dispose() {
    _connectionSubscription?.cancel();
    _tunnelsSubscription?.cancel();
    _requestsSubscription?.cancel();
    _webhooksSubscription?.cancel();
    _statsSubscription?.cancel();

    _globalConnectionController.close();
    _globalTunnelsController.close();
    _globalRequestsController.close();
    _globalWebhooksController.close();
    _globalStatsController.close();

    _tunnelService?.dispose();
    _isInitialized = false;
  }
}
