import 'package:flutter/material.dart';

/// Original vector trophy: no bitmap background or third-party game artwork.
class TournamentTrophy extends StatelessWidget {
  final double size;
  final Color color;
  const TournamentTrophy({
    super.key,
    this.size = 90,
    this.color = const Color(0xFFFFC332),
  });
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Troféu do torneio',
    child: SizedBox(
      width: size,
      height: size * 1.12,
      child: CustomPaint(painter: _TrophyPainter(color)),
    ),
  );
}

class _TrophyPainter extends CustomPainter {
  final Color color;
  _TrophyPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 112);
    final fill = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF623809),
          color,
          const Color(0xFFFFF0BB),
          color,
          const Color(0xFF7B470A),
        ],
        stops: const [0, .25, .45, .68, 1],
      ).createShader(const Rect.fromLTWH(20, 0, 60, 112));
    final rim = Paint()
      ..color = const Color(0xFFFFE5A1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final handle = Paint()
      ..shader = fill.shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawPath(
      Path()
        ..moveTo(26, 22)
        ..lineTo(8, 20)
        ..cubicTo(6, 56, 22, 64, 37, 66),
      handle,
    );
    canvas.drawPath(
      Path()
        ..moveTo(74, 22)
        ..lineTo(92, 20)
        ..cubicTo(94, 56, 78, 64, 63, 66),
      handle,
    );
    final cup = Path()
      ..moveTo(23, 16)
      ..lineTo(77, 16)
      ..cubicTo(76, 45, 72, 69, 54, 74)
      ..lineTo(55, 85)
      ..lineTo(67, 91)
      ..lineTo(33, 91)
      ..lineTo(45, 85)
      ..lineTo(46, 74)
      ..cubicTo(28, 69, 24, 45, 23, 16)
      ..close();
    canvas.drawShadow(cup, Colors.black, 6, true);
    canvas.drawPath(cup, fill);
    canvas.drawPath(cup, rim);
    canvas.drawOval(const Rect.fromLTWH(20, 9, 60, 12), fill);
    canvas.drawOval(const Rect.fromLTWH(20, 9, 60, 12), rim);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(28, 91, 44, 12),
        const Radius.circular(3),
      ),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(24, 102, 52, 6),
        const Radius.circular(2),
      ),
      fill,
    );
    final medal = Paint()..color = const Color(0xFF8C5A13);
    canvas.drawCircle(const Offset(50, 44), 11, medal);
    canvas.drawCircle(const Offset(50, 44), 10, rim);
    final star = Path()
      ..moveTo(50, 35)
      ..lineTo(53, 41)
      ..lineTo(60, 42)
      ..lineTo(55, 47)
      ..lineTo(56, 53)
      ..lineTo(50, 50)
      ..lineTo(44, 53)
      ..lineTo(45, 47)
      ..lineTo(40, 42)
      ..lineTo(47, 41)
      ..close();
    canvas.drawPath(star, Paint()..color = const Color(0xFFFFEABB));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_TrophyPainter oldDelegate) => oldDelegate.color != color;
}
