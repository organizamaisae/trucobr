part of '../../core/app.dart';

extension _HomeScreen on _AuroraAppState {
  Widget homeScreen() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          PlayerAvatar(
            playerName,
            cosmetic: equipped['avatar'],
            frame: equipped['frame'],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Nível ${me['level']} • ${me['xp']} XP',
                  style: const TextStyle(fontSize: 12, color: Colors.white60),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: ((me['xp'] as num? ?? 0) % 1000) / 1000,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(8),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          TextButton.icon(
            onPressed: () => go('wallet'),
            icon: const Icon(Icons.monetization_on, color: gold),
            label: Text(
              number(api.data['chips']),
              style: const TextStyle(color: gold, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      const BrBanner(),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: GameButton(
              'JOGAR',
              icon: Icons.play_arrow,
              color: gold,
              onPressed: () => go('modes'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GameButton(
              'SALA PRIVADA',
              icon: Icons.lock_outline,
              color: green,
              onPressed: () => go('private'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      grid([
        for (final item in [
          ('TORNEIOS', Icons.emoji_events, 'tournaments'),
          ('RANKING', Icons.bar_chart, 'ranking'),
          ('AMIGOS', Icons.people, 'friends'),
          ('LOJA', Icons.shopping_cart, 'shop'),
          ('PERFIL', Icons.person, 'profile'),
          ('PARTIDAS', Icons.history, 'history'),
        ])
          TrucoPanel(
            padding: EdgeInsets.zero,
            child: InkWell(
              onTap: () => go(item.$3),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(item.$2, color: gold, size: 28),
                    const SizedBox(height: 8),
                    Text(
                      item.$1,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ], minWidth: 100),
      const SizedBox(height: 16),
      ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: gold),
        ),
        leading: const Icon(Icons.assignment, color: gold),
        title: const Text('Missões e conquistas'),
        subtitle: const Text('Jogue, evolua e ganhe fichas.'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => go('missions'),
      ),
      if (api.data['room'] != null)
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: GameButton(
            'VOLTAR À SALA',
            onPressed: () =>
                go(room['status'] == 'playing' ? 'match' : 'lobby'),
          ),
        ),
    ],
  );
}
