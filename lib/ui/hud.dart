import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config.dart';
import '../game/meetra_game.dart';
import 'common.dart';

// Hearts, aura, gold, level and XP. Hearts pop when health changes and the last one
// beats when Ra is low; the gold counter bumps on every coin; bars have a moving shine.
class Hud extends StatefulWidget {
  const Hud(this.game, {super.key, required this.w});

  final MeetRaGame game;
  final double w;

  @override
  State<Hud> createState() => _HudState();
}

class _HudState extends State<Hud> with TickerProviderStateMixin {
  late final _clock = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
  late final _hpPop = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
  late final _goldPop = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
  late int _hp = widget.game.state.hp;
  late int _gold = widget.game.state.gold;
  bool _hurt = false;

  @override
  void initState() {
    super.initState();
    widget.game.state.addListener(_changed);
  }

  void _changed() {
    final s = widget.game.state;
    if (s.hp != _hp) {
      _hurt = s.hp < _hp;
      _hp = s.hp;
      _hpPop.forward(from: 0);
    }
    if (s.gold != _gold) {
      if (s.gold > _gold) _goldPop.forward(from: 0);
      _gold = s.gold;
    }
  }

  @override
  void dispose() {
    widget.game.state.removeListener(_changed);
    _clock.dispose();
    _hpPop.dispose();
    _goldPop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.w;
    return AnimatedBuilder(
      // The clock is not listened to here: only the pieces that move with it rebuild every frame
      animation: Listenable.merge([_hpPop, _goldPop, widget.game.state]),
      builder: (context, _) {
        final s = widget.game.state;
        final nHearts = (s.maxHp / 2).ceil();
        final pop = 1 - _hpPop.value; // 1 right after a change, fading to 0
        final shake = _hurt ? math.sin(_hpPop.value * math.pi * 6) * 4 * pop : 0.0;
        final low = s.hp <= 2 && s.hp > 0;
        final lastFull = (s.hp - 1) ~/ 2;
        return Stack(children: [
          // A soft dark backing so the HUD reads over bright skies
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 60 + nHearts * 32.0 + (s.hasFeather ? s.auraMax * 1.0 : 0),
              height: 92,
              decoration: const BoxDecoration(
                gradient: RadialGradient(center: Alignment(-1, -1), radius: 1.4, colors: [Color(0x661a1020), Color(0x001a1020)]),
              ),
            ),
          ),
          for (var i = 0; i < nHearts; i++)
            At(
              30 + i * 32.0 + shake,
              30,
              child: _ticking(
                low && i == lastFull,
                (t) => Transform.scale(
                  scale: 3 * (1 + 0.25 * pop * (_hurt ? 0.6 : 1)) * (low && i == lastFull ? 1 + 0.14 * math.max(0, math.sin(t * 9)) : 1),
                  child: SheetFrame(widget.game.art.heart, _heartFrame(s.hp - i * 2)),
                ),
              ),
            ),
          At(
            w - 28,
            28,
            child: _ticking(
              true,
              (t) => Transform(
                alignment: Alignment.center,
                transform: Matrix4.diagonal3Values(4 * math.max(0.3, math.cos(t * 2.4).abs()), 4, 1),
                child: SheetFrame(widget.game.art.coin, 0),
              ),
            ),
          ),
          At(w - 48, 28, ax: 1,
              child: Transform.scale(
                  scale: 1 + 0.3 * (1 - _goldPop.value) * (_goldPop.isAnimating ? 1 : 0),
                  alignment: Alignment.centerRight,
                  child: OutlinedText('${s.gold}', size: 24, color: gold))),
          At(w - 24, 58, ax: 1, child: OutlinedText('Lv ${s.level}', size: 18)),
          Positioned.fill(child: CustomPaint(painter: _Bars(s, w, _clock))),
          if (s.hasFeather) At(24, 62, ax: 0, child: const OutlinedText('AURA', size: 13, color: gold)),
        ]);
      },
    );
  }

  // Rebuilds [build] with the clock (in seconds) every frame when [live], once otherwise
  Widget _ticking(bool live, Widget Function(double t) build) =>
      live ? AnimatedBuilder(animation: _clock, builder: (context, _) => build(_clock.value * 10)) : build(_clock.value * 10);

  int _heartFrame(int v) => v >= 2 ? 0 : (v == 1 ? 1 : 2);
}

// Rounded bar with a dark trough, gradient fill, gloss line and a shine that sweeps across
void paintBar(Canvas c, Rect r, double frac, List<Color> fill, {double t = 0, Color border = gold, bool trough = true}) {
  final rr = RRect.fromRectAndRadius(r, Radius.circular(r.height / 2));
  if (trough) c.drawRRect(rr, Paint()..color = const Color(Palette.ink).withValues(alpha: 0.82));
  final f = frac.clamp(0.0, 1.0);
  if (f > 0) {
    final inner = Rect.fromLTWH(r.left + 2, r.top + 2, (r.width - 4) * f, r.height - 4);
    final ir = RRect.fromRectAndRadius(inner, Radius.circular(inner.height / 2));
    c.save();
    c.clipRRect(ir);
    c.drawRect(inner, Paint()..shader = LinearGradient(colors: fill, begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(inner));
    c.drawRect(Rect.fromLTWH(inner.left, inner.top, inner.width, inner.height * 0.35), Paint()..color = const Color(0x55ffffff));
    final sx = r.left + ((t * 0.35) % 1.6 - 0.3) * r.width;
    c.drawRect(
      Rect.fromLTWH(sx, inner.top, 24, inner.height),
      Paint()..shader = const LinearGradient(colors: [Color(0x00ffffff), Color(0x88ffffff), Color(0x00ffffff)]).createShader(Rect.fromLTWH(sx, 0, 24, 1)),
    );
    c.restore();
  }
  c.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = border.withValues(alpha: 0.9));
}

class _Bars extends CustomPainter {
  _Bars(this.s, this.w, this.clock) : super(repaint: clock);
  final GameState s;
  final double w;
  final Animation<double> clock;

  @override
  void paint(Canvas c, Size size) {
    final t = clock.value * 10;
    paintBar(c, Rect.fromLTWH(w - 24 - 150, 72, 150, 10), s.xp / s.xpNext, const [Color(0xffc8fff8), Color(0xff4ab8b0)], t: t);
    // Aura bar: only shown once a spell is earned
    if (s.hasFeather) {
      paintBar(c, Rect.fromLTWH(70, 54, s.auraMax * 2.0 + 4, 14), s.aura / s.auraMax, const [Color(0xfffff0a0), Color(0xffc8902a)], t: t + 3);
    }
  }

  @override
  bool shouldRepaint(_Bars old) => true;
}

// Signpost text box: slides down and fades in
class SignBox extends StatefulWidget {
  const SignBox(this.game, {super.key, required this.w});
  final MeetRaGame game;
  final double w;

  @override
  State<SignBox> createState() => _SignBoxState();
}

class _SignBoxState extends State<SignBox> with SingleTickerProviderStateMixin {
  late final _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
  String? _text;

  @override
  void initState() {
    super.initState();
    widget.game.ui.sign.addListener(_changed);
  }

  void _changed() {
    final t = widget.game.ui.sign.value;
    setState(() => _text = t);
    if (t != null) _anim.forward(from: 0);
  }

  @override
  void dispose() {
    widget.game.ui.sign.removeListener(_changed);
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _text;
    if (t == null) return const SizedBox.shrink();
    return Stack(children: [
      At(
        widget.w / 2,
        112,
        child: AnimatedBuilder(
          animation: _anim,
          builder: (context, child) {
            final k = Curves.easeOutBack.transform(_anim.value);
            return Opacity(
              opacity: _anim.value,
              child: Transform.translate(offset: Offset(0, -14 * (1 - k)), child: Transform.scale(scale: 0.92 + 0.08 * k, child: child)),
            );
          },
          child: Container(
            width: 640,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xfff8eed6), Color(0xffe6d2a8)],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(Palette.gold), width: 3),
              boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 14, offset: Offset(0, 6))],
            ),
            padding: const EdgeInsets.all(4),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(Palette.lapis).withValues(alpha: 0.7), width: 1),
              ),
              alignment: Alignment.center,
              child: OutlinedText(t, size: 21, color: ink, stroke: false, width: 600),
            ),
          ),
        ),
      ),
      // Little gold diamond clasps on the frame
      for (final dx in [-320.0, 320.0])
        At(widget.w / 2 + dx, 112, child: Transform.rotate(angle: math.pi / 4, child: Container(width: 12, height: 12, color: const Color(Palette.gold)))),
    ]);
  }
}

// Big centred title that pops in, holds, then fades out, between two growing gold flourishes
class BannerView extends StatefulWidget {
  const BannerView(this.game, {super.key, required this.w});
  final MeetRaGame game;
  final double w;

  @override
  State<BannerView> createState() => _BannerViewState();
}

class _BannerViewState extends State<BannerView> with SingleTickerProviderStateMixin {
  late final _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 3100));
  BannerMsg? _msg;

  @override
  void initState() {
    super.initState();
    widget.game.ui.banner.addListener(_changed);
  }

  void _changed() {
    setState(() => _msg = widget.game.ui.banner.value);
    if (_msg != null) _anim.forward(from: 0);
  }

  @override
  void dispose() {
    widget.game.ui.banner.removeListener(_changed);
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = _msg;
    if (m == null) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final ms = _anim.value * 3100;
        final fadeOut = 1 - ((ms - 2600) / 500).clamp(0.0, 1.0);
        final inT = (ms / 300).clamp(0.0, 1.0);
        final subIn = ((ms - 120) / 300).clamp(0.0, 1.0);
        final lineIn = Curves.easeOutCubic.transform(((ms - 80) / 600).clamp(0.0, 1.0));
        final scale = 0.8 + 0.2 * Curves.easeOutBack.transform(inT);
        return Stack(children: [
          Positioned.fill(
            child: CustomPaint(painter: _Flourish(widget.w / 2, 226, 300 * lineIn, fadeOut * lineIn)),
          ),
          At(widget.w / 2, 200,
              child: Opacity(
                opacity: inT * fadeOut,
                child: Transform.scale(scale: scale, child: ShimmerText(m.title, size: 40, phase: ms / 1400)),
              )),
          At(widget.w / 2, 248, child: Opacity(opacity: subIn * fadeOut, child: OutlinedText(m.sub, size: 20))),
        ]);
      },
    );
  }
}

class _Flourish extends CustomPainter {
  _Flourish(this.cx, this.y, this.half, this.alpha);
  final double cx, y, half, alpha;

  @override
  void paint(Canvas c, Size size) {
    if (alpha <= 0 || half <= 0) return;
    final p = Paint()
      ..shader = LinearGradient(colors: [
        const Color(0x00d4a845),
        const Color(0xffd4a845).withValues(alpha: alpha),
        const Color(0x00d4a845),
      ]).createShader(Rect.fromLTWH(cx - half, y, half * 2, 1))
      ..strokeWidth = 2;
    c.drawLine(Offset(cx - half, y), Offset(cx + half, y), p);
    final d = Paint()..color = const Color(0xfff7d774).withValues(alpha: alpha);
    c.drawPath(
        Path()
          ..moveTo(cx, y - 5)
          ..lineTo(cx + 5, y)
          ..lineTo(cx, y + 5)
          ..lineTo(cx - 5, y)
          ..close(),
        d);
  }

  @override
  bool shouldRepaint(_Flourish old) => true;
}

// Boss name and health bar (at the top, so thumbs never cover it).
// Damage first shows as a pale chunk that drains away a moment later.
class BossBar extends StatefulWidget {
  const BossBar(this.game, {super.key, required this.w});
  final MeetRaGame game;
  final double w;

  @override
  State<BossBar> createState() => _BossBarState();
}

class _BossBarState extends State<BossBar> with SingleTickerProviderStateMixin {
  late final _ticker = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
  double _trail = 1;

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
        valueListenable: widget.game.ui.boss,
        builder: (context, boss, _) {
          if (boss == null) {
            _trail = 1;
            return const SizedBox.shrink();
          }
          final w = widget.w;
          return Stack(children: [
            At(w / 2, 72, child: ShimmerText('${boss.name} · ${boss.title}', size: 20, phase: 0)),
            Positioned(
              left: w / 2 - 200,
              top: 88,
              child: AnimatedBuilder(
                animation: _ticker,
                builder: (context, _) {
                  final frac = widget.game.ui.bossFrac.value;
                  _trail = _trail > frac ? math.max(frac, _trail - 0.006) : frac;
                  return CustomPaint(size: const Size(400, 18), painter: _BossBarPainter(frac, _trail, _ticker.value));
                },
              ),
            ),
          ]);
        },
      );
}

class _BossBarPainter extends CustomPainter {
  _BossBarPainter(this.frac, this.trail, this.t);
  final double frac, trail, t;

  @override
  void paint(Canvas c, Size size) {
    final r = Offset.zero & size;
    final inner = Rect.fromLTWH(3, 3, size.width - 6, size.height - 6);
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(9)), Paint()..color = const Color(Palette.ink).withValues(alpha: 0.88));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(inner.left, inner.top, inner.width * trail, inner.height), const Radius.circular(6)),
        Paint()..color = const Color(0xfff0d0b0));
    paintBar(c, r, frac, const [Color(0xffff8a6a), Color(0xffa02018)], t: t * 3, trough: false);
  }

  @override
  bool shouldRepaint(_BossBarPainter old) => true;
}
