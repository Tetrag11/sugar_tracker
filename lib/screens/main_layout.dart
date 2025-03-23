import 'package:flutter/material.dart';
import 'package:sugar_tracker/screens/home/home_screen.dart';
import 'package:sugar_tracker/screens/sugar_log/sugar_log_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [const HomeScreen(), const SugarLogScreen()];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),

          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Sugar Log',
          ),
        ],
      ),
    );
  }
}
