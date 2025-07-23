import 'package:flutter/material.dart';
import '../models/active_tunnel.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  List<ActiveTunnel> _activeTunnels = [];
  final int _selectedNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeTunnels();
  }

  void _initializeTunnels() {
    _activeTunnels = [
      const ActiveTunnel(
        tunnelName: 'React Dev Server',
        tunnelUrl: 'https://abc123.ngrok.io',
        tunnelPort: 3000,
        requests: 24,
        isActive: true,
      ),
      const ActiveTunnel(
        tunnelName: 'API Server',
        tunnelUrl: 'https://def456.ngrok.io',
        tunnelPort: 8000,
        requests: 156,
        isActive: true,
      ),
      const ActiveTunnel(
        tunnelName: 'Webhook Listener',
        tunnelUrl: 'https://ghi789.ngrok.io',
        tunnelPort: 4000,
        requests: 0,
        isActive: true,
      ),
    ];
  }

  void _onNewTunnelPressed() {
    // TODO: Implement new tunnel creation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create new tunnel functionality')),
    );
  }

  void _onStopAllTunnelsPressed() {
    setState(() {
      _activeTunnels =
          _activeTunnels
              .map((tunnel) => tunnel.copyWith(isActive: false))
              .toList();
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('All tunnels stopped')));
  }

  void _onCopyTunnelUrl(String url) {
    // TODO: Implement clipboard copy functionality
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Copied: $url')));
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
                  icon: const SizedBox.shrink(), // Empty icon
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Actions
            _buildQuickActions(),

            const SizedBox(height: 20),

            // Active Tunnels
            _buildActiveTunnels(),

            const SizedBox(height: 100), // Space for bottom navigation
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
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
            backgroundColor: const Color(0xFF10B981),
            radius: 16,
            child: const Icon(Icons.add, color: Colors.white, size: 18),
          ),
          title: const Text(
            'New Tunnel',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          subtitle: const Text(
            'Create a new development tunnel',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
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
            backgroundColor: const Color(0xFFEF4444),
            radius: 16,
            child: const Icon(Icons.stop, color: Colors.white, size: 18),
          ),
          title: const Text(
            'Stop All Tunnels',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          subtitle: const Text(
            'Disconnect all active connections',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
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
    return ListTile(
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
      trailing: TextButton(
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      isThreeLine: true,
    );
  }
}
