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
  Map<String, dynamic>? lastTournament;
  Map<String, dynamic>? lastInvite;
  FixtureService({bool signedIn = true, bool admin = false}) {
    token = signedIn ? 'test' : null;
    connected = true;
    data = {
      'profile': profile('a', 'Gustavo'),
      'can_create_tournaments': admin,
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
    if (path == 'api/invite/respond') {
      lastInvite = body;
      data['invites'] = [];
      return request('api/rooms/state');
    }
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
      if (path.endsWith('/create')) lastTournament = body;
      return {
        'names': data['tournament_names'] ?? {},
        'tournaments':
            data['tournaments'] ??
            [
              if (lastTournament != null)
                {
                  'id': 't',
                  'name': lastTournament!['name'],
                  'size': lastTournament!['size'],
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

Future<void> settleImages(WidgetTester tester) async {
  final context = tester.element(find.byType(MaterialApp));
  final providers = tester
      .widgetList<Image>(find.byType(Image))
      .map((image) => image.image)
      .toSet();
  await tester.runAsync(
    () => Future.wait(providers.map((image) => precacheImage(image, context))),
  );
  await tester.pumpAndSettle();
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
  test(
    'Concurrent reads share HTTP and identical states do not rebuild',
    () async {
      var calls = 0;
      final service = TrucoService(
        client: MockClient((request) async {
          calls++;
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return http.Response('{"chips":100}', 200);
        }),
      );
      var changes = 0;
      service.addListener(() => changes++);
      await Future.wait([service.refresh(), service.refresh()]);
      expect(calls, 1);
      expect(changes, 1);
      await service.refresh();
      expect(changes, 1);
      service.dispose();
    },
  );
  testWidgets('Finished tournament never offers return to room', (
    tester,
  ) async {
    final service = FixtureService();
    service.data['room'] = {
      'code': 'FINAL',
      'status': 'finished',
      'tournament': 't1',
    };
    await tester.pumpWidget(AuroraApp(service: service));
    service.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.text('VOLTAR À SALA'), findsNothing);
    service.data['room'] = {
      'code': 'OPEN',
      'status': 'waiting',
      'tournament': null,
    };
    service.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.text('VOLTAR À SALA'), findsOneWidget);
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
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      AuroraApp(service: FixtureService(signedIn: false)),
    );
    await tester.pumpAndSettle();
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.textContaining('Google'), findsNothing);
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/images/truco-br-login-logo.png'),
        tester.element(find.byType(Scaffold)),
      ),
    );
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/images/truco-br-background.png'),
        tester.element(find.byType(Scaffold)),
      ),
    );
    await tester.pumpAndSettle();
    await settleImages(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/truco_br_login.png'),
    );
  });
  for (final admin in [false, true]) {
    testWidgets('Tournament creation visibility admin=$admin', (tester) async {
      final service = FixtureService(admin: admin);
      await tester.pumpWidget(AuroraApp(service: service));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('TORNEIOS'));
      await tester.tap(find.text('TORNEIOS'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Nenhum torneio publicado'), findsOneWidget);
      expect(find.text('CRIAR TORNEIO'), admin ? findsOneWidget : findsNothing);
      if (admin) {
        await tester.tap(find.text('CRIAR TORNEIO'));
        await tester.pumpAndSettle();
        expect(find.text('Criar torneio'), findsOneWidget);
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();
      }
    });
  }
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
          await settleImages(tester);
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(
              'goldens/truco_${['JOGAR', 'SALA PRIVADA', 'AMIGOS', 'RANKING', 'PERFIL', 'LOJA', 'TORNEIOS', 'PARTIDAS'].indexOf(label)}.png',
            ),
          );
        }
        if (label == 'TORNEIOS') {
          await tester.tap(find.text('Início').last);
        } else {
          await tester.tap(find.byIcon(Icons.arrow_back_ios_new).first);
        }
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byTooltip('Carteira'));
      await tester.pumpAndSettle();
      expect(find.text('10.250'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Tournament cards, adaptive bracket and winner profile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = FixtureService();
    service.data['tournament_names'] = {
      'a': 'Gustavo',
      'b': 'Rafa',
      'c': 'Lia',
      'd': 'Ana',
    };
    service.data['tournaments'] = [
      {
        'id': 'cup',
        'name': 'Copa dos Amigos',
        'mode': '2v2',
        'size': 16,
        'players': ['a', 'b', 'c', 'd'],
        'status': 'playing',
        'prize': 1000,
        'rounds': [
          [
            {
              'room': 'ABC123',
              'players': ['a', 'b', 'c', 'd'],
              'teams': [
                ['a', 'c'],
                ['b', 'd'],
              ],
              'winner': null,
            },
          ],
        ],
      },
      {
        'id': 'night',
        'name': 'Truco da Noite',
        'mode': '1v1',
        'size': 32,
        'players': ['a', 'b'],
        'status': 'playing',
        'rounds': [],
        'prize': 500,
      },
      {
        'id': 'bronze',
        'name': 'Copa Bronze',
        'mode': '1v1',
        'size': 8,
        'players': ['c', 'd'],
        'status': 'playing',
        'rounds': [],
        'prize': 500,
      },
    ];
    await tester.pumpWidget(AuroraApp(service: service));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Torneios').last);
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/images/truco-br-tournaments.png'),
        tester.element(find.byType(Scaffold)),
      ),
    );
    await tester.pumpAndSettle();
    await settleImages(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/tournaments_live.png'),
    );
    await tester.ensureVisible(find.text('ACOMPANHAR').last);
    await tester.tap(find.text('ACOMPANHAR').last);
    await tester.pumpAndSettle();
    expect(find.text('Gustavo + Lia'), findsOneWidget);
    expect(find.text('Rafa + Ana'), findsOneWidget);
    await settleImages(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/bracket.png'),
    );
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    final trophy = {
      'id': 'cup',
      'name': 'Copa dos Amigos',
      'mode': '2v2',
      'date': '2026-09-12T18:00:00Z',
      'chips': 500,
      'xp': 1000,
      'champions': ['a', 'c'],
    };
    service.data['profile']['trophies'] = [trophy];
    service.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.text('CAMPEÃO!'), findsNothing);
    await tester.tap(find.text('Perfil').last);
    await tester.pumpAndSettle();
    expect(find.text('Copa dos Amigos'), findsOneWidget);
  });

  testWidgets('Monthly pass shows earned XP and rewards', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = FixtureService();
    service.data['monthly_pass'] = {
      'month': '2026-09',
      'xp': 600,
      'active': true,
      'price': 3000,
      'levels': [
        for (int i = 1; i <= 10; i++)
          {
            'level': i,
            'target': i * 200,
            'chips': i * 100,
            'claimed': i == 1,
            'item': i == 3 ? 'back-4' : null,
          },
      ],
    };
    await tester.pumpWidget(AuroraApp(service: service));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Loja').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Passe'));
    await tester.tap(find.text('Passe'));
    await tester.pumpAndSettle();
    expect(find.text('600 XP neste mês • 10 conquistas'), findsOneWidget);
    expect(find.text('Resgatado'), findsOneWidget);
    await settleImages(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/monthly_pass.png'),
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('Eight player bracket and spectator controls', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = FixtureService();
    service.data['tournament_names'] = {
      for (int i = 0; i < 8; i++) 'p$i': 'Jogador ${i + 1}',
    };
    service.data['tournaments'] = [
      {
        'id': 'tree',
        'name': 'Copa da Praia',
        'mode': '1v1',
        'size': 8,
        'players': <String>[],
        'status': 'playing',
        'starts_at': '2026-09-15T21:00:00Z',
        'rounds': [
          [
            for (int i = 0; i < 4; i++)
              {
                'room': 'LIVE$i',
                'players': ['p${i * 2}', 'p${i * 2 + 1}'],
                'teams': [
                  ['p${i * 2}'],
                  ['p${i * 2 + 1}'],
                ],
                'winner': null,
              },
          ],
        ],
      },
    ];
    await tester.pumpWidget(AuroraApp(service: service));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Torneios').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ACOMPANHAR'));
    await tester.pumpAndSettle();
    expect(find.text('SEMIFINAL'), findsOneWidget);
    expect(find.text('ASSISTIR AO VIVO'), findsNWidgets(4));
    await settleImages(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/bracket_eight.png'),
    );
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    service.spectatingCode = 'LIVE0';
    service.spectatedRoom = {
      'code': 'LIVE0',
      'tournament': 'tree',
      'spectator': true,
      'status': 'playing',
      'table': 'table-5',
      'rule': 'paulista',
      'members': [profile('p0', 'Rafa'), profile('p1', 'Lia')],
      'game': {
        'seat': 0,
        'turn': 0,
        'scores': [3, 6],
        'counts': [3, 3],
        'hand': <String>[],
        'pending': null,
        'winner': null,
        'table': <dynamic>[],
        'hand_done': false,
        'vira': 'Q♦',
        'hand_no': 1,
        'stake': 1,
      },
    };
    service.notifyListeners();
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/images/table-praia.png'),
        tester.element(find.byType(Scaffold)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('TRUCO'), findsNothing);
    expect(find.text('CORRER'), findsNothing);
    expect(find.text('Agora é Você'), findsNothing);
    expect(find.byType(TrucoCard), findsOneWidget);
    await settleImages(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/spectator_praia.png'),
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('SAIR DO MODO ESPECTADOR'));
    await tester.pumpAndSettle();
    expect(service.spectatingCode, isNull);
  });
  testWidgets('Room invite overlays profile and open dialog, then joins', (
    tester,
  ) async {
    final service = FixtureService();
    await tester.pumpWidget(AuroraApp(service: service));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Perfil').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Editar nome'));
    await tester.pumpAndSettle();
    service.data['invites'] = [
      {'id': 'invite-1', 'sender': 'Rafa', 'code': 'ABC123'},
    ];
    service.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.text('Rafa convidou você para a sala ABC123.'), findsOneWidget);
    await tester.tap(find.text('ENTRAR'));
    await tester.pumpAndSettle();
    expect(service.lastInvite, {'id': 'invite-1', 'action': 'accept'});
    expect(find.text('Rafa convidou você para a sala ABC123.'), findsNothing);
    expect(find.text('Editar perfil'), findsNothing);
    expect(find.text('CÓDIGO: ABC123'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
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
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/images/truco-br-avatar.png'),
        tester.element(find.byType(Scaffold)),
      ),
    );
    await tester.pumpAndSettle();
    await settleImages(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/truco_match.png'),
    );
    service.data['invites'] = [
      {'id': 'during-match', 'sender': 'Lia', 'code': 'XYZ123'},
    ];
    service.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.text('Lia convidou você para a sala XYZ123.'), findsOneWidget);
    await tester.tap(find.text('Recusar'));
    await tester.pumpAndSettle();
    expect(service.lastInvite, {'id': 'during-match', 'action': 'decline'});
    expect(find.text('TRUCO'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Home visual reference', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(AuroraApp(service: FixtureService()));
    await tester.pumpAndSettle();
    await settleImages(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/truco_home.png'),
    );
  });
}
