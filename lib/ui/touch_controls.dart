import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/meetra_game.dart';
import '../input.dart';
import '../world/arms.dart';
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
          _Button(x: w - 90, y: h - 90, r: 66, icon: ButtonIcon.up, keyName: 'jump'),
          _Button(x: w - 240, y: h - 80, r: 56, icon: ButtonIcon.sword, keyName: 'attack'),
          if (game.state.hasFeather) _Button(x: w - 130, y: h - 235, r: 46, icon: ButtonIcon.star, keyName: 'spell'),
          // Trade or Rest, only while Ra stands at a stall or the inn's door
          ValueListenableBuilder<String?>(
            valueListenable: game.ui.action,
            builder: (context, a, _) => a == null
                ? const SizedBox.shrink()
                : At(w / 2, h - 300,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (_) => game.act(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xff1b2a6b),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: const Color(0xffd4a845), width: 3),
                          boxShadow: [BoxShadow(color: gold.withValues(alpha: 0.4), blurRadius: 16)],
                        ),
                        child: OutlinedText(a, size: 26, color: gold),
                      ),
                    )),
          ),
          // Bombs, with how many are left in the bag
          _Button(x: w - 375, y: h - 105, r: 44, icon: ButtonIcon.bomb, keyName: 'bomb'),
          At(w - 343, h - 140,
              child: IgnorePointer(
                  child: OutlinedText('${game.state.bombs}', size: 18, color: game.state.bombs > 0 ? parch : const Color(0xffff8a7a)))),
          // The arms button: shows the weapon in Ra's hand, tap to change to the next one
          if (game.state.arms.isNotEmpty) ...[
            _Button(x: w - 395, y: h - 225, r: 40, icon: ButtonIcon.arm, keyName: 'swap', arm: game.state.wield),
            At(w - 395, h - 172,
                child: IgnorePointer(
                    child: OutlinedText(armName(game.state.wield), size: 13, color: game.state.wield < 0 ? parch : Color(arms[game.state.wield].color)))),
          ],
          // Healing draughts, with how many are left
          if (game.state.draughts > 0) ...[
            _Button(x: w - 265, y: h - 205, r: 38, icon: ButtonIcon.flask, keyName: 'drink'),
            At(w - 237, h - 233,
                child: IgnorePointer(child: OutlinedText('${game.state.draughts}', size: 18, color: const Color(0xffff8a9a)))),
          ],
        ]),
      );
}

class _Button extends StatefulWidget {
  const _Button({required this.x, required this.y, required this.r, required this.icon, required this.keyName, this.arm = -1});

  final double x, y, r;
  final ButtonIcon icon;
  final String keyName;
  final int arm; // for the arms button: which weapon to draw

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
            child: CustomPaint(size: Size.square(r * 0.8), painter: ButtonIconPainter(widget.icon, arm: widget.arm)),
          ),
        ),
      ),
    );
  }
}

enum ButtonIcon { left, right, up, down, sword, star, flask, bomb, arm }

// Button icons are drawn as shapes: glyphs like ◀ ⚔ turn into emoji on some Android versions
class ButtonIconPainter extends CustomPainter {
  const ButtonIconPainter(this.icon, {this.arm = -1});
  final ButtonIcon icon;
  final int arm;

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
      case ButtonIcon.bomb:
        // A round black bomb with a short fuse and a spark
        c.drawCircle(Offset(s * 0.46, s * 0.58), s * 0.34, outline);
        c.drawCircle(Offset(s * 0.46, s * 0.58), s * 0.34, Paint()..color = const Color(0xff2a2a34));
        c.drawCircle(Offset(s * 0.36, s * 0.48), s * 0.08, Paint()..color = parch.withValues(alpha: 0.7));
        c.drawRect(Rect.fromLTWH(s * 0.58, s * 0.2, s * 0.12, s * 0.14), Paint()..color = const Color(0xff8a5a2a));
        c.drawCircle(Offset(s * 0.72, s * 0.16), s * 0.09, Paint()..color = const Color(0xffffc040));
      case ButtonIcon.arm:
        _paintArm(c, s, arm < 0 ? null : arms[arm].kind, shape, outline);
      case ButtonIcon.flask:
        // A round-bellied bottle with a cork, the draught glowing red inside
        final bottle = Path()
          ..moveTo(s * 0.42, s * 0.12)
          ..lineTo(s * 0.58, s * 0.12)
          ..lineTo(s * 0.58, s * 0.36)
          ..quadraticBezierTo(s * 0.86, s * 0.48, s * 0.82, s * 0.7)
          ..quadraticBezierTo(s * 0.76, s * 0.92, s * 0.5, s * 0.92)
          ..quadraticBezierTo(s * 0.24, s * 0.92, s * 0.18, s * 0.7)
          ..quadraticBezierTo(s * 0.14, s * 0.48, s * 0.42, s * 0.36)
          ..close();
        shape(bottle);
        c.drawOval(Rect.fromLTRB(s * 0.24, s * 0.56, s * 0.76, s * 0.88), Paint()..color = const Color(0xffe0485a));
        c.drawRect(Rect.fromLTRB(s * 0.4, s * 0.04, s * 0.6, s * 0.14), Paint()..color = const Color(0xff8a5a2a));
    }
  }

  // One small picture for each weapon, drawn on the diagonal like the sword button
  void _paintArm(Canvas c, double s, ArmKind? kind, void Function(Path) shape, Paint outline) {
    Paint paint(int color) => Paint()..color = Color(color);
    final wood = paint(0xff8a5a2a);
    final steel = paint(0xffd8dce8);
    void stick(Offset a, Offset b, double w, Paint p) {
      c.drawLine(a, b, Paint()
        ..color = ink
        ..strokeWidth = w + s * 0.07
        ..strokeCap = StrokeCap.round);
      c.drawLine(a, b, Paint()
        ..color = p.color
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round);
    }

    Path poly(List<Offset> pts) => Path()..addPolygon(pts, true);
    switch (kind) {
      case null:
        // Ra's own sword
        stick(Offset(s * 0.22, s * 0.78), Offset(s * 0.36, s * 0.64), s * 0.1, wood);
        shape(poly([Offset(s * 0.34, s * 0.6), Offset(s * 0.8, s * 0.14), Offset(s * 0.86, s * 0.2), Offset(s * 0.4, s * 0.66)]));
        stick(Offset(s * 0.26, s * 0.54), Offset(s * 0.46, s * 0.74), s * 0.07, paint(0xffd4a845));
      case ArmKind.spear:
        stick(Offset(s * 0.12, s * 0.88), Offset(s * 0.72, s * 0.28), s * 0.08, paint(0xffc8b070));
        shape(poly([Offset(s * 0.66, s * 0.26), Offset(s * 0.9, s * 0.1), Offset(s * 0.74, s * 0.34)]));
      case ArmKind.hammer:
        stick(Offset(s * 0.2, s * 0.84), Offset(s * 0.6, s * 0.4), s * 0.1, wood);
        c.save();
        c.translate(s * 0.62, s * 0.36);
        c.rotate(-math.pi / 4);
        final head = Rect.fromCenter(center: Offset.zero, width: s * 0.56, height: s * 0.26);
        c.drawRect(head.inflate(s * 0.035), Paint()..color = ink);
        c.drawRect(head, steel);
        c.restore();
      case ArmKind.bow:
        final arc = Path()
          ..moveTo(s * 0.3, s * 0.1)
          ..quadraticBezierTo(s * 0.95, s * 0.5, s * 0.3, s * 0.9);
        c.drawPath(arc, Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.15);
        c.drawPath(arc, Paint()
          ..color = const Color(0xffe8c070)
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.08);
        c.drawLine(Offset(s * 0.3, s * 0.1), Offset(s * 0.3, s * 0.9), Paint()
          ..color = parch
          ..strokeWidth = s * 0.03);
        stick(Offset(s * 0.14, s * 0.5), Offset(s * 0.7, s * 0.5), s * 0.04, steel);
      case ArmKind.mace:
        stick(Offset(s * 0.2, s * 0.84), Offset(s * 0.56, s * 0.46), s * 0.1, wood);
        c.drawCircle(Offset(s * 0.64, s * 0.36), s * 0.24, Paint()..color = ink);
        c.drawCircle(Offset(s * 0.64, s * 0.36), s * 0.2, paint(0xffb0b8d0));
        // The ox's horns
        stick(Offset(s * 0.5, s * 0.2), Offset(s * 0.42, s * 0.06), s * 0.06, Paint()..color = parch);
        stick(Offset(s * 0.8, s * 0.24), Offset(s * 0.92, s * 0.12), s * 0.06, Paint()..color = parch);
      case ArmKind.lasso:
        final loop = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.08;
        c.drawOval(Rect.fromLTRB(s * 0.3, s * 0.1, s * 0.9, s * 0.56), loop..color = ink..strokeWidth = s * 0.14);
        c.drawOval(Rect.fromLTRB(s * 0.3, s * 0.1, s * 0.9, s * 0.56), loop..color = const Color(0xffd8a868)..strokeWidth = s * 0.07);
        stick(Offset(s * 0.4, s * 0.5), Offset(s * 0.12, s * 0.9), s * 0.06, paint(0xffd8a868));
      case ArmKind.shield:
        final kite = Path()
          ..moveTo(s * 0.5, s * 0.08)
          ..quadraticBezierTo(s * 0.88, s * 0.14, s * 0.84, s * 0.4)
          ..quadraticBezierTo(s * 0.78, s * 0.74, s * 0.5, s * 0.92)
          ..quadraticBezierTo(s * 0.22, s * 0.74, s * 0.16, s * 0.4)
          ..quadraticBezierTo(s * 0.12, s * 0.14, s * 0.5, s * 0.08)
          ..close();
        c.drawPath(kite, outline);
        c.drawPath(kite, paint(0xff7ad8d0));
        c.drawCircle(Offset(s * 0.5, s * 0.42), s * 0.1, paint(0xffd4a845));
      case ArmKind.dawnfire:
        stick(Offset(s * 0.22, s * 0.78), Offset(s * 0.36, s * 0.64), s * 0.1, wood);
        final blade = poly([Offset(s * 0.34, s * 0.6), Offset(s * 0.82, s * 0.12), Offset(s * 0.88, s * 0.18), Offset(s * 0.4, s * 0.66)]);
        c.drawPath(blade, outline);
        c.drawPath(blade, paint(0xffffb040));
        c.drawCircle(Offset(s * 0.78, s * 0.22), s * 0.1, paint(0xfffff0a0));
        stick(Offset(s * 0.26, s * 0.54), Offset(s * 0.46, s * 0.74), s * 0.07, paint(0xffd4a845));
    }
  }

  @override
  bool shouldRepaint(ButtonIconPainter old) => old.icon != icon || old.arm != arm;
}
