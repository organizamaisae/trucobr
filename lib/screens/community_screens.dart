part of '../core/app.dart';

extension _CommunityScreens on _AuroraAppState {
  Widget walletScreen() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TrucoPanel(
        color: const Color(0xFF164332),
        child: Row(
          children: [
            const Icon(Icons.monetization_on, color: gold, size: 54),
            const SizedBox(width: 18),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Saldo de fichas'),
                Text(
                  number(api.data['chips']),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      grid([
        stat('Fichas ganhas', number(api.data['earned'])),
        stat('Fichas gastas', number(api.data['spent'])),
      ]),
      const SizedBox(height: 14),
      TrucoPanel(
        child: Row(
          children: [
            const Icon(Icons.card_giftcard, color: gold),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                api.data['daily_available'] == true
                    ? 'Bônus diário disponível\n+300 fichas'
                    : 'Bônus diário resgatado',
              ),
            ),
            TextButton(
              onPressed: busy || api.data['daily_available'] != true
                  ? null
                  : () => mutation('reward', {'id': 'daily'}),
              child: const Text('Resgatar'),
            ),
          ],
        ),
      ),
      heading('Histórico de recompensas'),
      for (final item in api.data['ledger'] as List? ?? [])
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(item['reason']),
          subtitle: Text(item['date'].toString().substring(0, 10)),
          trailing: Text(
            '${item['amount'] > 0 ? '+' : ''}${number(item['amount'])}',
            style: TextStyle(
              color: item['amount'] > 0 ? green : Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      const Text(
        'Fichas exclusivamente virtuais, sem saque ou conversão em dinheiro.',
        style: TextStyle(fontSize: 12, color: Colors.white54),
      ),
    ],
  );
  Widget rankingScreen() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'global', label: Text('Global')),
          ButtonSegment(value: 'weekly', label: Text('Semanal')),
          ButtonSegment(value: 'friends', label: Text('Amigos')),
        ],
        selected: {rankingMode},
        onSelectionChanged: (v) {
          rankingMode = v.first;
          go('ranking');
        },
      ),
      const SizedBox(height: 16),
      Text(
        'Sua posição: ${extra['position'] ?? '—'}',
        style: const TextStyle(color: gold),
      ),
      const SizedBox(height: 12),
      for (final p in extra['players'] as List? ?? [])
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TrucoPanel(
            color: p['id'] == uid ? const Color(0xFF514026) : null,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '${p['position']}',
                    style: const TextStyle(
                      color: gold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PlayerAvatar(p['name'], size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['name']),
                      Text(
                        'Nível ${p['level']} • ${p['wins']} vitórias',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  number(p['points']),
                  style: const TextStyle(
                    color: gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );
  Widget historyScreen() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if ((api.data['history'] as List? ?? []).isEmpty)
        empty(
          'Você ainda não concluiu uma partida. Encontre sua primeira mesa!',
          Icons.history,
        ),
      for (final h in api.data['history'] as List? ?? [])
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TrucoPanel(
            child: Row(
              children: [
                Icon(
                  h['won'] ? Icons.emoji_events : Icons.style,
                  color: h['won'] ? gold : Colors.white54,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        h['won'] ? 'Vitória' : 'Derrota',
                        style: TextStyle(
                          color: h['won'] ? green : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Mesa ${h['room']} • ${(h['scores'] as List).join(' × ')}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        h['date']
                            .toString()
                            .substring(0, 16)
                            .replaceAll('T', ' '),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
                Text('+${h['xp']} XP', style: const TextStyle(color: gold)),
              ],
            ),
          ),
        ),
    ],
  );
  Widget missionsScreen() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      heading('Missões diárias e semanais'),
      for (final m in api.data['missions'] as List? ?? [])
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: TrucoPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  m['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: ((m['progress'] as num) / (m['target'] as num))
                      .clamp(0, 1)
                      .toDouble(),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${m['progress']}/${m['target']} • +${number(m['reward'])} fichas',
                        style: const TextStyle(color: gold, fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed:
                          busy || m['claimed'] || m['progress'] < m['target']
                          ? null
                          : () => mutation('reward', {'id': m['id']}),
                      child: Text(m['claimed'] ? 'Resgatado' : 'Resgatar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      heading('Conquistas'),
      grid([
        for (final a in api.data['achievements'] as List? ?? [])
          TrucoPanel(
            child: Column(
              children: [
                Icon(
                  a['unlocked'] ? Icons.workspace_premium : Icons.lock_outline,
                  size: 40,
                  color: a['unlocked'] ? gold : Colors.white30,
                ),
                const SizedBox(height: 12),
                Text(a['name'], textAlign: TextAlign.center),
              ],
            ),
          ),
      ]),
    ],
  );
  Widget shopScreen() {
    final inventory = extra['inventory'] as List? ?? [];
    final items = (extra['items'] as List? ?? [])
        .where((i) => i['kind'] == shopTab)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${number(api.data['chips'])} fichas',
          textAlign: TextAlign.right,
          style: const TextStyle(
            color: gold,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final tab in [
                ('avatar', 'Avatares'),
                ('frame', 'Molduras'),
                ('back', 'Cartas'),
                ('table', 'Mesas'),
                ('emote', 'Emotes'),
                ('effect', 'Efeitos'),
                ('pass', 'Passe'),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(tab.$2),
                    selected: shopTab == tab.$1,
                    onSelected: (_) => refreshUI(() => shopTab = tab.$1),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        grid([
          for (final item in items)
            TrucoPanel(
              child: Column(
                children: [
                  SizedBox(
                    height: 90,
                    child: Center(
                      child: switch (shopTab) {
                        'avatar' => PlayerAvatar(
                          item['name'],
                          size: 72,
                          cosmetic: item['id'],
                        ),
                        'back' => TrucoCard('?', width: 48, back: item['id']),
                        'table' => SizedBox(
                          width: 110,
                          height: 70,
                          child: CustomPaint(
                            painter: FeltPainter(
                              purple: item['id'] == 'table-1',
                            ),
                          ),
                        ),
                        _ => Icon(
                          shopTab == 'frame'
                              ? Icons.circle_outlined
                              : shopTab == 'emote'
                              ? Icons.sentiment_satisfied
                              : Icons.workspace_premium,
                          color: gold,
                          size: 60,
                        ),
                      },
                    ),
                  ),
                  Text(
                    item['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${number(item['price'])} fichas',
                    style: const TextStyle(color: gold),
                  ),
                  const SizedBox(height: 12),
                  GameButton(
                    inventory.contains(item['id'])
                        ? (equipped[shopTab] == item['id'] ? 'Em uso' : 'Usar')
                        : 'Desbloquear',
                    color: panelColor,
                    onPressed: busy || equipped[shopTab] == item['id']
                        ? null
                        : () => mutation('shop', {
                            'id': item['id'],
                            'equip': inventory.contains(item['id']),
                          }, reload: true),
                  ),
                ],
              ),
            ),
        ], minWidth: 150),
        const SizedBox(height: 18),
        const Text(
          'Itens virtuais comprados apenas com fichas do jogo.',
          style: TextStyle(fontSize: 12, color: Colors.white54),
        ),
      ],
    );
  }

  Widget tournamentsScreen() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'Mata-mata 1v1 • inscrições gratuitas\nInício automático com 8, 16 ou 32 jogadores reais.',
        style: TextStyle(color: Colors.white60),
      ),
      const SizedBox(height: 16),
      for (final t in extra['tournaments'] as List? ?? [])
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: TrucoPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.emoji_events, color: gold, size: 38),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Torneio de ${t['size']} jogadores',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${(t['players'] as List).length}/${t['size']} • ${t['status'] == 'waiting'
                                ? 'Inscrições abertas'
                                : t['status'] == 'playing'
                                ? 'Em andamento'
                                : 'Encerrado'}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            'Campeão: ${number(t['size'] * 250)} fichas + 1.000 XP',
                            style: const TextStyle(fontSize: 11, color: gold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (t['status'] == 'waiting')
                  GameButton(
                    (t['players'] as List).contains(uid)
                        ? 'CANCELAR INSCRIÇÃO'
                        : 'PARTICIPAR',
                    onPressed: busy
                        ? null
                        : () => mutation('tournaments', {
                            'id': t['id'],
                            'action': (t['players'] as List).contains(uid)
                                ? 'leave'
                                : 'join',
                          }, reload: true),
                  ),
                if ((t['rounds'] as List).isNotEmpty)
                  ExpansionTile(
                    title: const Text('Chave do torneio'),
                    children: [
                      for (int i = 0; i < (t['rounds'] as List).length; i++)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Rodada ${i + 1}',
                              style: const TextStyle(color: gold),
                            ),
                            for (final m in t['rounds'][i])
                              ListTile(
                                dense: true,
                                title: Text(
                                  (m['players'] as List)
                                      .map((id) => extra['names']?[id] ?? id)
                                      .join(' × '),
                                ),
                                subtitle: Text(
                                  m['winner'] == null
                                      ? 'Em disputa'
                                      : 'Vencedor: ${extra['names']?[m['winner']] ?? m['winner']}',
                                ),
                                trailing:
                                    (m['players'] as List).contains(uid) &&
                                        m['winner'] == null
                                    ? IconButton(
                                        onPressed: () => enterRoom('state', {
                                          'code': m['room'],
                                        }),
                                        icon: const Icon(Icons.play_arrow),
                                      )
                                    : null,
                              ),
                          ],
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      TextButton.icon(
        onPressed: () => go('tournaments'),
        icon: const Icon(Icons.refresh),
        label: const Text('Atualizar torneios'),
      ),
    ],
  );
  Widget settingsScreen() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TrucoPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Conexão',
              style: TextStyle(color: gold, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SelectableText(api.url),
            Text(api.connected ? 'Servidor conectado' : 'Reconectando…'),
            const SizedBox(height: 12),
            GameButton('RECONECTAR', onPressed: api.connect),
          ],
        ),
      ),
      const SizedBox(height: 14),
      ListTile(
        leading: const Icon(Icons.menu_book),
        title: const Text('Regras do Truco'),
        trailing: const Icon(Icons.chevron_right),
        onTap: showRules,
      ),
      const ListTile(
        leading: Icon(Icons.shield_outlined),
        title: Text('Conta e privacidade'),
        subtitle: Text(
          'E-mail e senha protegidos no servidor. Sessão armazenada de forma segura no dispositivo. Contas de convidado não têm recuperação por e-mail.',
        ),
      ),
      const ListTile(
        leading: Icon(Icons.monetization_on_outlined),
        title: Text('Fichas virtuais'),
        subtitle: Text(
          'Sem compras com dinheiro, depósitos ou saques. As fichas são usadas em mesas e cosméticos.',
        ),
      ),
      const ListTile(
        leading: Icon(Icons.info_outline),
        title: Text('Aurora Truco 2.0'),
        subtitle: Text('Arte original desenhada no aplicativo.'),
      ),
      GameButton(
        'SAIR DA CONTA',
        color: const Color(0xFF9A2934),
        onPressed: busy
            ? null
            : () => run(() async {
                await api.logout();
                screen = 'home';
                room = {};
              }),
      ),
    ],
  );
}
