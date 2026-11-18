import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opentickly_app/main.dart';
import 'package:opentickly_app/track_api.dart' hide Row;

class Server extends TrackApi {
  final log = <Json>[];
  final workspaces = <Json>[
    {'id': 1, 'name': 'Privat'},
    {'id': 3, 'name': 'Personal Workspace', 'organization_id': 9},
  ];
  final calls = <String>[];
  Json? running;
  bool failStop = false;
  Server(super.base, super.token);
  @override
  Future<dynamic> request(
    String path, {
    String method = 'GET',
    Json? body,
  }) async {
    calls.add(path);
    if (path == 'me/organizations') {
      return [
        {'id': 9, 'name': 'Agentur'},
      ];
    }
    if (path.startsWith('workspaces/1/projects?') ||
        path.startsWith('workspaces/1/tags?')) {
      return [];
    }
    if (path == 'me/workspaces') return [...workspaces];
    if (path == 'me') return {'default_workspace_id': 1};
    if (path.startsWith('me/projects?') ||
        path.startsWith('workspaces/3/projects?')) {
      return [
        {'id': 12, 'workspace_id': 3, 'name': 'Studio'},
      ];
    }
    if (path.startsWith('me/tags?') || path.startsWith('workspaces/3/tags?')) {
      return [
        {'id': 17, 'workspace_id': 3, 'name': 'Design'},
        {'id': 18, 'workspace_id': 3, 'name': 'Review'},
      ];
    }
    if (path == 'me/time_entries') return [...log];
    if (path == 'me/time_entries/current') return running;
    if (path == 'workspaces/3/time_entries' && method == 'POST') {
      expect(body!['description'], 'Entwurf');
      expect(body['project_id'], 12);
      expect(body['tag_ids'], [17]);
      expect(body['billable'], true);
      return running = {
        ...body,
        'id': log.isEmpty ? 42 : 44,
        'project_name': 'Studio',
        'tags': ['Design'],
      };
    }
    if (path == 'workspaces/3/time_entries/42/stop' && method == 'PATCH') {
      if (failStop) throw TrackError(TrackFailure.timeout);
      log.add({
        ...running!,
        'stop': DateTime.now().toIso8601String(),
        'duration': 12,
      });
      running = null;
      return log.last;
    }
    fail('Unexpected request: $method $path');
  }
}

void main() {
  testWidgets(
    'Schlüsselbund-Login, Projekt mit Tags, Start/Stopp und Web-Abgleich',
    (tester) async {
      final server = Server(
        Uri.parse('https://test.invalid/api/v9/'),
        'fixture',
      );
      String? saved;
      final dockUpdates = <String?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(mac, (
        call,
      ) async {
        if (call.method == 'status') dockUpdates.add(call.arguments as String?);
        if (call.method == 'read') return null;
        if (call.method == 'save') saved = call.arguments as String;
        return null;
      });
      await tester.pumpWidget(
        OpenTicklyApp(initialLanguage: 'de', client: (_, _) => server),
      );
      await tester.pumpAndSettle();
      final serverField = find.byType(TextField).first;
      expect(tester.widget<TextField>(serverField).controller!.text, isEmpty);
      await tester.enterText(serverField, 'https://test.invalid');
      await tester.enterText(find.byType(TextField).last, 'fixture');
      await tester.tap(find.text('Verbinden'));
      await tester.pumpAndSettle();
      expect(jsonDecode(saved!)['token'], 'fixture');
      await tester.enterText(find.byType(TextField), 'Entwurf');
      expect(find.text('Keine Projekte vorhanden'), findsOneWidget);
      expect(find.text('Keine Tags vorhanden'), findsOneWidget);
      await tester.tap(find.byTooltip('Workspace auswählen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Agentur').last);
      await tester.pumpAndSettle();
      expect(find.text('Entwurf'), findsOneWidget);
      await tester.tap(find.byTooltip('Projekt auswählen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Studio').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tags'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Design'));
      await tester.pumpAndSettle();
      expect(jsonDecode(saved!)['defaults']['tag_ids'], [17]);
      final review = find.widgetWithText(CheckboxMenuButton, 'Review');
      await tester.tap(review);
      await tester.pumpAndSettle();
      expect(tester.widget<CheckboxMenuButton>(review).value, true);
      expect(jsonDecode(saved!)['defaults']['tag_ids'], [17, 18]);
      await tester.tap(review);
      await tester.pumpAndSettle();
      expect(tester.widget<CheckboxMenuButton>(review).value, false);
      expect(jsonDecode(saved!)['defaults']['tag_ids'], [17]);
      expect(find.text('Übernehmen'), findsNothing);
      expect(find.text('Abbrechen'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(review, findsNothing);
      await tester.tap(find.byTooltip('Abrechenbar'));
      await tester.tap(find.byTooltip('Timer starten'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Timer stoppen'), findsOneWidget);
      expect(dockUpdates.last, matches(RegExp(r'^\d+:\d{2}:\d{2}$')));
      server.running!['start'] = DateTime.now()
          .subtract(const Duration(seconds: 8))
          .toUtc()
          .toIso8601String();
      await tester.pump(const Duration(seconds: 1));
      expect(dockUpdates.last, isNot('0:00:00'));
      server.failStop = true;
      await tester.tap(find.byTooltip('Timer stoppen'));
      await tester.pumpAndSettle();
      expect(
        find.text('Der Server antwortet nicht rechtzeitig.'),
        findsOneWidget,
      );
      server.failStop = false;
      await tester.tap(find.byTooltip('Timer stoppen'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Timer starten'), findsOneWidget);
      expect(find.text('Entwurf'), findsOneWidget);
      final original = Map.of(server.log.single);
      await tester.tap(find.byTooltip('Eintrag fortsetzen'));
      await tester.pumpAndSettle();
      expect(server.running!['id'], isNot(original['id']));
      expect(server.running!['duration'], -1);
      expect(server.log.single, original);
      server.log.add({
        ...server.log.single,
        'id': 43,
        'description': 'Aus dem Web',
      });
      server.calls.clear();
      await tester.pump(const Duration(seconds: 30));
      await tester.pump();
      expect(find.text('Aus dem Web'), findsOneWidget);
      expect(server.calls, ['me/time_entries', 'me/time_entries/current']);
      expect(jsonDecode(saved!)['defaults'], {
        'workspace_id': 3,
        'project_id': 12,
        'tag_ids': [17],
        'billable': true,
      });
      await tester.tap(find.byTooltip('Einstellungen'));
      await tester.pumpAndSettle();
      expect(find.text('Abmelden'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'Manueller Sync, Migration und gespeicherte Auswahl beim Neustart',
    (tester) async {
      final server = Server(
        Uri.parse('https://test.invalid/api/v9/'),
        'fixture',
      );
      server.workspaces.removeAt(0);
      server.log.add({
        'id': 101,
        'wid': 3,
        'pid': 12,
        'tags': ['Design'],
        'billable': true,
        'description': 'Vorheriger Eintrag',
        'start': '2026-11-17T08:00:00Z',
        'stop': '2026-11-17T09:00:00Z',
        'duration': 3600,
      });
      var saved = jsonEncode({
        'url': server.base.toString(),
        'token': server.token,
      });
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(mac, (
        call,
      ) async {
        if (call.method == 'read') return saved;
        if (call.method == 'save') saved = call.arguments as String;
        return null;
      });
      Future<void> launch() async {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          OpenTicklyApp(initialLanguage: 'de', client: (_, _) => server),
        );
        await tester.pumpAndSettle();
      }

      await launch();
      expect(find.byTooltip('Workspace auswählen'), findsNothing);
      expect(find.text('Studio'), findsOneWidget);
      expect(find.text('Studio · Design · Abrechenbar'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      server.workspaces.add({'id': 1, 'name': 'Privat'});
      await tester.tap(find.byTooltip('Alles synchronisieren'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Workspace auswählen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Privat'));
      await tester.pumpAndSettle();
      expect(find.text('Keine Projekte vorhanden'), findsOneWidget);
      expect(find.text('Keine Tags vorhanden'), findsOneWidget);
      expect(find.text('Vorheriger Eintrag'), findsNothing);
      await launch();
      expect(find.text('Privat'), findsOneWidget);
      expect(find.text('Keine Projekte vorhanden'), findsOneWidget);
      expect(jsonDecode(saved)['defaults']['workspace_id'], 1);
      server.workspaces.removeLast();
      await tester.tap(find.byTooltip('Alles synchronisieren'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Workspace auswählen'), findsNothing);
      expect(find.text('Projekt'), findsOneWidget);
      expect(jsonDecode(saved)['defaults']['workspace_id'], 3);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('System language, English fallback and manual override', (
    tester,
  ) async {
    String? language;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(mac, (
      call,
    ) async {
      if (call.method == 'setLanguage') language = call.arguments as String?;
      return null;
    });
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(const OpenTicklyApp());
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsOneWidget);
    await tester.tap(find.byTooltip('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deutsch'));
    await tester.pumpAndSettle();
    expect(language, 'de');
    expect(find.text('Anmelden'), findsOneWidget);
    await tester.tap(find.byTooltip('Sprache'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Systemsprache'));
    await tester.pumpAndSettle();
    expect(language, isNull);
    expect(find.text('Sign in'), findsOneWidget);
    tester.platformDispatcher.localesTestValue = const [Locale('de', 'AT')];
    await tester.pumpAndSettle();
    expect(find.text('Anmelden'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
