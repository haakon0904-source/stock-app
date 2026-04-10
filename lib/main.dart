import 'package:flutter/material.dart';
import 'screens/screener_screen.dart';
import 'screens/portfolio_screen.dart';
import 'screens/etf_screen.dart';

void main() {
  runApp(const StockApp());
}

class StockApp extends StatelessWidget {
  const StockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '주식 분석',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0A0E1A),
        cardTheme: const CardThemeData(
          color: Color(0xFF141929),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ScreenerScreen(),
    PortfolioScreen(),
    EtfScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: const Color(0xFF0D1120),
        indicatorColor: const Color(0xFF1565C0).withOpacity(0.3),
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.trending_up), label: '스크리닝'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet), label: '포트폴리오'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'ETF'),
        ],
      ),
    );
  }
}
