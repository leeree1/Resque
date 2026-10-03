import 'dart:async';
import 'package:flutter/material.dart';

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
        'Zachowaj rytm 100-120 uciśnięć na minutę w cyklu 30 uciśnięć : 2 wdechy (lub ciągły masaż).',
        'Użyj defibrylatora AED, gdy tylko będzie dostępny.',
      ],
      warnings: [
        'Nie przerywaj uciskania na dłużej niż 10 sekund.',
        'Nie bój się złamania żeber – priorytetem jest natlenienie mózgu.',
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
        'Zachęcaj poszkodowanego do kaszlu, jeśli jest przytomny i wydaje dźwięki.',
        'Pochyl poszkodowanego do przodu i wykonaj do 5 energicznych uderzeń w plecy między łopatkami.',
        'Jeśli to nie pomaga, zastosuj chwyt Heimlicha: stań z tyłu, obejmij brzuch, przyłóż pięść nad pępkiem i pociągnij 5 razy do siebie i w górę.',
        'Powtarzaj naprzemiennie: 5 uderzeń w plecy / 5 uciśnięć nadbrzusza.',
        'Jeśli straci przytomność: natychmiast rozpocznij RKO.',
      ],
      warnings: [
        'Nie stosuj chwytu Heimlicha u niemowląt (u niemowląt uderzaj w plecy i uciskaj klatkę dwoma palcami).',
        'Nie wkładaj palców do gardła na oślep.',
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
        'Sprawdź reakcję na głos i delikatne potrząśnięcie za ramiona.',
        'Udrożnij drogi oddechowe i upewnij się, że poszkodowany prawidłowo oddycha.',
        'Ułóż w pozycji bocznej ustalonej (bezpiecznej), aby zapobiec zadławieniu językiem lub wymiocinami.',
        'Zabezpiecz przed wychłodzeniem kocem termicznym lub odzieżą.',
        'Stale monitoruj oddech do przybycia pomocy.',
      ],
      warnings: [
        'Nie kładź w pozycji bocznej, jeśli podejrzewasz uraz kręgosłupa i nie ma zagrożenia zachłyśnięciem.',
        'Nie podawaj niczego do picia ani jedzenia.',
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
        'Usuń źródło ciepła i zdejmij biżuterię z obrzękniętej kończyny.',
        'Schładzaj oparzone miejsce czystą, bieżącą wodą o temp. 15-20°C przez minimum 15-20 minut.',
        'Zabezpiecz ranę jałowym opatrunkiem hydrożelowym lub suchą gazą.',
        'W przypadku rozległych oparzeń zapobiegaj wstrząsowi i hipotermii (okryj resztę ciała folią NRC).',
      ],
      warnings: [
        'Nigdy nie przekłuwaj pęcherzy.',
        'Nie smaruj rany tłuszczem, masłem, maściami ani alkoholem.',
        'Nie odrywaj odzieży wtopionej w skórę – wytnij materiał dookoła.',
      ],
    ),
    AidProtocol(
      id: 'krwotok',
      title: 'Krwotok masywny',
      subtitle: 'Krew tętniąca lub lejąca się strugą',
      icon: Icons.water_drop,
      accentColor: Color(0xFFD50000),
      category: AidCategory.trauma,
      priority: 'KRYTYCZNY',
      steps: [
        'Wywrzyj natychmiastowy bezpośredni ucisk rany za pomocą dłoni w rękawiczce i gazy.',
        'Załóż mocny opatrunek uciskowy (bandaż elastyczny + rolka bandaża jako ucisk).',
        'Jeśli krwawienie z kończyny nie ustaje: załóż stazę taktyczną (opaskę uciskową) 5-7 cm powyżej rany.',
        'Dokręcaj stazę aż do całkowitego ustania krwawienia i zablokuj kołek.',
        'Napisz na czole lub opasce dokładną godzinę założenia stazy.',
      ],
      warnings: [
        'Nigdy nie zakładaj stazy bezpośrednio na staw (łokieć/kolano).',
        'Nie luzuj raz założonej stazy przed dotarciem do chirurga.',
      ],
    ),
    AidProtocol(
      id: 'zlamanie',
      title: 'Złamania i zwichnięcia',
      subtitle: 'Ból, deformacja, obrzęk',
      icon: Icons.accessibility_new,
      accentColor: Color(0xFFB0BEC5),
      category: AidCategory.trauma,
      priority: 'ŚREDNI',
      steps: [
        'Zasada Potta: unieruchom kość wraz z dwoma sąsiednimi stawami (np. przy złamaniu podudzia: kolano i staw skokowy).',
        'Przy złamaniu stawu: unieruchom staw wraz z dwiema sąsiednimi kośćmi.',
        'Użyj improwizowanej szyny (deska, kij, zwinięta karimata) i owiń bandażem.',
        'Sprawdzaj tętno i czucie obwodowe poniżej unieruchomienia.',
      ],
      warnings: [
        'Nie próbuj samodzielnie nastawiać kości ani prostować zdeformowanej kończyny.',
        'Przy złamaniu otwartym: nie wciskaj odłamków kostnych do wnętrza rany.',
      ],
    ),
    AidProtocol(
      id: 'udar',
      title: 'Udar mózgu',
      subtitle: 'Asymetria twarzy, niedowład, bełkot',
      icon: Icons.psychology,
      accentColor: Color(0xFF7C4DFF),
      category: AidCategory.emergency,
      priority: 'KRYTYCZNY',
      steps: [
        'Zastosuj test FAST:',
        'F (Face) – poproś o uśmiech (czy opada kącik ust?).',
        'A (Arms) – poproś o uniesienie obu rąk (czy jedna opada?).',
        'S (Speech) – poproś o powtórzenie prostego zdania (czy mowa jest bełkotliwa?).',
        'T (Time) – kluczowy czas: ułóż chorego z lekko uniesioną głową (30°) i natychmiast nadaj sygnał SOS.',
      ],
      warnings: [
        'Nie podawaj kwasu acetylosalicylowego (aspiryny) – to może być udar krwotoczny!',
        'Nie podawaj płynów ze względu na ryzyko zachłyśnięcia.',
      ],
    ),
    AidProtocol(
      id: 'hipotermia',
      title: 'Hipotermia / Wychłodzenie',
      subtitle: 'Dreszcze, apatia, zalanie zimną wodą',
      icon: Icons.ac_unit,
      accentColor: Color(0xFF40C4FF),
      category: AidCategory.environmental,
      priority: 'PILNY',
      steps: [
        'Odizoluj od podłoża (karimata, gałęzie, deski) i osłoń od wiatru.',
        'Zdejmij mokrą odzież, osusz ciało i załóż suche warstwy.',
        'Zawiń w folię termiczną NRC – srebrną stroną do wewnątrz.',
        'Ogrzewaj centralnie (tułów, pachy, klatka piersiowa).',
        'Podawaj ciepłe, słodkie płyny wyłącznie, jeśli osoba jest w pełni przytomna.',
      ],
      warnings: [
        'Nie rozcieraj rąk i nóg (ryzyko przemieszczenia zimnej krwi z obwodu do serca i zatrzymania krążenia).',
        'Nie podawaj alkoholu.',
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
            Icon(Icons.medical_services, color: Color(0xFFFF2A4B), size: 22),
            SizedBox(width: 10),
            Text(
              'APTECZKA // PROTOKOŁY RATUNKOWE',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Pole wyszukiwania
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF30363D)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF30363D)),
                ),
              ),
            ),
          ),

          // Filtry kategorii
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildFilterChip('WSZYSTKIE', AidCategory.all),
                _buildFilterChip('NAGŁE STANY', AidCategory.emergency),
                _buildFilterChip('URAZY I KRWOTOKI', AidCategory.trauma),
                _buildFilterChip('ŚRODOWISKOWE', AidCategory.environmental),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Siatka kafelków procedur
          Expanded(
            child: _filteredProtocols.isEmpty
                ? const Center(
                    child: Text(
                      'Brak procedury pasującej do kryteriów',
                      style: TextStyle(color: Colors.white38),
                    ),
                  )
                : GridView.builder(
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
                      return _buildProtocolTile(item);
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
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFFFF2A4B) : Colors.white60,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected ? const Color(0xFFFF2A4B) : const Color(0xFF30363D),
          ),
        ),
      ),
    );
  }

  Widget _buildProtocolTile(AidProtocol item) {
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
                  child: Icon(item.icon, color: item.accentColor, size: 24),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: item.accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.priority,
                    style: TextStyle(
                      color: item.accentColor,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  'Instrukcja (${item.steps.length})',
                  style: TextStyle(color: item.accentColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios, color: item.accentColor, size: 10),
              ],
            ),
          ],
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
    final isBreath = _cprCount > 28;

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
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: p.accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(p.icon, color: p.accentColor, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.title,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          p.subtitle,
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Opcjonalny wbudowany metronom RKO
              if (p.hasMetronome) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D0F12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isMetronomeRunning ? (isBreath ? Colors.cyanAccent : p.accentColor) : const Color(0xFF30363D),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TEMPO RKO (110 BPM)', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                          Text(
                            _isMetronomeRunning ? 'CYKL: $_cprCount / 30' : 'METRONOM GOTOWY',
                            style: TextStyle(
                              color: _isMetronomeRunning ? Colors.white : Colors.white38,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: _toggleMetronome,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isMetronomeRunning ? Colors.grey.shade800 : p.accentColor,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(_isMetronomeRunning ? 'STOP' : 'START'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              const Text(
                'DZIAŁANIE KROK PO KROKU:',
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1),
              ),
              const SizedBox(height: 10),
              ...p.steps.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final text = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: p.accentColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$idx',
                          style: TextStyle(color: p.accentColor, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          text,
                          style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 16),
              const Text(
                'CZEGO BEZWZGLĘDNIE NIE ROBIĆ:',
                style: TextStyle(color: Color(0xFFFF5252), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1),
              ),
              const SizedBox(height: 8),
              ...p.warnings.map((w) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.close, color: Color(0xFFFF5252), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(w, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}