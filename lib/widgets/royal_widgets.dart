import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/royal_theme.dart';
import '../models/game.dart';

class GoldPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final bool bright;
  final double radius;
  const GoldPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.bright = false,
    this.radius = 30,
  });
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [cream, gold, Color(0xFFB16A04), cream, gold],
      ),
      boxShadow: const [
        BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 7)),
      ],
    ),
    padding: const EdgeInsets.all(5),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius - 4),
        border: Border.all(color: navy, width: 3),
      ),
      padding: const EdgeInsets.all(3),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius - 8),
          border: Border.all(color: const Color(0xFF248DFF), width: 1.5),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: bright ? [blue, navy] : [const Color(0xFF04245D), navy],
          ),
        ),
        child: child,
      ),
    ),
  );
}

class RoyalButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool greenButton;
  final bool red;
  final bool vertical;
  final double fontSize;
  const RoyalButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.greenButton = false,
    this.red = false,
    this.vertical = false,
    this.fontSize = 32,
  });
  @override
  State<RoyalButton> createState() => _RoyalButtonState();
}

class _RoyalButtonState extends State<RoyalButton> {
  bool pressed = false;
  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final colors = widget.red
        ? [const Color(0xFFF52A26), const Color(0xFF6B0000)]
        : widget.greenButton
        ? [const Color(0xFF00DD39), const Color(0xFF004E28)]
        : [const Color(0xFF0756CD), const Color(0xFF001749)];
    final text = Flexible(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: widget.label == '✓'
            ? const Icon(Icons.check, color: cream, size: 36)
            : widget.label == '×'
            ? const Icon(Icons.close, color: cream, size: 36)
            : Text(widget.label, style: royalText(widget.fontSize)),
      ),
    );
    final children = <Widget>[
      if (widget.icon != null)
        if (widget.icon == Icons.sports_kabaddi)
          CustomPaint(
            size: Size(widget.fontSize * 1.3, widget.fontSize * 1.3),
            painter: SwordsPainter(),
          )
        else
          Icon(
            widget.icon,
            color: cream,
            size: widget.vertical ? 54 : widget.fontSize * 1.3,
          ),
      if (widget.icon != null)
        SizedBox(
          width: widget.vertical ? 0 : 22,
          height: widget.vertical ? 8 : 0,
        ),
      text,
    ];
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label == '✓'
          ? 'Aceitar convite'
          : widget.label == '×'
          ? 'Recusar convite'
          : widget.label,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: enabled ? 1 : .42,
        child: AnimatedScale(
          scale: pressed ? 0.97 : 1,
          duration: const Duration(milliseconds: 80),
          child: GestureDetector(
            onTapDown: enabled ? (_) => setState(() => pressed = true) : null,
            onTapCancel: () => setState(() => pressed = false),
            onTapUp: (_) => setState(() => pressed = false),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onPressed,
                borderRadius: BorderRadius.circular(27),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(27),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [cream, gold, Color(0xFFA96805), gold],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .65),
                        offset: Offset(0, pressed ? 2 : 6),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: navy,
                      borderRadius: BorderRadius.circular(23),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: widget.greenButton
                              ? green
                              : const Color(0xFF318DFF),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0, .47, .48, 1],
                          colors: [
                            colors[0],
                            Color.lerp(colors[0], colors[1], .55)!,
                            Color.lerp(colors[0], colors[1], .7)!,
                            colors[1],
                          ],
                        ),
                      ),
                      child: widget.vertical
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: children,
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: children,
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  const RoundButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 108,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Avatar(size: size, icon: icon),
      ),
    ),
  );
}

class Avatar extends StatelessWidget {
  final double size;
  final IconData icon;
  final int variant;
  const Avatar({
    super.key,
    this.size = 100,
    this.icon = Icons.person,
    this.variant = 0,
  });
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    padding: EdgeInsets.all(size * .045),
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(colors: [cream, gold, Color(0xFFB97403), cream]),
    ),
    child: Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: navy, width: 3),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            variant == 0
                ? blue
                : Color.lerp(blue, const Color(0xFF604394), variant * .13)!,
            navy,
          ],
        ),
      ),
      child: Icon(icon, size: size * .64, color: cream),
    ),
  );
}

class SectionTitle extends StatelessWidget {
  final String text;
  final double size;
  const SectionTitle(this.text, {super.key, this.size = 42});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        const Expanded(child: Divider(color: gold)),
        const SizedBox(width: 14),
        const Icon(Icons.diamond, size: 25, color: cream),
        const SizedBox(width: 20),
        Expanded(
          flex: 5,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(text, style: royalText(size, color: cream)),
          ),
        ),
        const SizedBox(width: 20),
        const Icon(Icons.diamond, size: 25, color: cream),
        const SizedBox(width: 14),
        const Expanded(child: Divider(color: gold)),
      ],
    ),
  );
}

class RoyalTitle extends StatelessWidget {
  final String text;
  const RoyalTitle(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      CustomPaint(size: const Size(58, 105), painter: LaurelPainter()),
      SizedBox(
        width: 520,
        height: 105,
        child: GoldPanel(
          radius: 18,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Center(
            child: FittedBox(
              child: Text(text, style: royalText(54, color: cream)),
            ),
          ),
        ),
      ),
      Transform.flip(
        flipX: true,
        child: CustomPaint(size: const Size(58, 105), painter: LaurelPainter()),
      ),
    ],
  );
}

class LaurelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(colors: [gold, cream, gold])
          .createShader(Offset.zero & size);
    final path = Path()
      ..moveTo(size.width * .9, size.height)
      ..quadraticBezierTo(-5, size.height * .5, size.width * .35, 0);
    canvas.drawPath(
      path,
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    paint.style = PaintingStyle.fill;
    for (var i = 0; i < 6; i++) {
      final y = size.height * (.15 + i * .13);
      final x = size.width * (.12 + i * i * .015);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(-.55);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 12, height: 29),
        paint,
      );
      canvas.restore();
      canvas.save();
      canvas.translate(x + 22, y + 6);
      canvas.rotate(.65);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 12, height: 27),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RoyalBackground extends CustomPainter {
  final bool sweeping;
  RoyalBackground({this.sweeping = false});
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -.6),
          radius: 1,
          colors: [Color(0xFF0854BE), Color(0xFF001139)],
        ).createShader(Offset.zero & size),
    );
    final line = Paint()
      ..color = const Color(0xFF2469CD).withValues(alpha: .14)
      ..strokeWidth = 1.5;
    for (double x = -size.height; x < size.width + size.height; x += 150) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), line);
      canvas.drawLine(Offset(x, 0), Offset(x - size.height, size.height), line);
    }
    for (var row = 0; row < 7; row++) {
      for (var col = 0; col < 11; col++) {
        canvas.save();
        canvas.translate(
          col * 174.0 + (row.isOdd ? 78 : 0) - 40,
          row * 155.0 - 35,
        );
        SuitPainter(
          ['♠', '♥', '♦', '♣'][(row + col * 3) % 4],
          const Color(0xFF1270E8).withValues(alpha: .20),
        ).paint(canvas, const Size(76, 86));
        canvas.restore();
      }
    }
    if (sweeping) {
      for (final mirror in [false, true]) {
        canvas.save();
        if (mirror) {
          canvas.translate(size.width, 0);
          canvas.scale(-1, 1);
        }
        final ribbon = Path()
          ..moveTo(0, size.height * .45)
          ..quadraticBezierTo(
            size.width * .09,
            size.height * .61,
            size.width * .29,
            size.height * .69,
          )
          ..quadraticBezierTo(
            size.width * .09,
            size.height * .64,
            0,
            size.height * .49,
          )
          ..close();
        canvas.drawPath(
          ribbon,
          Paint()
            ..shader = const LinearGradient(
              colors: [gold, cream, Color(0xFF9D6208)],
            ).createShader(Offset.zero & size),
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant RoyalBackground oldDelegate) =>
      oldDelegate.sweeping != sweeping;
}

class Emblem extends StatelessWidget {
  final double width;
  const Emblem({super.key, this.width = 650});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: width * 2 / 3,
    child: ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          Colors.white,
          Colors.white,
          Colors.transparent,
        ],
        stops: [0, .035, .965, 1],
      ).createShader(rect),
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.white,
            Colors.white,
            Colors.transparent,
          ],
          stops: [0, .025, .955, 1],
        ).createShader(rect),
        child: Image.asset(
          'assets/images/aurora-emblem-transparent.png',
          fit: BoxFit.contain,
          semanticLabel: 'Aurora Cards — jogo de estratégia',
          errorBuilder: (_, error, stack) =>
              CustomPaint(painter: EmblemPainter()),
        ),
      ),
    ),
  );
}

class EmblemPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..shader = const LinearGradient(
        colors: [gold, cream, Color(0xFFC7810D), cream, gold],
      ).createShader(Offset.zero & s);
    for (final sign in [-1, 1]) {
      c.save();
      c.translate(s.width * (.5 + sign * .16), s.height * .31);
      c.rotate(sign * .27);
      final r = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: s.width * .25,
          height: s.height * .70,
        ),
        const Radius.circular(13),
      );
      c.drawRRect(r, p);
      c.drawRRect(r.deflate(8), Paint()..color = blue);
      c.save();
      c.translate(-s.width * .055, -s.width * .065);
      SuitPainter(
        sign < 0 ? '♠' : '♦',
        gold,
      ).paint(c, Size(s.width * .11, s.width * .13));
      c.restore();
      c.restore();
    }
    final crown = Path()
      ..moveTo(s.width * .27, s.height * .53)
      ..lineTo(s.width * .22, s.height * .25)
      ..lineTo(s.width * .38, s.height * .36)
      ..lineTo(s.width * .5, s.height * .03)
      ..lineTo(s.width * .62, s.height * .36)
      ..lineTo(s.width * .78, s.height * .25)
      ..lineTo(s.width * .73, s.height * .53)
      ..close();
    c.drawShadow(crown, Colors.black, 10, true);
    c.drawPath(crown, p);
    c.drawPath(
      crown,
      Paint()
        ..color = const Color(0xFF925205)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    final banner = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        s.width * .01,
        s.height * .57,
        s.width * .98,
        s.height * .29,
      ),
      const Radius.circular(15),
    );
    c.drawRRect(banner, p);
    c.drawRRect(banner.deflate(6), Paint()..color = navy);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PlayingCard extends StatelessWidget {
  final ActionCard card;
  final double width;
  final bool selected;
  final VoidCallback? onTap;
  final bool back;
  const PlayingCard({
    super.key,
    required this.card,
    this.width = 108,
    this.selected = false,
    this.onTap,
    this.back = false,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    label: back
        ? 'Carta virada'
        : '${card.rank} ${card.description}, ${card.power} pontos',
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: width,
        height: width * 1.32,
        padding: EdgeInsets.all(width * .08),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: back
                ? [blue, navy]
                : [Colors.white, const Color(0xFFE9E8DD)],
          ),
          border: Border.all(
            color: selected
                ? gold
                : back
                ? gold
                : const Color(0xFFB8BCB9),
            width: selected ? 4 : 2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 5,
              offset: Offset(2, 5),
            ),
          ],
        ),
        child: back
            ? const Center(
                child: Icon(Icons.auto_awesome, color: gold, size: 45),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.rank,
                    style: TextStyle(
                      fontFamily: 'RoyalSerif',
                      fontSize: width * .27,
                      fontWeight: FontWeight.bold,
                      color: card.suit == '♥' || card.suit == '♦'
                          ? Colors.red.shade700
                          : Colors.black,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: CustomPaint(
                        size: Size(width * .57, width * .60),
                        painter: SuitPainter(
                          card.suit,
                          card.suit == '♥' || card.suit == '♦'
                              ? Colors.red.shade700
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    ),
  );
}

class TablePainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final r = Rect.fromLTWH(55, 25, s.width - 110, s.height - 60);
    c.drawOval(r.translate(0, 16), Paint()..color = const Color(0xFF5B3204));
    c.drawOval(
      r,
      Paint()
        ..shader = const LinearGradient(
          colors: [gold, cream, gold, Color(0xFF9B6107)],
        ).createShader(r),
    );
    c.drawOval(r.deflate(9), Paint()..color = navy);
    c.drawOval(
      r.deflate(35),
      Paint()
        ..shader = const LinearGradient(
          colors: [cream, gold, Color(0xFFBD7A0C)],
        ).createShader(r),
    );
    c.drawOval(
      r.deflate(44),
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF06A958), Color(0xFF00482E)],
        ).createShader(r),
    );
    c.drawOval(
      r.deflate(69),
      Paint()
        ..color = gold.withValues(alpha: .40)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final random = math.Random(7);
    final texture = Paint()..color = Colors.white.withValues(alpha: .035);
    c.save();
    c.clipPath(Path()..addOval(r.deflate(45)));
    for (var i = 0; i < 5000; i++) {
      c.drawCircle(
        Offset(random.nextDouble() * s.width, random.nextDouble() * s.height),
        .8,
        texture,
      );
    }
    c.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SuitPainter extends CustomPainter {
  final String suit;
  final Color color;
  const SuitPainter(this.suit, this.color);
  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.scale(s.width / 100, s.height / 100);
    final p = Paint()..color = color;
    final path = Path();
    if (suit == '♦') {
      path.moveTo(50, 0);
      path.lineTo(96, 50);
      path.lineTo(50, 100);
      path.lineTo(4, 50);
      path.close();
    } else if (suit == '♥') {
      path.moveTo(50, 94);
      path.cubicTo(30, 72, -12, 43, 8, 15);
      path.cubicTo(20, -4, 43, 3, 50, 23);
      path.cubicTo(58, 3, 82, -4, 94, 15);
      path.cubicTo(114, 44, 72, 75, 50, 94);
      path.close();
    } else if (suit == '♠') {
      path.moveTo(50, 2);
      path.cubicTo(35, 27, -7, 51, 6, 70);
      path.cubicTo(15, 88, 37, 80, 46, 66);
      path.cubicTo(46, 80, 40, 93, 30, 99);
      path.lineTo(70, 99);
      path.cubicTo(60, 93, 54, 80, 54, 66);
      path.cubicTo(65, 80, 87, 88, 95, 70);
      path.cubicTo(109, 50, 65, 26, 50, 2);
      path.close();
    } else {
      c.drawCircle(const Offset(50, 24), 24, p);
      c.drawCircle(const Offset(25, 57), 24, p);
      c.drawCircle(const Offset(75, 57), 24, p);
      path.moveTo(44, 50);
      path.quadraticBezierTo(49, 86, 28, 100);
      path.lineTo(72, 100);
      path.quadraticBezierTo(51, 86, 56, 50);
      path.close();
    }
    c.drawPath(path, p);
    c.restore();
  }

  @override
  bool shouldRepaint(covariant SuitPainter old) =>
      old.suit != suit || old.color != color;
}

class SwordsPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..shader = const LinearGradient(colors: [cream, gold])
          .createShader(Offset.zero & s);
    for (final angle in [-.72, .72]) {
      c.save();
      c.translate(s.width / 2, s.height / 2);
      c.rotate(angle);
      final blade = Path()
        ..moveTo(-s.width * .06, s.height * .18)
        ..lineTo(-s.width * .06, -s.height * .32)
        ..lineTo(0, -s.height * .5)
        ..lineTo(s.width * .06, -s.height * .32)
        ..lineTo(s.width * .06, s.height * .18)
        ..close();
      c.drawPath(blade, p);
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            -s.width * .2,
            s.height * .15,
            s.width * .4,
            s.height * .065,
          ),
          const Radius.circular(2),
        ),
        p,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            -s.width * .035,
            s.height * .2,
            s.width * .07,
            s.height * .2,
          ),
          const Radius.circular(2),
        ),
        p,
      );
      c.drawCircle(Offset(0, s.height * .43), s.width * .06, p);
      c.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class CodeEntry extends StatelessWidget {
  final TextEditingController controller;
  const CodeEntry({super.key, required this.controller});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 102,
    child: Stack(
      children: [
        Positioned.fill(
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, child) => Row(
              children: [
                for (var i = 0; i < 6; i++) ...[
                  if (i > 0) const SizedBox(width: 14),
                  Expanded(
                    child: GoldPanel(
                      radius: 18,
                      padding: EdgeInsets.zero,
                      bright: true,
                      child: Center(
                        child: Text(
                          controller.text.length > i
                              ? controller.text[i].toUpperCase()
                              : '',
                          style: royalText(45),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: TextField(
            controller: controller,
            maxLength: 6,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
            ],
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(color: Colors.transparent, fontSize: 50),
            cursorColor: Colors.transparent,
            decoration: const InputDecoration(
              labelText: 'Código da sala',
              floatingLabelBehavior: FloatingLabelBehavior.never,
              labelStyle: TextStyle(color: Colors.transparent),
              counterText: '',
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
      ],
    ),
  );
}
