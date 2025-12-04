// lib/screens/Technician/technician_main_page.dart
// Main page với bottom navigation: Công việc, Lịch làm việc, Cá nhân

import 'package:flutter/material.dart';
import 'technician_home_screen.dart';
import 'technician_schedule_screen.dart';
import 'technician_profile_screen.dart';

class TechnicianMainPage extends StatefulWidget {
  final int initialIndex; // Tab mặc định khi mở
  
  const TechnicianMainPage({
    super.key,
    this.initialIndex = 0, // Mặc định là tab "Công việc"
  });

  @override
  State<TechnicianMainPage> createState() => _TechnicianMainPageState();
}

class _TechnicianMainPageState extends State<TechnicianMainPage> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  final List<Widget> _screens = [
    const TechnicianHomeScreen(),      // Tab 0: Công việc
    const TechnicianScheduleScreen(),  // Tab 1: Lịch làm việc
    const TechnicianProfileScreen(),   // Tab 2: Cá nhân
  ];

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
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'Công việc',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Lịch làm việc',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }
}