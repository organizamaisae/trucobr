part of '../../core/app.dart';

extension _ProfileScreen on _AuroraAppState {
  Widget profileScreen() => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        flex: 29,
        child: GoldPanel(
          child: Column(
            children: [
              const Spacer(),
              const Avatar(size: 265),
              const SizedBox(height: 14),
              Text(name, style: royalText(52)),
              Text('NÍVEL 1', style: royalText(28, color: gold)),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36),
                child: progress(),
              ),
              const Spacer(),
              SizedBox(
                height: 82,
                child: RoyalButton(
                  label: 'EDITAR PERFIL',
                  icon: Icons.edit,
                  onPressed: editProfile,
                  fontSize: 29,
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(width: 18),
      Expanded(
        flex: 37,
        child: GoldPanel(
          child: Column(
            children: [
              const SectionTitle('ESTATÍSTICAS', size: 38),
              const SizedBox(height: 15),
              Expanded(
                child: Row(
                  children: [
                    stat('PARTIDAS', '$gamesPlayed', Icons.sports_kabaddi),
                    const SizedBox(width: 16),
                    stat('VITÓRIAS', '$wins', Icons.emoji_events),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: Row(
                  children: [
                    stat('AMIGOS', '${friends.length}', Icons.people),
                    const SizedBox(width: 16),
                    stat('PONTOS', '$points', Icons.workspace_premium),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(width: 18),
      Expanded(
        flex: 33,
        child: GoldPanel(
          child: Column(
            children: [
              const SectionTitle('CONQUISTAS', size: 38),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  medal(Icons.style, 0),
                  medal(Icons.workspace_premium, 1),
                  medal(Icons.people, 2),
                ],
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  medal(Icons.star, 3),
                  medal(Icons.handshake, 4),
                  medal(Icons.lock, 5),
                ],
              ),
              const Spacer(),
              SizedBox(
                height: 82,
                child: RoyalButton(
                  label: 'VER TODAS',
                  icon: Icons.chevron_right,
                  greenButton: true,
                  onPressed: achievements,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
  Widget stat(String title, String value, IconData icon) => Expanded(
    child: GoldPanel(
      bright: true,
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: cream),
          const SizedBox(height: 8),
          Text(title, style: royalText(26)),
          Text(value, style: royalText(48)),
        ],
      ),
    ),
  );
  Widget medal(IconData icon, int variant) => GestureDetector(
    onTap: achievements,
    child: Avatar(size: 130, icon: icon, variant: variant),
  );
  Future<void> editProfile() async {
    final input = TextEditingController(text: name);
    final value = await showDialog<String>(
      context: dialogContext,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar perfil'),
        content: TextField(
          controller: input,
          maxLength: 20,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nome'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () {
              if (input.text.trim().isNotEmpty) {
                Navigator.pop(ctx, input.text.trim());
              }
            },
            child: const Text('SALVAR'),
          ),
        ],
      ),
    );
    if (value != null) {
      refresh(() => name = value);
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    input.dispose();
  }
}
