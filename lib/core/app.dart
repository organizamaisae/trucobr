import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/truco_service.dart';
import '../widgets/truco_widgets.dart';
import '../widgets/br_art.dart';
import '../widgets/tournament_trophy.dart';
import '../widgets/bar_table.dart';
import '../widgets/bracket_lines.dart';
part '../screens/home/home_screen.dart';
part '../screens/profile/profile_screen.dart';
part '../screens/private_room/private_room_screen.dart';
part '../screens/friends/friends_screen.dart';
part '../screens/game_modes/game_modes_screen.dart';
part '../screens/room_lobby/room_lobby_screen.dart';
part '../screens/match/match_screen.dart';
part '../screens/community_screens.dart';
part '../screens/tournaments_screen.dart';

class AuroraApp extends StatefulWidget {
  final TrucoService? service;
  const AuroraApp({super.key, this.service});
  @override
  State<AuroraApp> createState() => _AuroraAppState();
}

class _AuroraAppState extends State<AuroraApp> {
  late final TrucoService api;
  final messenger = GlobalKey<ScaffoldMessengerState>();
  final navigator = GlobalKey<NavigatorState>();
  String screen = 'home', authMode = 'login', rankingMode = 'global';
  String rule = 'paulista', shopTab = 'avatar';
  int capacity = 2;
  int privateTab = 0;
  int tournamentTab = 0;
  final Set<String> seenTrophies = {};
  final Set<String> seenFinals = {};
  final Set<String> knownTournaments = {};
  final List<Map<String, dynamic>> tournamentNotices = [];
  bool turnFlash = false;
  bool tournamentBaseline = false;
  String lastTurn = '';
  bool soundsEnabled = true;
  String promptedTournamentRoom = '';
  Timer? turnTimer;
  final Set<String> hiddenInvites = {};
  bool busy = false, restoring = true, showPassword = false;
  void refreshUI(VoidCallback callback) {
    if (mounted) setState(callback);
  }

  Map<String, dynamic> extra = {}, room = {};
  final nameInput = TextEditingController();
  final emailInput = TextEditingController();
  final passwordInput = TextEditingController();
  final adminCodeInput = TextEditingController();
  final tournamentNameInput = TextEditingController();
  final profileNameInput = TextEditingController();
  final roomInput = TextEditingController(text: 'Mesa dos amigos');
  final codeInput = TextEditingController();
  final roomPassword = TextEditingController();
  final searchInput = TextEditingController();
  Map<String, dynamic> get me =>
      Map<String, dynamic>.from(api.data['profile'] as Map? ?? {});
  Map<String, dynamic> get equipped =>
      Map<String, dynamic>.from(me['equipped'] as Map? ?? {});
  String get uid => me['id'] as String? ?? '';
  String get playerName => me['name'] as String? ?? 'Jogador';
  @override
  void initState() {
    super.initState();
    api = widget.service ?? TrucoService();
    tournamentBaseline = api.token != null;
    for (final t in me['trophies'] as List? ?? []) {
      seenTrophies.add(t['id'].toString());
    }
    for (final t in api.data['tournaments'] as List? ?? []) {
      knownTournaments.add(t['id'].toString());
      if (t['status'] == 'finished') seenFinals.add(t['id'].toString());
    }
    api.addListener(changed);
    if (api.token != null) {
      restoring = false;
    } else {
      restore();
    }
  }

  Future<void> restore() async {
    try {
      await api.restore();
    } catch (e) {
      message(e);
    } finally {
      if (mounted) setState(() => restoring = false);
    }
  }

  void changed() {
    if (!mounted) return;
    final incoming = api.spectatingCode == null
        ? api.data['room']
        : api.spectatedRoom;
    setState(() {
      for (final t in api.data['tournaments'] as List? ?? []) {
        if (knownTournaments.add(t['id'].toString()) &&
            t['status'] == 'waiting' &&
            !restoring &&
            tournamentBaseline) {
          tournamentNotices.add(Map<String, dynamic>.from(t));
        }
      }
      tournamentBaseline = true;
      if (screen == 'tournaments' && api.data['tournaments'] is List) {
        extra = {
          'tournaments': api.data['tournaments'],
          'names': api.data['tournament_names'] ?? {},
        };
      }
      if (incoming is Map) {
        final started =
            room['status'] != 'playing' || room['code'] != incoming['code'];
        room = Map<String, dynamic>.from(incoming);
        if (room['status'] == 'closed' && screen == 'match') {
          screen = 'home';
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => message(room['close_reason'] ?? 'Sala encerrada.'),
          );
        }
        final g = room['game'] as Map?;
        final isTurn =
            room['spectator'] != true &&
            room['status'] == 'playing' &&
            g != null &&
            g['turn'] == g['seat'] &&
            g['pending'] == null &&
            g['hand_done'] != true &&
            g['winner'] == null;
        final key = isTurn
            ? '${room['code']}-${g['hand_no']}-${(g['tricks'] as List? ?? []).length}-${g['turn']}'
            : '';
        if (isTurn && lastTurn != key) {
          turnFlash = true;
          if (soundsEnabled) SystemSound.play(SystemSoundType.click);
          turnTimer?.cancel();
          turnTimer = Timer(
            const Duration(milliseconds: 1400),
            () => refreshUI(() => turnFlash = false),
          );
        }
        lastTurn = key;
        if (room['status'] == 'playing' && started && screen != 'match') {
          if (room['spectator'] == true) {
            screen = 'match';
          } else if (room['tournament'] != null) {
            if (promptedTournamentRoom != room['code']) {
              promptedTournamentRoom = room['code'].toString();
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => showTournamentMatchPrompt(),
              );
            }
          } else {
            screen = 'match';
            orient(true);
          }
        }
      }
    });
  }

  void orient(bool match) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  void message(Object e) {
    messenger.currentState?.showSnackBar(
      SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> run(Future<void> Function() task) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await task();
    } catch (e) {
      message(e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> go(String target) async {
    if (target != 'match') api.stopSpectating();
    orient(target == 'match');
    setState(() {
      screen = target;
      extra = {};
    });
    if (['friends', 'ranking', 'shop', 'tournaments'].contains(target)) {
      await run(() async {
        final result = await api.request(
          'api/$target${target == 'ranking' ? '?mode=$rankingMode' : ''}',
        );
        if (mounted && screen == target) setState(() => extra = result);
      });
    } else if (api.token != null) {
      await run(api.refresh);
    }
  }

  Future<void> enterRoom(String path, Map<String, dynamic> body) async {
    await run(() async {
      final result = await api.request('api/rooms/$path', body);
      if (mounted) {
        setState(() {
          room = result;
          screen = result['status'] == 'playing' ? 'match' : 'lobby';
        });
      }
      orient(screen == 'match');
      await api.refresh();
    });
  }

  Future<void> mutation(
    String path,
    Map<String, dynamic> body, {
    bool reload = false,
  }) async {
    await run(() async {
      final response = await api.request('api/$path', body);
      if (reload && mounted) setState(() => extra = response);
      await api.refresh();
    });
  }

  @override
  void dispose() {
    turnTimer?.cancel();
    api.removeListener(changed);
    if (widget.service == null) api.dispose();
    for (final c in [
      nameInput,
      emailInput,
      passwordInput,
      adminCodeInput,
      tournamentNameInput,
      profileNameInput,
      roomInput,
      codeInput,
      roomPassword,
      searchInput,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Truco BR',
    debugShowCheckedModeBanner: false,
    scaffoldMessengerKey: messenger,
    navigatorKey: navigator,
    builder: (context, child) {
      final invites = (api.data['invites'] as List? ?? []).where(
        (i) => !hiddenInvites.contains(i['id']),
      );
      return Stack(
        children: [
          child!,
          if (api.token != null &&
              invites.isEmpty &&
              tournamentNotices.isNotEmpty)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              left: 12,
              right: 12,
              child: Material(
                color: panelColor,
                elevation: 16,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.emoji_events, color: gold, size: 40),
                      const Text(
                        'TORNEIO CRIADO!',
                        style: TextStyle(
                          fontSize: 22,
                          color: gold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        tournamentNotices.first['name'],
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        tournamentDate(tournamentNotices.first['starts_at']),
                        style: const TextStyle(fontSize: 12),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () =>
                                setState(() => tournamentNotices.removeAt(0)),
                            child: const Text('Depois'),
                          ),
                          GameButton(
                            'VER TORNEIO',
                            onPressed: () {
                              setState(() {
                                tournamentNotices.removeAt(0);
                                tournamentTab = 1;
                              });
                              navigator.currentState?.popUntil(
                                (r) => r.isFirst,
                              );
                              go('tournaments');
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (api.token != null && invites.isNotEmpty)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              left: 12,
              right: 12,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Material(
                    elevation: 16,
                    color: panelColor,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.mark_email_unread, color: gold),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${invites.first['sender']} convidou você para a sala ${invites.first['code']}.',
                                ),
                              ),
                              Semantics(
                                label: 'Ver depois',
                                child: IconButton(
                                  onPressed: () => setState(
                                    () =>
                                        hiddenInvites.add(invites.first['id']),
                                  ),
                                  icon: const Icon(Icons.close),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: busy
                                    ? null
                                    : () => respondInvite(invites.first, false),
                                child: const Text('Recusar'),
                              ),
                              GameButton(
                                'ENTRAR',
                                onPressed: busy
                                    ? null
                                    : () => respondInvite(invites.first, true),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
    theme: ThemeData(
      fontFamily: 'Inter',
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: ink,
      colorScheme: ColorScheme.fromSeed(
        seedColor: green,
        brightness: Brightness.dark,
        primary: green,
        secondary: gold,
        surface: panelColor,
      ),
      appBarTheme: const AppBarTheme(backgroundColor: ink, centerTitle: true),
      navigationBarTheme: const NavigationBarThemeData(
        labelTextStyle: WidgetStatePropertyAll(TextStyle(fontSize: 10)),
        indicatorColor: Color(0xFF695019),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF091D26),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.all(14),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
    ),
    home: Builder(
      builder: (context) {
        if (restoring) {
          return const Scaffold(
            body: BrBackdrop(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TrucoLogo(),
                    SizedBox(height: 24),
                    CircularProgressIndicator(),
                  ],
                ),
              ),
            ),
          );
        }
        if (api.token == null) return loginScreen();
        final match = screen == 'match';
        return PopScope(
          canPop: screen == 'home',
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              go(match ? 'lobby' : 'home');
            }
          },
          child: Scaffold(
            appBar: match || screen == 'tournaments'
                ? null
                : AppBar(
                    leading: screen == 'home'
                        ? null
                        : IconButton(
                            onPressed: () => go('home'),
                            icon: const Icon(Icons.arrow_back_ios_new),
                          ),
                    title: Text(
                      {
                            'home': 'TRUCO BR',
                            'private': 'Sala privada',
                            'modes': 'Escolha uma mesa',
                            'lobby': 'Sua sala',
                            'profile': 'Meu perfil',
                            'friends': 'Amigos',
                            'ranking': 'Ranking',
                            'wallet': 'Minha carteira',
                            'shop': 'Loja',
                            'tournaments': 'Torneios',
                            'history': 'Minhas partidas',
                            'missions': 'Missões e conquistas',
                            'settings': 'Configurações',
                          }[screen] ??
                          'Aurora',
                    ),
                    actions: [
                      IconButton(
                        onPressed: () => go('wallet'),
                        tooltip: 'Carteira',
                        icon: const Icon(Icons.monetization_on, color: gold),
                      ),
                      IconButton(
                        onPressed: () => go('settings'),
                        tooltip: 'Configurações',
                        icon: const Icon(Icons.settings_outlined),
                      ),
                    ],
                  ),
            body: SafeArea(
              child: Column(
                children: [
                  if (busy) const LinearProgressIndicator(minHeight: 2),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final body = switch (screen) {
                          'home' => homeScreen(),
                          'profile' => profileScreen(),
                          'private' => privateScreen(),
                          'friends' => friendsScreen(),
                          'modes' => modesScreen(),
                          'lobby' => lobbyScreen(),
                          'match' => matchScreen(constraints),
                          'ranking' => rankingScreen(),
                          'wallet' => walletScreen(),
                          'shop' => shopScreen(),
                          'tournaments' => tournamentsScreen(),
                          'history' => historyScreen(),
                          'missions' => missionsScreen(),
                          _ => settingsScreen(),
                        };
                        return match
                            ? body
                            : Align(
                                alignment: Alignment.topCenter,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 1100,
                                  ),
                                  child: SingleChildScrollView(
                                    key: ValueKey(screen),
                                    padding: EdgeInsets.all(
                                      MediaQuery.sizeOf(context).width < 400
                                          ? 12
                                          : 20,
                                    ),
                                    child: body,
                                  ),
                                ),
                              );
                      },
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: match
                ? null
                : NavigationBar(
                    height: 64,
                    selectedIndex: [
                      'home',
                      'modes',
                      'friends',
                      'tournaments',
                      'ranking',
                      'shop',
                      'profile',
                    ].indexOf(screen).clamp(0, 6),
                    onDestinationSelected: (i) => go(
                      [
                        'home',
                        'modes',
                        'friends',
                        'tournaments',
                        'ranking',
                        'shop',
                        'profile',
                      ][i],
                    ),
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.home_outlined),
                        label: 'Início',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.style),
                        label: 'Jogar',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.people_outline),
                        label: 'Amigos',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.emoji_events_outlined),
                        label: 'Torneios',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.bar_chart),
                        label: 'Ranking',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.shopping_cart_outlined),
                        label: 'Loja',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.person_outline),
                        label: 'Perfil',
                      ),
                    ],
                  ),
          ),
        );
      },
    ),
  );

  Widget loginScreen() => Scaffold(
    body: BrBackdrop(
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 410),
              child: Column(
                children: [
                  const TrucoLogo(size: 180),
                  const SizedBox(height: 24),
                  const Text(
                    'Entre no jogo!',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Jogue com amigos, faça novas amizades\ne mostre que você é bom de Truco!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 24),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'login', label: Text('Entrar')),
                      ButtonSegment(
                        value: 'register',
                        label: Text('Criar conta'),
                      ),
                    ],
                    selected: {authMode},
                    onSelectionChanged: (v) =>
                        setState(() => authMode = v.first),
                  ),
                  const SizedBox(height: 18),
                  if (authMode == 'register')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        controller: nameInput,
                        autofillHints: const [AutofillHints.nickname],
                        decoration: const InputDecoration(
                          labelText: 'Nome do jogador',
                        ),
                      ),
                    ),
                  TextField(
                    controller: emailInput,
                    onChanged: (_) => setState(() {}),
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordInput,
                    obscureText: !showPassword,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      helperText: authMode == 'register'
                          ? 'Pelo menos 10 caracteres'
                          : null,
                      suffixIcon: IconButton(
                        onPressed: () =>
                            setState(() => showPassword = !showPassword),
                        icon: Icon(
                          showPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (authMode == 'register' &&
                      emailInput.text.trim().toLowerCase() ==
                          'gustavoluzmachado@gmail.com')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextField(
                        controller: adminCodeInput,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Código de ativação do administrador',
                        ),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: GameButton(
                      busy
                          ? 'Conectando…'
                          : authMode == 'login'
                          ? 'ENTRAR'
                          : 'CRIAR CONTA',
                      icon: Icons.login,
                      onPressed: busy
                          ? null
                          : () => run(
                              () => api.login(authMode, {
                                'email': emailInput.text,
                                'password': passwordInput.text,
                                'name': nameInput.text,
                                'admin_code': adminCodeInput.text,
                              }),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: GameButton(
                      'Jogar como convidado',
                      color: panelColor,
                      onPressed: busy
                          ? null
                          : () => run(
                              () => api.login('guest', {
                                'name': nameInput.text.trim().length >= 2
                                    ? nameInput.text.trim()
                                    : 'Visitante',
                              }),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Fichas virtuais para jogar e personalizar. Sem saque ou conversão em dinheiro.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget heading(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Text(
      text,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    ),
  );
  Widget stat(String label, String value) => TrucoPanel(
    padding: const EdgeInsets.all(12),
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
            color: gold,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
  Widget grid(List<Widget> children, {double minWidth = 150}) => LayoutBuilder(
    builder: (context, c) {
      final columns = (c.maxWidth / minWidth).floor().clamp(1, 4);
      final width = (c.maxWidth - (columns - 1) * 12) / columns;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
  Widget empty(String text, IconData icon) => TrucoPanel(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(icon, size: 40, color: gold),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
