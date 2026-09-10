import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aurora_cards/core/app.dart';

void main() {
  for (final screen in [
    'home',
    'profile',
    'private',
    'friends',
    'modes',
    'lobby',
    'match',
  ]) {
    testWidgets('Referência visual $screen', (tester) async {
      tester.view.physicalSize = const Size(1672, 941);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final loader = FontLoader('RoyalSerif')
        ..addFont(rootBundle.load('assets/fonts/CormorantGaramond-Bold.ttf'));
      await loader.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('capture'),
          child: AuroraApp(initialScreen: screen),
        ),
      );
      await tester.runAsync(() async {
        await precacheImage(
          const AssetImage('assets/images/aurora-logo.png'),
          tester.element(find.byType(MaterialApp)),
        );
      });
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(const ValueKey('capture')),
        matchesGoldenFile('goldens/$screen.png'),
      );
    });
  }
}
