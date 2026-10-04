import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart';
import 'sos_broadcast_screen.dart';
import '../models/sos_packet.dart';

enum AidCategory { all, trauma, emergency, environmental }

class AidProtocol {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final AidCategory category;
  final String priority;
  final List<String> steps;
  final List<String> warnings;
  final bool hasMetronome;

  const AidProtocol({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.category,
    required this.priority,
    required this.steps,
    required this.warnings,
    this.hasMetronome = false,
  });
}

class FirstAidScreen extends StatefulWidget {
  const FirstAidScreen({super.key});

  @override
  State<FirstAidScreen> createState() => _FirstAidScreenState();
}

class _FirstAidScreenState extends State<FirstAidScreen> {
  AidCategory _selectedCategory = AidCategory.all;
  String _searchQuery = '';

  final List<AidProtocol> _protocols = const [
    AidProtocol(
      id: 'rko',
      title: 'Zatrzymanie krążenia',
      subtitle: 'Brak oddechu i reakcji',
      icon: Icons.monitor_heart,
      accentColor: Color(0xFFFF2A4B),
      category: AidCategory.emergency,
      priority: 'KRYTYCZNY',
      hasMetronome: true,
      steps: [
        'Sprawdź bezpieczeństwo i udrożnij drogi oddechowe (odchyl głowę do tyłu).',
        'Sprawdzaj oddech przez 10 sekund (patrz, słuchaj, wyczuj).',
        'Rozpocznij uciskanie klatki piersiowej na głębokość 5-6 cm.',
        'Zachowaj rytm 100-120 uciśnięć na minutę w cyklu 30 uciśnięć : 2 wdechy.',
        'Użyj defibrylatora AED, gdy tylko będzie dostępny.',
      ],
      warnings: [
        'Nie przerywaj uciskania na dłużej niż 10 sekund.',
        'Nie bój się złamania żeber – priorytetem jest krążenie krwi.',
      ],
    ),
    AidProtocol(
      id: 'zadlawienie',
      title: 'Zadławienie / Krztuszenie',
      subtitle: 'Niedrożność dróg oddechowych',
      icon: Icons.air,
      accentColor: Color(0xFFFF9100),
      category: AidCategory.emergency,
      priority: 'PILNY',
      steps: [
        'Zachęcaj poszkodowanego do kaszlu, jeśli jest przytomny.',
        'Pochyl go do przodu i wykonaj 5 uderzeń w plecy między łopatkami.',
        'Wykonaj chwyt Heimlicha: 5 uciśnięć nadbrzusza od tyłu do siebie i w górę.',
        'Powtarzaj naprzemiennie: 5 uderzeń / 5 uciśnięć brzucha.',
      ],
      warnings: [
        'Nie wykonuj chwytu Heimlicha u niemowląt.',
        'Nie wkładaj palców do jamy ustnej na oślep.',
      ],
    ),
    AidProtocol(
      id: 'nieprzytomny',
      title: 'Utrata przytomności',
      subtitle: 'Oddycha, brak kontaktu',
      icon: Icons.hotel,
      accentColor: Color(0xFF00E5FF),
      category: AidCategory.emergency,
      priority: 'PILNY',
      steps: [
        'Sprawdź oddech przez 10 sekund.',
        'Ułóż osobę w pozycji bocznej ustalonej (bezpiecznej).',
        'Zabezpiecz przed wychłodzeniem folią NRC.',
        'Stale monitoruj oddech do nadejścia pomocy.',
      ],
      warnings: [
        'Nie podawaj napojów ani leków.',
        'Nie ruszaj poszkodowanego przy podejrzeniu urazu kręgosłupa.',
      ],
    ),
    AidProtocol(
      id: 'krwotok',
      title: 'Krwotok tętniczy / masywny',
      subtitle: 'Mocne krwawienie strugą',
      icon: Icons.water_drop,
      accentColor: Color(0xFFD50000),
      category: AidCategory.trauma,
      priority: 'KRYTYCZNY',
      steps: [
        'Zastosuj natychmiastowy bezpośredni ucisk rany.',
        'Załóż mocny opatrunek uciskowy.',
        'Jeśli krew nadal wypływa: załóż stazę taktyczną 5-7 cm powyżej rany.',
        'Zapisz dokładną godzinę założenia stazy.',
      ],
      warnings: [
        'Nie zakładaj stazy bezpośrednio na stawy.',
        'Nie luzuj raz zaciśniętej stazy.',
      ],
    ),
    AidProtocol(
      id: 'poparzenie',
      title: 'Oparzenia termiczne',
      subtitle: 'Ogień, wrzątek, para',
      icon: Icons.local_fire_department,
      accentColor: Color(0xFFFF5252),
      category: AidCategory.environmental,
      priority: 'ŚREDNI',
      steps: [
        'Schładzaj czystą wodą przez 15-20 minut.',
        'Zdejmij biżuterię i zegarek przed pojawieniem się obrzęku.',
        'Załóż jałowy opatrunek hydrożelowy lub suchą gazę.',
      ],
      warnings: [
        'Nie przekłuwaj pęcherzy.',
        'Nie smaruj masłem, olejem ani maściami.',
      ],
    ),
  ];

  List<AidProtocol> get _filteredProtocols {
    return _protocols.where((p) {
      final matchesCategory = _selectedCategory == AidCategory.all || p.category == _selectedCategory;
      final matchesSearch = p.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.subtitle.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _showProtocolSheet(AidProtocol protocol) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProtocolDetailSheet(protocol: protocol),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.medical_services, color: Color(0xFFFF2A4B), size: 20),
            SizedBox(width: 10),
            Text('APTECZKA // PROTOKOŁY RATUNKOWE', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Szukaj objawu lub procedury...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 20),
                filled: true,
                fillColor: const Color(0xFF161B22),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF30363D))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF30363D))),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildFilterChip('WSZYSTKIE', AidCategory.all),
                _buildFilterChip('NAGŁE STANY', AidCategory.emergency),
                _buildFilterChip('URAZY', AidCategory.trauma),
                _buildFilterChip('ŚRODOWISKO', AidCategory.environmental),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              itemCount: _filteredProtocols.length,
              itemBuilder: (context, index) {
                final item = _filteredProtocols[index];
                return GestureDetector(
                  onTap: () => _showProtocolSheet(item),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B22),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF30363D)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: item.accentColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(item.icon, color: item.accentColor, size: 22),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: item.accentColor.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                              child: Text(item.priority, style: TextStyle(color: item.accentColor, fontSize: 8, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, height: 1.2)),
                            const SizedBox(height: 4),
                            Text(item.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                          ],
                        ),
                        Row(
                          children: [
                            Text('Instrukcja', style: TextStyle(color: item.accentColor, fontSize: 10, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios, color: item.accentColor, size: 10),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, AidCategory category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {
          if (val) setState(() => _selectedCategory = category);
        },
        selectedColor: const Color(0xFFFF2A4B).withOpacity(0.2),
        backgroundColor: const Color(0xFF161B22),
        labelStyle: TextStyle(color: isSelected ? const Color(0xFFFF2A4B) : Colors.white60, fontSize: 10, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: isSelected ? const Color(0xFFFF2A4B) : const Color(0xFF30363D)),
        ),
      ),
    );
  }
}

class _ProtocolDetailSheet extends StatefulWidget {
  final AidProtocol protocol;
  const _ProtocolDetailSheet({required this.protocol});

  @override
  State<_ProtocolDetailSheet> createState() => _ProtocolDetailSheetState();
}

class _ProtocolDetailSheetState extends State<_ProtocolDetailSheet> {
  bool _isMetronomeRunning = false;
  int _cprCount = 0;
  Timer? _timer;

  void _toggleMetronome() {
    if (_isMetronomeRunning) {
      _timer?.cancel();
      setState(() {
        _isMetronomeRunning = false;
        _cprCount = 0;
      });
      return;
    }

    setState(() => _isMetronomeRunning = true);
    _timer = Timer.periodic(const Duration(milliseconds: 545), (_) {
      setState(() {
        _cprCount = (_cprCount % 30) + 1;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.protocol;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF161B22),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(top: BorderSide(color: Color(0xFF30363D), width: 1.5)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: p.accentColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                    child: Icon(p.icon, color: p.accentColor, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(p.subtitle, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  SosBroadcastScreen.customNote = 'Pilna pomoc: ${p.title} (${p.subtitle})';
                  SosBroadcastScreen.customType = EmergencyType.medical;
                  TacticalNavController.switchToSos();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF2A4B),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.emergency, size: 18),
                label: const Text('NADAJ SOS Z TYM URAZEM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.1)),
              ),
              const SizedBox(height: 20),
              if (p.hasMetronome) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D0F12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _isMetronomeRunning ? p.accentColor : const Color(0xFF30363D)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TEMPO RKO (110 BPM)', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                          Text(_isMetronomeRunning ? 'CYKL: $_cprCount / 30' : 'METRONOM GOTOWY', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: _toggleMetronome,
                        style: ElevatedButton.styleFrom(backgroundColor: p.accentColor, foregroundColor: Colors.white),
                        child: Text(_isMetronomeRunning ? 'STOP' : 'START'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              const Text('KROKI RATUNKOWE:', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
              const SizedBox(height: 10),
              ...p.steps.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: p.accentColor.withOpacity(0.2), shape: BoxShape.circle),
                        child: Text('${entry.key + 1}', style: TextStyle(color: p.accentColor, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(entry.value, style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.35))),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              const Text('CZEGO NIE ROBIĆ:', style: TextStyle(color: Color(0xFFFF5252), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
              const SizedBox(height: 8),
              ...p.warnings.map((w) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.close, color: Color(0xFFFF5252), size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(w, style: const TextStyle(color: Colors.white70, fontSize: 12))),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}