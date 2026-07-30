/// Temple + scales hero from munshi-ui/index.html `#sheetLogin` SVG (simplified layout).
library;

import 'package:flutter/material.dart';

import '../theme.dart';

class LoginHeroArt extends StatelessWidget {
  const LoginHeroArt({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth.clamp(200.0, 320.0);
        return SizedBox(
          width: w,
          height: w * 0.78,
          child: CustomPaint(
            painter: _LoginHeroPainter(),
            size: Size(w, w * 0.78),
          ),
        );
      },
    );
  }
}

class _LoginHeroPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 280;
    canvas.scale(scale);

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(140, 198), width: 216, height: 24),
      Paint()..color = Colors.black.withValues(alpha: 0.25),
    );

    void pillar(double x, Color fill) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, 88, 22, 80), const Radius.circular(3)),
        Paint()..color = fill,
      );
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(36, 168, 208, 14), Radius.circular(3)),
      Paint()..color = MunshiColors.brassGold,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(48, 176, 184, 10), Radius.circular(2)),
      Paint()..color = const Color(0xFFE8E0D0),
    );

    pillar(62, const Color(0xFFD9D0BE));
    pillar(109, const Color(0xFFE8E0D0));
    pillar(149, const Color(0xFFD9D0BE));
    pillar(196, const Color(0xFFE8E0D0));

    final gild = Paint()..color = MunshiColors.brassGold;
    canvas.drawPath(
      Path()
        ..moveTo(48, 88)
        ..lineTo(232, 88)
        ..lineTo(218, 70)
        ..lineTo(62, 70)
        ..close(),
      gild,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(70, 62, 140, 12), Radius.circular(2)),
      Paint()..color = const Color(0xFFCBB27F),
    );
    canvas.drawPath(
      Path()
        ..moveTo(92, 62)
        ..lineTo(140, 28)
        ..lineTo(188, 62)
        ..close(),
      gild,
    );

    final ink = Paint()
      ..color = MunshiColors.inkGreen
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(140, 52), const Offset(140, 78), ink);
    canvas.drawLine(const Offset(104, 78), const Offset(176, 78), ink);
    canvas.drawCircle(const Offset(140, 78), 4, Paint()..color = MunshiColors.brassGold);

    final brassStroke = Paint()
      ..color = MunshiColors.brassGold
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawArc(Rect.fromLTWH(104, 78, 36, 40), 0, 3.14, false, brassStroke);
    canvas.drawArc(Rect.fromLTWH(140, 78, 36, 40), 0, 3.14, false, brassStroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
