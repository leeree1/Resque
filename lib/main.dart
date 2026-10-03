import 'package:flutter/material.dart';
import 'screens/sos_broadcast_screen.dart';
import 'screens/relay_monitor_screen.dart';
import 'screens/radar_screen.dart';

void main() {
  runApp(const ResqueApp());
}

class ResqueApp extends StatefulWidget {
  const ResqueApp({super.key});

  @override
  State<ResqueApp> createState() => _ResqueAppState();
}

class _ResqueAppState extends State<ResqueApp> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    SosBroadcastScreen(),
    RelayMonitorScreen(),
    RadarScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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