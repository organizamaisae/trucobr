import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aurora_cards/core/app.dart';
import 'package:aurora_cards/models/game.dart';
import 'package:aurora_cards/services/room_service.dart';

void main() {
  setUp(() async {
    final font = FontLoader('RoyalSerif')
      ..addFont(rootBundle.load('assets/fonts/CormorantGaramond-Bold.ttf'));
    await font.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  test('poker usa fichas e revela cartas por rodada', () {
    final game = DemoGame();
    expect(game.chips[0], 1000);
    game.call();
    game.check();
    game.check();
    game.check();
    expect(game.revealed, 1);
    game.raise(20);
    expect(game.chips[0], 960);
    game.dispose();
  });
  test('Cinco rodadas encerram e bloqueiam ações', () {
    final game = DemoGame(playerCount: 2);
    for (var i = 0; i < 5; i++) {
      game.call();
      game.check();
    }
    expect(game.finished, true);
    final score = game.chips[0];
    game.raise(20);
    game.call();
    expect(game.chips[0], score);
    game.dispose();
  });
  test('Sala local pode ser criada e localizada pelo código', () async {
    final service = RoomService();
    final room = await service.create('Teste', 3, true);
    expect((await service.join(room['code'] as String))['capacity'], 3);
    await expectLater(service.join('XXXXXX'), throwsException);
  });
  for (final size in [
    const Size(1672, 941),
    const Size(844, 390),
    const Size(1280, 800),
  ]) {
    for (final screen in [
      'home',
      'profile',
      'private',
      'friends',
      'modes',
      'lobby',
      'match',
    ]) {
      testWidgets('$screen sem overflow em $size', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(AuroraApp(initialScreen: screen));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('Navegação e início de partida com aumento', (tester) async {
    tester.view.physicalSize = const Size(1672, 941);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const AuroraApp());
    await tester.tap(find.text('JOGAR').first);
    await tester.pumpAndSettle();
    expect(find.text('ESCOLHA UM MODO'), findsOneWidget);
    await tester.tap(find.text('JOGAR').at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('INICIAR PARTIDA'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('AUMENTAR 20'));
    await tester.pumpAndSettle();
    expect(find.textContaining('aumentou para'), findsOneWidget);
    await tester.tap(find.text('JOGAR CARTA'));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Formulário valida código e reabre sala criada', (tester) async {
    tester.view.physicalSize = const Size(1672, 941);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const AuroraApp(initialScreen: 'private'));
    await tester.tap(find.text('ENTRAR'));
    await tester.pumpAndSettle();
    expect(find.text('Código inválido'), findsOneWidget);
    await tester.tap(find.text('ENTENDI'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Sala teste');
    await tester.tap(find.text('CRIAR SALA').last);
    await tester.pumpAndSettle();
    final label = tester.widget<Text>(find.textContaining('CÓDIGO:')).data!;
    final code = RegExp(r'CÓDIGO: ([A-Z0-9]{6})').firstMatch(label)!.group(1)!;
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, code);
    await tester.tap(find.text('ENTRAR'));
    await tester.pumpAndSettle();
    expect(find.textContaining('SALA TESTE'), findsOneWidget);
  });
  testWidgets('Aceitar e recusar convites alteram a lista', (tester) async {
    tester.view.physicalSize = const Size(1672, 941);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const AuroraApp(initialScreen: 'friends'));
    await tester.tap(find.bySemanticsLabel('Aceitar convite').first);
    await tester.pumpAndSettle();
    expect(find.text('5 AMIGOS'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Recusar convite').last);
    await tester.pumpAndSettle();
    expect(find.text('Fernanda'), findsNothing);
  });
}
