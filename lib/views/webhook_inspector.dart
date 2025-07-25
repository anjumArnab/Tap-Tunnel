import 'package:flutter/material.dart';
import 'package:tap_tunnel/models/connection_status.dart';
import 'package:tap_tunnel/services/persistent_connection_service.dart';
import 'dart:async';
import '../models/recent_webhook.dart';
import '../models/webhook_status.dart';

class WebhookInspectorPage extends StatefulWidget {
  const WebhookInspectorPage({super.key});

  @override
  State<WebhookInspectorPage> createState() => _WebhookInspectorPageState();
}

class _WebhookInspectorPageState extends State<WebhookInspectorPage> {
  final PersistentConnectionService _persistentService =
      PersistentConnectionService();

  WebhookStatus _webhookStatus = const WebhookStatus(
    status: 'Connecting to webhook listener...',
    description: 'Initializing webhook monitoring',
    url: '',
    isListening: false,
  );

  List<RecentWebhook> _recentWebhooks = [];
  int _selectedNavIndex = 2; // Webhooks tab
  bool _isLoading = true;
  String? _errorMessage;

  // Stream subscriptions
  StreamSubscription<RecentWebhook>? _webhookSubscription;
  StreamSubscription<ConnectionStatus>? _connectionSubscription;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  @override
  void dispose() {
    _webhookSubscription?.cancel();
    _connectionSubscription?.cancel();
    // Don't dispose the persistent service - it's a singleton
    super.dispose();
  }

  Future<void> _initializeService() async {
    try {
      // Initialize the persistent service if not already done
      await _persistentService.initialize();

      // Listen to real-time webhook events from persistent service
      _webhookSubscription = _persistentService.webhooksStream.listen((
        webhook,
      ) {
        setState(() {
          _recentWebhooks.insert(0, webhook);
          // Keep only the last 50 webhooks
          if (_recentWebhooks.length > 50) {
            _recentWebhooks = _recentWebhooks.take(50).toList();
          }
        });
      });

      // Listen to connection status changes from persistent service
      _connectionSubscription = _persistentService.connectionStream.listen((
        connectionStatus,
      ) {
        setState(() {
          if (connectionStatus.isConnected) {
            _webhookStatus = _webhookStatus.copyWith(
              status: 'Listening for webhooks',
              description: 'Connected to webhook listener',
              isListening: true,
            );
            _errorMessage = null;
          } else {
            _webhookStatus = _webhookStatus.copyWith(
              status: 'Webhook listener disconnected',
              description: 'Unable to connect to agent',
              isListening: false,
            );
            _errorMessage = 'Connection lost with Tap Tunnel Agent';
          }
        });
      });

      // Get initial connection status
      setState(() {
        final connectionStatus = _persistentService.connectionStatus;
        if (connectionStatus?.isConnected == true) {
          _webhookStatus = _webhookStatus.copyWith(
            status: 'Listening for webhooks',
            description: 'Connected to webhook listener',
            isListening: true,
          );
        }
      });

      // Load initial webhook data
      await _loadWebhookData();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Failed to initialize webhook inspector: ${e.toString()}';
      });
    }
  }

  Future<void> _loadWebhookData() async {
    try {
      // Fetch recent webhooks from the persistent service
      final webhooks = await _persistentService.getWebhooks();
      if (webhooks != null) {
        setState(() {
          _recentWebhooks = webhooks;
          _errorMessage = null;
        });
      }

      // Update webhook status based on persistent service connection
      if (_persistentService.isConnected) {
        setState(() {
          _webhookStatus = _webhookStatus.copyWith(
            status: 'Listening for webhooks',
            description: 'Webhook listener is active',
            isListening: true,
          );
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load webhook data: ${e.toString()}';
      });
    }
  }

  void _onViewPayloadDetails() {
    // TODO: Navigate to payload details screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigate to payload details')),
    );
  }

  void _onWebhookStatusToggle() {
    // This would typically send a command to the agent to start/stop webhook listening
    // For now, we'll just toggle the UI state
    setState(() {
      _webhookStatus = _webhookStatus.copyWith(
        isListening: !_webhookStatus.isListening,
        status:
            _webhookStatus.isListening
                ? 'Webhook listener stopped'
                : 'Listening for webhooks',
        description:
            _webhookStatus.isListening
                ? 'Webhook monitoring paused'
                : 'Webhook listener is active',
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _webhookStatus.isListening
              ? 'Webhook listener started'
              : 'Webhook listener stopped',
        ),
      ),
    );
  }

  Future<void> _onRefreshWebhooks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _loadWebhookData();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Webhooks refreshed')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to refresh: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onWebhookItemTap(RecentWebhook webhook) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${webhook.service} - ${webhook.event}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Status', webhook.statusText),
                _buildDetailRow('Time', webhook.timeAgo),
                _buildDetailRow('Details', webhook.details),
                if (webhook.amount?.isNotEmpty == true)
                  _buildDetailRow('Amount', webhook.amount!),
                if (webhook.customerId?.isNotEmpty == true)
                  _buildDetailRow('Customer', webhook.customerId!),
                if (webhook.repository?.isNotEmpty == true)
                  _buildDetailRow('Repository', webhook.repository!),
                if (webhook.action?.isNotEmpty == true)
                  _buildDetailRow('Action', webhook.action!),
                if (webhook.channel?.isNotEmpty == true)
                  _buildDetailRow('Channel', webhook.channel!),
                if (webhook.user?.isNotEmpty == true)
                  _buildDetailRow('User', webhook.user!),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  void _onNavItemPressed(int index) {
    // Handle navigation based on index
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
        // Already on webhooks page
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Webhook Inspector',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_recentWebhooks.where((w) => w.status == WebhookEventStatus.processed).length} Processed • ${_recentWebhooks.length} Total',
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
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Color(0xFFEF4444)),
            const SizedBox(height: 16),
            Text(
              'Connection Error',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                  _isLoading = true;
                });
                _initializeService();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
              ),
              child: const Text('Retry Connection'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Webhook Status
          _buildWebhookStatus(),

          const SizedBox(height: 20),

          // Recent Webhooks
          _buildRecentWebhooks(),

          const SizedBox(height: 20),

          // View Payload Details Button
          _buildPayloadDetailsButton(),

          const SizedBox(height: 100), // Space for bottom navigation
        ],
      ),
    );
  }

  Widget _buildWebhookStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Webhook Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            IconButton(
              onPressed: _isLoading ? null : _onRefreshWebhooks,
              icon:
                  _isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF6366F1),
                          ),
                        ),
                      )
                      : const Icon(Icons.refresh),
              iconSize: 20,
            ),
          ],
        ),
        const SizedBox(height: 8),

        ListTile(
          leading: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _webhookStatus.statusColor,
              shape: BoxShape.circle,
            ),
          ),
          title: Text(
            _webhookStatus.status,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          subtitle: Text(
            _webhookStatus.description,
            style: const TextStyle(fontSize: 13, color: Color(0xFF3B82F6)),
          ),
          trailing: Switch(
            value: _webhookStatus.isListening,
            onChanged:
                _persistentService.isConnected
                    ? (value) => _onWebhookStatusToggle()
                    : null,
            activeColor: const Color(0xFF10B981),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentWebhooks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Webhooks (${_recentWebhooks.length})',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),

        if (_recentWebhooks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(Icons.webhook, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No webhooks received yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Webhook events will appear here when received',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ..._recentWebhooks
              .map(
                (webhook) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _buildWebhookCard(webhook),
                ),
              )
              .toList(),
      ],
    );
  }

  Widget _buildWebhookCard(RecentWebhook webhook) {
    return GestureDetector(
      onTap: () => _onWebhookItemTap(webhook),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 2),
        elevation: 1,
        child: ListTile(
          leading: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: webhook.statusColor,
              shape: BoxShape.circle,
            ),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: webhook.serviceColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  webhook.service,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  webhook.event,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (webhook.amount?.isNotEmpty == true)
                Text(
                  webhook.amount!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF059669),
                  ),
                ),
              if (webhook.customerId?.isNotEmpty == true)
                Text(
                  webhook.customerId!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              Text(
                '${webhook.timeAgo} • ${webhook.statusText}',
                style: TextStyle(fontSize: 12, color: webhook.statusColor),
              ),
            ],
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          isThreeLine: true,
        ),
      ),
    );
  }

  Widget _buildPayloadDetailsButton() {
    return Center(
      child: TextButton(
        onPressed: _onViewPayloadDetails,
        child: const Text(
          'View Payload Details',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF3B82F6),
          ),
        ),
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
