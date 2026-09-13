import 'package:flutter/material.dart';

class NewCharacterPainter extends CustomPainter {
  final int index;
  const NewCharacterPainter(this.index);

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      [const Color(0xFF9A5B37), const Color(0xFFC7A26A)],
      [const Color(0xFFB8753E), const Color(0xFFE7B35A)],
      [const Color(0xFF6A4636), const Color(0xFFD69B52)],
      [const Color(0xFF342C33), const Color(0xFF7FBCD2)],
    ][index.clamp(0, 3)];
    final bg = Paint()
      ..shader = LinearGradient(colors: [colors[0], const Color(0xFF082D2D)])
          .createShader(Offset.zero & size);
    canvas.drawCircle(size.center(Offset.zero), size.width / 2, bg);
    final skin = Paint()..color = const Color(0xFFE7B57B);
    canvas.drawCircle(
      Offset(size.width * .5, size.height * .43),
      size.width * .25,
      skin,
    );
    final hair = Paint()..color = colors[0];
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width * .5, size.height * .36),
        radius: size.width * .27,
      ),
      3.2,
      3.2,
      true,
      hair,
    );
    if (index == 1) {
      final hat = Paint()..color = const Color(0xFF9C642C);
      canvas.drawOval(
        Rect.fromLTWH(
          size.width * .15,
          size.height * .12,
          size.width * .7,
          size.height * .16,
        ),
        hat,
      );
      canvas.drawOval(
        Rect.fromLTWH(
          size.width * .27,
          size.height * .02,
          size.width * .46,
          size.height * .22,
        ),
        hat,
      );
    }
    if (index == 3) {
      final glasses = Paint()
        ..color = Colors.black87
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * .035;
      canvas.drawCircle(
        Offset(size.width * .4, size.height * .43),
        size.width * .09,
        glasses,
      );
      canvas.drawCircle(
        Offset(size.width * .6, size.height * .43),
        size.width * .09,
        glasses,
      );
      canvas.drawLine(
        Offset(size.width * .49, size.height * .43),
        Offset(size.width * .51, size.height * .43),
        glasses,
      );
    }
    final shirt = Paint()..color = colors[1];
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * .2,
        size.height * .58,
        size.width * .6,
        size.height * .48,
      ),
      shirt,
    );
    final eye = Paint()..color = Colors.black87;
    canvas.drawCircle(
      Offset(size.width * .42, size.height * .43),
      size.width * .025,
      eye,
    );
    canvas.drawCircle(
      Offset(size.width * .58, size.height * .43),
      size.width * .025,
      eye,
    );
  }

  @override
  bool shouldRepaint(NewCharacterPainter old) => old.index != index;
}

class AmazonTablePainter extends CustomPainter {
  const AmazonTablePainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF163C27),
    );
    final felt = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFBE8C45), Color(0xFF6A431F)],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .06,
          size.height * .03,
          size.width * .88,
          size.height * .94,
        ),
        Radius.circular(size.width * .08),
      ),
      felt,
    );
    final mat = Paint()..color = const Color(0xFFB89158);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .11,
          size.height * .08,
          size.width * .78,
          size.height * .84,
        ),
        Radius.circular(size.width * .04),
      ),
      mat,
    );
    final leaf = Paint()..color = const Color(0xFF277A3C);
    for (int i = 0; i < 8; i++) {
      final x = i.isEven ? size.width * .03 : size.width * .92;
      canvas.drawOval(
        Rect.fromLTWH(
          x,
          size.height * (.12 + i * .1),
          size.width * .1,
          size.height * .05,
        ),
        leaf,
      );
    }
  }

  @override
  bool shouldRepaint(AmazonTablePainter old) => false;
}
