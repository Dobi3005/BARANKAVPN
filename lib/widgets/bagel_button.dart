import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/vpn_engine.dart';
import '../theme.dart';

/// Кнопка-баранка: вращается при подключении и «румянится» до золотого.
class BagelButton extends StatefulWidget {
  final VpnStatus status;
  final VoidCallback onTap;
  final double size;
  const BagelButton({super.key, required this.status, required this.onTap, this.size = 260});
  @override
  State<BagelButton> createState() => _BagelButtonState();
}

class _BagelButtonState extends State<BagelButton> with TickerProviderStateMixin {
  late final AnimationController _spin =
      AnimationController(vsync: this, duration: const Duration(seconds: 6));
  late final AnimationController _bake =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void initState() {
    super.initState();
    _apply();
  }

  @override
  void didUpdateWidget(covariant BagelButton old) {
    super.didUpdateWidget(old);
    if (old.status != widget.status) _apply();
  }

  void _apply() {
    switch (widget.status) {
      case VpnStatus.disconnected:
        _spin.stop();
        _bake.animateTo(0, curve: Curves.easeOut);
        break;
      case VpnStatus.connecting:
        _spin.duration = const Duration(milliseconds: 1600);
        _spin.repeat();
        _bake.animateTo(.55, curve: Curves.easeInOut);
        break;
      case VpnStatus.connected:
        _spin.duration = const Duration(seconds: 7);
        _spin.repeat();
        _bake.animateTo(1, curve: Curves.easeInOut);
        break;
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    _bake.dispose();
    super.dispose();
  }

  String get _label => switch (widget.status) {
        VpnStatus.disconnected => 'Включить',
        VpnStatus.connecting => 'Соединяем…',
        VpnStatus.connected => 'Отключить',
      };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: _label,
      child: GestureDetector(
        onTap: widget.onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(alignment: Alignment.center, children: [
              AnimatedBuilder(
                animation: Listenable.merge([_spin, _bake]),
                builder: (_, __) => CustomPaint(
                  size: Size.square(widget.size),
                  painter: _BagelPainter(angle: _spin.value * 2 * math.pi, bake: _bake.value),
                ),
              ),
              SizedBox(
                width: widget.size * .3,
                child: Text(_label,
                    textAlign: TextAlign.center, style: titleStyle(widget.size * .07)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _BagelPainter extends CustomPainter {
  final double angle;
  final double bake;
  _BagelPainter({required this.angle, required this.bake});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 8;
    final hole = r * .36;

    final light = Color.lerp(C.dough, const Color(0xFFF2B84B), bake)!;
    final edge = Color.lerp(const Color(0xFFC9A26A), const Color(0xFFB5651A), bake)!;
    final blush = Color.lerp(const Color(0x00C0392B), const Color(0x66C0392B), bake)!;

    final ring = Path()
      ..fillType = PathFillType.evenOdd
      ..addOval(Rect.fromCircle(center: c, radius: r))
      ..addOval(Rect.fromCircle(center: c, radius: hole));

    canvas.drawShadow(ring, Colors.black.withOpacity(.45), 10, true);

    final shader = RadialGradient(
      colors: [edge, light, light, edge],
      stops: [hole / r, .55, .72, 1],
    ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawPath(ring, Paint()..shader = shader);

    // румянец — тёплое пятно сбоку
    final bc = c + Offset(r * .35, r * .3);
    canvas.save();
    canvas.clipPath(ring);
    canvas.drawCircle(
        bc,
        r * .7,
        Paint()
          ..shader = RadialGradient(colors: [blush, const Color(0x00C0392B)])
              .createShader(Rect.fromCircle(center: bc, radius: r * .7)));
    canvas.restore();

    // маковые зёрна — вращаются вместе с баранкой
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);
    final rnd = math.Random(11);
    final seed = Paint()..color = C.ink.withOpacity(.75);
    for (var i = 0; i < 46; i++) {
      final a = rnd.nextDouble() * 2 * math.pi;
      final rad = hole + (r - hole) * (.22 + rnd.nextDouble() * .56);
      canvas.save();
      canvas.translate(math.cos(a) * rad, math.sin(a) * rad);
      canvas.rotate(a + rnd.nextDouble());
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 5.5, height: 2.6), seed);
      canvas.restore();
    }
    canvas.restore();

    // красный ободок вокруг дырки
    canvas.drawCircle(
        c,
        hole,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = C.cinnabar);
  }

  @override
  bool shouldRepaint(covariant _BagelPainter o) => o.angle != angle || o.bake != bake;
}
