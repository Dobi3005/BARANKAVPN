import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class C {
  static const linen = Color(0xFFEFE7D6);      // лён
  static const linenDark = Color(0xFFE2D7BE);
  static const ink = Color(0xFF2A1F17);        // сажа
  static const inkSoft = Color(0xFF6B5B4B);
  static const cinnabar = Color(0xFFB8321F);   // киноварь
  static const gold = Color(0xFFD9962B);       // золотистая корочка
  static const dough = Color(0xFFE9CFA0);      // сырое тесто
}

ThemeData buildTheme() {
  final body = GoogleFonts.ptSerifTextTheme();
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: C.linen,
    colorScheme: ColorScheme.fromSeed(
      seedColor: C.cinnabar,
      primary: C.cinnabar,
      surface: C.linen,
      brightness: Brightness.light,
    ),
    textTheme: body.apply(bodyColor: C.ink, displayColor: C.ink),
  );
}

TextStyle titleStyle(double size) => GoogleFonts.ruslanDisplay(
    fontSize: size, color: C.cinnabar, height: 1.1, letterSpacing: .5);

/// Льняная ткань: тонкая сетка нитей
class LinenBackground extends StatelessWidget {
  final Widget child;
  const LinenBackground({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Stack(children: [
        Positioned.fill(
            child: RepaintBoundary(child: CustomPaint(painter: _LinenPainter()))),
        child,
      ]);
}

class _LinenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = C.linen);
    final h = Paint()
      ..color = C.linenDark.withOpacity(.35)
      ..strokeWidth = .6;
    final v = Paint()
      ..color = C.linenDark.withOpacity(.2)
      ..strokeWidth = .6;
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), h);
    }
    for (double x = 0; x < size.width; x += 4) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), v);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Красный орнамент-«ромбы» (как вышивка на рушнике)
class Ornament extends StatelessWidget {
  const Ornament({super.key});
  @override
  Widget build(BuildContext context) =>
      SizedBox(height: 14, width: double.infinity, child: CustomPaint(painter: _OrnPainter()));
}

class _OrnPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final red = Paint()..color = C.cinnabar;
    final line = Paint()
      ..color = C.cinnabar
      ..strokeWidth = 1;
    c.drawLine(Offset(0, s.height / 2), Offset(s.width, s.height / 2), line);
    const step = 22.0;
    for (double x = step / 2; x < s.width; x += step) {
      final path = Path()
        ..moveTo(x, 1)
        ..lineTo(x + 6, s.height / 2)
        ..lineTo(x, s.height - 1)
        ..lineTo(x - 6, s.height / 2)
        ..close();
      c.drawPath(path, red);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
