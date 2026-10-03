import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resque/main.dart';
import 'package:resque/models/sos_packet.dart';
import 'package:resque/services/mesh_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  testWidgets('kliknięcie SOS otwiera wybór danych i odbiorców', (tester) async {
    await tester.pumpWidget(const ResqueApp());
    await tester.pump();

    await tester.tap(find.byKey(const Key('open-sos')));
    await tester.pumpAndSettle();

    expect(find.text('Co wysłać'), findsOneWidget);

    final list = find.descendant(
      of: find.byKey(const Key('sos-compose-list')),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ),
    );
    await tester.scrollUntilVisible(
      find.text('Limit 120 znaków'),
      250,
      scrollable: list,
    );
    expect(find.text('Dołącz wiadomość tekstową'), findsOneWidget);
    expect(find.text('Limit 120 znaków'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Wszyscy wokół'),
      250,
      scrollable: list,
    );
    expect(find.text('Wszyscy wokół'), findsOneWidget);
    expect(find.text('Konkretna osoba'), findsOneWidget);
  });

  testWidgets('odebrany pakiet widać w aplikacji, nie jako alert systemowy', (tester) async {
    await tester.pumpWidget(const ResqueApp());
    await tester.pump();

    final packet = SosDraft(
      shareLocation: false,
      shareMessage: true,
      message: 'Test odbioru',
    ).toPacket(
      id: 'odbiort1',
      timestamp: DateTime.utc(2026, 10, 3, 12),
    );

    await MeshNodeService().onPacketReceivedFromPeer(
      jsonEncode(packet.toJson()),
      relay: false,
    );
    await tester.pumpAndSettle();

    expect(find.text('Test odbioru'), findsOneWidget);
    expect(
      find.textContaining('nie jest powiadomienie systemowe'),
      findsOneWidget,
    );
  });
}
