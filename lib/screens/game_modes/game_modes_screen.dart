part of '../../core/app.dart';

extension _ModesScreen on _AuroraAppState {
  Widget modesScreen() => GoldPanel(
    padding: const EdgeInsets.all(40),
    child: Column(
      children: [
        const SectionTitle('PARTIDA RÁPIDA', size: 49),
        Expanded(
          child: Center(
            child: SizedBox(
              width: 680,
              child: GoldPanel(
                bright: true,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.style, size: 120, color: cream),
                    Text(
                      'POKER RECREATIVO',
                      style: royalText(43, color: cream),
                    ),
                    Text(
                      'Mesa multiplayer com jogadores reais',
                      style: royalText(28),
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      height: 80,
                      child: RoyalButton(
                        label: 'ENTRAR NA SALA',
                        icon: Icons.play_arrow,
                        greenButton: true,
                        fontSize: 34,
                        onPressed: () {
                          roomName = 'Mesa de poker';
                          code = 'DEMO01';
                          ready = true;
                          go('lobby');
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('JOGADORES', style: royalText(30)),
            const SizedBox(width: 30),
            for (final n in [2, 3, 4])
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 145,
                  height: 64,
                  child: RoyalButton(
                    label: '$n',
                    greenButton: capacity == n,
                    onPressed: () => refresh(() => capacity = n),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'FICHAS INTERNAS DA MÃO · SEM COMPRAS OU VALOR MONETÁRIO',
          style: royalText(22, color: muted),
        ),
      ],
    ),
  );
}
