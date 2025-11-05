import 'package:flutter/material.dart';
import 'technician_home_screen.dart';
import 'technician_profile_screen.dart';
import 'technician_schedule_screen.dart';

class TechnicianMainPage extends StatefulWidget {
  const TechnicianMainPage({super.key});

  @override
  State<TechnicianMainPage> createState() => _TechnicianMainPageState();
}

class _TechnicianMainPageState extends State<TechnicianMainPage> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const TechnicianHomeScreen(),
    const TechnicianScheduleScreen(),
    const TechnicianProfileScreen(),
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
