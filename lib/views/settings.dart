import 'package:flutter/material.dart';
import '../models/connection_status.dart';
import '../models/tunnel_preset.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  ConnectionStatus getConnectionStatus() {
    return ConnectionStatus(
      isConnected: true,
      deviceName: "MacBook Pro",
      ipAddress: "192.168.1.100",
      lastSync:
          DateTime.now().subtract(const Duration(minutes: 2)).toIso8601String(),
    );
  }

  List<TunnelPreset> getTunnelPresets() {
    return [
      TunnelPreset(
        id: "react",
        name: "React Development",
        description: "Port 3000, hot reload enabled",
        port: 3000,
        isHotReloadEnabled: true,
        accentColor: Colors.blue,
      ),
      TunnelPreset(
        id: "api",
        name: "API Server",
        description: "",
        port: 8000,
        isHotReloadEnabled: false,
        accentColor: Colors.green,
      ),
    ];
  }

  Future<void> disconnectFromDevice() async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> connectToDevice() async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 1000));
  }
}

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final SettingsService _settingsService = SettingsService();
  late ConnectionStatus _connectionStatus;
  late List<TunnelPreset> _tunnelPresets;
  bool _isLoading = false;
  final int _selectedNavIndex = 3;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _connectionStatus = _settingsService.getConnectionStatus();
    _tunnelPresets = _settingsService.getTunnelPresets();
  }

  Future<void> _toggleConnection() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_connectionStatus.isConnected) {
        await _settingsService.disconnectFromDevice();
      } else {
        await _settingsService.connectToDevice();
      }

      // Reload connection status
      _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _connectionStatus.isConnected
                ? 'Disconnected successfully'
                : 'Connected successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getTimeAgo(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final difference = DateTime.now().difference(dateTime);
      if (difference.inMinutes < 60) {
        return '${difference.inMinutes} minutes ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hours ago';
      } else {
        return '${difference.inDays} days ago';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  void _onNavItemPressed(int index) {
    switch (index) {
      case 0: // HOME

        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        break;
      case 1: // MONITOR
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/monitor',
          (route) => false,
        );
        break;
      case 2: // WEBHOOKS
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/webhooks',
          (route) => false,
        );
        break;
      case 3: // SETTINGS
        // Already on settings page
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Tunnel Configuration',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        toolbarHeight: 80,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConnectionSection(),
            const SizedBox(height: 20),
            _buildTunnelPresetsSection(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildConnectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Connection',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color:
                          _connectionStatus.isConnected
                              ? Colors.green
                              : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _connectionStatus.isConnected
                              ? 'Connected to ${_connectionStatus.deviceName}'
                              : 'Disconnected',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        if (_connectionStatus.isConnected) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${_connectionStatus.deviceName} • ${_connectionStatus.ipAddress}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          Text(
                            'Last sync: ${_getTimeAgo(_connectionStatus.lastSync)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (_isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF6366F1),
                        ),
                      ),
                    )
                  else
                    TextButton(
                      onPressed: _toggleConnection,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        backgroundColor:
                            _connectionStatus.isConnected
                                ? Colors.red.withOpacity(0.1)
                                : Colors.green.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: BorderSide(
                            color:
                                _connectionStatus.isConnected
                                    ? Colors.red
                                    : Colors.green,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Text(
                        _connectionStatus.isConnected
                            ? 'DISCONNECT'
                            : 'CONNECT',
                        style: TextStyle(
                          color:
                              _connectionStatus.isConnected
                                  ? Colors.red
                                  : Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTunnelPresetsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tunnel Presets',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        ..._tunnelPresets.map((preset) => _buildTunnelPresetCard(preset)),
      ],
    );
  }

  Widget _buildTunnelPresetCard(TunnelPreset preset) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: preset.accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            preset.id.toUpperCase(),
            style: TextStyle(
              color: preset.accentColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        title: Text(
          preset.name,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
        subtitle:
            preset.description.isNotEmpty
                ? Text(
                  preset.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                )
                : null,
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Color(0xFF9CA3AF),
          size: 16,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    final navItems = ['HOME', 'MONITOR', 'WEBHOOKS', 'SETTINGS'];

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _selectedNavIndex,
      onTap: _onNavItemPressed,
      selectedItemColor: const Color(0xFF6366F1),
      unselectedItemColor: const Color(0xFF9CA3AF),
      backgroundColor: Colors.white,
      elevation: 10,
      items:
          navItems
              .map(
                (label) => BottomNavigationBarItem(
                  icon: const SizedBox.shrink(), // Empty icon
                  label: label,
                ),
              )
              .toList(),
    );
  }
}
