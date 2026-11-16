// A parchment scroll that tells the saga one page at a time. The game waits underneath until
// the last page is turned.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config.dart';
import '../game/meetra_game.dart';
import '../world/saga.dart';
import 'common.dart';

class StoryView extends StatefulWidget {
  const StoryView(this.game, this.scroll, {super.key, required this.w});
  final MeetRaGame game;
  final StoryScroll scroll;
  final double w;

  @override
  State<StoryView> createState() => _StoryViewState();
}

class _StoryViewState extends State<StoryView> with SingleTickerProviderStateMixin {
  late final AnimationController _anim; // the page fading in; it also drives the pulse of the hint
  StreamSubscription<LogicalKeyboardKey>? _keys;
  int _page = 0;
  bool _armed = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..forward();
    // A tap that opened the scroll (or the end of a fight) must not turn its first page
    Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      _armed = true;
      _keys = widget.game.keyDowns.stream.listen((_) => _next());
    });
  }

  void _next() {
    if (!_armed) return;
    if (_page < widget.scroll.pages.length - 1) {
      setState(() => _page++);
      _anim.forward(from: 0);
      _armed = false;
      Timer(const Duration(milliseconds: 250), () => _armed = true);
    } else {
      _keys?.cancel();
      widget.game.closeStory();
    }
  }

  @override
  void dispose() {
    _keys?.cancel();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.w;
    final s = widget.scroll;
    final p = s.pages[_page];
    final last = _page == s.pages.length - 1;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (_) => _next(),
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          final t = _anim.value * 2.4; // seconds since the page appeared
          final fade = Curves.easeOut.transform((t / 0.35).clamp(0.0, 1.0));
          final hint = ((t - 0.9) / 0.4).clamp(0.0, 1.0) * (0.6 + 0.4 * math.sin(t * 4));
          return Container(
            color: const Color(0xcc0a0e28),
            child: Stack(children: [
              At(
                w / 2,
                gameH / 2,
                child: Container(
                  width: math.min(780, w - 60),
                  height: 360,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xfff8eed6), Color(0xffe3cd9f)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(Palette.gold), width: 3),
                    boxShadow: const [BoxShadow(color: Color(0xaa000000), blurRadius: 24, offset: Offset(0, 8))],
                  ),
                  padding: const EdgeInsets.all(5),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: const Color(Palette.lapis).withValues(alpha: 0.6), width: 1.2),
                    ),
                    padding: const EdgeInsets.fromLTRB(36, 18, 36, 14),
                    child: Column(children: [
                      OutlinedText(s.title, size: 17, color: const Color(Palette.lapis), stroke: false),
                      const SizedBox(height: 6),
                      Container(width: 220, height: 1.5, color: const Color(Palette.gold)),
                      const Spacer(),
                      Opacity(
                        opacity: fade,
                        child: Transform.translate(
                          offset: Offset(0, 8 * (1 - fade)),
                          child: Column(children: [
                            if (p.speaker != narrator) ...[
                              OutlinedText(p.speaker, size: 22, color: const Color(0xff8a4a1a), stroke: false),
                              const SizedBox(height: 10),
                            ],
                            OutlinedText(p.text, size: p.text.length > 200 ? 21 : 23, color: ink, stroke: false, width: math.min(690, w - 150)),
                          ]),
                        ),
                      ),
                      const Spacer(),
                      Row(children: [
                        OutlinedText('${_page + 1} / ${s.pages.length}', size: 14, color: const Color(0xff8a7a60), stroke: false),
                        const Spacer(),
                        Opacity(
                          opacity: hint,
                          child: OutlinedText(last ? 'Tap to close' : 'Tap to continue', size: 16, color: const Color(0xff8a4a1a), stroke: false),
                        ),
                      ]),
                    ]),
                  ),
                ),
              ),
              // Gold clasps on the scroll's edges
              for (final dx in [-1.0, 1.0])
                At(w / 2 + dx * math.min(390, w / 2 - 30), gameH / 2,
                    child: Transform.rotate(angle: math.pi / 4, child: Container(width: 14, height: 14, color: const Color(Palette.gold)))),
            ]),
          );
        },
      ),
    );
  }
}
