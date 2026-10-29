import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../art/pixel.dart';
import '../music.dart';

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

// Outlined text whose gold fill has a highlight sweeping across it
class ShimmerText extends StatelessWidget {
  const ShimmerText(this.text, {super.key, required this.size, required this.phase});

  final String text;
  final double size;
  final double phase; // advances the highlight; any number, it wraps

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(fontFamily: fontFamily, fontSize: size, height: 1.2, decoration: TextDecoration.none);
    final p = phase % 1.6 - 0.3;
    return Stack(children: [
      Text(text,
          style: base.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = size / 5 < 3 ? 3 : size / 5
              ..strokeJoin = StrokeJoin.round
              ..color = ink,
            shadows: [Shadow(color: const Color(0xffd4a845).withValues(alpha: 0.6), blurRadius: size * 0.4)],
          )),
      ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (r) => LinearGradient(
          colors: const [Color(0xffd4a845), Color(0xfff7d774), Color(0xfffffbe8), Color(0xfff7d774), Color(0xffd4a845)],
          stops: [0, (p - 0.12).clamp(0.0, 1.0), p.clamp(0.0, 1.0), (p + 0.12).clamp(0.0, 1.0), 1],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(r),
        child: Text(text, style: base.copyWith(color: Colors.white)),
      ),
    ]);
  }
}

// Gold double frame used by the title and victory screens, with ornamental corners
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
    final fill = Paint()..color = const Color(0xffd4a845);
    for (final (x, y) in [(40.0, 40.0), (size.width - 40, 40.0), (40.0, size.height - 40), (size.width - 40, size.height - 40)]) {
      canvas.drawPath(
          Path()
            ..moveTo(x, y - 12)
            ..lineTo(x + 12, y)
            ..lineTo(x, y + 12)
            ..lineTo(x - 12, y)
            ..close(),
          fill);
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = const Color(0xff1b2a6b));
    }
  }

  @override
  bool shouldRepaint(FramePainter old) => old.inner != inner;
}

// Golden motes drifting upward behind menus
class FloatingMotes extends StatefulWidget {
  const FloatingMotes({super.key, this.count = 40, this.color = const Color(0xfff7d774)});
  final int count;
  final Color color;

  @override
  State<FloatingMotes> createState() => _FloatingMotesState();
}

class _FloatingMotesState extends State<FloatingMotes> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 30))..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _MotesPainter(_c, widget.count, widget.color), child: const SizedBox.expand());
}

class _MotesPainter extends CustomPainter {
  _MotesPainter(this.anim, this.count, this.color) : super(repaint: anim);
  final Animation<double> anim;
  final int count;
  final Color color;

  @override
  void paint(Canvas c, Size size) {
    final t = anim.value * 30;
    final r = math.Random(3);
    final p = Paint()..blendMode = BlendMode.plus;
    for (var i = 0; i < count; i++) {
      final speed = 8 + r.nextDouble() * 18;
      final x = r.nextDouble() * size.width + math.sin(t * 0.6 + i) * 14;
      final y = size.height - ((r.nextDouble() * size.height + t * speed) % (size.height + 20));
      final s = 1 + r.nextDouble() * 2.2;
      final a = 0.35 + 0.35 * math.sin(t * 1.5 + i * 2.1);
      p.color = color.withValues(alpha: a.clamp(0.0, 1.0) * 0.35);
      c.drawCircle(Offset(x, y), s * 3, p);
      p.color = color.withValues(alpha: a.clamp(0.0, 1.0));
      c.drawCircle(Offset(x, y), s * 0.8, p);
    }
  }

  @override
  bool shouldRepaint(_MotesPainter old) => false;
}

// Round speaker button that switches music and sound effects on and off
class SoundButton extends StatelessWidget {
  const SoundButton({super.key, this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
        valueListenable: music.soundOn,
        builder: (context, on, _) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: music.toggleSound,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0x991b2a6b),
              border: Border.all(color: const Color(0xaad4a845), width: 2),
            ),
            child: CustomPaint(painter: _SpeakerPainter(on)),
          ),
        ),
      );
}

class _SpeakerPainter extends CustomPainter {
  _SpeakerPainter(this.on);
  final bool on;

  @override
  void paint(Canvas c, Size size) {
    final s = size.width;
    final fill = Paint()..color = parch;
    c.drawPath(
        Path()
          ..moveTo(s * 0.22, s * 0.4)
          ..lineTo(s * 0.36, s * 0.4)
          ..lineTo(s * 0.52, s * 0.26)
          ..lineTo(s * 0.52, s * 0.74)
          ..lineTo(s * 0.36, s * 0.6)
          ..lineTo(s * 0.22, s * 0.6)
          ..close(),
        fill);
    final line = Paint()
      ..color = parch
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.06
      ..strokeCap = StrokeCap.round;
    if (on) {
      for (final r in [0.12, 0.22]) {
        c.drawArc(Rect.fromCircle(center: Offset(s * 0.52, s * 0.5), radius: s * r), -0.8, 1.6, false, line);
      }
    } else {
      line.color = const Color(0xffff8a7a);
      c.drawLine(Offset(s * 0.62, s * 0.38), Offset(s * 0.82, s * 0.62), line);
      c.drawLine(Offset(s * 0.82, s * 0.38), Offset(s * 0.62, s * 0.62), line);
    }
  }

  @override
  bool shouldRepaint(_SpeakerPainter old) => old.on != on;
}
