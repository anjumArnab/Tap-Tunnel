import 'package:flutter/material.dart';
import 'dart:async';
import '../models/connection_status.dart';
import '../models/tunnel_preset.dart';
import '../models/active_tunnel.dart';
import '../services/tap_tunnel_services.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final TapTunnelService _tunnelService = TapTunnelService();
  ConnectionStatus? _connectionStatus;
  List<TunnelPreset> _tunnelPresets = [];
  bool _isLoading = false;
  bool _isConnecting = false;
  String? _errorMessage;
  final int _selectedNavIndex = 3;

  // Controllers for connection form
  final TextEditingController _ipController = TextEditingController(
    text: '192.168.1.100',
  );
  final TextEditingController _portController = TextEditingController(
    text: '3001',
  );

  // Stream subscriptions
  StreamSubscription<ConnectionStatus>? _connectionSubscription;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _tunnelService.dispose();
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _initializeService() async {
    // Setup connection stream listener
    _connectionSubscription = _tunnelService.connectionStream.listen(
      (status) {
        setState(() {
          _connectionStatus = status;
          _isConnecting = false;
        });
      },
      onError: (error) {
        print('Connection stream error: $error');
        setState(() {
          _isConnecting = false;
        });
      },
    );

    // Try to get current connection status
    _connectionStatus = _tunnelService.connectionStatus;

    // Load presets if connected
    if (_connectionStatus?.isConnected == true) {
      await _loadPresets();
    }
  }

  Future<void> _loadPresets() async {
    try {
      final presets = await _tunnelService.getPresets();
      if (presets != null) {
        setState(() {
          _tunnelPresets = presets;
        });
      }
    } catch (e) {
      print('Error loading presets: $e');
      // Use default presets if API fails
      _setDefaultPresets();
    }
  }

  void _setDefaultPresets() {
    setState(() {
      _tunnelPresets = [
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
          description: "Port 8000, production API",
          port: 8000,
          isHotReloadEnabled: false,
          accentColor: Colors.green,
        ),
        TunnelPreset(
          id: "nextjs",
          name: "Next.js App",
          description: "Port 3000, full-stack development",
          port: 3000,
          isHotReloadEnabled: true,
          accentColor: Colors.purple,
        ),
      ];
    });
  }

  Future<void> _toggleConnection() async {
    if (_isConnecting) return;

    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      if (_connectionStatus?.isConnected == true) {
        // Disconnect (there's no explicit disconnect method, so we'll just dispose)
        _tunnelService.dispose();
        setState(() {
          _connectionStatus = null;
          _tunnelPresets = [];
          _isConnecting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Disconnected successfully'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        // Connect
        final ip = _ipController.text.trim();
        final port = int.tryParse(_portController.text.trim()) ?? 3001;

        if (ip.isEmpty) {
          throw Exception('IP address is required');
        }

        final connected = await _tunnelService.connect(ip, port: port);

        if (connected) {
          await _loadPresets();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connected successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception('Failed to connect to Tap Tunnel Agent');
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isConnecting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _startTunnelFromPreset(TunnelPreset preset) async {
    try {
      setState(() {
        _isLoading = true;
      });

      ActiveTunnel? tunnel;

      // Try to start from preset first, fallback to manual creation
      try {
        tunnel = await _tunnelService.startTunnelFromPreset(preset.id);
      } catch (e) {
        // Fallback to manual tunnel creation
        tunnel = await _tunnelService.startTunnel(
          port: preset.port,
          name: preset.name,
          protocol: preset.protocol ?? 'http',
        );
      }

      if (tunnel != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Started tunnel: ${preset.name}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to start tunnel');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start tunnel: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showCreatePresetDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final portController = TextEditingController();
    bool isHotReloadEnabled = false;
    Color selectedColor = Colors.blue;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Create Tunnel Preset'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Preset Name',
                        hintText: 'e.g., React Dev Server',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Optional description',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: portController,
                      decoration: const InputDecoration(
                        labelText: 'Port',
                        hintText: 'e.g., 3000',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('Enable Hot Reload'),
                      value: isHotReloadEnabled,
                      onChanged: (value) {
                        setDialogState(() {
                          isHotReloadEnabled = value ?? false;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Accent Color:'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children:
                          [
                            Colors.blue,
                            Colors.green,
                            Colors.purple,
                            Colors.orange,
                            Colors.red,
                            Colors.teal,
                          ].map((color) {
                            return GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  selectedColor = color;
                                });
                              },
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border:
                                      selectedColor == color
                                          ? Border.all(
                                            color: Colors.black,
                                            width: 2,
                                          )
                                          : null,
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final port = int.tryParse(portController.text.trim());

                    if (name.isNotEmpty && port != null) {
                      Navigator.of(context).pop();
                      await _createPreset(
                        name: name,
                        description: descriptionController.text.trim(),
                        port: port,
                        isHotReloadEnabled: isHotReloadEnabled,
                        accentColor: selectedColor,
                      );
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _createPreset({
    required String name,
    required String description,
    required int port,
    required bool isHotReloadEnabled,
    required Color accentColor,
  }) async {
    try {
      final preset = TunnelPreset(
        id: name.toLowerCase().replaceAll(' ', '_'),
        name: name,
        description: description,
        port: port,
        isHotReloadEnabled: isHotReloadEnabled,
        accentColor: accentColor,
      );

      final createdPreset = await _tunnelService.createPreset(preset);

      if (createdPreset != null) {
        setState(() {
          _tunnelPresets.add(createdPreset);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Preset "$name" created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Add locally if API fails
        setState(() {
          _tunnelPresets.add(preset);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Preset "$name" created locally'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create preset: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
              _connectionStatus?.isConnected == true
                  ? 'Connected to ${_connectionStatus!.deviceName}'
                  : 'Not Connected',
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
            const SizedBox(height: 100), // Space for bottom navigation
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
              if (_connectionStatus?.isConnected != true) ...[
                // Connection form when disconnected
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _ipController,
                        decoration: const InputDecoration(
                          labelText: 'IP Address',
                          hintText: '192.168.1.100',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _portController,
                        decoration: const InputDecoration(
                          labelText: 'Port',
                          hintText: '3001',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 12),
              ],

              // Connection status row
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color:
                          _connectionStatus?.isConnected == true
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
                          _connectionStatus?.isConnected == true
                              ? 'Connected to ${_connectionStatus!.deviceName}'
                              : 'Disconnected',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        if (_connectionStatus?.isConnected == true) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${_connectionStatus!.deviceName} • ${_connectionStatus!.ipAddress}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          Text(
                            'Last sync: ${_getTimeAgo(_connectionStatus!.lastSync)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (_isConnecting)
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
                            _connectionStatus?.isConnected == true
                                ? Colors.red.withOpacity(0.1)
                                : Colors.green.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: BorderSide(
                            color:
                                _connectionStatus?.isConnected == true
                                    ? Colors.red
                                    : Colors.green,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Text(
                        _connectionStatus?.isConnected == true
                            ? 'DISCONNECT'
                            : 'CONNECT',
                        style: TextStyle(
                          color:
                              _connectionStatus?.isConnected == true
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tunnel Presets',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            if (_connectionStatus?.isConnected == true)
              TextButton.icon(
                onPressed: _showCreatePresetDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6366F1),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        if (_tunnelPresets.isEmpty)
          Center(
            child: Column(
              children: [
                const SizedBox(height: 32),
                const Icon(Icons.settings, size: 48, color: Color(0xFF9CA3AF)),
                const SizedBox(height: 8),
                const Text(
                  'No presets available',
                  style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                ),
                if (_connectionStatus?.isConnected != true)
                  const Text(
                    'Connect to agent to manage presets',
                    style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                  ),
              ],
            ),
          )
        else
          ..._tunnelPresets.map((preset) => _buildTunnelPresetCard(preset)),
      ],
    );
  }

  Widget _buildTunnelPresetCard(TunnelPreset preset) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: preset.accentColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          preset.id.toUpperCase().substring(
            0,
            preset.id.length > 3 ? 3 : preset.id.length,
          ),
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
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (preset.description.isNotEmpty)
            Text(
              preset.description,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          Text(
            'Port ${preset.port}${preset.isHotReloadEnabled ? ' • Hot Reload' : ''}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
      trailing:
          _connectionStatus?.isConnected == true
              ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    TextButton(
                      onPressed: () => _startTunnelFromPreset(preset),
                      child: const Text(
                        'START',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                ],
              )
              : const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFF9CA3AF),
                size: 16,
              ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  icon: const SizedBox.shrink(),
                  label: label,
                ),
              )
              .toList(),
    );
  }
}
