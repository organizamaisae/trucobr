import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/royal_theme.dart';
import '../widgets/royal_widgets.dart';
import '../models/game.dart';
import '../services/room_service.dart';
part '../screens/home/home_screen.dart';
part '../screens/profile/profile_screen.dart';
part '../screens/private_room/private_room_screen.dart';
part '../screens/friends/friends_screen.dart';
part '../screens/game_modes/game_modes_screen.dart';
part '../screens/room_lobby/room_lobby_screen.dart';
part '../screens/match/match_screen.dart';

class AuroraApp extends StatefulWidget {
  final String initialScreen;
  const AuroraApp({super.key, this.initialScreen = 'home'});
  @override
  State<AuroraApp> createState() => _AuroraAppState();
}

class _AuroraAppState extends State<AuroraApp> {
  final navigatorKey = GlobalKey<NavigatorState>();
  late String screen;
  String name = 'Gustavo',
      roomName = 'Sala do Gustavo',
      code = 'DEMO01',
      mode = 'Partida rápida';
  bool sound = true, private = true, ready = true, busy = false;
  int capacity = 4;
  final friends = <Friend>[
    const Friend('Rafael', 8, true),
    const Friend('Lívia', 12, true),
    const Friend('Bruno', 5, false),
    const Friend('Marina', 10, false),
  ];
  final requests = <Friend>[
    const Friend('Lucas', 7, true),
    const Friend('Fernanda', 3, true),
  ];
  final roomNameInput = TextEditingController(text: 'Sala do Gustavo');
  final codeInput = TextEditingController();
  final searchInput = TextEditingController();
  final roomService = RoomService();
  DemoGame? game;
  Timer? botTimer;
  int gamesPlayed = 12, wins = 7, points = 350;
  bool recorded = false;
  @override
  void initState() {
    super.initState();
    screen = widget.initialScreen;
    if (screen == 'match') {
      game = DemoGame();
      game!.addListener(gameChanged);
    }
  }

  void refresh(VoidCallback callback) {
    if (mounted) {
      setState(callback);
    }
  }

  void go(String route) {
    if (screen == 'match' && route != 'match') {
      botTimer?.cancel();
    }
    refresh(() => screen = route);
  }

  void gameChanged() {
    if (!mounted) {
      return;
    }
    if (game!.finished && !recorded) {
      recorded = true;
      gamesPlayed++;
      points += game!.chips[0];
      if (game!.chips[0] >= 1000) {
        wins++;
      }
    }
    setState(() {});
  }

  void startGame() {
    botTimer?.cancel();
    game?.removeListener(gameChanged);
    game?.dispose();
    game = DemoGame(playerCount: capacity);
    recorded = false;
    game!.addListener(gameChanged);
    go('match');
  }

  void action({bool pass = false}) {
    if (pass) {
      game!.check();
    } else {
      game!.call();
    }
  }

  BuildContext get dialogContext => navigatorKey.currentContext!;
  void info(String title, String message) {
    showDialog<void>(
      context: dialogContext,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ENTENDI'),
          ),
        ],
      ),
    );
  }

  void settings() {
    showDialog<void>(
      context: dialogContext,
      builder: (ctx) => AlertDialog(
        title: const Text('Configurações'),
        content: const Text(
          'Aurora Cards · poker recreativo\nFichas internas da mão\nCheck, pagar, aumentar e desistir\nAs fichas não podem ser compradas, sacadas ou trocadas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('VOLTAR'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    botTimer?.cancel();
    game?.removeListener(gameChanged);
    game?.dispose();
    roomNameInput.dispose();
    codeInput.dispose();
    searchInput.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Aurora Cards',
    theme: royalTheme,
    navigatorKey: navigatorKey,
    home: Builder(
      builder: (context) => PopScope(
        canPop: screen == 'home',
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            go('home');
          }
        },
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final media = MediaQuery.of(context);
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;
                return Center(
                  child: SizedBox(
                    width: width,
                    height: height,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: MediaQuery(
                        data: media.copyWith(textScaler: TextScaler.noScaling),
                        child: SizedBox(
                          width: 1672,
                          height: 941,
                          child: CustomPaint(
                            painter: RoyalBackground(
                              sweeping: screen == 'home',
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                32,
                                22,
                                32,
                                30,
                              ),
                              child: screen == 'home'
                                  ? homeScreen()
                                  : screen == 'match'
                                  ? matchScreen()
                                  : Column(
                                      children: [
                                        header(),
                                        const SizedBox(height: 20),
                                        Expanded(
                                          child: switch (screen) {
                                            'profile' => profileScreen(),
                                            'private' => privateRoomScreen(),
                                            'friends' => friendsScreen(),
                                            'modes' => modesScreen(),
                                            'lobby' => lobbyScreen(),
                                            _ => homeScreen(),
                                          },
                                        ),
                                        if (screen != 'lobby') ...[
                                          const SizedBox(height: 28),
                                          bottomBar(),
                                        ],
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
  Widget header() => SizedBox(
    height: 120,
    child: Row(
      children: [
        SizedBox(
          width: 246,
          child: Align(
            alignment: Alignment.centerLeft,
            child: RoundButton(
              icon: Icons.arrow_back,
              onTap: () => go(screen == 'lobby' ? 'private' : 'home'),
            ),
          ),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (screen == 'lobby') ...[
                SizedBox(
                  height: 80,
                  child: FittedBox(child: RoyalTitle(roomName.toUpperCase())),
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: code));
                    info('Código copiado', code);
                  },
                  child: Text(
                    'CÓDIGO: $code  ·  COPIAR',
                    style: royalText(28, color: cream),
                  ),
                ),
              ] else
                RoyalTitle(switch (screen) {
                  'profile' => 'PERFIL',
                  'private' => 'SALA PRIVADA',
                  'friends' => 'AMIGOS',
                  'modes' => 'JOGAR',
                  _ => 'AURORA CARDS',
                }),
            ],
          ),
        ),
        RoundButton(
          icon: sound ? Icons.volume_up : Icons.volume_off,
          onTap: () {
            refresh(() => sound = !sound);
            if (sound) {
              SystemSound.play(SystemSoundType.click);
            }
          },
        ),
        const SizedBox(width: 30),
        RoundButton(icon: Icons.settings, onTap: settings),
      ],
    ),
  );
  Widget bottomBar() => SizedBox(
    height: 126,
    child: Row(
      children: [
        nav('INÍCIO', Icons.home, 'home'),
        const SizedBox(width: 38),
        nav('PERFIL', Icons.person, 'profile'),
        const SizedBox(width: 38),
        nav('SALA PRIVADA', Icons.people, 'private'),
        const SizedBox(width: 38),
        nav('AMIGOS', Icons.group, 'friends'),
      ],
    ),
  );
  Widget nav(String title, IconData icon, String route) => Expanded(
    child: RoyalButton(
      label: title,
      icon: icon,
      vertical: true,
      greenButton: screen == route || (screen == 'modes' && route == 'home'),
      onPressed: () => go(route),
      fontSize: 30,
    ),
  );
  Widget label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12, top: 16),
    child: Text(text, style: royalText(30)),
  );
  Widget progress() => Container(
    width: double.infinity,
    height: 24,
    decoration: BoxDecoration(
      color: navy,
      border: Border.all(color: muted),
      borderRadius: BorderRadius.circular(20),
    ),
    child: FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: .46,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [cream, green, Color(0xFF038027)],
          ),
        ),
      ),
    ),
  );
  void achievements() {
    info(
      'Conquistas',
      '♠ Primeiro passo — jogue sua primeira partida\n♛ Estrategista — alcance 300 pontos\n★ Em boa companhia — adicione 4 amigos\n✦ Persistência — conclua 10 partidas\nA próxima conquista chega com 20 partidas.',
    );
  }
}
