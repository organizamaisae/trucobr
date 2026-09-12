import 'dart:math' as math;

import 'package:flutter/material.dart';

class BrBackdrop extends StatelessWidget {
  final Widget child;
  const BrBackdrop({super.key, required this.child});
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      image: DecorationImage(
        image: AssetImage('assets/images/truco-br-background.png'),
        fit: BoxFit.cover,
        colorFilter: ColorFilter.mode(Color(0x4000120E), BlendMode.srcATop),
      ),
    ),
    child: child,
  );
}

class BrBanner extends StatelessWidget {
  const BrBanner({super.key});
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: AspectRatio(
      aspectRatio: 3,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/truco-br-banner.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Align(
          alignment: Alignment.centerRight,
          child: FractionallySizedBox(
            widthFactor: .6,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'CHAMA OS AMIGOS\nE VEM PRO JOGO!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: MediaQuery.sizeOf(context).width < 500 ? 17 : 27,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: const [
                    Shadow(
                      color: Colors.black,
                      blurRadius: 7,
                      offset: Offset(1, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class ChipStack extends StatelessWidget {
  final Color color;
  const ChipStack(this.color, {super.key});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 52,
    height: 55,
    child: CustomPaint(painter: _ChipPainter(color)),
  );
}

class _ChipPainter extends CustomPainter {
  final Color color;
  _ChipPainter(this.color);
  @override
  void paint(Canvas c, Size s) {
    for (final offset in [
      const Offset(0, 14),
      const Offset(21, 23),
      const Offset(12, 3),
    ]) {
      for (int i = 0; i < 4; i++) {
        final r = Rect.fromLTWH(offset.dx, offset.dy + 18 - i * 5, 29, 12);
        c.drawOval(
          r.translate(0, 3),
          Paint()..color = Color.lerp(color, Colors.black, .45)!,
        );
        c.drawOval(
          r,
          Paint()
            ..shader = LinearGradient(
              colors: [Color.lerp(color, Colors.white, .25)!, color],
            ).createShader(r),
        );
        for (int j = 0; j < 6; j++) {
          final a = j * math.pi / 3;
          final center = r.center + Offset(math.cos(a) * 11, math.sin(a) * 4);
          c.drawLine(
            center,
            center + Offset(math.cos(a) * 3, math.sin(a) * 2),
            Paint()
              ..color = const Color(0xFFFFF0C6)
              ..strokeWidth = 3,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_ChipPainter old) => old.color != color;
}
