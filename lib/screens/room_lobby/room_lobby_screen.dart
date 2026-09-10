part of '../../core/app.dart';

extension _LobbyScreen on _AuroraAppState {
  Widget lobbyScreen() => Column(
    children: [
      Expanded(
        flex: 6,
        child: GoldPanel(
          padding: const EdgeInsets.symmetric(horizontal: 27, vertical: 8),
          child: Column(
            children: [
              SectionTitle('JOGADORES $capacity/$capacity', size: 46),
              const SizedBox(height: 8),
              Expanded(
                child: Row(
                  children: [
                    for (var i = 0; i < capacity; i++) ...[
                      if (i > 0) const SizedBox(width: 20),
                      Expanded(
                        child: GoldPanel(
                          bright: true,
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            children: [
                              const Spacer(),
                              Avatar(size: 130, icon: Icons.person, variant: i),
                              const SizedBox(height: 10),
                              Text(
                                i == 0 ? name : 'Aguardando jogador',
                                style: royalText(31),
                              ),
                              Text(
                                i == 0 ? 'ANFITRIÃO' : 'JOGADOR',
                                style: royalText(18, color: cream),
                              ),
                              const Spacer(),
                              SizedBox(
                                height: 63,
                                child: RoyalButton(
                                  label: i == 0 && !ready
                                      ? 'AGUARDANDO'
                                      : 'PRONTO',
                                  icon: Icons.check_circle,
                                  greenButton: i != 0 || ready,
                                  fontSize: 28,
                                  onPressed: i == 0
                                      ? () => refresh(() => ready = !ready)
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 18),
      Expanded(
        flex: 4,
        child: Row(
          children: [
            Expanded(
              flex: 45,
              child: GoldPanel(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                child: Column(
                  children: [
                    const SectionTitle('CONFIGURAÇÕES', size: 35),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.people, color: cream, size: 40),
                        const SizedBox(width: 25),
                        Text('JOGADORES', style: royalText(27)),
                        const Spacer(),
                        IconButton(
                          onPressed: capacity > 2
                              ? () => refresh(() => capacity--)
                              : null,
                          icon: const Icon(Icons.arrow_left, size: 38),
                        ),
                        Text('$capacity', style: royalText(32)),
                        IconButton(
                          onPressed: capacity < 4
                              ? () => refresh(() => capacity++)
                              : null,
                          icon: const Icon(Icons.arrow_right, size: 38),
                        ),
                      ],
                    ),
                    const Divider(color: blue),
                    Row(
                      children: [
                        const Icon(Icons.style, color: cream, size: 40),
                        const SizedBox(width: 25),
                        Text('TIPO', style: royalText(27)),
                        const Spacer(),
                        Text('RECREATIVA', style: royalText(28, color: cream)),
                      ],
                    ),
                    const Divider(color: blue),
                    Row(
                      children: [
                        const Icon(Icons.lock, color: cream, size: 40),
                        const SizedBox(width: 25),
                        Text('SOMENTE CONVIDADOS', style: royalText(25)),
                        const Spacer(),
                        Switch(
                          value: private,
                          onChanged: (v) => refresh(() => private = v),
                        ),
                      ],
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 55,
              child: GoldPanel(
                child: Column(
                  children: [
                    const Spacer(),
                    SizedBox(
                      height: 76,
                      child: RoyalButton(
                        label: 'CONVIDAR',
                        icon: Icons.person_add,
                        onPressed: () => info(
                          'Compartilhar sala',
                          'Código: $code\nCompartilhe o código para outros jogadores entrarem na sala.',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 88,
                            child: RoyalButton(
                              label: 'INICIAR PARTIDA',
                              icon: Icons.play_arrow,
                              greenButton: true,
                              onPressed: ready ? startGame : null,
                              fontSize: 34,
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        SizedBox(
                          width: 190,
                          height: 76,
                          child: RoyalButton(
                            label: 'SAIR',
                            icon: Icons.logout,
                            red: true,
                            onPressed: () => go('private'),
                            fontSize: 23,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      ready
                          ? 'Todos prontos · adversários demonstrativos'
                          : 'Marque PRONTO para começar',
                      style: royalText(23, color: muted),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
