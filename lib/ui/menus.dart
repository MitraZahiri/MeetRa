import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config.dart';
import '../game/meetra_game.dart';
import 'common.dart';

// ---------- Title screen ----------

class TitleScreen extends StatefulWidget {
  const TitleScreen(this.game, {super.key, required this.w});
  final MeetRaGame game;
  final double w;

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..repeat(reverse: true);
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
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.w;
    return AnimatedOpacity(
      opacity: _leaving ? 0 : 1,
      duration: const Duration(milliseconds: 400),
      onEnd: () => widget.game.ui.title.value = false,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (_) => _start(),
        child: Container(
          color: const Color(0xff0d1233).withValues(alpha: 0.82),
          child: CustomPaint(
            painter: const FramePainter(),
            child: Stack(children: [
              At(w / 2, 190, child: const OutlinedText('MeetRa', size: 96, color: gold)),
              At(w / 2, 270, child: const OutlinedText('Seven realms · one hundred and forty places to explore', size: 24)),
              At(w / 2, 400,
                  child: FadeTransition(
                    opacity: Tween(begin: 1.0, end: 0.3).animate(_pulse),
                    child: const OutlinedText('Tap to begin', size: 30, color: gold),
                  )),
            ]),
          ),
        ),
      ),
    );
  }
}

// ---------- Level up ----------

class _Choice {
  const _Choice(this.icon, this.name, this.desc, this.apply);
  final String icon, name, desc;
  final void Function(GameState s) apply;
}

final _choices = [
  _Choice('♥', 'Heart', '+1 heart', (s) {
    s.maxHp += 2;
    s.hp += 2;
  }),
  _Choice('⚔', 'Might', '+1 sword damage', (s) => s.attack += 1),
  _Choice('✦', 'Aura', '+20 Aura\n+1 spell power', (s) {
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

class _LevelUpPanelState extends State<LevelUpPanel> {
  StreamSubscription<LogicalKeyboardKey>? _keys;
  late DateTime _opened;
  int? _pressed;

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
    return Container(
      color: const Color(0xff0d1233).withValues(alpha: 0.75),
      child: Stack(children: [
        At(w / 2, 90, child: OutlinedText('LEVEL ${widget.game.state.level}!', size: 48, color: gold)),
        At(w / 2, 140, child: const OutlinedText('Choose your strength', size: 22)),
        for (var i = 0; i < 3; i++) _card(i, w / 2 + (i - 1) * 260, 320),
      ]),
    );
  }

  Widget _card(int i, double x, double y) {
    final ch = _choices[i];
    final hover = _pressed == i;
    return Positioned(
      left: x - 115,
      top: y - 120,
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
          child: Container(
            width: 230,
            height: 250,
            decoration: BoxDecoration(
              color: Color(hover ? 0xff2a3a8b : Palette.lapis),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: hover ? gold : const Color(Palette.gold), width: 3),
            ),
            child: Stack(children: [
              At(115, 60, child: OutlinedText(ch.icon, size: 56, color: gold)),
              At(115, 130, child: OutlinedText(ch.name, size: 32)),
              At(115, 186, child: OutlinedText(ch.desc, size: 19, color: const Color(0xffc8bca0))),
            ]),
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

class _VictoryScreenState extends State<VictoryScreen> {
  StreamSubscription<LogicalKeyboardKey>? _keys;
  double _opacity = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? setState(() => _opacity = 1) : null);
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
    return AnimatedOpacity(
      opacity: _opacity,
      duration: const Duration(milliseconds: 800),
      child: Container(
        color: const Color(0xff0d1233).withValues(alpha: 0.88),
        child: CustomPaint(
          painter: const FramePainter(inner: false),
          child: Stack(children: [
            At(w / 2, 120, child: const OutlinedText('PLACE CLEARED', size: 52, color: gold)),
            At(w / 2, 185, child: OutlinedText(loc?.name ?? g.def.title, size: 28)),
            At(w / 2, 222, child: OutlinedText(loc?.realm.name ?? '', size: 18, color: const Color(0xffc8bca0))),
            for (var i = 0; i < rewards.length; i++)
              At(w / 2, 272 + i * 32.0, child: OutlinedText(rewards[i], size: 22, color: const Color(0xff8ae0d8))),
            At(w / 2, 272 + rewards.length * 32.0 + 12,
                child: OutlinedText('Level ${s.level}   ·   ${s.gold} gold', size: 20, color: const Color(0xffc8bca0))),
            At(w / 2, 450,
                child: GestureDetector(
                  onTapUp: (_) => g.leaveLevel(),
                  child: const OutlinedText('[ Continue ]', size: 30, color: gold),
                )),
          ]),
        ),
      ),
    );
  }
}
