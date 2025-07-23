import 'package:flutter/material.dart';
import '../models/webhook.dart';

class WebhookInspectorPage extends StatefulWidget {
  const WebhookInspectorPage({super.key});

  @override
  State<WebhookInspectorPage> createState() => _WebhookInspectorPageState();
}

class _WebhookInspectorPageState extends State<WebhookInspectorPage> {
  WebhookStatus _webhookStatus = const WebhookStatus(
    status: 'Listening for webhooks',
    description: 'https://ghi789.ngrok.io/webhook',
    url: 'https://ghi789.ngrok.io/webhook',
    isListening: true,
  );

  List<RecentWebhook> _recentWebhooks = [];
  int _selectedNavIndex = 2; // Webhooks tab

  @override
  void initState() {
    super.initState();
    _initializeWebhooks();
  }

  void _initializeWebhooks() {
    final now = DateTime.now();
    _recentWebhooks = [
      RecentWebhook(
        service: 'STRIPE',
        event: 'payment_intent.succeeded',
        amount: '\$49.99',
        customerId: 'Customer: cus_12356',
        timestamp: now.subtract(const Duration(minutes: 2)),
        status: WebhookEventStatus.processed,
        details: 'Payment processed successfully',
      ),
      RecentWebhook(
        service: 'GITHUB',
        event: 'push',
        amount: '',
        customerId: 'myapp • main branch • 3 commits',
        timestamp: now.subtract(const Duration(minutes: 5)),
        status: WebhookEventStatus.triggered,
        details: 'Build triggered successfully',
      ),
      RecentWebhook(
        service: 'SLACK',
        event: 'message.im',
        amount: '',
        customerId: '@john.doe • #dev-alerts',
        timestamp: now.subtract(const Duration(minutes: 12)),
        status: WebhookEventStatus.failed,
        details: 'Message delivery failed',
      ),
    ];
  }

  void _onViewPayloadDetails() {
    // TODO: Navigate to payload details screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigate to payload details')),
    );
  }

  void _onWebhookStatusToggle() {
    setState(() {
      _webhookStatus = _webhookStatus.copyWith(
        isListening: !_webhookStatus.isListening,
        status:
            _webhookStatus.isListening
                ? 'Webhook listener stopped'
                : 'Listening for webhooks',
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

  void _onRefreshWebhooks() {
    setState(() {
      // Simulate refresh by adding a new webhook
      final now = DateTime.now();
      _recentWebhooks.insert(
        0,
        RecentWebhook(
          service: 'STRIPE',
          event: 'customer.created',
          amount: '',
          customerId: 'Customer: cus_${DateTime.now().millisecondsSinceEpoch}',
          timestamp: now,
          status: WebhookEventStatus.processed,
          details: 'New customer created',
        ),
      );
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Webhooks refreshed')));
  }

  void _onWebhookItemTap(RecentWebhook webhook) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${webhook.service} - ${webhook.event}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status: ${webhook.statusText}'),
              const SizedBox(height: 8),
              Text('Time: ${webhook.timeAgo}'),
              const SizedBox(height: 8),
              Text('Details: ${webhook.details}'),
              if (webhook.amount.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Amount: ${webhook.amount}'),
              ],
            ],
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
              '${_recentWebhooks.where((w) => w.status == WebhookEventStatus.processed).length} Active Tunnels',
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
      ),
      bottomNavigationBar: _buildBottomNavigation(),
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
              onPressed: _onRefreshWebhooks,
              icon: const Icon(Icons.refresh),
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
            onChanged: (value) => _onWebhookStatusToggle(),
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
        const Text(
          'Recent Webhooks',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),

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
            if (webhook.amount.isNotEmpty)
              Text(
                webhook.amount,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF059669),
                ),
              ),
            Text(
              webhook.customerId,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            Text(
              '${webhook.timeAgo} • ${webhook.statusText}',
              style: TextStyle(fontSize: 12, color: webhook.statusColor),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        isThreeLine: true,
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
