part of '../../core/app.dart';

extension _FriendsScreen on _AuroraAppState {
  Widget friendsScreen() => Row(
    children: [
      Expanded(
        child: GoldPanel(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle('MEUS AMIGOS', size: 47),
              Text('${friends.length} AMIGOS', style: royalText(28)),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.separated(
                  itemCount: friends.length,
                  separatorBuilder: (_, i) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final friend = friends[i];
                    return Container(
                      height: 104,
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: blue),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF06337A), navy],
                        ),
                      ),
                      child: Row(
                        children: [
                          const Avatar(size: 80),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(friend.name, style: royalText(34)),
                                Text(
                                  'NÍVEL ${friend.level}',
                                  style: royalText(24, color: muted),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.circle,
                            color: friend.online ? green : Colors.red,
                            size: 21,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            friend.online ? 'ONLINE' : 'OFFLINE',
                            style: royalText(18),
                          ),
                          const SizedBox(width: 18),
                          SizedBox(
                            width: 172,
                            height: 69,
                            child: RoyalButton(
                              label: 'CONVIDAR',
                              fontSize: 20,
                              greenButton: true,
                              onPressed: friend.online
                                  ? () => info(
                                      'Convite preparado',
                                      'Compartilhe o código $code com ${friend.name} para entrar na mesa.',
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 135,
                            height: 69,
                            child: RoyalButton(
                              label: 'PERFIL',
                              fontSize: 20,
                              onPressed: () => info(
                                friend.name,
                                'Nível ${friend.level} · jogador recreativo',
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(width: 55),
      Expanded(
        child: GoldPanel(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SectionTitle('ADICIONAR AMIGO', size: 43),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchInput,
                      style: royalText(28),
                      decoration: const InputDecoration(
                        hintText: 'NOME OU ID DO JOGADOR',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 225,
                    height: 78,
                    child: RoyalButton(
                      label: 'BUSCAR',
                      icon: Icons.search,
                      greenButton: true,
                      fontSize: 26,
                      onPressed: searchFriend,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const SectionTitle('CONVITES', size: 44),
              Expanded(
                child: ListView.separated(
                  itemCount: requests.length,
                  separatorBuilder: (_, i) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final f = requests[i];
                    return Container(
                      height: 115,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: blue.withValues(alpha: .20),
                        border: Border.all(color: blue),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Avatar(size: 85),
                          const SizedBox(width: 25),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(f.name, style: royalText(33)),
                                Text(
                                  'NÍVEL ${f.level}',
                                  style: royalText(23, color: muted),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 90,
                            height: 75,
                            child: RoyalButton(
                              label: '✓',
                              greenButton: true,
                              onPressed: () => refresh(() {
                                friends.add(f);
                                requests.removeAt(i);
                              }),
                            ),
                          ),
                          const SizedBox(width: 24),
                          SizedBox(
                            width: 90,
                            height: 75,
                            child: RoyalButton(
                              label: '×',
                              red: true,
                              onPressed: () =>
                                  refresh(() => requests.removeAt(i)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
  void searchFriend() {
    final value = searchInput.text.trim();
    if (value.isEmpty) {
      info('Buscar amigo', 'Digite um nome ou ID.');
      return;
    }
    if (friends.any((f) => f.name.toLowerCase() == value.toLowerCase())) {
      info('Amigo encontrado', '$value já está na sua lista.');
      return;
    }
    refresh(() => requests.add(Friend(value, 1, true)));
    searchInput.clear();
    info(
      'Perfil demonstrativo encontrado',
      'Um convite local de $value está disponível para aceitar.',
    );
  }
}
