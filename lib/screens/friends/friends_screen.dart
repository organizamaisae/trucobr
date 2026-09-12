part of '../../core/app.dart';

extension _FriendsScreen on _AuroraAppState {
  Widget friendsScreen() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchInput,
              decoration: const InputDecoration(
                hintText: 'Nome ou ID do jogador',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Buscar jogadores',
            onPressed: busy
                ? null
                : () => run(() async {
                    final result = await api.request(
                      'api/friends?search=${Uri.encodeComponent(searchInput.text)}',
                    );
                    refreshUI(() => extra = result);
                  }),
            icon: const Icon(Icons.search, color: gold),
          ),
        ],
      ),
      if ((extra['results'] as List? ?? []).isNotEmpty) ...[
        heading('Resultados'),
        for (final p in extra['results']) friendRow(p, request: true),
      ],
      heading('Meus amigos'),
      if ((extra['friends'] as List? ?? []).isEmpty)
        empty(
          'Seus amigos aparecerão aqui. Busque pelo nome ou compartilhe seu ID no perfil.',
          Icons.people_outline,
        ),
      for (final p in extra['friends'] as List? ?? []) friendRow(p),
      heading('Pedidos de amizade'),
      if ((extra['requests'] as List? ?? []).isEmpty)
        const Text(
          'Nenhum pedido pendente.',
          style: TextStyle(color: Colors.white54),
        ),
      for (final p in extra['requests'] as List? ?? [])
        friendRow(p, accept: true),
      heading('Convites para jogar'),
      if ((extra['invites'] as List? ?? []).isEmpty)
        const Text(
          'Nenhum convite no momento.',
          style: TextStyle(color: Colors.white54),
        ),
      for (final i in extra['invites'] as List? ?? [])
        ListTile(
          leading: const Icon(Icons.mail, color: gold),
          title: Text(i['sender']),
          subtitle: Text('Sala ${i['code']}'),
          trailing: TextButton(
            onPressed: () => respondInvite(i, true),
            child: const Text('Entrar'),
          ),
        ),
      const SizedBox(height: 16),
      TextButton.icon(
        onPressed: () => go('friends'),
        icon: const Icon(Icons.refresh),
        label: const Text('Atualizar lista'),
      ),
    ],
  );
  Widget friendRow(
    dynamic p, {
    bool request = false,
    bool accept = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TrucoPanel(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          PlayerAvatar(p['name'], size: 42),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  p['online'] ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 11,
                    color: p['online'] ? green : Colors.white54,
                  ),
                ),
              ],
            ),
          ),
          if (request || accept)
            IconButton(
              tooltip: accept ? 'Aceitar pedido' : 'Adicionar amigo',
              onPressed: busy
                  ? null
                  : () => mutation('friends', {
                      'id': p['id'],
                      'action': accept ? 'accept' : 'request',
                    }, reload: true),
              icon: Icon(accept ? Icons.check : Icons.person_add, color: green),
            )
          else
            IconButton(
              tooltip: 'Convidar para sala',
              onPressed: room.isEmpty || busy
                  ? null
                  : () => run(() async {
                      await api.request('api/invite', {
                        'id': p['id'],
                        'code': room['code'],
                      });
                      message('Convite enviado.');
                    }),
              icon: const Icon(Icons.mail_outline, color: gold),
            ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'remove') {
                mutation('friends', {
                  'id': p['id'],
                  'action': 'remove',
                }, reload: true);
              } else {
                showDialog<void>(
                  context: navigator.currentContext!,
                  builder: (c) => AlertDialog(
                    title: Text(p['name']),
                    content: Text(
                      'Nível ${p['level']}\nVitórias: ${p['wins']}\nDerrotas: ${p['losses']}\nTaxa: ${p['win_rate']}%\nID: ${p['id']}',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(c),
                        child: const Text('Fechar'),
                      ),
                    ],
                  ),
                );
              }
            },
            itemBuilder: (c) => [
              const PopupMenuItem(value: 'profile', child: Text('Ver perfil')),
              if (!request)
                const PopupMenuItem(
                  value: 'remove',
                  child: Text('Remover / recusar'),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}
