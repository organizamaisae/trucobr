import 'dart:convert';

import 'package:aurora_cards/core/app.dart';
import 'package:aurora_cards/services/truco_service.dart';
import 'package:aurora_cards/widgets/truco_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> profile(String id, String name) => {
  'id': id,
  'name': name,
  'level': 1,
  'xp': 300,
  'wins': 3,
  'losses': 2,
  'games': 5,
  'win_rate': 60,
  'best': 2,
  'equipped': {},
  'online': true,
};

class FixtureService extends TrucoService {
  FixtureService({bool signedIn = true}) {
    token = signedIn ? 'test' : null;
    connected = true;
    data = {
      'profile': profile('a', 'Gustavo'),
      'chips': 10250,
      'earned': 10550,
      'spent': 300,
      'daily_available': true,
      'ledger': [
        {'amount': 10250, 'reason': 'Boas-vindas', 'date': '2026-09-11'},
      ],
      'history': [],
      'missions': [
        {
          'id': 'daily',
          'name': 'Jogue 3 partidas hoje',
          'progress': 0,
          'target': 3,
          'reward': 300,
          'claimed': false,
        },
      ],
      'achievements': [
        {'name': 'Primeira vitória', 'unlocked': true},
      ],
      'inventory': [],
    };
  }
  @override
  Future<void> restore() async {}
  @override
  Future<void> refresh() async {
    notifyListeners();
  }

  @override
  Future<Map<String, dynamic>> request(
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    if (path.contains('friends')) {
      return {
        'friends': [profile('b', 'Rafa')],
        'requests': [],
        'results': [],
        'invites': [],
      };
    }
    if (path.contains('ranking')) {
      return {
        'position': 1,
        'players': [
          {...profile('a', 'Gustavo'), 'points': 300, 'position': 1},
        ],
      };
    }
    if (path.contains('shop')) {
      return {
        'items': [
          {
            'id': 'avatar-0',
            'kind': 'avatar',
            'name': 'Explorador',
            'price': 500,
          },
        ],
        'inventory': [],
      };
    }
    if (path.contains('tournaments')) {
      return {
        'tournaments': [
          {
            'id': 't',
            'size': 8,
            'players': [],
            'rounds': [],
            'status': 'waiting',
          },
        ],
      };
    }
    if (path.contains('rooms')) {
      return {
        'code': 'ABC123',
        'name': 'Sala de teste',
        'host': 'a',
        'players': ['a'],
        'members': [profile('a', 'Gustavo')],
        'capacity': 2,
        'status': 'waiting',
        'rule': 'paulista',
        'game': null,
      };
    }
    return data;
  }
}

void main() {
  setUpAll(() async {
    for (final font in [
      ('Inter', 'assets/fonts/Inter.ttf'),
      ('RoyalSerif', 'assets/fonts/CormorantGaramond-Bold.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      await (FontLoader(font.$1)..addFont(rootBundle.load(font.$2))).load();
    }
  });
  test('API surfaces route errors and sends bearer token', () async {
    final service = TrucoService(
      client: MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer test');
        return http.Response(
          jsonEncode({'detail': 'Sala não encontrada'}),
          404,
        );
      }),
    );
    service.token = 'test';
    await expectLater(
      service.request('api/rooms/join', {'code': 'ABC123'}),
      throwsException,
    );
    service.dispose();
  });
  testWidgets('Login has email/password and no social login', (tester) async {
    await tester.pumpWidget(
      AuroraApp(service: FixtureService(signedIn: false)),
    );
    await tester.pumpAndSettle();
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.textContaining('Google'), findsNothing);
  });
  for (final size in [const Size(390, 844), const Size(844, 390)]) {
    testWidgets('All screens responsive at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = FixtureService();
      await tester.pumpWidget(AuroraApp(service: service));
      await tester.pumpAndSettle();
      for (final label in [
        'JOGAR',
        'SALA PRIVADA',
        'AMIGOS',
        'RANKING',
        'PERFIL',
        'LOJA',
        'TORNEIOS',
        'PARTIDAS',
      ]) {
        final target = find.text(label).first;
        await tester.ensureVisible(target);
        await tester.tap(target);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: label);
        if (size.width == 390) {
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(
              'goldens/truco_${['JOGAR', 'SALA PRIVADA', 'AMIGOS', 'RANKING', 'PERFIL', 'LOJA', 'TORNEIOS', 'PARTIDAS'].indexOf(label)}.png',
            ),
          );
        }
        await tester.tap(find.byIcon(Icons.arrow_back_ios_new).first);
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byTooltip('Carteira'));
      await tester.pumpAndSettle();
      expect(find.text('10.250'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Private room action reaches lobby', (tester) async {
    await tester.pumpWidget(AuroraApp(service: FixtureService()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SALA PRIVADA'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('CRIAR SALA'));
    await tester.tap(find.text('CRIAR SALA'));
    await tester.pumpAndSettle();
    expect(find.text('CÓDIGO: ABC123'), findsOneWidget);
    final start = tester.widget<GameButton>(
      find.widgetWithText(GameButton, 'INICIAR PARTIDA'),
    );
    expect(start.onPressed, isNull);
  });
  testWidgets('Match hides remote hands and fits landscape', (tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = FixtureService();
    await tester.pumpWidget(AuroraApp(service: service));
    await tester.pumpAndSettle();
    service.data['room'] = {
      'code': 'ABC123',
      'name': 'Mesa',
      'status': 'playing',
      'rule': 'paulista',
      'members': [
        profile('a', 'Gustavo'),
        profile('b', 'Rafa'),
        profile('c', 'Lia'),
        profile('d', 'Ana'),
      ],
      'game': {
        'seat': 0,
        'turn': 0,
        'players': ['a', 'b', 'c', 'd'],
        'pending': null,
        'winner': null,
        'scores': [0, 0],
        'stake': 1,
        'hand_no': 1,
        'hand_done': false,
        'counts': [3, 3, 3, 3],
        'hand': ['A♥', '3♣', '7♦'],
        'vira': 'Q♦',
        'table': [],
        'last_table': [],
        'raise_owner': null,
      },
    };
    service.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.text('TRUCO'), findsOneWidget);
    expect(find.text('CORRER'), findsOneWidget);
    expect(find.byType(TrucoCard), findsNWidgets(4));
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/truco_match.png'),
    );
  });
  testWidgets('Home visual reference', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(AuroraApp(service: FixtureService()));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/truco_home.png'),
    );
  });
}
