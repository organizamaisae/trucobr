part of '../core/app.dart';

extension _CommunityScreens on _AuroraAppState {
  Future<void> activateAdmin() async {
    final input = adminCodeInput..clear();
    final code = await showDialog<String>(
      context: navigator.currentContext!,
      builder: (c) => AlertDialog(
        title: const Text('Ativar administrador'),
        content: TextField(
          controller: input,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Código privado de ativação',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, input.text),
            child: const Text('Ativar'),
          ),
        ],
      ),
    );
    if (code != null) await mutation('admin/activate', {'admin_code': code});
  }

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
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: BarTable(table: item['id']),
                          ),
                        ),
                        'frame' => PlayerAvatar(
                          playerName,
                          size: 68,
                          frame: item['id'],
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

  Widget settingsScreen() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (api.data['admin_eligible'] == true &&
          api.data['can_create_tournaments'] != true)
        GameButton(
          'ATIVAR ADMINISTRADOR',
          icon: Icons.admin_panel_settings,
          onPressed: activateAdmin,
        ),
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
        title: Text('Truco BR 2.0'),
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
