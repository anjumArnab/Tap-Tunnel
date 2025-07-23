// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/traffic_monitor.dart';

class TrafficMonitorScreen extends StatefulWidget {
  const TrafficMonitorScreen({super.key});

  @override
  State<TrafficMonitorScreen> createState() => _TrafficMonitorScreenState();
}

class _TrafficMonitorScreenState extends State<TrafficMonitorScreen> {
  late TrafficStats _stats;
  late List<RequestData> _recentRequests;
  late List<ChartData> _chartData;
  int _selectedNavIndex = 1; // Monitor tab

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    // Initialize stats
    _stats = TrafficStats(
      totalRequests: 180,
      avgResponseTime: '2.3s',
      improvementPercentage: '+23%',
    );

    // Initialize chart data
    _chartData = [
      ChartData(time: '12PM', value: 45),
      ChartData(time: '1PM', value: 65),
      ChartData(time: '2PM', value: 80),
      ChartData(time: '3PM', value: 72),
      ChartData(time: '4PM', value: 58),
      ChartData(time: '5PM', value: 42),
      ChartData(time: '6PM', value: 35),
    ];

    // Initialize recent requests
    _recentRequests = [
      RequestData(
        method: 'POST',
        endpoint: '/api/webhooks',
        statusCode: 200,
        responseTime: '1.2s',
        timeAgo: '2 min ago',
      ),
      RequestData(
        method: 'GET',
        endpoint: '/api/users',
        statusCode: 200,
        responseTime: '0.8s',
        timeAgo: '5 min ago',
      ),
      RequestData(
        method: 'POST',
        endpoint: '/api/login',
        statusCode: 401,
        responseTime: '2.1s',
        timeAgo: '8 min ago',
      ),
    ];
  }

  void _onNavItemPressed(int index) {
    // Handle navigation based on index
    switch (index) {
      case 0: // HOME
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        break;
      case 1: // MONITOR
        // Already on monitor page
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Match Homepage background
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Traffic Monitor',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Real-time analytics',
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
        padding: const EdgeInsets.all(12), // Match Homepage padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsSection(),
            const SizedBox(height: 20), // Reduced from 24
            _buildChartSection(),
            const SizedBox(height: 20), // Reduced from 24
            _buildRecentRequestsSection(),
            const SizedBox(height: 100), // Space for bottom navigation
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Today\'s Stats',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_stats.totalRequests}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const Text(
                      'Requests',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(
                          0xFF6B7280,
                        ), // Match Homepage subtitle color
                      ),
                    ),
                    const SizedBox(height: 2), // Reduced from 4
                    Text(
                      '${_stats.improvementPercentage} vs yesterday',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16), // Reduced from 20
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _stats.avgResponseTime,
                      style: const TextStyle(
                        fontSize: 28, // Reduced from 32
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const Text(
                      'Avg Response',
                      style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 2), // Reduced from 4
                    const Text(
                      '-0.2s improvement',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Request Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16), // Reduced from 20
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8), // Reduced from 16
          ),
          child: SizedBox(
            height: 180, // Reduced from 200
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < _chartData.length) {
                          return Text(
                            _chartData[value.toInt()].time,
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups:
                    _chartData.asMap().entries.map((entry) {
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value.value,
                            color: const Color(
                              0xFF6366F1,
                            ), // Match Homepage primary color
                            width: 24,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      );
                    }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentRequestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Requests',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        ..._recentRequests.map((request) => _buildRequestItem(request)),
      ],
    );
  }

  Widget _buildRequestItem(RequestData request) {
    Color statusColor =
        request.statusCode == 200
            ? const Color(0xFF10B981)
            : const Color(0xFFEF4444);
    Color methodColor =
        request.method == 'GET'
            ? const Color(0xFF3B82F6)
            : const Color(0xFFF59E0B);

    return Container(
      margin: const EdgeInsets.only(bottom: 4), // Reduced from 12
      child: ListTile(
        leading: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ), // Reduced padding
              decoration: BoxDecoration(
                color: methodColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                request.method,
                style: TextStyle(
                  color: methodColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                request.endpoint,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          '${request.statusCode} • ${request.responseTime} • ${request.timeAgo}',
          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        ),
        trailing: Text(
          '${request.statusCode}',
          style: TextStyle(
            fontSize: 12, // Reduced from 14
            fontWeight: FontWeight.bold,
            color: statusColor,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ), // Match Homepage
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
