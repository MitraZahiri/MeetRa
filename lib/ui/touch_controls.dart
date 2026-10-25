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
          _Button(x: 85, y: h - 90, r: 62, icon: _Icon.left, keyName: 'left'),
          _Button(x: 230, y: h - 90, r: 62, icon: _Icon.right, keyName: 'right'),
          _Button(x: 158, y: h - 205, r: 42, icon: _Icon.down, keyName: 'down'),
          _Button(x: w - 90, y: h - 90, r: 66, icon: _Icon.up, keyName: 'jump'),
          _Button(x: w - 240, y: h - 80, r: 56, icon: _Icon.sword, keyName: 'attack'),
          if (game.state.hasFeather) _Button(x: w - 130, y: h - 235, r: 46, icon: _Icon.star, keyName: 'spell'),
        ]),
      );
}

class _Button extends StatefulWidget {
  const _Button({required this.x, required this.y, required this.r, required this.icon, required this.keyName});

  final double x, y, r;
  final _Icon icon;
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
        child: Container(
          width: r * 2,
          height: r * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: parch.withValues(alpha: pressed ? 0.4 : 0.14),
            border: Border.all(color: const Color(0xffd4a845).withValues(alpha: 0.6), width: 3),
          ),
          alignment: Alignment.center,
          child: CustomPaint(size: Size.square(r * 0.8), painter: _IconPainter(widget.icon)),
        ),
      ),
    );
  }
}

enum _Icon { left, right, up, down, sword, star }

// Button icons are drawn as shapes: glyphs like ◀ ⚔ turn into emoji on some Android versions
class _IconPainter extends CustomPainter {
  const _IconPainter(this.icon);
  final _Icon icon;

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
      case _Icon.left:
        shape(tri(Offset(s * 0.2, s * 0.5), Offset(s * 0.75, s * 0.18), Offset(s * 0.75, s * 0.82)));
      case _Icon.right:
        shape(tri(Offset(s * 0.8, s * 0.5), Offset(s * 0.25, s * 0.18), Offset(s * 0.25, s * 0.82)));
      case _Icon.up:
        shape(tri(Offset(s * 0.5, s * 0.2), Offset(s * 0.18, s * 0.75), Offset(s * 0.82, s * 0.75)));
      case _Icon.down:
        shape(tri(Offset(s * 0.5, s * 0.8), Offset(s * 0.18, s * 0.25), Offset(s * 0.82, s * 0.25)));
      case _Icon.sword:
        // Two crossed blades with gold guards
        for (final flip in [false, true]) {
          c.save();
          if (flip) {
            c.translate(s, 0);
            c.scale(-1, 1);
          }
          final blade = Path()
            ..moveTo(s * 0.12, s * 0.12)
            ..lineTo(s * 0.24, s * 0.12)
            ..lineTo(s * 0.74, s * 0.62)
            ..lineTo(s * 0.62, s * 0.74)
            ..lineTo(s * 0.12, s * 0.24)
            ..close();
          shape(blade);
          c.drawLine(Offset(s * 0.58, s * 0.82), Offset(s * 0.82, s * 0.58), outline..strokeWidth = s * 0.16);
          c.drawLine(Offset(s * 0.58, s * 0.82), Offset(s * 0.82, s * 0.58),
              Paint()
                ..color = const Color(0xffd4a845)
                ..strokeWidth = s * 0.09
                ..strokeCap = StrokeCap.round);
          outline.strokeWidth = s * 0.07;
          c.restore();
        }
      case _Icon.star:
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
  bool shouldRepaint(_IconPainter old) => old.icon != icon;
}
