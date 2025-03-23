import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:sugar_tracker/utils/theme.dart';
import 'package:sugar_tracker/screens/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Skip Firebase initialization in test environment
  if (!const bool.fromEnvironment('FLUTTER_TEST')) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sugar Tracker',
      theme: AppTheme.lightTheme,
      home: const MainLayout(),
    );
  }
}
