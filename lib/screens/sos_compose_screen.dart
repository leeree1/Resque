import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../models/sos_packet.dart';
import '../services/mesh_engine.dart';
import '../services/nearby_mesh_service.dart';
import '../widgets/sos_packet_view.dart';

class SosComposeScreen extends StatefulWidget {
  const SosComposeScreen({super.key});

  @override
  State<SosComposeScreen> createState() => _SosComposeScreenState();
}

class _SosComposeScreenState extends State<SosComposeScreen> {
  final SosDraft _draft = SosDraft();
  final _nameController = TextEditingController(text: 'Osoba w pobliżu');
  final _messageController = TextEditingController();

  bool _sending = false;
  SosPacket? _lastPacket;

  @override
  void dispose() {
    _nameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _syncText() {
    _draft.senderName = _nameController.text;
    _draft.message = _messageController.text;
  }

  Future<Position?> _readPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _send() async {
    _syncText();
    final error = _draft.validate();
    if (error != null) {
      _showMessage(error);
      return;
    }

    setState(() => _sending = true);

    double? lat;
    double? lng;
    if (_draft.shareLocation) {
      final pos = await _readPosition();
      if (!mounted) return;
      if (pos == null) {
        setState(() => _sending = false);
        _showMessage(
          'Nie udało się odczytać pozycji. Odznacz pozycję GPS albo włącz lokalizację i spróbuj jeszcze raz.',
        );
        return;
      }
      lat = pos.latitude;
      lng = pos.longitude;
    }

    final packet = _draft.toPacket(
      id: const Uuid().v4().substring(0, 8),
      timestamp: DateTime.now(),
      latitude: lat,
      longitude: lng,
    );

    await MeshNodeService().broadcastMySos(packet);
    if (!mounted) return;
    setState(() {
      _sending = false;
      _lastPacket = packet;
    });
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    _syncText();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Co wysłać',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_lastPacket != null) _buildDeliveryCard(_lastPacket!),
            Expanded(
              child: ListView(
                key: const Key('sos-compose-list'),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                children: [
                  _buildQuietBanner(),
                  const SizedBox(height: 16),
                  _buildPeersLine(),
                  const SizedBox(height: 18),
                  const Text(
                    'Jakie informacje wysłać',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildTypeSection(),
                  _buildCheck(
                    'Pozycja GPS',
                    'Dołączana tylko, gdy jest zaznaczona.',
                    _draft.shareLocation,
                    (value) => setState(() => _draft.shareLocation = value),
                  ),
                  _buildCheck(
                    'Nazwa',
                    'Krótki opis nadawcy, do ${SosDraft.maxSenderNameLength} znaków.',
                    _draft.shareSenderName,
                    (value) => setState(() => _draft.shareSenderName = value),
                  ),
                  if (_draft.shareSenderName) _buildNameField(),
                  _buildCheck(
                    'Czas wysłania',
                    'Godzina z tego telefonu.',
                    _draft.shareTimestamp,
                    (value) => setState(() => _draft.shareTimestamp = value),
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: Colors.white12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _draft.shareMessage,
                    activeThumbColor: Colors.redAccent,
                    title: const Text('Dołącz wiadomość tekstową'),
                    subtitle: const Text(
                      'Limit ${SosDraft.maxMessageLength} znaków',
                    ),
                    onChanged: _sending
                        ? null
                        : (value) => setState(() => _draft.shareMessage = value),
                  ),
                  if (_draft.shareMessage) _buildMessageField(),
                  const SizedBox(height: 8),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 8),
                  const Text(
                    'Do kogo',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  RadioGroup<SosAudience>(
                    groupValue: _draft.audience,
                    onChanged: _sending
                        ? (_) {}
                        : (value) {
                            if (value == null ||
                                value == SosAudience.specificPerson) {
                              return;
                            }
                            setState(() => _draft.audience = value);
                          },
                    child: const Column(
                      children: [
                        RadioListTile<SosAudience>(
                          contentPadding: EdgeInsets.zero,
                          value: SosAudience.everyoneNearby,
                          title: Text('Wszyscy wokół'),
                          subtitle: Text(
                            'Każdy telefon z otwartą aplikacją Resque w zasięgu',
                          ),
                        ),
                        RadioListTile<SosAudience>(
                          contentPadding: EdgeInsets.zero,
                          value: SosAudience.specificPerson,
                          enabled: false,
                          title: Text('Konkretna osoba'),
                          subtitle: Text(
                            'Niedostępne. Na razie wysyłka idzie do wszystkich wokół.',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildPreview(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: FilledButton(
                key: const Key('send-sos'),
                onPressed: _sending ? null : _send,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  disabledBackgroundColor: Colors.redAccent.withValues(alpha: 0.4),
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _sending
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _lastPacket == null
                            ? 'Wyślij do wszystkich wokół'
                            : 'Wyślij ponownie',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuietBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF14241C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.35)),
      ),
      child: const Text(
        'Sygnał idzie wyłącznie do telefonów z otwartą aplikacją Resque w zasięgu. '
        'Nie pojawia się jako powiadomienie systemowe na telefonach obok. '
        'Latarka i kod QR są wyłączone.',
        style: TextStyle(color: Colors.white, height: 1.35),
      ),
    );
  }

  Widget _buildPeersLine() {
    return ListenableBuilder(
      listenable: NearbyMeshService(),
      builder: (context, _) {
        final link = NearbyMeshService();
        final countLabel = link.isSupported
            ? 'Aplikacje Resque w zasięgu: ${link.peersInRange}'
            : 'Ten ekran nie nadaje w zasięgu';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              countLabel,
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              link.statusMessage,
              style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.3),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTypeSection() {
    const types = [
      (EmergencyType.medical, 'Medyczne', Icons.medical_services_outlined),
      (EmergencyType.flood, 'Woda / Powódź', Icons.flood_outlined),
      (EmergencyType.trapped, 'Uwięzienie', Icons.warning_amber_outlined),
      (EmergencyType.fire, 'Pożar', Icons.local_fire_department_outlined),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCheck(
          'Rodzaj zagrożenia',
          null,
          _draft.shareType,
          (value) => setState(() => _draft.shareType = value),
        ),
        if (_draft.shareType)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in types)
                  ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.$3,
                          size: 16,
                          color: _draft.type == item.$1
                              ? Colors.white
                              : Colors.white60,
                        ),
                        const SizedBox(width: 6),
                        Text(item.$2),
                      ],
                    ),
                    selected: _draft.type == item.$1,
                    selectedColor: Colors.redAccent,
                    backgroundColor: const Color(0xFF1E1E1E),
                    labelStyle: TextStyle(
                      color: _draft.type == item.$1 ? Colors.white : Colors.white70,
                    ),
                    onSelected: _sending
                        ? null
                        : (selected) {
                            if (selected) setState(() => _draft.type = item.$1);
                          },
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCheck(
    String title,
    String? subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      activeColor: Colors.redAccent,
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      controlAffinity: ListTileControlAffinity.leading,
      onChanged: _sending
          ? null
          : (next) {
              if (next == null) return;
              onChanged(next);
            },
    );
  }

  Widget _buildNameField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: _nameController,
        enabled: !_sending,
        maxLength: SosDraft.maxSenderNameLength,
        style: const TextStyle(color: Colors.white),
        onChanged: (_) => setState(() {}),
        decoration: _fieldDecoration('Nazwa nadawcy'),
      ),
    );
  }

  Widget _buildMessageField() {
    return TextField(
      controller: _messageController,
      enabled: !_sending,
      maxLength: SosDraft.maxMessageLength,
      maxLines: 3,
      style: const TextStyle(color: Colors.white),
      onChanged: (_) => setState(() {}),
      decoration: _fieldDecoration('Treść wiadomości'),
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white60),
      counterStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'To zostanie wysłane',
            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          for (final line in _draft.previewLines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(line, style: const TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _buildDeliveryCard(SosPacket packet) {
    return ListenableBuilder(
      listenable: NearbyMeshService(),
      builder: (context, _) {
        final link = NearbyMeshService();
        final delivered = link.deliveredCount(packet.id);
        final String status;
        if (!link.isSupported) {
          status =
              'Zapisane tylko na tym urządzeniu. Druga osoba tego stąd nie odbierze.';
        } else if (delivered > 0) {
          status =
              'Dostarczono do $delivered połączeń z aplikacją Resque. Inne telefony nie dostały powiadomienia.';
        } else {
          status =
              'Pakiet czeka na drugą aplikację Resque w zasięgu. Zostaw obie aplikacje otwarte. Telefony bez Resque nic nie dostaną.';
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status,
                  style: const TextStyle(color: Colors.white, height: 1.35),
                ),
                const SizedBox(height: 10),
                Text(
                  'ID ${packet.id}',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(height: 8),
                SosPacketView(packet: packet, dense: true),
              ],
            ),
          ),
        );
      },
    );
  }
}
