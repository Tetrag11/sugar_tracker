// screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sugar_tracker/services/api_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sugar_tracker/services/storage_service.dart';
import 'package:sugar_tracker/utils/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _portionSizeController = TextEditingController();
  final OpenFoodFactsService _apiService = OpenFoodFactsService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isOffline = false;
  // get from local storage
  List<Map<String, dynamic>> _sugarLogs = [];

  @override
  void initState() {
    super.initState();
    _loadSavedLogs();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    setState(() {
      _isOffline = connectivityResult == ConnectivityResult.none;
    });
  }

  Future<void> _loadSavedLogs() async {
    final logs = await LocalStorageService.loadSugarLogs();
    if (logs.isNotEmpty) {
      setState(() {
        _sugarLogs = logs;
      });
      print('Loaded ${_sugarLogs.length} logs from local storage');
    }
  }

  Future<void> _trackSugar() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        if (_isOffline) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You are offline, please connect to the internet.'),
            ),
          );
          return;
        }

        final productData = await _apiService.searchProductByName(
          _productNameController.text,
        );

        final sugarPer100g = _apiService.extractSugarContent(productData);

        if (sugarPer100g != null) {
          final portionGrams = double.parse(_portionSizeController.text);
          final sugarConsumed = (portionGrams / 100) * sugarPer100g;

          final sugarLog = {
            'productName':
                productData?['product_name'] ?? _productNameController.text,
            'portionGrams': portionGrams,
            'sugarGrams': double.parse(sugarConsumed.toStringAsFixed(1)),
            'timestamp': Timestamp.fromDate(DateTime.now()),
          };

          //save to fire base
          try {
            await FirebaseFirestore.instance
                .collection('sugar_logs')
                .add(sugarLog);
            print(
              'Successfully saved to Firestore: ${sugarLog['productName']}',
            );
          } catch (e) {
            print('Error saving to Firestore: $e');
            throw e;
          }

          //save to local storage
          try {
            await LocalStorageService.saveSugarLogs(sugarLog);
          } catch (e) {
            print('Error saving to local storage: $e');
          }

          // You can still keep the local state update if needed for immediate UI refresh
          setState(() {
            _sugarLogs.insert(0, {
              ...sugarLog,
              'timestamp':
                  DateTime.now(), // Convert Timestamp back to DateTime for local use
            });
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sugar consumption tracked')),
          );

          // Clear fields
          _productNameController.clear();
          _portionSizeController.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Could not find sugar information for this product',
              ),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Errors: ${e.toString()}')));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _portionSizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sugar Tracker')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Track Sugar Consumption',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),

              // Product Name Input
              TextFormField(
                controller: _productNameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Chocolate Bar',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Portion Size Input
              TextFormField(
                controller: _portionSizeController,
                decoration: const InputDecoration(
                  labelText: 'Portion Size (g)',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 100',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a portion size';
                  }
                  final portion = double.tryParse(value);
                  if (portion == null || portion <= 0) {
                    return 'Please enter a valid positive number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Track button with loading indicator
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _trackSugar,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child:
                      _isLoading
                          ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text('TRACK', style: TextStyle(fontSize: 16)),
                ),
              ),

              const SizedBox(height: 24),

              // Sugar consumption overview
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                  ),
                ),
                child: Center(child: _getTotalSugarWidget()),
              ),

              const SizedBox(height: 24),

              // Sugar logs section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Sugar Logs',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton(
                    onPressed: () async {
                      setState(() {
                        _sugarLogs = [];
                      });
                      await LocalStorageService.clearLogs();
                    },
                    child: Text(
                      'Clear All',
                      style: TextStyle(color: AppTheme.primaryColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 200, // Fixed height
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    _sugarLogs.isEmpty
                        ? Center(
                          child: Text(
                            'No sugar logs yet',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        )
                        : ListView.builder(
                          itemCount: _sugarLogs.length,
                          itemBuilder: (context, index) {
                            final log = _sugarLogs[index];
                            return ListTile(
                              title: Text(
                                log['productName'],
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                '${log['portionGrams']}g • ${log['sugarGrams']}g sugar',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                              trailing: Text(
                                _formatDate(log['timestamp']),
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getTotalSugarWidget() {
    // Calculate total sugar for today
    final today = DateTime.now();
    final todayLogs =
        _sugarLogs.where((log) {
          final logDate = log['timestamp'] as DateTime;
          return logDate.day == today.day &&
              logDate.month == today.month &&
              logDate.year == today.year;
        }).toList();

    final totalSugar = todayLogs.fold<double>(
      0,
      (sum, log) => sum + (log['sugarGrams'] as double),
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Today\'s Sugar Consumption',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          '${totalSugar.toStringAsFixed(1)}g',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: _getSugarLevelColor(totalSugar),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _getSugarLevelMessage(totalSugar),
          style: TextStyle(
            color: _getSugarLevelColor(totalSugar),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getSugarLevelColor(double sugar) {
    // WHO recommends limiting sugar to about 25g per day for an adult
    if (sugar <= 25) return AppTheme.lowSugar;
    if (sugar <= 50) return AppTheme.mediumSugar;
    return AppTheme.highSugar;
  }

  String _getSugarLevelMessage(double sugar) {
    if (sugar <= 25) return 'Within recommended limit';
    if (sugar <= 50) return 'Approaching daily limit';
    return 'Exceeding recommended limit';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day &&
        date.month == now.month &&
        date.year == now.year) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
