import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/sos_broadcast_screen.dart';
import 'screens/relay_monitor_screen.dart';
import 'screens/radar_screen.dart';
import 'screens/map_offline_screen.dart';
import 'screens/first_aid_screen.dart';
import 'services/mesh_engine.dart';
import 'services/nearby_mesh_service.dart';
import 'services/firebase_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  MeshNodeService();
  runApp(const ResqueApp());
  unawaited(NearbyMeshService().start());

  // Okresowa synchronizacja bufora z Firebase (co 60 s)
  Timer.periodic(const Duration(minutes: 1), (_) {
    FirebaseSyncService.trySyncInBackground();
  });
}

class ResqueApp extends StatelessWidget {
  const ResqueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Resque Tactical Mesh',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0F12),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF2A4B),
          secondary: Color(0xFF00E5FF),
          surface: Color(0xFF161B22),
          surfaceContainerHighest: Color(0xFF21262D),
        ),
        fontFamily: 'monospace',
        useMaterial3: true,
      ),
      home: const TacticalRootNavigation(),
    );
  }
}

class TacticalRootNavigation extends StatefulWidget {
  const TacticalRootNavigation({super.key});

  @override
  State<TacticalRootNavigation> createState() => _TacticalRootNavigationState();
}

class _TacticalRootNavigationState extends State<TacticalRootNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    SosBroadcastScreen(),
    RelayMonitorScreen(),
    RadarScreen(),
    MapOfflineScreen(),
    FirstAidScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF30363D), width: 1)),
        ),
        child: NavigationBar(
          height: 68,
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          backgroundColor: const Color(0xFF0D0F12),
          indicatorColor: const Color(0xFFFF2A4B).withOpacity(0.2),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.emergency_outlined, color: Colors.white60),
              selectedIcon: Icon(Icons.emergency, color: Color(0xFFFF2A4B)),
              label: 'NADAJNIK',
            ),
            NavigationDestination(
              icon: Icon(Icons.hub_outlined, color: Colors.white60),
              selectedIcon: Icon(Icons.hub, color: Color(0xFF00E5FF)),
              label: 'WĘZEŁ',
            ),
            NavigationDestination(
              icon: Icon(Icons.radar_outlined, color: Colors.white60),
              selectedIcon: Icon(Icons.radar, color: Colors.greenAccent),
              label: 'RADAR',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined, color: Colors.white60),
              selectedIcon: Icon(Icons.map, color: Colors.amberAccent),
              label: 'SZTAB',
            ),
            NavigationDestination(
              icon: Icon(Icons.medical_services_outlined, color: Colors.white60),
              selectedIcon: Icon(Icons.medical_services, color: Colors.redAccent),
              label: 'APTECZKA',
            ),
          ],
        ),
      ),
    );
  }
}