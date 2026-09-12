import 'package:flutter/material.dart';

class BracketLines extends CustomPainter {
  final int openingMatches;
  final int rounds;
  const BracketLines(this.openingMatches, this.rounds);

  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()
      ..color = const Color(0xFFCAA84F)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final height = size.height - 40;
    for (int r = 0; r < rounds - 1; r++) {
      final count = openingMatches >> r;
      for (int m = 0; m < count; m++) {
        final y = 40 + height * (m + .5) / count;
        final nextY = 40 + height * ((m ~/ 2) + .5) / (count ~/ 2);
        final x = r * 252.0 + 228;
        canvas.drawPath(
          Path()
            ..moveTo(x, y)
            ..lineTo(x + 16, y)
            ..lineTo(x + 16, nextY)
            ..lineTo(x + 32, nextY),
          pen,
        );
      }
    }
  }

  @override
  bool shouldRepaint(BracketLines oldDelegate) =>
      openingMatches != oldDelegate.openingMatches ||
      rounds != oldDelegate.rounds;
}
