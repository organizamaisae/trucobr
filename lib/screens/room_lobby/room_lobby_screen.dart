part of '../../core/app.dart';

extension _LobbyScreen on _AuroraAppState {
  Widget lobbyScreen() {
    if (room.isEmpty) {
      return empty('Você ainda não entrou em uma sala.', Icons.meeting_room);
    }
    final members = room['members'] as List? ?? [];
    final full = members.length == room['capacity'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          room['name'] ?? 'Sala',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'CÓDIGO: ${room['code']}',
            style: const TextStyle(color: gold),
          ),
          subtitle: Text(
            '${members.length}/${room['capacity']} jogadores • ${room['rule']}',
          ),
          trailing: IconButton(
            tooltip: 'Copiar código',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: room['code']));
              message('Código copiado.');
            },
            icon: const Icon(Icons.copy),
          ),
        ),
        grid([
          for (int i = 0; i < (room['capacity'] as int? ?? 2); i++)
            TrucoPanel(
              child: Column(
                children: [
                  PlayerAvatar(
                    i < members.length ? members[i]['name'] : '?',
                    size: 64,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    i < members.length ? members[i]['name'] : 'Vaga livre',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Dupla ${i % 2 + 1}',
                    style: const TextStyle(color: gold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    i < members.length
                        ? '${members[i]['online'] ? 'Online' : 'Reconectando'}${members[i]['id'] == room['host'] ? ' • Anfitrião' : ''}'
                        : 'Convide um amigo',
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
        ]),
        const SizedBox(height: 20),
        GameButton(
          'CONVIDAR AMIGOS',
          icon: Icons.person_add,
          color: const Color(0xFF0064CB),
          onPressed: () => go('friends'),
        ),
        const SizedBox(height: 12),
        if (room['status'] == 'playing')
          GameButton('VOLTAR À PARTIDA', onPressed: () => go('match'))
        else
          GameButton(
            'INICIAR PARTIDA',
            icon: Icons.play_arrow,
            onPressed:
                busy ||
                    !full ||
                    room['host'] != uid ||
                    room['status'] != 'waiting'
                ? null
                : () => enterRoom('start', {'code': room['code']}),
          ),
        const SizedBox(height: 8),
        Text(
          full
              ? 'O anfitrião pode iniciar.'
              : 'Aguardando jogadores reais. Compartilhe o código da sala.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
        const SizedBox(height: 20),
        GameButton(
          'SAIR DA SALA',
          color: const Color(0xFF9A2934),
          onPressed: busy ? null : () => leaveRoom(),
        ),
      ],
    );
  }

  Future<void> leaveRoom() async {
    if (room['status'] == 'playing') {
      final accepted = await showDialog<bool>(
        context: navigator.currentContext!,
        builder: (c) => AlertDialog(
          title: const Text('Sair da partida?'),
          content: const Text(
            'Sua dupla perderá esta partida. A entrada não será devolvida.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Continuar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Sair'),
            ),
          ],
        ),
      );
      if (accepted != true) return;
    }
    await run(() async {
      await api.request('api/rooms/leave', {'code': room['code']});
      room = {};
      screen = 'home';
      orient(false);
      await api.refresh();
    });
  }
}
