import 'dart:async';

import 'package:flutter/material.dart';
import 'models/sos_packet.dart';
import 'screens/sos_broadcast_screen.dart';
import 'screens/sos_incoming_screen.dart';
import 'screens/relay_monitor_screen.dart';
import 'screens/radar_screen.dart';
import 'services/mesh_engine.dart';
import 'services/nearby_mesh_service.dart';

void main() {
  runApp(const ResqueApp());
}

class ResqueApp extends StatefulWidget {
  const ResqueApp({super.key});

  @override
  State<ResqueApp> createState() => _ResqueAppState();
}

class _ResqueAppState extends State<ResqueApp> {
  final _navKey = GlobalKey<NavigatorState>();
  final _shownPacketIds = <String>{};
  late final StreamSubscription<SosPacket> _peerSub;
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    SosBroadcastScreen(),
    RelayMonitorScreen(),
    RadarScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _peerSub = MeshNodeService().peerAlerts.listen(_onPeerAlert);
    unawaited(NearbyMeshService().start());
  }

  @override
  void dispose() {
    _peerSub.cancel();
    super.dispose();
  }

  void _onPeerAlert(SosPacket packet) {
    if (!_shownPacketIds.add(packet.id)) return;

    void open() {
      if (!mounted) return;
      _navKey.currentState?.push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => SosIncomingScreen(packet: packet),
        ),
      );
    }

    if (_navKey.currentState == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => open());
    } else {
      open();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navKey,
      title: 'Resque',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: Scaffold(
        body: _screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: const Color(0xFF181818),
          selectedItemColor: Colors.redAccent,
          unselectedItemColor: Colors.white38,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.warning_amber_rounded),
              label: 'Nadaj SOS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.hub_outlined),
              label: 'Węzeł Mesh',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.radar),
              label: 'Radar BLE',
            ),
          ],
        ),
      ),
    );
  }
}