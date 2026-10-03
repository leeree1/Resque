import 'dart:async';
import 'package:flutter/material.dart';

class FirstAidScreen extends StatefulWidget {
  const FirstAidScreen({super.key});

  @override
  State<FirstAidScreen> createState() => _FirstAidScreenState();
}

class _FirstAidScreenState extends State<FirstAidScreen> {
  bool _isCprActive = false;
  int _cprCount = 0;
  Timer? _cprTimer;

  void _toggleCpr() {
    if (_isCprActive) {
      _cprTimer?.cancel();
      setState(() {
        _isCprActive = false;
        _cprCount = 0;
      });
      return;
    }

    setState(() => _isCprActive = true);
    // Tempo 110 uderzeń na minutę (standard RKO)
    _cprTimer = Timer.periodic(const Duration(milliseconds: 545), (timer) {
      setState(() {
        _cprCount = (_cprCount % 30) + 1;
      });
    });
  }

  @override
  void dispose() {
    _cprTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBreathMoment = _cprCount > 28;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.health_and_safety, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('PROCEDURY RATUNKOWE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Interaktywny Moduł Asystenta RKO
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isCprActive ? (isBreathMoment ? Colors.cyanAccent : Colors.redAccent) : const Color(0xFF30363D),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ASYSTENT RKO (110 BPM)',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                    ),
                    if (_isCprActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isBreathMoment ? Colors.cyanAccent : Colors.redAccent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isBreathMoment ? 'WDECH!' : 'UCIŚNIĘCIE',
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _isCprActive ? '$_cprCount / 30' : 'METRONOM ZATRZYMANY',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: _isCprActive ? Colors.white : Colors.white38,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _toggleCpr,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isCprActive ? Colors.grey.shade800 : Colors.redAccent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 45),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: Icon(_isCprActive ? Icons.stop : Icons.play_arrow),
                  label: Text(_isCprActive ? 'ZATRZYMAJ METRONOM' : 'URUCHOM TEMPO UCIŚNIĘĆ'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'PROTOKOŁY TRAUMA OFFLINE',
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          _buildProtocolCard(
            title: 'KRWOTOK TĘTNICZY',
            tag: 'PRIORYTET I',
            tagColor: Colors.redAccent,
            steps: '1. Bezpośredni ucisk rany gazą lub odzieżą.\n2. Załóż opaskę uciskową (stazę) 5-7 cm powyżej zranienia.\n3. Zapisz dokładną godzinę założenia stazy.',
          ),
          _buildProtocolCard(
            title: 'HIPOTERMIA / ZALANIE',
            tag: 'POWÓDŹ',
            tagColor: Colors.cyanAccent,
            steps: '1. Zdejmij mokre ubranie, odizoluj od podłoża.\n2. Owiń folią NRC (srebrną stroną do ciała).\n3. Nie rozgrzewaj gwałtownie kończyn.',
          ),
          _buildProtocolCard(
            title: 'UWIĘZIENIE POD GRUZAMI',
            tag: 'CRUSH SYNDROME',
            tagColor: Colors.amberAccent,
            steps: '1. Ogranicz ruchy, oszczędzaj tlen i energię telefonu.\n2. Uderzaj rytmicznie metalem w rury (dźwięk niesie się dalej niż krzyk).\n3. Włącz latarkę SOS na ekranie głównym Resque.',
          ),
        ],
      ),
    );
  }

  Widget _buildProtocolCard({
    required String title,
    required String tag,
    required Color tagColor,
    required String steps,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: tagColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(tag, style: TextStyle(color: tagColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(steps, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
        ],
      ),
    );
  }
}