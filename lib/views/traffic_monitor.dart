// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import '../models/request_data.dart';
import '../models/traffic_stats.dart';
import '../models/chart_data.dart';
import '../models/connection_status.dart';
import '../services/persistent_connection_service.dart';

class TrafficMonitorScreen extends StatefulWidget {
  const TrafficMonitorScreen({super.key});

  @override
  State<TrafficMonitorScreen> createState() => _TrafficMonitorScreenState();
}

class _TrafficMonitorScreenState extends State<TrafficMonitorScreen> {
  // Use the persistent service instead of creating a new instance
  final PersistentConnectionService _persistentService =
      PersistentConnectionService();

  TrafficStats _stats = TrafficStats(
    totalRequests: 0,
    avgResponseTime: '0ms',
    improvementPercentage: '+0%',
  );

  List<RequestData> _recentRequests = [];
  List<ChartData> _chartData = [];
  int _selectedNavIndex = 1; // Monitor tab

  bool _isLoading = true;
  String? _errorMessage;
  bool _isConnected = false;

  // Stream subscriptions - now using persistent service streams
  StreamSubscription<RequestData>? _requestSubscription;
  StreamSubscription<TrafficStats>? _statsSubscription;
  StreamSubscription<ConnectionStatus>? _connectionSubscription;

  // Chart data tracking
  final Map<String, int> _hourlyRequestCounts = {};
  Timer? _chartUpdateTimer;

  @override
  void initState() {
    super.initState();
    _initializeService();
    _startChartUpdateTimer();
  }

  @override
  void dispose() {
    _requestSubscription?.cancel();
    _statsSubscription?.cancel();
    _connectionSubscription?.cancel();
    _chartUpdateTimer?.cancel();
    // Don't dispose the persistent service - it should remain alive
    super.dispose();
  }

  Future<void> _initializeService() async {
    try {
      // Ensure the persistent service is initialized
      if (!_persistentService.isInitialized) {
        await _persistentService.initialize();
      }

      // Listen to real-time request data from persistent service
      _requestSubscription = _persistentService.requestsStream.listen((
        request,
      ) {
        setState(() {
          _recentRequests.insert(0, request);
          // Keep only the last 100 requests
          if (_recentRequests.length > 100) {
            _recentRequests = _recentRequests.take(100).toList();
          }
        });
        _updateChartData(request);
      });

      // Listen to traffic statistics updates from persistent service
      _statsSubscription = _persistentService.statsStream.listen((stats) {
        setState(() {
          _stats = stats;
        });
      });

      // Listen to connection status changes from persistent service
      _connectionSubscription = _persistentService.connectionStream.listen((
        connectionStatus,
      ) {
        setState(() {
          _isConnected = connectionStatus.isConnected;
          if (!connectionStatus.isConnected) {
            _errorMessage = 'Connection lost with Tap Tunnel Agent';
          } else {
            _errorMessage = null;
          }
        });
      });

      // Load initial data
      await _loadInitialData();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to initialize traffic monitor: ${e.toString()}';
      });
    }
  }

  Future<void> _loadInitialData() async {
    try {
      // Fetch recent requests from persistent service
      final requests = await _persistentService.getRequests(limit: 50);
      if (requests != null) {
        setState(() {
          _recentRequests = requests;
        });

        // Build initial chart data from existing requests
        _buildInitialChartData(requests);
      }

      // Fetch current statistics from persistent service
      final stats = await _persistentService.getStats();
      if (stats != null) {
        setState(() {
          _stats = stats;
        });
      }

      setState(() {
        _isConnected = _persistentService.isConnected;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load traffic data: ${e.toString()}';
      });
    }
  }

  void _buildInitialChartData(List<RequestData> requests) {
    _hourlyRequestCounts.clear();

    // Process existing requests to build hourly counts
    for (final request in requests) {
      if (request.timestamp != null) {
        try {
          final timestamp = DateTime.parse(request.timestamp!);
          final hour = _formatHour(timestamp);
          _hourlyRequestCounts[hour] = (_hourlyRequestCounts[hour] ?? 0) + 1;
        } catch (e) {
          // Skip invalid timestamps
        }
      }
    }

    _updateChartDataFromCounts();
  }

  void _updateChartData(RequestData request) {
    if (request.timestamp != null) {
      try {
        final timestamp = DateTime.parse(request.timestamp!);
        final hour = _formatHour(timestamp);
        _hourlyRequestCounts[hour] = (_hourlyRequestCounts[hour] ?? 0) + 1;
        _updateChartDataFromCounts();
      } catch (e) {
        // Skip invalid timestamps
      }
    }
  }

  String _formatHour(DateTime dateTime) {
    final hour = dateTime.hour;
    if (hour == 0) return '12AM';
    if (hour == 12) return '12PM';
    if (hour < 12) return '${hour}AM';
    return '${hour - 12}PM';
  }

  void _updateChartDataFromCounts() {
    final now = DateTime.now();
    final chartData = <ChartData>[];

    // Show last 7 hours
    for (int i = 6; i >= 0; i--) {
      final time = now.subtract(Duration(hours: i));
      final hour = _formatHour(time);
      final count = _hourlyRequestCounts[hour] ?? 0;
      chartData.add(ChartData(time: hour, value: count.toDouble()));
    }

    setState(() {
      _chartData = chartData;
    });
  }

  void _startChartUpdateTimer() {
    // Update chart data every minute to keep it current
    _chartUpdateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateChartDataFromCounts();
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _loadInitialData();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Traffic data refreshed')));
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
      backgroundColor: const Color(0xFFF8F9FA),
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
              _isConnected
                  ? 'Real-time analytics • ${_recentRequests.length} requests'
                  : 'Disconnected from agent',
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
      floatingActionButton: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
        child: FloatingActionButton(
          onPressed: _isLoading ? null : _refreshData,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child:
              _isLoading
                  ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                  : const Icon(Icons.refresh, color: Colors.white),
        ),
      ),
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
            const Text(
              'Connection Error',
              style: TextStyle(
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
          _buildStatsSection(),
          const SizedBox(height: 15),
          _buildChartSection(),
          const SizedBox(height: 15),
          _buildRecentRequestsSection(),
          const SizedBox(height: 100),
        ],
      ),
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
        Row(
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
                    'Total Requests',
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 2),
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
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _stats.avgResponseTime,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const Text(
                    'Avg Response Time',
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getResponseTimeImprovement(),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getResponseTimeColor(),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getResponseTimeImprovement() {
    // Extract numeric value from response time for comparison
    final responseTimeStr = _stats.avgResponseTime;
    if (responseTimeStr.contains('ms')) {
      return 'Real-time monitoring';
    }
    return 'Performance tracked';
  }

  Color _getResponseTimeColor() {
    return const Color(0xFF3B82F6);
  }

  Widget _buildChartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Request Activity (Last 7 Hours)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child:
              _chartData.isEmpty
                  ? const Center(
                    child: Text(
                      'No request data available',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                    ),
                  )
                  : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMaxYValue(),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            if (groupIndex < _chartData.length) {
                              final data = _chartData[groupIndex];
                              return BarTooltipItem(
                                '${data.time}\n${data.value.toInt()} requests',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }
                            return null;
                          },
                        ),
                      ),
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
                                  color: const Color(0xFF6366F1),
                                  width: 24,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            );
                          }).toList(),
                    ),
                  ),
        ),
      ],
    );
  }

  double _getMaxYValue() {
    if (_chartData.isEmpty) return 10;
    final maxValue = _chartData
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b);
    return (maxValue + 5).ceilToDouble();
  }

  Widget _buildRecentRequestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Requests (${_recentRequests.length})',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),

        if (_recentRequests.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No requests yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'HTTP requests to your tunnels will appear here',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ..._recentRequests
              .take(20)
              .map((request) => _buildRequestItem(request)),
      ],
    );
  }

  Widget _buildRequestItem(RequestData request) {
    Color statusColor = _getStatusColor(request.statusCode);
    Color methodColor = _getMethodColor(request.method);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: CircleAvatar(radius: 4, backgroundColor: statusColor),
        title: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: methodColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(
                  request.method,
                  style: TextStyle(
                    color: methodColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
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
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: statusColor,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  Color _getStatusColor(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) {
      return const Color(0xFF10B981); // Green for success
    } else if (statusCode >= 400 && statusCode < 500) {
      return const Color(0xFFF59E0B); // Orange for client errors
    } else if (statusCode >= 500) {
      return const Color(0xFFEF4444); // Red for server errors
    } else {
      return const Color(0xFF6B7280); // Gray for others
    }
  }

  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return const Color(0xFF3B82F6); // Blue
      case 'POST':
        return const Color(0xFF10B981); // Green
      case 'PUT':
        return const Color(0xFDF59E0B); // Orange
      case 'DELETE':
        return const Color(0xFFEF4444); // Red
      case 'PATCH':
        return const Color(0xFF8B5CF6); // Purple
      default:
        return const Color(0xFF6B7280); // Gray
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
}
