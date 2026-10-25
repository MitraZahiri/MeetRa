import 'package:flutter/material.dart';

import '../art/pixel.dart';

const gold = Color(0xfff7d774);
const parch = Color(0xfff2e6c9);
const ink = Color(0xff1a1020);
const fontFamily = 'serif';

// Text with a dark outline, like Phaser text with stroke
class OutlinedText extends StatelessWidget {
  const OutlinedText(this.text, {super.key, required this.size, this.color = parch, this.stroke = true, this.width});

  final String text;
  final double size;
  final Color color;
  final bool stroke;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(fontFamily: fontFamily, fontSize: size, height: 1.2, decoration: TextDecoration.none);
    Widget t(TextStyle s) => SizedBox(width: width, child: Text(text, textAlign: TextAlign.center, softWrap: width != null, style: s));
    if (!stroke) return t(base.copyWith(color: color));
    return Stack(children: [
      t(base.copyWith(
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = size / 5 < 3 ? 3 : size / 5
          ..strokeJoin = StrokeJoin.round
          ..color = ink,
      )),
      t(base.copyWith(color: color)),
    ]);
  }
}

// Places a child so that its anchor point (ax, ay in 0..1) sits at (x, y) of the virtual screen
class At extends StatelessWidget {
  const At(this.x, this.y, {super.key, this.ax = 0.5, this.ay = 0.5, required this.child});

  final double x, y, ax, ay;
  final Widget child;

  @override
  Widget build(BuildContext context) => Positioned(
        left: x,
        top: y,
        child: FractionalTranslation(translation: Offset(-ax, -ay), child: child),
      );
}

// One frame of a generated sprite sheet, scaled up with crisp pixels
class SheetFrame extends StatelessWidget {
  const SheetFrame(this.sheet, this.frame, {super.key, this.scale = 1});

  final Sheet sheet;
  final int frame;
  final double scale;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(sheet.frameW * scale, sheet.frameH * scale), painter: _FramePainter(sheet, frame));
}

class _FramePainter extends CustomPainter {
  _FramePainter(this.sheet, this.frame);
  final Sheet sheet;
  final int frame;

  @override
  void paint(Canvas canvas, Size size) =>
      canvas.drawImageRect(sheet.image, sheet.src(frame), Offset.zero & size, Paint()..filterQuality = FilterQuality.none);

  @override
  bool shouldRepaint(_FramePainter old) => old.frame != frame || old.sheet != sheet;
}

// Gold double frame used by the title and victory screens
class FramePainter extends CustomPainter {
  const FramePainter({this.inner = true});
  final bool inner;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromLTWH(40, 40, size.width - 80, size.height - 80), p..color = const Color(0xffd4a845)..strokeWidth = 3);
    if (inner) {
      canvas.drawRect(Rect.fromLTWH(50, 50, size.width - 100, size.height - 100), p..color = const Color(0xff2bb3a8)..strokeWidth = 1);
    }
  }

  @override
  bool shouldRepaint(FramePainter old) => old.inner != inner;
}
