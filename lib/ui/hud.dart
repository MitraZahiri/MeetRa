import 'package:flutter/material.dart';

import '../config.dart';
import '../game/meetra_game.dart';
import 'common.dart';

// Hearts, aura, gold, level and XP
class Hud extends StatelessWidget {
  const Hud(this.game, {super.key, required this.w});

  final MeetRaGame game;
  final double w;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: game.state,
      builder: (context, _) {
        final s = game.state;
        final nHearts = (s.maxHp / 2).ceil();
        return Stack(children: [
          for (var i = 0; i < nHearts; i++)
            At(30 + i * 32.0, 30, child: SheetFrame(game.art.heart, _heartFrame(s.hp - i * 2), scale: 3)),
          At(w - 28, 28, child: SheetFrame(game.art.coin, 0, scale: 4)),
          At(w - 48, 28, ax: 1, child: OutlinedText('${s.gold}', size: 24, color: gold)),
          At(w - 24, 58, ax: 1, child: OutlinedText('Lv ${s.level}', size: 18)),
          Positioned.fill(child: CustomPaint(painter: _Bars(s, w))),
          if (s.hasFeather) At(24, 62, ax: 0, child: const OutlinedText('AURA', size: 13, color: gold)),
        ]);
      },
    );
  }

  int _heartFrame(int v) => v >= 2 ? 0 : (v == 1 ? 1 : 2);
}

class _Bars extends CustomPainter {
  _Bars(this.s, this.w) : xp = s.xp, aura = s.aura, auraMax = s.auraMax, hasFeather = s.hasFeather;
  final GameState s;
  final double w;
  final int xp, auraMax;
  final double aura;
  final bool hasFeather;

  @override
  void paint(Canvas c, Size size) {
    final back = Paint()..color = const Color(Palette.ink).withValues(alpha: 0.8);
    // XP bar
    const xpW = 140.0;
    c.drawRect(Rect.fromLTWH(w - 24 - xpW, 74, xpW, 7), back);
    c.drawRect(Rect.fromLTWH(w - 24 - xpW, 74, xpW * (s.xp / s.xpNext), 7), Paint()..color = const Color(0xff8ae0d8));
    // Aura bar: only shown once a spell is earned
    if (hasFeather) {
      final bw = auraMax * 2.0;
      c.drawRect(Rect.fromLTWH(70, 56, bw + 4, 12), back);
      c.drawRect(Rect.fromLTWH(72, 58, bw * (aura / auraMax), 8), Paint()..color = const Color(Palette.gold));
      c.drawRect(
          Rect.fromLTWH(70, 56, bw + 4, 12),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = gold);
    }
  }

  @override
  bool shouldRepaint(_Bars old) => true;
}

// Signpost text box
class SignBox extends StatefulWidget {
  const SignBox(this.game, {super.key, required this.w});
  final MeetRaGame game;
  final double w;

  @override
  State<SignBox> createState() => _SignBoxState();
}

class _SignBoxState extends State<SignBox> with SingleTickerProviderStateMixin {
  late final _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 160));
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
    return At(
      widget.w / 2,
      110,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, child) => Opacity(
          opacity: _anim.value,
          child: Transform.scale(scale: 0.9 + 0.1 * _anim.value, child: child),
        ),
        child: Container(
          width: 640,
          height: 96,
          decoration: BoxDecoration(
            color: parch.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(Palette.gold), width: 3),
          ),
          padding: const EdgeInsets.all(4),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(Palette.lapis), width: 1),
            ),
            alignment: Alignment.center,
            child: OutlinedText(t, size: 21, color: ink, stroke: false, width: 600),
          ),
        ),
      ),
    );
  }
}

// Big centred title that pops in, holds, then fades out
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
        final scale = 0.8 + 0.2 * Curves.easeOutBack.transform(inT);
        return Stack(children: [
          At(widget.w / 2, 200,
              child: Opacity(
                opacity: inT * fadeOut,
                child: Transform.scale(scale: scale, child: OutlinedText(m.title, size: 40, color: gold)),
              )),
          At(widget.w / 2, 242, child: Opacity(opacity: subIn * fadeOut, child: OutlinedText(m.sub, size: 20))),
        ]);
      },
    );
  }
}

// Boss name and health bar (at the top, so thumbs never cover it)
class BossBar extends StatelessWidget {
  const BossBar(this.game, {super.key, required this.w});
  final MeetRaGame game;
  final double w;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
        valueListenable: game.ui.boss,
        builder: (context, boss, _) {
          if (boss == null) return const SizedBox.shrink();
          return Stack(children: [
            At(w / 2, 72, child: OutlinedText('${boss.name} · ${boss.title}', size: 20, color: gold)),
            Positioned(
              left: w / 2 - 193,
              top: 89,
              child: ValueListenableBuilder(
                valueListenable: game.ui.bossFrac,
                builder: (context, frac, _) => CustomPaint(size: const Size(386, 16), painter: _BossBarPainter(frac)),
              ),
            ),
          ]);
        },
      );
}

class _BossBarPainter extends CustomPainter {
  _BossBarPainter(this.frac);
  final double frac;

  @override
  void paint(Canvas c, Size size) {
    c.drawRect(Offset.zero & size, Paint()..color = const Color(Palette.ink).withValues(alpha: 0.85));
    c.drawRect(Rect.fromLTWH(3, 3, 380 * frac, 10), Paint()..color = const Color(Palette.red));
    c.drawRect(
        Offset.zero & size,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(Palette.gold));
  }

  @override
  bool shouldRepaint(_BossBarPainter old) => old.frac != frac;
}
