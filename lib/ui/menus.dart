import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../art/sun_eye.dart';
import '../config.dart';
import '../game/meetra_game.dart';
import 'common.dart';
import 'touch_controls.dart';

// Slowly turning sunburst behind headings
class _Rays extends CustomPainter {
  _Rays(this.center, this.t, {this.radius = 420, this.alpha = 0.16});
  final Offset center;
  final double t, radius, alpha;
  static const color = Color(0xfff7d774);

  @override
  void paint(Canvas c, Size size) {
    final p = Paint()
      ..shader = RadialGradient(colors: [color.withValues(alpha: alpha), color.withValues(alpha: 0)])
          .createShader(Rect.fromCircle(center: center, radius: radius));
    const n = 16;
    for (var i = 0; i < n; i++) {
      final a = i / n * math.pi * 2 + t * 0.15;
      c.drawPath(
        Path()
          ..moveTo(center.dx, center.dy)
          ..lineTo(center.dx + math.cos(a - 0.09) * radius, center.dy + math.sin(a - 0.09) * radius)
          ..lineTo(center.dx + math.cos(a + 0.09) * radius, center.dy + math.sin(a + 0.09) * radius)
          ..close(),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_Rays old) => true;
}

// Repaints every frame for as long as it is on screen
mixin _Clock<T extends StatefulWidget> on SingleTickerProviderStateMixin<T> {
  late final clock = AnimationController(vsync: this, duration: const Duration(seconds: 60))..repeat();
  double get seconds => clock.value * 60;

  @override
  void dispose() {
    clock.dispose();
    super.dispose();
  }
}

// ---------- Title screen ----------

class TitleScreen extends StatefulWidget {
  const TitleScreen(this.game, {super.key, required this.w});
  final MeetRaGame game;
  final double w;

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> with SingleTickerProviderStateMixin, _Clock {
  StreamSubscription<LogicalKeyboardKey>? _keys;
  bool _armed = false;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    // A short delay so a tap from the previous screen can't skip the title
    Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _armed = true;
      _keys = widget.game.keyDowns.stream.listen((_) => _start());
    });
  }

  void _start() {
    if (!_armed || _leaving) return;
    _keys?.cancel();
    widget.game.begin();
    setState(() => _leaving = true);
  }

  @override
  void dispose() {
    _keys?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.w;
    return AnimatedOpacity(
      opacity: _leaving ? 0 : 1,
      duration: const Duration(milliseconds: 500),
      onEnd: () => widget.game.ui.title.value = false,
      child: Stack(children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (_) => _start(),
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  radius: 1.1,
                  colors: [Color(0x990d1233), Color(0xee0a0e28)],
                ),
              ),
              child: AnimatedBuilder(
                animation: clock,
                builder: (context, _) {
                  final t = seconds;
                  final breathe = 1 + math.sin(t * 1.4) * 0.015;
                  return CustomPaint(
                    painter: _WatchingSun(Offset(w / 2, 78), t),
                    foregroundPainter: const FramePainter(),
                    child: Stack(children: [
                      const Positioned.fill(child: FloatingMotes(count: 46)),
                      At(w / 2, 190, child: Transform.scale(scale: breathe, child: ShimmerText('MeetRa', size: 96, phase: t * 0.35))),
                      At(w / 2, 272, child: const OutlinedText('Seven realms · one hundred and forty places to explore', size: 24)),
                      At(w / 2, 308,
                          child: const OutlinedText('A tale from the Book of Kings', size: 17, color: Color(0xff8ae0d8))),
                      At(w / 2, 410,
                          child: Opacity(
                            opacity: 0.55 + 0.45 * (0.5 + 0.5 * math.sin(t * 4.2)),
                            child: Transform.scale(scale: 1 + 0.04 * math.sin(t * 4.2), child: const OutlinedText('Tap to begin', size: 30, color: gold)),
                          )),
                    ]),
                  );
                },
              ),
            ),
          ),
        ),
        At(w - 80, gameH - 80, child: const SoundButton(size: 46)),
      ]),
    );
  }
}

// The sun over the title, its eye wandering about the screen
class _WatchingSun extends CustomPainter {
  _WatchingSun(this.center, this.t);
  final Offset center;
  final double t;

  @override
  void paint(Canvas c, Size size) {
    _Rays(center, t, radius: 560, alpha: 0.12).paint(c, size);
    c.drawCircle(center, 80, Paint()..shader = const RadialGradient(colors: [Color(0x55f7d774), Color(0x00f7d774)]).createShader(Rect.fromCircle(center: center, radius: 80)));
    paintSunDisc(c, center, 1.4);
    final look = Offset(math.sin(t * 0.6) * 0.8, 0.5 + math.cos(t * 0.43) * 0.4);
    paintSunEye(c, center, 1.4, look: look, open: sunBlink(t));
  }

  @override
  bool shouldRepaint(_WatchingSun old) => true;
}

// ---------- Level up ----------

class _Choice {
  const _Choice(this.name, this.desc, this.apply);
  final String name, desc;
  final void Function(GameState s) apply;
}

final _choices = [
  _Choice('Heart', '+1 heart', (s) {
    s.maxHp += 2;
    s.hp += 2;
  }),
  _Choice('Might', '+1 sword damage', (s) => s.attack += 1),
  _Choice('Aura', '+20 Aura\n+1 spell power', (s) {
    s.auraMax += 20;
    s.magic += 1;
  }),
];

class LevelUpPanel extends StatefulWidget {
  const LevelUpPanel(this.game, {super.key, required this.w});
  final MeetRaGame game;
  final double w;

  @override
  State<LevelUpPanel> createState() => _LevelUpPanelState();
}

class _LevelUpPanelState extends State<LevelUpPanel> with SingleTickerProviderStateMixin, _Clock {
  StreamSubscription<LogicalKeyboardKey>? _keys;
  late DateTime _opened;
  int? _pressed;
  double _openedAt = 0;

  @override
  void initState() {
    super.initState();
    _opened = DateTime.now();
    Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      _keys = widget.game.keyDowns.stream.listen((k) {
        final i = [LogicalKeyboardKey.digit1, LogicalKeyboardKey.digit2, LogicalKeyboardKey.digit3].indexOf(k);
        if (i >= 0) _pick(i);
      });
    });
  }

  void _pick(int i) {
    setState(() => _pressed = null);
    _opened = DateTime.now();
    _openedAt = seconds;
    widget.game.chooseLevelUp(_choices[i].apply);
  }

  @override
  void dispose() {
    _keys?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.w;
    return AnimatedBuilder(
      animation: clock,
      builder: (context, _) {
        final t = seconds;
        final since = t - _openedAt;
        final bg = Curves.easeOut.transform((since / 0.3).clamp(0.0, 1.0));
        return Container(
          color: const Color(0xff0d1233).withValues(alpha: 0.78 * bg),
          child: CustomPaint(
            painter: _Rays(Offset(w / 2, 92), t, radius: 360, alpha: 0.18 * bg),
            child: Stack(children: [
              At(w / 2, 90,
                  child: Transform.scale(
                    scale: 0.6 + 0.4 * Curves.elasticOut.transform((since / 0.9).clamp(0.0, 1.0)),
                    child: ShimmerText('LEVEL ${widget.game.state.level}!', size: 50, phase: t * 0.5),
                  )),
              At(w / 2, 142, child: Opacity(opacity: bg, child: const OutlinedText('Choose your strength', size: 22))),
              for (var i = 0; i < 3; i++) _card(i, w / 2 + (i - 1) * 260, 320, t, since),
            ]),
          ),
        );
      },
    );
  }

  Widget _icon(int i, double t) {
    final bob = math.sin(t * 2.5 + i) * 4;
    final Widget icon = switch (i) {
      0 => SheetFrame(widget.game.art.heart, 0, scale: 6),
      1 => const CustomPaint(size: Size.square(64), painter: ButtonIconPainter(ButtonIcon.sword)),
      _ => const CustomPaint(size: Size.square(60), painter: ButtonIconPainter(ButtonIcon.star)),
    };
    return Transform.translate(offset: Offset(0, bob), child: icon);
  }

  Widget _card(int i, double x, double y, double t, double since) {
    final ch = _choices[i];
    final hover = _pressed == i;
    // Cards rise into place one after another
    final k = Curves.easeOutBack.transform(((since - 0.1 - i * 0.09) / 0.45).clamp(0.0, 1.0));
    return Positioned(
      left: x - 115,
      top: y - 120 + 60 * (1 - k),
      child: Opacity(
        opacity: k.clamp(0.0, 1.0),
        child: MouseRegion(
          onEnter: (_) => setState(() => _pressed = i),
          onExit: (_) => setState(() => _pressed = null),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _pressed = i),
            onTapCancel: () => setState(() => _pressed = null),
            // Short delay so the tap that triggered the level-up can't pick a card by accident
            onTapUp: (_) {
              if (DateTime.now().difference(_opened).inMilliseconds > 300) {
                _pick(i);
              } else {
                setState(() => _pressed = null);
              }
            },
            child: AnimatedScale(
              scale: hover ? 1.06 : 1,
              duration: const Duration(milliseconds: 120),
              child: Container(
                width: 230,
                height: 250,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: hover ? const [Color(0xff3a4aa0), Color(0xff1b2a6b)] : const [Color(0xff26357d), Color(0xff141f52)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: hover ? gold : const Color(Palette.gold), width: 3),
                  boxShadow: [
                    BoxShadow(color: (hover ? gold : Colors.black).withValues(alpha: hover ? 0.45 : 0.4), blurRadius: hover ? 24 : 14, offset: const Offset(0, 6)),
                  ],
                ),
                child: Stack(children: [
                  // A soft glow behind the icon
                  Positioned(
                    left: 55,
                    top: 0,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(colors: [gold.withValues(alpha: 0.28 + 0.1 * math.sin(t * 3 + i)), gold.withValues(alpha: 0)]),
                      ),
                    ),
                  ),
                  At(115, 62, child: _icon(i, t)),
                  At(115, 136, child: OutlinedText(ch.name, size: 32)),
                  At(115, 190, child: OutlinedText(ch.desc, size: 19, color: const Color(0xffc8bca0))),
                  At(115, 236, child: OutlinedText('${i + 1}', size: 13, color: const Color(0x88f7d774))),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------- Victory ----------

class VictoryScreen extends StatefulWidget {
  const VictoryScreen(this.game, {super.key, required this.w});
  final MeetRaGame game;
  final double w;

  @override
  State<VictoryScreen> createState() => _VictoryScreenState();
}

class _VictoryScreenState extends State<VictoryScreen> with SingleTickerProviderStateMixin, _Clock {
  StreamSubscription<LogicalKeyboardKey>? _keys;

  @override
  void initState() {
    super.initState();
    _keys = widget.game.keyDowns.stream.listen((k) {
      if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.space) widget.game.leaveLevel();
    });
  }

  @override
  void dispose() {
    _keys?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.w;
    final g = widget.game;
    final s = g.state;
    final loc = g.location;
    final rewards = g.ui.rewards.value;
    return AnimatedBuilder(
      animation: clock,
      builder: (context, _) {
        final t = seconds;
        final fade = Curves.easeOut.transform((t / 0.8).clamp(0.0, 1.0));
        // Lines appear one by one
        double line(int i) => Curves.easeOut.transform(((t - 0.35 - i * 0.18) / 0.4).clamp(0.0, 1.0));
        Widget appear(int i, Widget child) => Opacity(opacity: line(i), child: Transform.translate(offset: Offset(0, 12 * (1 - line(i))), child: child));
        return Opacity(
          opacity: fade,
          child: Container(
            color: const Color(0xff0d1233).withValues(alpha: 0.88),
            child: CustomPaint(
              painter: _Rays(Offset(w / 2, 120), t, radius: 600, alpha: 0.14),
              foregroundPainter: const FramePainter(inner: false),
              child: Stack(children: [
                Positioned.fill(child: CustomPaint(painter: _Confetti(t))),
                At(w / 2, 120,
                    child: Transform.scale(
                      scale: 0.7 + 0.3 * Curves.elasticOut.transform((t / 1.1).clamp(0.0, 1.0)),
                      child: ShimmerText('PLACE CLEARED', size: 52, phase: t * 0.45),
                    )),
                At(w / 2, 185, child: appear(0, OutlinedText(loc?.name ?? g.def.title, size: 28))),
                At(w / 2, 222, child: appear(1, OutlinedText(loc?.realm.name ?? '', size: 18, color: const Color(0xffc8bca0)))),
                for (var i = 0; i < rewards.length; i++)
                  At(w / 2, 272 + i * 32.0, child: appear(2 + i, OutlinedText(rewards[i], size: 22, color: const Color(0xff8ae0d8)))),
                At(w / 2, 272 + rewards.length * 32.0 + 12,
                    child: appear(2 + rewards.length,
                        OutlinedText('Level ${s.level}   ·   ${s.gold} gold', size: 20, color: const Color(0xffc8bca0)))),
                At(w / 2, 450,
                    child: appear(
                      3 + rewards.length,
                      GestureDetector(
                        onTapUp: (_) => g.leaveLevel(),
                        child: Transform.scale(
                          scale: 1 + 0.05 * math.sin(t * 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xff1b2a6b),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: const Color(Palette.gold), width: 2.5),
                              boxShadow: [BoxShadow(color: gold.withValues(alpha: 0.35), blurRadius: 18)],
                            ),
                            child: const OutlinedText('Continue', size: 28, color: gold),
                          ),
                        ),
                      ),
                    )),
              ]),
            ),
          ),
        );
      },
    );
  }
}

// Gold and turquoise flakes tumbling down
class _Confetti extends CustomPainter {
  _Confetti(this.t);
  final double t;

  @override
  void paint(Canvas c, Size size) {
    final r = math.Random(11);
    const colors = [Color(0xfff7d774), Color(0xffd4a845), Color(0xff8ae0d8), Color(0xfff2e6c9), Color(0xffd83a3a)];
    for (var i = 0; i < 70; i++) {
      final x0 = r.nextDouble() * size.width;
      final speed = 40 + r.nextDouble() * 70;
      final delay = r.nextDouble() * 1.5;
      final tt = t - delay;
      if (tt < 0) continue;
      final y = -20 + (tt * speed) % (size.height + 40);
      final x = x0 + math.sin(tt * 2 + i) * 18;
      c.save();
      c.translate(x, y);
      c.rotate(tt * (2 + r.nextDouble() * 3));
      c.scale(math.cos(tt * 4 + i), 1);
      c.drawRect(const Rect.fromLTWH(-4, -2.5, 8, 5), Paint()..color = colors[i % colors.length].withValues(alpha: 0.85));
      c.restore();
    }
  }

  @override
  bool shouldRepaint(_Confetti old) => true;
}
