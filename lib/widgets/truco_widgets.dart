import 'package:flutter/material.dart';

import 'bar_table.dart';

const gold = Color(0xFFFFC332);
const green = Color(0xFF00984F);
const ink = Color(0xFF00140F);
const panelColor = Color(0xFF06272A);
String number(dynamic n) => (n ?? 0).toString().replaceAllMapped(
  RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
  (m) => '${m[1]}.',
);

class TrucoPanel extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsets padding;
  const TrucoPanel({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(16),
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color ?? panelColor, ink],
      ),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: color == null
            ? const Color(0xFF23434D)
            : gold.withValues(alpha: .6),
      ),
      boxShadow: const [
        BoxShadow(color: Colors.black38, blurRadius: 14, offset: Offset(0, 5)),
      ],
    ),
    child: child,
  );
}

class GameButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color color;
  const GameButton(
    this.label, {
    super.key,
    this.icon,
    this.onPressed,
    this.color = green,
  });
  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: onPressed,
    icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 20),
    label: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(label, maxLines: 1, textAlign: TextAlign.center),
    ),
    style: ButtonStyle(
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      foregroundColor: WidgetStatePropertyAll(
        color == gold ? ink : Colors.white,
      ),
      backgroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled)
            ? const Color(0xFF263940)
            : s.contains(WidgetState.pressed)
            ? color.withValues(alpha: .5)
            : color,
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: color.withValues(alpha: .8)),
        ),
      ),
    ),
  );
}

class PlayerAvatar extends StatelessWidget {
  final String name;
  final double size;
  final bool active;
  final String? cosmetic;
  final String? frame;
  const PlayerAvatar(
    this.name, {
    super.key,
    this.size = 48,
    this.active = false,
    this.cosmetic,
    this.frame,
  });
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        colors: [
          cosmetic == 'avatar-1' ? Colors.indigo : const Color(0xFF1C6672),
          ink,
        ],
      ),
      border: Border.all(
        color: active
            ? green
            : switch (frame) {
                'frame-1' => green,
                'frame-2' => const Color(0xFFD38A54),
                'frame-3' => Colors.lightBlueAccent,
                'frame-4' => Colors.pinkAccent,
                _ => gold,
              },
        width: frame == null ? 2 : 4,
      ),
      boxShadow: active
          ? [BoxShadow(color: green.withValues(alpha: .5), blurRadius: 15)]
          : [],
    ),
    alignment: Alignment.center,
    child:
        cosmetic != null && (int.tryParse(cosmetic!.split('-').last) ?? 0) >= 3
        ? Padding(
            padding: const EdgeInsets.all(3),
            child: CharacterPortrait(
              index: ((int.tryParse(cosmetic!.split('-').last) ?? 3) - 3).clamp(
                0,
                5,
              ),
              size: size - 10,
            ),
          )
        : cosmetic != null
        ? Icon(
            cosmetic == 'avatar-0'
                ? Icons.explore
                : cosmetic == 'avatar-1'
                ? Icons.shield
                : Icons.star,
            color: gold,
            size: size * .55,
          )
        : name != '?'
        ? Padding(
            padding: const EdgeInsets.all(3),
            child: ClipOval(
              child: Image.asset(
                'assets/images/truco-br-avatar.png',
                width: size,
                height: size,
                fit: BoxFit.cover,
              ),
            ),
          )
        : Text(
            name.isEmpty ? '?' : name.characters.first.toUpperCase(),
            style: TextStyle(
              fontSize: size * .42,
              fontWeight: FontWeight.bold,
              color: gold,
            ),
          ),
  );
}

class TrucoCard extends StatelessWidget {
  final String card;
  final double width;
  final VoidCallback? onTap;
  final bool enabled;
  final String? back;
  const TrucoCard(
    this.card, {
    super.key,
    this.width = 64,
    this.onTap,
    this.enabled = true,
    this.back,
  });
  @override
  Widget build(BuildContext context) {
    final hidden = card == '?';
    final color = card.contains('♥') || card.contains('♦')
        ? const Color(0xFFB82236)
        : ink;
    return Semantics(
      label: hidden ? 'Carta fechada' : 'Carta $card',
      button: onTap != null,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(7),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: width,
          height: width * 1.45,
          padding: EdgeInsets.all(width * .09),
          decoration: BoxDecoration(
            color: hidden
                ? switch (back) {
                    'back-1' => const Color(0xFF762837),
                    'back-2' => const Color(0xFF087A40),
                    'back-3' => const Color(0xFF2465AE),
                    'back-4' => const Color(0xFF705223),
                    _ => const Color(0xFF124358),
                  }
                : const Color(0xFFFFFAEC),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: hidden ? gold : Colors.white, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 6,
                offset: Offset(2, 4),
              ),
            ],
          ),
          child: hidden
              ? CustomPaint(painter: CardBackPainter())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.substring(0, card.length - 1),
                      style: TextStyle(
                        fontSize: width * .26,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: CustomPaint(
                          size: Size(width * .55, width * .6),
                          painter: SuitPainter(card[card.length - 1], color),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class CardBackPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = gold.withValues(alpha: .35)
      ..style = PaintingStyle.stroke;
    for (double y = -s.width; y < s.height; y += 10) {
      c.drawLine(Offset(0, y), Offset(s.width, y + s.width), p);
      c.drawLine(Offset(s.width, y), Offset(0, y + s.width), p);
    }
  }

  @override
  bool shouldRepaint(CardBackPainter oldDelegate) => false;
}

class SuitPainter extends CustomPainter {
  final String suit;
  final Color color;
  SuitPainter(this.suit, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width, size.height);
    final paint = Paint()..color = color;
    if (suit == '♦') {
      canvas.drawPath(
        Path()
          ..moveTo(.5, 0)
          ..lineTo(1, .5)
          ..lineTo(.5, 1)
          ..lineTo(0, .5)
          ..close(),
        paint,
      );
    } else if (suit == '♥') {
      canvas.drawPath(
        Path()
          ..moveTo(.5, .95)
          ..cubicTo(.35, .75, -.2, .35, .1, .12)
          ..cubicTo(.25, 0, .4, .1, .5, .25)
          ..cubicTo(.6, .1, .75, 0, .9, .12)
          ..cubicTo(1.2, .35, .65, .75, .5, .95)
          ..close(),
        paint,
      );
    } else {
      if (suit == '♠') {
        canvas.drawPath(
          Path()
            ..moveTo(.5, 0)
            ..cubicTo(.4, .18, -.2, .52, .1, .72)
            ..cubicTo(.25, .85, .4, .72, .5, .6)
            ..cubicTo(.6, .72, .75, .85, .9, .72)
            ..cubicTo(1.2, .52, .6, .18, .5, 0)
            ..close(),
          paint,
        );
      } else {
        canvas.drawCircle(const Offset(.5, .25), .24, paint);
        canvas.drawCircle(const Offset(.25, .56), .24, paint);
        canvas.drawCircle(const Offset(.75, .56), .24, paint);
      }
      canvas.drawPath(
        Path()
          ..moveTo(.46, .55)
          ..quadraticBezierTo(.45, .86, .28, 1)
          ..lineTo(.72, 1)
          ..quadraticBezierTo(.55, .86, .54, .55)
          ..close(),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(SuitPainter old) => old.suit != suit || old.color != color;
}

class TrucoLogo extends StatelessWidget {
  final double size;
  const TrucoLogo({super.key, this.size = 160});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size * 1.6,
    height: size * 1.32,
    child: Image.asset(
      'assets/images/truco-br-login-logo.png',
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    ),
  );
}

class FeltPainter extends CustomPainter {
  final bool purple;
  final bool glow;
  FeltPainter({this.purple = false, this.glow = false});
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final oval = RRect.fromRectAndRadius(
      rect.deflate(7),
      const Radius.circular(30),
    );
    if (glow) {
      canvas.drawRRect(
        oval,
        Paint()
          ..color = gold.withValues(alpha: .6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
    canvas.drawRRect(oval, Paint()..color = const Color(0xFF382B1D));
    for (int i = 1; i < 6; i++) {
      canvas.drawRRect(
        oval.deflate(i.toDouble()),
        Paint()
          ..color = Color.lerp(
            const Color(0xFF704322),
            const Color(0xFF24170E),
            i / 6,
          )!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
    canvas.drawRRect(
      oval.deflate(7),
      Paint()
        ..shader = RadialGradient(
          colors: purple
              ? [const Color(0xFF413D69), ink]
              : [const Color(0xFF087549), const Color(0xFF013525)],
        ).createShader(rect),
    );
    canvas.drawRRect(
      oval,
      Paint()
        ..color = gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawRRect(
      oval.deflate(18),
      Paint()
        ..color = gold.withValues(alpha: .25)
        ..style = PaintingStyle.stroke,
    );
    final p = Paint()..color = Colors.white.withValues(alpha: .025);
    for (double x = 20; x < size.width - 20; x += 18) {
      for (double y = 25; y < size.height - 25; y += 18) {
        if (oval.deflate(20).contains(Offset(x, y))) {
          canvas.drawCircle(Offset(x, y), 1, p);
        }
      }
    }
  }

  @override
  bool shouldRepaint(FeltPainter oldDelegate) =>
      purple != oldDelegate.purple || glow != oldDelegate.glow;
}
