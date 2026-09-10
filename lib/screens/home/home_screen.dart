part of '../../core/app.dart';

extension _HomeScreen on _AuroraAppState {
  Widget homeScreen() => Column(
    children: [
      SizedBox(
        height: 124,
        child: Row(
          children: [
            GestureDetector(
              onTap: () => go('profile'),
              child: SizedBox(
                width: 410,
                child: Row(
                  children: [
                    const Avatar(size: 130),
                    Expanded(
                      child: GoldPanel(
                        radius: 35,
                        padding: const EdgeInsets.all(3),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(name, style: royalText(32)),
                            Text('NÍVEL 1', style: royalText(20, color: gold)),
                            const SizedBox(height: 4),
                            progress(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            RoundButton(
              icon: sound ? Icons.volume_up : Icons.volume_off,
              onTap: () => refresh(() => sound = !sound),
            ),
            const SizedBox(width: 30),
            RoundButton(icon: Icons.settings, onTap: settings),
          ],
        ),
      ),
      Expanded(
        child: Transform.translate(
          offset: const Offset(0, -30),
          child: const OverflowBox(maxHeight: 480, child: Emblem(width: 720)),
        ),
      ),
      SizedBox(
        width: 650,
        height: 155,
        child: RoyalButton(
          label: 'JOGAR',
          icon: Icons.sports_kabaddi,
          greenButton: true,
          fontSize: 72,
          onPressed: () => go('modes'),
        ),
      ),
      const SizedBox(height: 42),
      SizedBox(
        height: 145,
        child: Row(
          children: [
            nav('PERFIL', Icons.person, 'profile'),
            const SizedBox(width: 42),
            nav('SALA PRIVADA', Icons.people, 'private'),
            const SizedBox(width: 42),
            nav('AMIGOS', Icons.group, 'friends'),
            const SizedBox(width: 42),
            Expanded(
              child: RoyalButton(
                label: 'CONQUISTAS',
                icon: Icons.emoji_events,
                vertical: true,
                onPressed: achievements,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
    ],
  );
}
