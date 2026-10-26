import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/meetra_game.dart';
import '../input.dart';
import 'common.dart';

// On-screen buttons. Left thumb: movement. Right thumb: actions.
// Each button tracks its own pointers, so several can be held at once.
class TouchControls extends StatelessWidget {
  const TouchControls(this.game, {super.key, required this.w, required this.h});

  final MeetRaGame game;
  final double w, h;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: game.state,
        builder: (context, _) => Stack(children: [
          _Button(x: 85, y: h - 90, r: 62, icon: ButtonIcon.left, keyName: 'left'),
          _Button(x: 230, y: h - 90, r: 62, icon: ButtonIcon.right, keyName: 'right'),
          _Button(x: 158, y: h - 205, r: 42, icon: ButtonIcon.down, keyName: 'down'),
          _Button(x: w - 90, y: h - 90, r: 66, icon: ButtonIcon.up, keyName: 'jump'),
          _Button(x: w - 240, y: h - 80, r: 56, icon: ButtonIcon.sword, keyName: 'attack'),
          if (game.state.hasFeather) _Button(x: w - 130, y: h - 235, r: 46, icon: ButtonIcon.star, keyName: 'spell'),
        ]),
      );
}

class _Button extends StatefulWidget {
  const _Button({required this.x, required this.y, required this.r, required this.icon, required this.keyName});

  final double x, y, r;
  final ButtonIcon icon;
  final String keyName;

  @override
  State<_Button> createState() => _ButtonState();
}

class _ButtonState extends State<_Button> {
  final _pointers = <int>{};

  bool _inside(Offset p) => (p - Offset(widget.r, widget.r)).distance <= widget.r;

  void _sync() {
    final down = _pointers.isNotEmpty;
    touch.set(widget.keyName, down);
    setState(() {});
  }

  @override
  void dispose() {
    touch.set(widget.keyName, false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.r;
    final pressed = _pointers.isNotEmpty;
    return Positioned(
      left: widget.x - r,
      top: widget.y - r,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (e) {
          if (!_inside(e.localPosition)) return;
          _pointers.add(e.pointer);
          _sync();
        },
        // Sliding a thumb off the button releases it
        onPointerMove: (e) {
          if (_pointers.contains(e.pointer) && !_inside(e.localPosition)) {
            _pointers.remove(e.pointer);
            _sync();
          }
        },
        onPointerUp: (e) {
          if (_pointers.remove(e.pointer)) _sync();
        },
        onPointerCancel: (e) {
          if (_pointers.remove(e.pointer)) _sync();
        },
        // Glassy disc that sinks a little and glows gold while held
        child: AnimatedScale(
          scale: pressed ? 0.9 : 1,
          duration: const Duration(milliseconds: 70),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            width: r * 2,
            height: r * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.4),
                colors: pressed
                    ? [parch.withValues(alpha: 0.6), const Color(0xffd4a845).withValues(alpha: 0.35)]
                    : [parch.withValues(alpha: 0.24), const Color(0xff1b2a6b).withValues(alpha: 0.18)],
              ),
              border: Border.all(color: const Color(0xffd4a845).withValues(alpha: pressed ? 0.95 : 0.6), width: 3),
              boxShadow: pressed
                  ? [BoxShadow(color: const Color(0xfff7d774).withValues(alpha: 0.5), blurRadius: 18, spreadRadius: 2)]
                  : const [BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 3))],
            ),
            alignment: Alignment.center,
            child: CustomPaint(size: Size.square(r * 0.8), painter: ButtonIconPainter(widget.icon)),
          ),
        ),
      ),
    );
  }
}

enum ButtonIcon { left, right, up, down, sword, star }

// Button icons are drawn as shapes: glyphs like ◀ ⚔ turn into emoji on some Android versions
class ButtonIconPainter extends CustomPainter {
  const ButtonIconPainter(this.icon);
  final ButtonIcon icon;

  @override
  void paint(Canvas c, Size size) {
    final s = size.width;
    final fill = Paint()..color = parch.withValues(alpha: 0.85);
    final outline = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.07
      ..strokeJoin = StrokeJoin.round;
    void shape(Path p) {
      c.drawPath(p, outline);
      c.drawPath(p, fill);
    }

    Path tri(Offset a, Offset b, Offset d) => Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy)
      ..lineTo(d.dx, d.dy)
      ..close();

    switch (icon) {
      case ButtonIcon.left:
        shape(tri(Offset(s * 0.2, s * 0.5), Offset(s * 0.75, s * 0.18), Offset(s * 0.75, s * 0.82)));
      case ButtonIcon.right:
        shape(tri(Offset(s * 0.8, s * 0.5), Offset(s * 0.25, s * 0.18), Offset(s * 0.25, s * 0.82)));
      case ButtonIcon.up:
        shape(tri(Offset(s * 0.5, s * 0.2), Offset(s * 0.18, s * 0.75), Offset(s * 0.82, s * 0.75)));
      case ButtonIcon.down:
        shape(tri(Offset(s * 0.5, s * 0.8), Offset(s * 0.18, s * 0.25), Offset(s * 0.82, s * 0.25)));
      case ButtonIcon.sword:
        // Two crossed sabres: blade from the hilt (bottom corner) to the tip (opposite top corner)
        final goldPaint = Paint()
          ..color = const Color(0xffd4a845)
          ..strokeCap = StrokeCap.round;
        for (final flip in [false, true]) {
          c.save();
          if (flip) {
            c.translate(s, 0);
            c.scale(-1, 1);
          }
          // Drawn along the diagonal from (0.2, 0.8) to (0.88, 0.12)
          c.translate(s * 0.5, s * 0.5);
          c.rotate(-math.pi / 4);
          final len = s * 0.98;
          final blade = Path()
            ..moveTo(-len * 0.28, -s * 0.045)
            ..lineTo(len * 0.42, -s * 0.045)
            ..lineTo(len * 0.52, 0)
            ..lineTo(len * 0.42, s * 0.045)
            ..lineTo(-len * 0.28, s * 0.045)
            ..close();
          shape(blade);
          // Cross-guard and grip
          final guard = Rect.fromCenter(center: Offset(-len * 0.3, 0), width: s * 0.07, height: s * 0.3);
          c.drawRRect(RRect.fromRectAndRadius(guard.inflate(s * 0.03), Radius.circular(s * 0.04)), Paint()..color = ink);
          c.drawRRect(RRect.fromRectAndRadius(guard, Radius.circular(s * 0.03)), goldPaint);
          c.drawLine(Offset(-len * 0.34, 0), Offset(-len * 0.48, 0), outline..strokeWidth = s * 0.13);
          c.drawLine(Offset(-len * 0.34, 0), Offset(-len * 0.48, 0), goldPaint..strokeWidth = s * 0.07);
          outline.strokeWidth = s * 0.07;
          c.restore();
        }
      case ButtonIcon.star:
        final p = Path();
        for (var i = 0; i < 8; i++) {
          final r = i.isEven ? s * 0.45 : s * 0.13;
          final a = i * 3.141592653589793 / 4 - 3.141592653589793 / 2;
          final o = Offset(s / 2 + r * math.cos(a), s / 2 + r * math.sin(a));
          i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
        }
        shape(p..close());
    }
  }

  @override
  bool shouldRepaint(ButtonIconPainter old) => old.icon != icon;
}
