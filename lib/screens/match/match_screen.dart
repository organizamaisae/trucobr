part of '../../core/app.dart';

extension _MatchScreen on _AuroraAppState {
  Widget matchScreen() {
    final g = game!;
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                top: 105,
                bottom: 12,
                child: CustomPaint(painter: TablePainter()),
              ),
              Positioned(
                left: 0,
                top: 0,
                child: RoundButton(
                  icon: Icons.arrow_back,
                  onTap: () => go('lobby'),
                  size: 96,
                ),
              ),
              const Positioned(top: -2, left: 655, child: Emblem(width: 300)),
              Positioned(
                right: 120,
                top: 0,
                child: RoundButton(
                  icon: sound ? Icons.volume_up : Icons.volume_off,
                  onTap: () => refresh(() => sound = !sound),
                  size: 96,
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: RoundButton(
                  icon: Icons.settings,
                  onTap: settings,
                  size: 96,
                ),
              ),
              Positioned(
                top: 185,
                left: 620,
                width: 370,
                height: 72,
                child: GoldPanel(
                  radius: 15,
                  padding: const EdgeInsets.all(8),
                  child: Center(
                    child: Text(
                      'RODADA ${g.round} / 5',
                      style: royalText(25, color: cream),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 280,
                left: 480,
                child: Row(
                  children: [
                    for (final c in g.visibleCommunity)
                      Padding(
                        padding: const EdgeInsets.only(right: 17),
                        child: PlayingCard(card: c, width: 105),
                      ),
                  ],
                ),
              ),
              Positioned(
                left: 485,
                top: 435,
                width: 650,
                child: Text(
                  g.message,
                  style: royalText(23, color: cream),
                  textAlign: TextAlign.center,
                ),
              ),
              Positioned(
                left: 665,
                top: 485,
                child: Row(
                  children: [
                    for (var i = 0; i < 2; i++)
                      Transform.rotate(
                        angle: i == 0 ? -.10 : .10,
                        child: PlayingCard(
                          card: g.hand[i],
                          width: 97,
                          selected: g.selected == i,
                          onTap: g.current == 0 ? () => g.select(i) : null,
                        ),
                      ),
                  ],
                ),
              ),
              Positioned(
                left: 640,
                bottom: 0,
                width: 335,
                child: GoldPanel(
                  padding: const EdgeInsets.all(8),
                  radius: 18,
                  child: Row(
                    children: [
                      const Avatar(size: 92),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          children: [
                            Text(name, style: royalText(31)),
                            Text(
                              '${g.chips[0]} FICHAS',
                              style: royalText(23, color: cream),
                            ),
                            Text(
                              'POTE ${g.pot} FICHAS',
                              style: royalText(18, color: muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              for (var i = 1; i < g.playerCount; i++)
                Positioned(
                  left: i == 1
                      ? 240
                      : i == 2
                      ? 1190
                      : 10,
                  top: i == 3 ? 275 : 80,
                  child: playerSeat(i, g),
                ),
              Positioned(
                right: 50,
                top: 360,
                child: Transform.rotate(
                  angle: .18,
                  child: const PlayingCard(
                    card: ActionCard('', '', 0),
                    width: 75,
                    back: true,
                  ),
                ),
              ),
              if (g.finished)
                Positioned(
                  left: 490,
                  top: 250,
                  width: 650,
                  height: 270,
                  child: GoldPanel(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'PARTIDA CONCLUÍDA',
                          style: royalText(38, color: cream),
                        ),
                        const SizedBox(height: 14),
                        Text('Mão encerrada', style: royalText(27)),
                        Text(
                          'Você terminou com ${g.chips[0]} fichas',
                          style: royalText(27),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 70,
                          child: RoyalButton(
                            label: 'JOGAR NOVAMENTE',
                            greenButton: true,
                            onPressed: startGame,
                            fontSize: 27,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 120,
          child: Row(
            children: [
              Expanded(
                flex: 10,
                child: RoyalButton(
                  label: 'PASSAR',
                  icon: Icons.double_arrow,
                  onPressed: !g.finished && g.current == 0
                      ? () => action(pass: true)
                      : null,
                  fontSize: 34,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 12,
                child: RoyalButton(
                  label: 'JOGAR CARTA',
                  icon: Icons.style,
                  greenButton: true,
                  onPressed: !g.finished && g.current == 0
                      ? () => action()
                      : null,
                  fontSize: 34,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 10,
                child: RoyalButton(
                  label: 'AUMENTAR 20',
                  icon: Icons.add,
                  onPressed: g.canAct ? () => g.raise(20) : null,
                  fontSize: 32,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 10,
                child: RoyalButton(
                  label: 'VER MÃO',
                  icon: Icons.visibility,
                  onPressed: showHand,
                  fontSize: 32,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text('Fichas internas da mesa', style: royalText(21, color: muted)),
      ],
    );
  }

  Widget playerSeat(int i, DemoGame g) => SizedBox(
    width: 200,
    child: Column(
      children: [
        Avatar(size: 130, icon: Icons.person, variant: i),
        GoldPanel(
          radius: 15,
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Text(['Rafael', 'Lívia', 'Lucas'][i - 1], style: royalText(26)),
              Text('${g.chips[i]} fichas', style: royalText(22, color: cream)),
              if (g.current == i)
                Text('JOGANDO…', style: royalText(17, color: green)),
            ],
          ),
        ),
      ],
    ),
  );
  void showHand() {
    showDialog<void>(
      context: dialogContext,
      builder: (ctx) => AlertDialog(
        title: const Text('Sua mão · selecione uma carta'),
        content: SizedBox(
          width: 450,
          height: 250,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < game!.hand.length; i++)
                Column(
                  children: [
                    PlayingCard(
                      card: game!.hand[i],
                      width: 100,
                      selected: game!.selected == i,
                      onTap: game!.current == 0 && !game!.finished
                          ? () {
                              game!.select(i);
                              Navigator.pop(ctx);
                            }
                          : null,
                    ),
                    const SizedBox(height: 15),
                    Text('${game!.hand[i].power} pontos'),
                    Text(game!.hand[i].description),
                  ],
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('VOLTAR'),
          ),
        ],
      ),
    );
  }
}
