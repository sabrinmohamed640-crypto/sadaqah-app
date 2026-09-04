import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'screens/records_screen.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  DonationStorageService().initializeWithDemoData();
  runApp(const SadaqahApp());
}

class SadaqahApp extends StatelessWidget {
  const SadaqahApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sadaqah & Giving',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({Key? key}) : super(key: key);

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(
        onNavigateToRecords: () => setState(() => _currentIndex = 1),
      ),
      const RecordsScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.borderDark, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (idx) => setState(() => _currentIndex = idx),
          backgroundColor: AppTheme.bgDark,
          selectedItemColor: AppTheme.primaryEmeraldLight,
          unselectedItemColor: AppTheme.textMuted,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Records',
            ),
          ],
        ),
      ),
    );
  }
}
