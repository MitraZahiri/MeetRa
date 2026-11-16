// The Book of Verses: every legend Ra has pieced together from the Verse Stones, realm by realm.
// Verses not yet found show only where to look, once that place is known.

import 'package:flutter/material.dart';

import '../config.dart';
import '../game/meetra_game.dart';
import '../world/saga.dart';
import '../world/world.dart';
import 'common.dart';

const _brown = Color(0xff8a4a1a);
const _faded = Color(0xff9a8a6a);

class BookScreen extends StatefulWidget {
  const BookScreen(this.game, {super.key, required this.w, required this.realm});
  final MeetRaGame game;
  final double w;
  final int realm; // the page it opens on

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  late int _realm = widget.realm;

  // A realm's page can be opened once Ra can travel there, or once one of its verses is found
  bool _known(Realm r) => realmUnlocked(r, widget.game.progress) || widget.game.progress.versesIn(r) > 0;

  @override
  Widget build(BuildContext context) {
    final g = widget.game;
    final w = widget.w;
    final p = g.progress;
    final r = realms[_realm];
    final c = chapterOf(r);
    final stops = [for (final i in verseStops) r.locations[i]];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Container(
        decoration: const BoxDecoration(gradient: RadialGradient(radius: 1.1, colors: [Color(0xfff6ecd6), Color(0xffdcc79c)])),
        child: CustomPaint(
          foregroundPainter: const FramePainter(inner: false),
          child: Stack(
            children: [
              At(w / 2, 34, child: const OutlinedText('The Book of Verses', size: 30, color: Color(Palette.lapis), stroke: false)),
              At(w - 40, 36, ax: 1, child: OutlinedText('${p.verseCount} / ${realms.length * 7} verses', size: 17, color: _brown, stroke: false)),
              At(40, 36, ax: 0, child: _button('‹  Back', () => g.ui.book.value = null)),
              // The realms down the left side
              Positioned(
                left: 40,
                top: 80,
                width: 210,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final rr in realms)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _known(rr) ? () => setState(() => _realm = rr.index) : null,
                        child: Container(
                          width: 210,
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: rr.index == _realm ? const Color(Palette.lapis) : const Color(0x22000000),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(Palette.gold), width: rr.index == _realm ? 2 : 1),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _known(rr) ? rr.name : '· · ·',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: fontFamily,
                                    fontSize: 15,
                                    decoration: TextDecoration.none,
                                    color: rr.index == _realm ? gold : (_known(rr) ? ink : _faded),
                                  ),
                                ),
                              ),
                              Text(
                                '${p.versesIn(rr)}/7',
                                style: TextStyle(
                                  fontFamily: fontFamily,
                                  fontSize: 13,
                                  decoration: TextDecoration.none,
                                  color: rr.index == _realm ? parch : (p.versesIn(rr) == 7 ? const Color(Palette.turquoise) : _faded),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // The legend of the chosen realm
              Positioned(
                left: 280,
                right: 40,
                top: 76,
                bottom: 26,
                // Shrinks to fit when a whole legend is found on a narrow phone
                child: LayoutBuilder(
                  builder:
                      (context, box) => FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.topLeft,
                        child: SizedBox(
                          width: box.maxWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.legend, style: const TextStyle(fontFamily: fontFamily, fontSize: 22, color: _brown, decoration: TextDecoration.none)),
                              const SizedBox(height: 8),
                              for (var i = 0; i < 7; i++)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 7),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 34,
                                        child: Text(
                                          numerals[i],
                                          style: const TextStyle(
                                            fontFamily: fontFamily,
                                            fontSize: 15,
                                            color: Color(Palette.lapis),
                                            decoration: TextDecoration.none,
                                          ),
                                        ),
                                      ),
                                      Expanded(child: _verse(c.verses[i], stops[i])),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _verse(String text, Location at) {
    final p = widget.game.progress;
    if (p.hasVerse(at)) {
      return Text(text, style: const TextStyle(fontFamily: fontFamily, fontSize: 15, height: 1.25, color: ink, decoration: TextDecoration.none));
    }
    // Where to look, once Ra has heard of the place
    final known = p.isCleared(at) || at.links.any(p.isCleared);
    return Text(
      known ? '· · ·   still waiting somewhere on ${at.name}' : '· · ·',
      style: const TextStyle(fontFamily: fontFamily, fontSize: 15, fontStyle: FontStyle.italic, color: _faded, decoration: TextDecoration.none),
    );
  }

  Widget _button(String text, VoidCallback onTap) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(Palette.lapis),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(Palette.gold), width: 2),
      ),
      child: OutlinedText(text, size: 16, color: gold),
    ),
  );
}
