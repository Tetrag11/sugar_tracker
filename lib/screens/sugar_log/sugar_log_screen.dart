import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:sugar_tracker/utils/theme.dart';

class SugarLogScreen extends StatefulWidget {
  const SugarLogScreen({Key? key}) : super(key: key);

  @override
  State<SugarLogScreen> createState() => _SugarLogScreenState();
}

class _SugarLogScreenState extends State<SugarLogScreen> {
  bool _isLoading = true;
  bool _isOffline = false;
  List<Map<String, dynamic>> _allLogs = [];
  Map<String, double> _dailyTotals = {};

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<bool> _checkConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> _fetchLogs() async {
    setState(() {
      _isLoading = true;
      _isOffline = false;
    });

    // Check for internet connection
    bool isConnected = await _checkConnectivity();
    if (!isConnected) {
      setState(() {
        _isLoading = false;
        _isOffline = true;
      });
      return;
    }

    try {
      // Fetch logs from Firebase
      final snapshot =
          await FirebaseFirestore.instance
              .collection('sugar_logs')
              .orderBy('timestamp', descending: true)
              .get();

      final logs =
          snapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data();
            data['id'] = doc.id;

            // Convert Timestamp to DateTime
            if (data['timestamp'] is Timestamp) {
              data['timestamp'] = (data['timestamp'] as Timestamp).toDate();
            }

            return data;
          }).toList();

      // Calculate daily totals
      Map<String, double> totals = {};
      for (var log in logs) {
        final date = DateFormat('yyyy-MM-dd').format(log['timestamp']);
        if (!totals.containsKey(date)) {
          totals[date] = 0;
        }
        totals[date] = totals[date]! + (log['sugarGrams'] as double);
      }

      setState(() {
        _allLogs = logs;
        _dailyTotals = totals;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching logs: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading logs: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sugar Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchLogs,
            tooltip: 'Refresh logs',
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              )
              : _isOffline
              ? _buildOfflineState()
              : _allLogs.isEmpty
              ? _buildEmptyState()
              : _buildLogList(),
    );
  }

  Widget _buildOfflineState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 80, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          Text(
            'You are offline',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your internet connection and try again',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchLogs,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.data_usage, size: 80, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          Text(
            'No sugar logs found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Track your first sugar consumption to get started',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildLogList() {
    // Group logs by date
    Map<String, List<Map<String, dynamic>>> groupedLogs = {};

    for (var log in _allLogs) {
      final date = DateFormat('yyyy-MM-dd').format(log['timestamp']);
      if (!groupedLogs.containsKey(date)) {
        groupedLogs[date] = [];
      }
      groupedLogs[date]!.add(log);
    }

    // Sort dates
    final sortedDates =
        groupedLogs.keys.toList()
          ..sort((a, b) => b.compareTo(a)); // Descending order

    return ListView.builder(
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final logs = groupedLogs[date]!;
        final totalSugar = _dailyTotals[date]!;

        return _buildDateSection(date, logs, totalSugar);
      },
    );
  }

  Widget _buildDateSection(
    String dateStr,
    List<Map<String, dynamic>> logs,
    double totalSugar,
  ) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));

    String dateDisplay;
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      dateDisplay = 'Today';
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      dateDisplay = 'Yesterday';
    } else {
      dateDisplay = DateFormat('EEEE, MMMM d').format(date);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header with total sugar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          color: AppTheme.backgroundColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(dateDisplay, style: Theme.of(context).textTheme.titleLarge),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getSugarLevelColor(totalSugar),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Total: ${totalSugar.toStringAsFixed(1)}g',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Logs for this date
        ...logs.map((log) => _buildLogItem(log)),

        const Divider(height: 1, thickness: 1),
      ],
    );
  }

  Widget _buildLogItem(Map<String, dynamic> log) {
    final time = DateFormat('h:mm a').format(log['timestamp']);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Text(
        log['productName'],
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            'Portion: ${log['portionGrams']}g',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            'Sugar: ${log['sugarGrams']}g',
            style: TextStyle(
              color: _getSugarLevelColor(log['sugarGrams']),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(time, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(
            '${(log['sugarGrams'] / log['portionGrams'] * 100).toStringAsFixed(1)}% sugar',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Color _getSugarLevelColor(double sugar) {
    // WHO recommends limiting sugar to about 25g per day for an adult
    if (sugar <= 25) return AppTheme.lowSugar;
    if (sugar <= 50) return AppTheme.mediumSugar;
    return AppTheme.highSugar;
  }
}
