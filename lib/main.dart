import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/User/user_home_screen.dart';
import 'screens/User/user_profile_screen.dart';
import 'screens/User/user_service_screen.dart';
import 'screens/User/user_news_screen.dart';
import 'services/notification_service.dart'; // ← THÊM

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  const storage = FlutterSecureStorage();
  await storage.delete(key: 'access_token');
  
  // ✅ Khởi tạo locale tiếng Việt
  await initializeDateFormatting('vi_VN', null);
  
  // Khởi tạo Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // ✅ THÊM: Initialize notification service
  try {
    await NotificationService().initialize();
    print('✅ Notification service initialized');
  } catch (e) {
    print('❌ Error initializing notifications: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.white,
      ),
      
      // ✅ LOCALIZATION CONFIG (FIX DATEPICKER)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi', 'VN'), // Tiếng Việt
        Locale('en', 'US'), // English
      ],
      locale: const Locale('vi', 'VN'),
      
      routes: {
        '/login': (context) => const LoginScreen(),
      },
      
      home: const WelcomeScreen(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const UserServiceScreen(),
    const NewsScreen(),
    const ProfileScreen(),
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
            icon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: 'Dịch vụ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.newspaper),
            label: 'Tin tức',
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