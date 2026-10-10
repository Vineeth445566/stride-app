import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/ads_service.dart';
import '../services/step_service.dart';
import 'history_screen.dart';
import 'home_tab.dart';
import 'settings_screen.dart';

/// Bottom-navigation shell. Persists step data when the app backgrounds.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      context.read<StepService>().persistNow();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Stride',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: IndexedStack(
        index: _tab,
        children: const [
          HomeTab(),
          HistoryScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) {
          if (i == 1) {
            // Interstitial (max once per 3 min) when opening History.
            context.read<AdsService>().maybeShowInterstitial();
          }
          setState(() => _tab = i);
        },
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.directions_walk), label: 'Today'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart), label: 'History'),
          NavigationDestination(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
