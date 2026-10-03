import 'package:flutter_test/flutter_test.dart';
import 'package:resque/models/sos_packet.dart';

void main() {
  test('ukrywa pozycję i rodzaj, gdy nie są zaznaczone', () {
    final draft = SosDraft(
      shareType: false,
      shareLocation: false,
      shareMessage: true,
      message: 'Potrzebna woda',
    );

    final packet = draft.toPacket(
      id: 'abc12345',
      timestamp: DateTime.utc(2026, 10, 3, 12, 30),
      latitude: 51.1,
      longitude: 17.0,
    );

    final json = packet.toJson();
    expect(json['latitude'], isNull);
    expect(json['longitude'], isNull);
    expect(json['type'], isNull);
    expect(json['message'], 'Potrzebna woda');
    expect(json['audience'], 'everyoneNearby');

    final again = SosPacket.fromJson(json);
    expect(again.shareLocation, isFalse);
    expect(again.shareType, isFalse);
    expect(again.latitude, isNull);
    expect(again.message, 'Potrzebna woda');
    expect(again.sharedLines.map((line) => line.label), ['Nazwa', 'Czas', 'Wiadomość']);
  });

  test('odrzuca zbyt długą wiadomość i wysyłkę do konkretnej osoby', () {
    final longMessage = SosDraft(
      shareMessage: true,
      message: 'a' * (SosDraft.maxMessageLength + 1),
    );
    expect(longMessage.validate(), contains('120'));

    final direct = SosDraft(audience: SosAudience.specificPerson);
    expect(direct.validate(), contains('konkretnej osoby'));

    final empty = SosDraft(
      shareType: false,
      shareLocation: false,
      shareSenderName: false,
      shareTimestamp: false,
      shareMessage: false,
    );
    expect(empty.validate(), contains('przynajmniej jedną'));
  });
}
