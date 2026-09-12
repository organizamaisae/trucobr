part of '../../core/app.dart';

extension _ModesScreen on _AuroraAppState {
  Widget modesScreen() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      playerSelector(),
      const SizedBox(height: 16),
      rulesSelector(),
      const SizedBox(height: 16),
      const Text(
        'Partida rápida com jogadores reais. A mesa começa quando todos entrarem.',
        style: TextStyle(color: Colors.white60),
      ),
      const SizedBox(height: 16),
      for (final tier in [
        ('Iniciante', 100, green),
        ('Bronze', 500, const Color(0xFF9C592C)),
        ('Prata', 1000, const Color(0xFF6D8992)),
        ('Ouro', 5000, gold),
        ('Elite', 10000, const Color(0xFF536789)),
      ])
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TrucoPanel(
            color: const Color(0xFF3D2E1B),
            child: Row(
              children: [
                ChipStack(tier.$3),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mesa ${tier.$1}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Entrada: ${number(tier.$2)} fichas',
                        style: const TextStyle(color: gold),
                      ),
                    ],
                  ),
                ),
                GameButton(
                  'Entrar',
                  onPressed: busy || (api.data['chips'] as num? ?? 0) < tier.$2
                      ? null
                      : () => enterRoom('quick', {
                          'capacity': capacity,
                          'fee': tier.$2,
                          'rule': rule,
                        }),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}
