part of '../../core/app.dart';

extension _ProfileScreen on _AuroraAppState {
  Widget profileScreen() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TrucoPanel(
        child: Row(
          children: [
            PlayerAvatar(
              playerName,
              size: 82,
              cosmetic: visuals['avatar'],
              frame: visuals['frame'],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playerName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SelectableText(
                    '#$uid',
                    style: const TextStyle(fontSize: 11, color: Colors.white54),
                  ),
                  Text(
                    'Nível ${me['level']}',
                    style: const TextStyle(color: gold),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: ((me['xp'] as num? ?? 0) % 1000) / 1000,
                  ),
                  Text('${me['xp']} XP', style: const TextStyle(fontSize: 11)),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Editar nome',
              onPressed: editName,
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      grid([
        stat('Vitórias', '${me['wins']}'),
        stat('Derrotas', '${me['losses']}'),
        stat('Partidas', '${me['games']}'),
        stat('Taxa de vitória', '${me['win_rate']}%'),
        stat('Maior sequência', '${me['best']}'),
        stat('Nível', '${me['level']}'),
      ], minWidth: 100),
      heading('Títulos de torneios'),
      if ((me['trophies'] as List? ?? []).isEmpty)
        const Text(
          'Suas conquistas em torneios ficarão salvas aqui.',
          style: TextStyle(color: Colors.white60),
        ),
      for (final t in me['trophies'] as List? ?? [])
        ListTile(
          leading: const Icon(Icons.emoji_events, color: gold),
          title: Text(t['name']),
          subtitle: Text('${t['mode']} • ${tournamentDate(t['date'])}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showChampion(Map<String, dynamic>.from(t)),
        ),
      heading('Personalização'),
      grid([
        for (final item in [
          ('Avatar', Icons.person),
          ('Moldura', Icons.circle_outlined),
          ('Cartas', Icons.style),
          ('Mesa', Icons.table_bar),
          ('Emotes', Icons.face),
        ])
          GameButton(
            item.$1,
            icon: item.$2,
            color: panelColor,
            onPressed: () => go('shop'),
          ),
      ], minWidth: 100),
      const SizedBox(height: 20),
      GameButton(
        'CONQUISTAS E MISSÕES',
        icon: Icons.workspace_premium,
        onPressed: () => go('missions'),
      ),
      const SizedBox(height: 12),
      GameButton(
        'HISTÓRICO DE PARTIDAS',
        color: panelColor,
        icon: Icons.history,
        onPressed: () => go('history'),
      ),
      const SizedBox(height: 12),
      GameButton(
        'MINHA POSIÇÃO NO RANKING',
        color: panelColor,
        onPressed: () => go('ranking'),
      ),
    ],
  );
  Future<void> editName() async {
    final input = profileNameInput..text = playerName;
    final result = await showDialog<String>(
      context: navigator.currentContext!,
      builder: (c) => AlertDialog(
        title: const Text('Editar perfil'),
        content: TextField(
          controller: input,
          maxLength: 24,
          decoration: const InputDecoration(labelText: 'Nome'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, input.text),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (result != null) await mutation('profile', {'name': result});
  }
}
