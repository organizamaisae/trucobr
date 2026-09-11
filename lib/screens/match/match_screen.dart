part of '../../core/app.dart';

extension _MatchScreen on _AuroraAppState {
  Future<void> playAction(String action, {int? card, int? value}) async {
    await run(() async {
      final result = await api.request('api/rooms/action', {
        'code': room['code'],
        'version': room['game']['version'],
        'action': action,
        'card': ?card,
        'value': ?value,
      });
      if (mounted) refreshUI(() => room = result);
      await api.refresh();
    });
  }

  Widget matchScreen(BoxConstraints constraints) {
    final g = room['game'] as Map?;
    if (g == null) {
      return Center(
        child: GameButton('VOLTAR À SALA', onPressed: () => go('lobby')),
      );
    }
    final members = room['members'] as List;
    final seat = g['seat'] as int, team = seat % 2;
    final pending = g['pending'] as Map?;
    final finished = g['winner'] != null;
    final respond = pending != null && pending['team'] == team;
    final own =
        g['turn'] == seat &&
        pending == null &&
        !g['hand_done'] &&
        !finished &&
        api.connected;
    final scores = g['scores'] as List;
    final cardWidth = (constraints.maxHeight * .13).clamp(34.0, 64.0);
    Widget seatWidget(int index) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PlayerAvatar(
          members[index]['name'],
          size: constraints.maxHeight < 500 ? 28 : 44,
          active: g['turn'] == index && !finished,
          cosmetic: members[index]['equipped']?['avatar'],
          frame: members[index]['equipped']?['frame'],
        ),
        Text(
          members[index]['id'] == uid ? 'Você' : members[index]['name'],
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
        Text(
          '${g['counts'][index]} cartas • D${index % 2 + 1}',
          style: const TextStyle(fontSize: 10, color: Colors.white60),
        ),
      ],
    );
    final visible = (g['table'] as List).isNotEmpty
        ? g['table'] as List
        : g['last_table'] as List;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => go('lobby'),
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: Text(
                  'Nós ${scores[team]}   ×   ${scores[1 - team]} Eles',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: gold,
                  ),
                ),
              ),
              Text(
                'Mão ${g['hand_no']} • vale ${g['stake']}',
                style: const TextStyle(fontSize: 12),
              ),
              IconButton(
                tooltip: 'Regras',
                onPressed: () => showRules(),
                icon: const Icon(Icons.help_outline),
              ),
              if (equipped['emote'] != null)
                IconButton(
                  tooltip: 'Enviar emote',
                  onPressed: busy
                      ? null
                      : () => mutation('rooms/emote', {'code': room['code']}),
                  icon: const Icon(Icons.sentiment_satisfied, color: gold),
                ),
            ],
          ),
          if (room['emote'] != null)
            Text(
              '${room['emote']['name']}: ${room['emote']['text']}',
              style: const TextStyle(color: gold, fontSize: 11),
            ),
          Expanded(
            child: CustomPaint(
              painter: FeltPainter(
                purple: equipped['table'] == 'table-1',
                glow: own && equipped['effect'] != null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    if (members.length == 4) seatWidget((seat + 1) % 4),
                    Expanded(
                      child: Column(
                        children: [
                          seatWidget(
                            (seat + (members.length == 4 ? 2 : 1)) %
                                members.length,
                          ),
                          Expanded(
                            child: Center(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (room['rule'] == 'paulista')
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 24,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text(
                                              'VIRA',
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: gold,
                                              ),
                                            ),
                                            TrucoCard(
                                              g['vira'],
                                              width: cardWidth * .7,
                                            ),
                                          ],
                                        ),
                                      ),
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 350,
                                      ),
                                      transitionBuilder: (child, a) =>
                                          SlideTransition(
                                            position: Tween(
                                              begin: const Offset(0, .3),
                                              end: Offset.zero,
                                            ).animate(a),
                                            child: FadeTransition(
                                              opacity: a,
                                              child: child,
                                            ),
                                          ),
                                      child: Row(
                                        key: ValueKey('$visible'),
                                        children: [
                                          for (final c in visible)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 5,
                                                  ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  TrucoCard(
                                                    c['card'],
                                                    width: cardWidth * .8,
                                                  ),
                                                  Text(
                                                    members[c['seat']]['name'],
                                                    style: const TextStyle(
                                                      fontSize: 9,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: seatWidget(seat),
                              ),
                              for (
                                int i = 0;
                                i < (g['hand'] as List).length;
                                i++
                              )
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  child: TrucoCard(
                                    g['hand'][i],
                                    width: cardWidth,
                                    back: equipped['back'],
                                    enabled: own && !busy,
                                    onTap: () => playAction('play', card: i),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (members.length == 4) seatWidget((seat + 3) % 4),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Text(
              finished
                  ? (g['winner'] == team
                        ? 'Sua dupla venceu!'
                        : 'Fim de partida. Boa disputa!')
                  : g['hand_done']
                  ? '${(g['log'] as List).last} Próxima mão disponível.'
                  : pending != null
                  ? '${pending['special'] ? 'Mão de onze' : 'Desafio de ${pending['value']} pontos'} • ${respond ? 'Sua dupla responde' : 'Aguardando adversários'}'
                  : own
                  ? 'Sua vez! Toque em uma carta.'
                  : 'Vez de ${members[g['turn']]['name']}',
              style: const TextStyle(fontSize: 12, color: gold),
            ),
          ),
          if (g['partner_hand'] != null && respond)
            Text(
              'Cartas do parceiro: ${(g['partner_hand'] as List).join('  ')}',
              style: const TextStyle(fontSize: 11),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (finished)
                  GameButton('VOLTAR AO INÍCIO', onPressed: () => go('home'))
                else if (g['hand_done'])
                  GameButton(
                    'PRÓXIMA MÃO',
                    onPressed: busy ? null : () => playAction('next'),
                  )
                else ...[
                  if (respond)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GameButton(
                        'ACEITAR',
                        onPressed: busy ? null : () => playAction('accept'),
                      ),
                    ),
                  for (final value in [3, 6, 9, 12])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GameButton(
                        {3: 'TRUCO', 6: 'SEIS', 9: 'NOVE', 12: 'DOZE'}[value]!,
                        color: {
                          3: green,
                          6: const Color(0xFFAF6700),
                          9: const Color(0xFF0064CB),
                          12: const Color(0xFFAF2934),
                        }[value]!,
                        onPressed:
                            busy ||
                                !api.connected ||
                                !(respond
                                    ? pending['special'] == false &&
                                          value == pending['value'] + 3
                                    : own &&
                                          !(scores.contains(11)) &&
                                          value ==
                                              (g['stake'] == 1
                                                  ? 3
                                                  : g['stake'] + 3) &&
                                          (g['raise_owner'] == null ||
                                              g['raise_owner'] == team))
                            ? null
                            : () => playAction('raise', value: value),
                      ),
                    ),
                  GameButton(
                    'CORRER',
                    color: const Color(0xFF384B53),
                    onPressed: busy || !(own || respond)
                        ? null
                        : () => playAction('run'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void showRules() {
    showModalBottomSheet<void>(
      context: navigator.currentContext!,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (c) => const Padding(
        padding: EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Text(
            'TRUCO AURORA\n\nVença duas vazas para ganhar a mão. A partida termina em 12 pontos. Ordem: 4, 5, 6, 7, Q, J, K, A, 2, 3.\n\nPaulista: a carta após a vira é manilha. Naipes das manilhas: ♦ < ♠ < ♥ < ♣.\nManilha fixa: 7♦ < A♠ < 7♥ < 4♣. Esta variante mantém a pontuação paulista (não é o regulamento mineiro).\n\nDesafios: 1 → 3 → 6 → 9 → 12. Quem recebe responde ou aumenta. Correr concede o valor aceito anteriormente.\n\nMão de onze: a dupla vê as cartas do parceiro e aceita por 3 ou corre por 1. Onze a onze: cartas ocultas, sem aumentos.\n\nEmpate favorece quem ganhou a primeira vaza. Se a primeira empata, vale a segunda. Três empates não dão pontos.\n\nSair da partida dá a vitória à outra dupla. Desconexão mantém a sala para reconexão.',
          ),
        ),
      ),
    );
  }
}
