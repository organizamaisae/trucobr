part of '../../core/app.dart';

extension _MatchScreen on _AuroraAppState {
  Future<void> playAction(String action, {int? card, int? value}) async {
    await run(() async {
      await api.request('api/rooms/action', {
        'code': room['code'],
        'version': room['game']['version'],
        'action': action,
        'card': ?card,
        'value': ?value,
      });
      await api.refresh();
    });
  }

  Widget matchScreen(BoxConstraints constraints) {
    final g = room['game'] as Map?;
    if (g == null || room['status'] == 'closed') {
      return Center(
        child: GameButton('VOLTAR AO INÍCIO', onPressed: () => go('home')),
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
    final visible = g['hand_done'] == true ? <dynamic>[] : g['table'] as List;
    Widget score(String label, dynamic value, Color color) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, ink]),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            Text(
              '$value',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
    return ColoredBox(
      color: const Color(0xFF211407),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => go('lobby'),
                  icon: const Icon(Icons.arrow_back_ios_new),
                ),
                score('Nós', scores[team], green),
                const SizedBox(width: 3),
                score('Eles', scores[1 - team], const Color(0xFF98201B)),
                IconButton(
                  tooltip: 'Regras',
                  onPressed: showRules,
                  icon: const Icon(Icons.settings),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child: LayoutBuilder(
                builder: (context, area) {
                  final avatar = area.maxHeight < 340 ? 32.0 : 52.0;
                  final cw = (area.maxWidth * .145).clamp(28.0, 62.0);
                  Widget player(int index) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PlayerAvatar(
                        members[index]['name'],
                        size: avatar,
                        active: !finished && g['turn'] == index,
                        cosmetic: members[index]['equipped']?['avatar'],
                        frame: members[index]['equipped']?['frame'],
                      ),
                      Container(
                        width: 78,
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        decoration: BoxDecoration(
                          color: ink,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          children: [
                            Text(
                              index == seat ? 'Você' : members[index]['name'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${g['counts'][index]} cartas',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        BarTable(
                          table:
                              room['table'] ?? equipped['table'] ?? 'table-2',
                        ),
                        Positioned(
                          top: 12,
                          left: 16,
                          child: player(
                            (seat + (members.length == 4 ? 2 : 1)) %
                                members.length,
                          ),
                        ),
                        if (members.length == 4)
                          Positioned(
                            top: 12,
                            right: 16,
                            child: player((seat + 3) % 4),
                          ),
                        Positioned(
                          bottom: cw * 1.42 + 12,
                          left: 16,
                          child: player(seat),
                        ),
                        if (members.length == 4)
                          Positioned(
                            bottom: cw * 1.42 + 12,
                            right: 16,
                            child: player((seat + 1) % 4),
                          ),
                        Positioned(
                          top: area.maxHeight < 340 ? 72 : 112,
                          left: 90,
                          right: 90,
                          child: Text(
                            room['table_text'] ?? 'TRUCO BR',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: gold.withValues(alpha: .45),
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Row(
                              key: ValueKey('$visible'),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (final c in visible)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    child: Transform.rotate(
                                      angle: c['seat'] % 2 == 0 ? -.1 : .1,
                                      child: TrucoCard(
                                        c['card'],
                                        width: cw * .92,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          left: 8,
                          right: 8,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (room['rule'] == 'paulista')
                                Padding(
                                  padding: const EdgeInsets.only(right: 10),
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
                                      TrucoCard(g['vira'], width: cw * .6),
                                    ],
                                  ),
                                ),
                              for (
                                int i = 0;
                                i < (g['hand'] as List).length;
                                i++
                              )
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  child: TrucoCard(
                                    g['hand'][i],
                                    width: cw,
                                    back: equipped['back'],
                                    enabled: own && !busy,
                                    onTap: () => playAction('play', card: i),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (turnFlash)
                          IgnorePointer(
                            child: Center(
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: .75, end: 1),
                                duration: const Duration(milliseconds: 300),
                                builder: (_, scale, child) =>
                                    Transform.scale(scale: scale, child: child),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ink.withValues(alpha: .94),
                                    border: Border.all(color: gold, width: 2),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: const [
                                      BoxShadow(color: green, blurRadius: 24),
                                    ],
                                  ),
                                  child: const Text(
                                    'Agora é Você',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      color: gold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                finished
                    ? (g['winner'] == team ? 'Você venceu!' : 'Fim de partida')
                    : g['hand_done']
                    ? 'Rodada encerrada • próxima mão disponível'
                    : pending != null
                    ? '${respond ? 'Sua dupla responde' : 'Aguardando resposta'} • ${pending['value']} pontos'
                    : own
                    ? 'É a sua vez de jogar!'
                    : 'Vez de ${members[g['turn']]['name']}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            if (g['partner_hand'] != null && respond)
              Text(
                'Parceiro: ${(g['partner_hand'] as List).join('  ')}',
                style: const TextStyle(fontSize: 11),
              ),
            if (finished)
              GameButton('VOLTAR AO INÍCIO', onPressed: () => go('home'))
            else if (g['hand_done'])
              GameButton(
                'PRÓXIMA MÃO',
                onPressed: busy ? null : () => playAction('next'),
              )
            else ...[
              if (respond)
                GameButton(
                  'ACEITAR',
                  onPressed: busy ? null : () => playAction('accept'),
                ),
              Row(
                children: [
                  for (final value in [3, 6, 9, 12])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: GameButton(
                          {
                            3: 'TRUCO',
                            6: 'SEIS',
                            9: 'NOVE',
                            12: 'DOZE',
                          }[value]!,
                          color: {
                            3: green,
                            6: const Color(0xFFDA9406),
                            9: const Color(0xFFBC520C),
                            12: const Color(0xFFB92828),
                          }[value]!,
                          onPressed:
                              busy ||
                                  !api.connected ||
                                  !(respond
                                      ? pending['special'] == false &&
                                            value == pending['value'] + 3
                                      : own &&
                                            !scores.contains(11) &&
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
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Regras da partida',
                    onPressed: showRules,
                    icon: const Icon(Icons.help_outline),
                  ),
                  Expanded(
                    child: GameButton(
                      'CORRER',
                      color: panelColor,
                      onPressed: busy || !(own || respond)
                          ? null
                          : () => playAction('run'),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Enviar emote',
                    onPressed: busy
                        ? null
                        : () => equipped['emote'] == null
                              ? message('Equipe um emote na loja.')
                              : mutation('rooms/emote', {'code': room['code']}),
                    icon: const Icon(Icons.sentiment_satisfied),
                  ),
                ],
              ),
            ],
            if (room['emote'] != null)
              Text(
                '${room['emote']['name']}: ${room['emote']['text']}',
                style: const TextStyle(fontSize: 11, color: gold),
              ),
          ],
        ),
      ),
    );
  }

  void showRules() => showModalBottomSheet<void>(
    context: navigator.currentContext!,
    showDragHandle: true,
    builder: (_) => const Padding(
      padding: EdgeInsets.all(24),
      child: Text(
        'TRUCO BR\n\nVença duas vazas por mão e alcance 12 pontos. Aumentos: Truco, Seis, Nove e Doze. Toque em uma carta na sua vez. Mão de onze exige aceitar ou correr. A vira define a manilha no Truco Paulista. A dupla ocupa posições diagonais.',
      ),
    ),
  );
}
