import 'dart:async';
import 'package:flutter/material.dart';
import 'screens/sos_broadcast_screen.dart';
import 'screens/relay_monitor_screen.dart';
import 'screens/radar_screen.dart';
import 'services/mesh_engine.dart';
import 'services/nearby_mesh_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicjalizacja bazy Store-and-Forward
  MeshNodeService();

  runApp(const ResqueApp());

  // Uruchomienie nasłuchu i rozgłaszania Nearby po wyrenderowaniu pierwszej klatki UI
  unawaited(NearbyMeshService().start());
}

class ResqueApp extends StatelessWidget {
  const ResqueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Resque',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Colors.redAccent,
          secondary: Colors.cyanAccent,
          surface: Color(0xFF1E1E1E),
        ),
        useMaterial3: true,
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    SosBroadcastScreen(),
    RelayMonitorScreen(),
    RadarScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF181818),
        indicatorColor: Colors.redAccent.withOpacity(0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.sos, color: Colors.white70),
            selectedIcon: Icon(Icons.sos, color: Colors.redAccent),
            label: 'Nadaj SOS',
          ),
          NavigationDestination(
            icon: Icon(Icons.hub_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.hub, color: Colors.cyanAccent),
            label: 'Węzeł Mesh',
          ),
          NavigationDestination(
            icon: Icon(Icons.radar_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.radar, color: Colors.greenAccent),
            label: 'Radar BLE',
          ),
        ],
      ),
    );
  }
}