// services/local_storage_service.dart
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocalStorageService {
  static const String _sugarLogsBoxName = 'sugarLogsBox';
  static const String _recentLogsKey = 'recentLogs';

  static Future<List<Map<String, dynamic>>> loadSugarLogs() async {
    try {
      final box = await Hive.openBox(_sugarLogsBoxName);
      final savedLogs = box.get(_recentLogsKey, defaultValue: []);

      if (savedLogs == null || savedLogs.isEmpty) {
        return [];
      }

      return List<Map<String, dynamic>>.from(
        savedLogs.map(
          (log) => {
            'productName': log['productName'],
            'portionGrams': log['portionGrams'],
            'sugarGrams': log['sugarGrams'],
            'timestamp':
                log['timestamp'] is Timestamp
                    ? log['timestamp'].toDate()
                    : (log['timestamp'] is int
                        ? DateTime.fromMillisecondsSinceEpoch(log['timestamp'])
                        : log['timestamp']),
          },
        ),
      );
    } catch (e) {
      print('Error loading saved logs: $e');
      return [];
    }
  }

  static Future<void> saveSugarLogs(Map<String, dynamic> sugarLog) async {
    try {
      final box = await Hive.openBox(_sugarLogsBoxName);

      // Get existing logs
      List<dynamic> existingLogs = box.get(_recentLogsKey, defaultValue: []);

      final sugarLogForHive = {
        'productName': sugarLog['productName'],
        'portionGrams': sugarLog['portionGrams'],
        'sugarGrams': sugarLog['sugarGrams'],
        'timestamp':
            sugarLog['timestamp'] is Timestamp
                ? (sugarLog['timestamp'] as Timestamp)
                    .toDate()
                    .millisecondsSinceEpoch
                : (sugarLog['timestamp'] is DateTime
                    ? (sugarLog['timestamp'] as DateTime).millisecondsSinceEpoch
                    : sugarLog['timestamp']),
      };

      existingLogs.insert(0, sugarLogForHive);

      // Keep only the last 3 logs
      if (existingLogs.length > 3) {
        existingLogs = existingLogs.sublist(0, 3);
      }

      // Save back to Hive
      await box.put(_recentLogsKey, existingLogs);
      print('Successfully saved to local storage');
    } catch (e) {
      print('Error saving to local storage: $e');
    }
  }

  // Clear all logs from local storage
  static Future<void> clearLogs() async {
    try {
      final box = await Hive.openBox(_sugarLogsBoxName);
      await box.put(_recentLogsKey, []);
      print('Cleared logs from local storage');
    } catch (e) {
      print('Error clearing logs: $e');
    }
  }
}
