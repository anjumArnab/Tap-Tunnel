import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/persistent_connection_service.dart';
import 'dart:async';
import '../models/active_tunnel.dart';
import '../models/connection_status.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final PersistentConnectionService _persistentService =
      PersistentConnectionService();
  List<ActiveTunnel> _activeTunnels = [];
  ConnectionStatus? _connectionStatus;
  final int _selectedNavIndex = 0;

  // Stream subscriptions
  StreamSubscription<List<ActiveTunnel>>? _tunnelsSubscription;
  StreamSubscription<ConnectionStatus>? _connectionSubscription;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  @override
  void dispose() {
    _tunnelsSubscription?.cancel();
    _connectionSubscription?.cancel();
    // Don't dispose the persistent service - it's a singleton
    super.dispose();
  }

  Future<void> _initializeService() async {
    // Initialize the persistent service if not already done
    await _persistentService.initialize();

    // Set up stream listeners
    _setupStreamListeners();

    // Get initial state
    setState(() {
      _connectionStatus = _persistentService.connectionStatus;
      _isLoading = false;
    });

    // Load initial tunnels if connected
    if (_persistentService.isConnected) {
      final tunnels = await _persistentService.getTunnels();
      if (tunnels != null) {
        setState(() {
          _activeTunnels = tunnels;
        });
      }
    }
  }

  void _setupStreamListeners() {
    // Listen to tunnel updates from persistent service
    _tunnelsSubscription = _persistentService.tunnelsStream.listen(
      (tunnels) {
        setState(() {
          _activeTunnels = tunnels;
          _isLoading = false;
        });
      },
      onError: (error) {
        print('Tunnels stream error: $error');
      },
    );

    // Listen to connection status from persistent service
    _connectionSubscription = _persistentService.connectionStream.listen(
      (status) {
        setState(() {
          _connectionStatus = status;
        });
      },
      onError: (error) {
        print('Connection stream error: $error');
      },
    );
  }

  Future<void> _onNewTunnelPressed() async {
    // Check if connected before allowing tunnel creation
    if (_connectionStatus?.isConnected != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please connect to Tap Tunnel Agent first'),
        ),
      );
      return;
    }
    // Show dialog to create new tunnel
    _showCreateTunnelDialog();
  }

  void _showCreateTunnelDialog() {
    final portController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create New Tunnel'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tunnel Name',
                  hintText: 'e.g., React Dev Server',
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final port = int.tryParse(portController.text);
                if (port != null && nameController.text.isNotEmpty) {
                  Navigator.of(context).pop();
                  await _createTunnel(port, nameController.text);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createTunnel(int port, String name) async {
    try {
      final tunnel = await _persistentService.startTunnel(
        port: port,
        name: name,
      );

      if (tunnel != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tunnel "$name" created successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create tunnel')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creating tunnel: $e')));
    }
  }

  Future<void> _onStopAllTunnelsPressed() async {
    // Check if connected before allowing tunnel operations
    if (_connectionStatus?.isConnected != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please connect to Tap Tunnel Agent first'),
        ),
      );
      return;
    }

    try {
      // Stop all active tunnels
      final futures = _activeTunnels
          .where((tunnel) => tunnel.isActive)
          .map((tunnel) => _persistentService.stopTunnel(tunnel.tunnelName));

      await Future.wait(futures);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('All tunnels stopped')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error stopping tunnels: $e')));
    }
  }

  Future<void> _onCopyTunnelUrl(String url) async {
    try {
      await Clipboard.setData(ClipboardData(text: url));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Copied: $url')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to copy URL')));
    }
  }

  Future<void> _onStopTunnel(ActiveTunnel tunnel) async {
    try {
      final success = await _persistentService.stopTunnel(tunnel.tunnelName);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tunnel "${tunnel.tunnelName}" stopped')),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to stop tunnel')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error stopping tunnel: $e')));
    }
  }

  void _onNavItemPressed(int index) {
    switch (index) {
      case 0: // HOME
        // Already on home page
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
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/settings',
          (route) => false,
        );
        break;
    }
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

  int get _activeTunnelCount {
    return _activeTunnels.where((tunnel) => tunnel.isActive).length;
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
              'Tap Tunnel',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$_activeTunnelCount active tunnels',
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
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Connecting to Tap Tunnel Agent...'),
          ],
        ),
      );
    }

    // Always show the main content regardless of connection status
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Actions
          _buildQuickActions(),

          const SizedBox(height: 15),

          // Active Tunnels
          _buildActiveTunnels(),

          const SizedBox(height: 100), // Space for bottom navigation
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),

        // New Tunnel Action
        ListTile(
          leading: CircleAvatar(
            backgroundColor:
                (_connectionStatus?.isConnected == true)
                    ? const Color(0xFF10B981)
                    : const Color(0xFF9CA3AF),
            radius: 16,
            child: const Icon(Icons.add, color: Colors.white, size: 18),
          ),
          title: Text(
            'New Tunnel',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color:
                  (_connectionStatus?.isConnected == true)
                      ? const Color(0xFF1F2937)
                      : const Color(0xFF9CA3AF),
            ),
          ),
          subtitle: Text(
            (_connectionStatus?.isConnected == true)
                ? 'Create a new development tunnel'
                : 'Connect to agent to create tunnels',
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          onTap: _onNewTunnelPressed,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
        ),

        // Stop All Tunnels Action
        ListTile(
          leading: CircleAvatar(
            backgroundColor:
                (_connectionStatus?.isConnected == true)
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF9CA3AF),
            radius: 16,
            child: const Icon(Icons.stop, color: Colors.white, size: 18),
          ),
          title: Text(
            'Stop All Tunnels',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color:
                  (_connectionStatus?.isConnected == true)
                      ? const Color(0xFF1F2937)
                      : const Color(0xFF9CA3AF),
            ),
          ),
          subtitle: Text(
            (_connectionStatus?.isConnected == true)
                ? 'Disconnect all active connections'
                : 'Connect to agent to manage tunnels',
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          onTap: _onStopAllTunnelsPressed,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveTunnels() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Active Tunnels',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),

        // Show different content based on connection status
        if (_connectionStatus?.isConnected != true)
          // Not connected - show connection message
          Center(
            child: Column(
              children: [
                const Icon(
                  Icons.settings_ethernet,
                  size: 35,
                  color: Color(0xFF9CA3AF),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Connect to Tap Tunnel Agent',
                  style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 5),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/settings',
                      (route) => false,
                    );
                  },
                  child: const Text('Go to settings page'),
                ),
              ],
            ),
          )
        else if (_activeTunnels.isEmpty)
          // Connected but no tunnels
          Center(
            child: Column(
              children: [
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 48,
                  color: Color(0xFF9CA3AF),
                ),
                const SizedBox(height: 8),
                const Text(
                  'No active tunnels',
                  style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _onNewTunnelPressed,
                  child: const Text('Create your first tunnel'),
                ),
              ],
            ),
          )
        else
          // Connected with tunnels - show tunnel list
          ..._activeTunnels
              .map(
                (tunnel) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _buildTunnelCard(tunnel),
                ),
              )
              .toList(),
      ],
    );
  }

  Widget _buildTunnelCard(ActiveTunnel tunnel) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        leading: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: tunnel.statusColor,
            shape: BoxShape.circle,
          ),
        ),
        title: Text(
          tunnel.tunnelName,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tunnel.tunnelUrl,
              style: const TextStyle(fontSize: 13, color: Color(0xFF3B82F6)),
            ),
            Text(
              'Port ${tunnel.tunnelPort} • ${tunnel.requestsText}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => _onCopyTunnelUrl(tunnel.tunnelUrl),
              child: const Text(
                'COPY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ),
            if (tunnel.isActive)
              IconButton(
                onPressed: () => _onStopTunnel(tunnel),
                icon: const Icon(
                  Icons.stop,
                  color: Color(0xFFEF4444),
                  size: 18,
                ),
              ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        isThreeLine: true,
      ),
    );
  }
}
