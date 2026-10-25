// The world map (seven realms) and the realm map (twenty locations each).

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config.dart';
import '../game/meetra_game.dart';
import '../world/world.dart';
import 'common.dart';

const _lapis = Color(Palette.lapis);
const _goldDark = Color(Palette.gold);
const _turq = Color(Palette.turquoise);
const _inkBrown = Color(0xff3b2a1a);

Paint _fill(Color c) => Paint()..color = c;
Paint _stroke(Color c, double w) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeJoin = StrokeJoin.round
  ..strokeCap = StrokeCap.round;

void _parchment(Canvas c, Rect r, {bool dark = false}) {
  final colors = dark ? const [Color(0xff2c2a3a), Color(0xff14121c)] : const [Color(0xfff6ecd2), Color(0xffd6bd8a)];
  c.drawRect(r, Paint()..shader = RadialGradient(colors: colors, radius: 0.9).createShader(r));
}

void _label(Canvas c, String text, Offset at, {double size = 15, Color color = _inkBrown, bool bold = true, double? maxW}) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: fontFamily,
        fontSize: size,
        color: color,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        shadows: const [Shadow(color: Color(0xccf6ecd2), blurRadius: 3)],
      ),
    ),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: maxW ?? 220);
  tp.paint(c, at - Offset(tp.width / 2, 0));
}

// ---------- Shared bits ----------

class _TextButton extends StatelessWidget {
  const _TextButton(this.text, this.onTap, {this.size = 22});
  final String text;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: _lapis,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _goldDark, width: 2),
          ),
          child: OutlinedText(text, size: size, color: gold),
        ),
      );
}

// ============================================================
// World map
// ============================================================

class WorldMapScreen extends StatefulWidget {
  const WorldMapScreen(this.game, {super.key, required this.w});
  final MeetRaGame game;
  final double w;

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  String? _hint;
  bool _confirmWipe = false;

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Rect get _area => Rect.fromLTRB(40, 70, widget.w - 40, 470);
  Offset _pos(Realm r) => Offset(_area.left + r.mapX * _area.width, _area.top + r.mapY * _area.height);

  void _tap(Offset p) {
    final g = widget.game;
    for (final r in realms) {
      if ((p - _pos(r)).distance > 52) continue;
      if (realmUnlocked(r, g.progress)) {
        g.openRealm(r);
      } else {
        setState(() => _hint = r.hidden
            ? 'Something is hidden in the far north. Find all six Dawn Sigils.'
            : 'Free ${realms[r.index - 1].name} first: defeat ${realms[r.index - 1].bossName}.');
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.game;
    final w = widget.w;
    return ListenableBuilder(
      listenable: g.progress,
      builder: (context, _) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => _tap(d.localPosition),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: _WorldPainter(g, _area, _pulse))),
          At(w / 2, 36, child: const OutlinedText('The Realm of the Dawnfire', size: 32, color: gold)),
          At(w - 30, 36, ax: 1, child: OutlinedText('Dawn Sigils  ${sigilCount(g.progress)} / 6', size: 18, color: const Color(0xff8ae0d8))),
          At(30, 36, ax: 0, child: OutlinedText('Lv ${g.state.level}  ·  ${g.state.gold} gold', size: 18)),
          At(w / 2, 505,
              child: OutlinedText(_hint ?? 'Choose a realm. Free each realm to open the next.', size: 18, color: const Color(0xfff2e6c9))),
          At(w - 24, 512,
              ax: 1,
              child: GestureDetector(
                onTap: () {
                  if (_confirmWipe) {
                    g.newGame();
                    setState(() {
                      _confirmWipe = false;
                      _hint = 'A new saga begins.';
                    });
                  } else {
                    setState(() => _confirmWipe = true);
                  }
                },
                child: OutlinedText(_confirmWipe ? 'Tap again to erase your save' : 'New game', size: 14, color: const Color(0xffc8bca0)),
              )),
        ]),
      ),
    );
  }
}

class _WorldPainter extends CustomPainter {
  _WorldPainter(this.game, this.area, this.pulse) : super(repaint: pulse);
  final MeetRaGame game;
  final Rect area;
  final Animation<double> pulse;

  Offset _p(double x, double y) => Offset(area.left + x * area.width, area.top + y * area.height);

  @override
  void paint(Canvas c, Size size) {
    c.drawRect(Offset.zero & size, _fill(const Color(0xff0d1233)));
    _parchment(c, area);
    // Seas
    final sea = _fill(const Color(0xff9cc3c0));
    final coast = _stroke(_inkBrown, 2);
    final inner = Path()..addOval(Rect.fromCenter(center: _p(0.52, 0.1), width: area.width * 0.16, height: area.height * 0.22));
    final west = Path()
      ..moveTo(area.left, area.top + area.height * 0.18)
      ..quadraticBezierTo(_p(0.2, 0.2).dx, _p(0.2, 0.2).dy, _p(0.22, 0.4).dx, _p(0.22, 0.4).dy)
      ..quadraticBezierTo(_p(0.2, 0.58).dx, _p(0.2, 0.58).dy, area.left, area.top + area.height * 0.62)
      ..close();
    final south = Path()
      ..moveTo(area.left, area.bottom)
      ..lineTo(area.left, area.top + area.height * 0.92)
      ..quadraticBezierTo(_p(0.3, 0.86).dx, _p(0.3, 0.86).dy, _p(0.46, 0.8).dx, _p(0.46, 0.8).dy)
      ..quadraticBezierTo(_p(0.6, 0.97).dx, _p(0.6, 0.97).dy, _p(0.85, 0.9).dx, _p(0.85, 0.9).dy)
      ..lineTo(area.right, area.top + area.height * 0.88)
      ..lineTo(area.right, area.bottom)
      ..close();
    for (final s in [inner, west, south]) {
      c.drawPath(s, sea);
      c.drawPath(s, coast);
    }
    // Fog over the far north
    c.drawCircle(_p(0.3, 0.08), area.height * 0.22,
        Paint()..shader = RadialGradient(colors: [const Color(0x884a4658), const Color(0x004a4658)]).createShader(Rect.fromCircle(center: _p(0.3, 0.08), radius: area.height * 0.22)));
    c.drawRect(area, _stroke(_goldDark, 3));

    final prog = game.progress;
    // Route between realms, in unlock order
    for (var i = 0; i < 5; i++) {
      final a = realms[i], b = realms[i + 1];
      final open = realmUnlocked(b, prog);
      final p = _stroke(open ? const Color(Palette.red) : const Color(0x88553a20), 3);
      _dashed(c, _p(a.mapX, a.mapY), _p(b.mapX, b.mapY), p, dash: open ? 14 : 6);
    }

    final t = pulse.value;
    for (final r in realms) {
      final unlocked = realmUnlocked(r, prog);
      if (r.hidden && !unlocked) {
        final at = _p(r.mapX, r.mapY);
        c.drawCircle(at, 34, _fill(const Color(0x664a4658)));
        c.drawCircle(at, 34, _stroke(const Color(0x88f2e6c9), 1.5));
        _label(c, '?', at - const Offset(0, 18), size: 30, color: const Color(0xfff2e6c9));
        continue;
      }
      final at = _p(r.mapX, r.mapY);
      final cleared = prog.isCleared(r.boss);
      final color = unlocked ? Color(r.color) : const Color(0xff9a9080);
      if (unlocked && !cleared) {
        c.drawCircle(at, 44 + 8 * t, _stroke(gold.withValues(alpha: 1 - t), 3));
      }
      c.drawCircle(at, 42, _fill(color));
      c.drawCircle(at, 42, _stroke(unlocked ? _goldDark : const Color(0xff6a6050), 4));
      c.drawCircle(at, 34, _stroke(const Color(0x99f6ecd2), 1.2));
      _label(c, '${r.index + 1}', at - const Offset(0, 22), size: 30, color: unlocked ? const Color(0xfffbf3df) : const Color(0xffe8e0d0));
      _label(c, r.name, at + const Offset(0, 46), size: 16);
      _label(c, unlocked ? '${clearedIn(r, prog)} / 20${cleared ? '  ✓' : ''}' : 'locked', at + const Offset(0, 66), size: 13, bold: false);
    }
  }

  void _dashed(Canvas c, Offset a, Offset b, Paint p, {double dash = 10}) {
    final d = (b - a).distance;
    final dir = (b - a) / d;
    for (var s = 0.0; s < d; s += dash * 1.8) {
      c.drawLine(a + dir * s, a + dir * math.min(d, s + dash), p);
    }
  }

  @override
  bool shouldRepaint(_WorldPainter old) => true;
}

// ============================================================
// Realm map
// ============================================================

class RealmMapScreen extends StatefulWidget {
  const RealmMapScreen(this.game, {super.key, required this.w});
  final MeetRaGame game;
  final double w;

  @override
  State<RealmMapScreen> createState() => _RealmMapScreenState();
}

class _RealmMapScreenState extends State<RealmMapScreen> with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  Location? _selected;
  List<String> _message = const [];

  Realm get realm => realms[widget.game.ui.realm.value];
  Rect get _area => Rect.fromLTRB(50, 78, widget.w - 50, 392);
  Offset _pos(Location l) => Offset(_area.left + l.x * _area.width, _area.top + l.y * _area.height);

  @override
  void initState() {
    super.initState();
    final last = widget.game.progress.lastLocation;
    _selected = realm.locations.where((l) => l.id == last).firstOrNull;
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  bool _visible(Location l) {
    final g = widget.game;
    return l.kind != LocKind.secret || g.progress.isCleared(l) || isOpen(l, g.progress, g.state);
  }

  void _tap(Offset p) {
    Location? best;
    var bestD = 34.0;
    for (final l in realm.locations) {
      if (!_visible(l)) continue;
      final d = (p - _pos(l)).distance;
      if (d < bestD) {
        bestD = d;
        best = l;
      }
    }
    if (best != null) {
      setState(() {
        _selected = best;
        _message = const [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.game;
    final w = widget.w;
    final r = realm;
    return ListenableBuilder(
      listenable: g.progress,
      builder: (context, _) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => _tap(d.localPosition),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: _RealmPainter(g, r, _area, _pulse, _selected, _visible))),
          At(w / 2, 32, child: OutlinedText(r.name, size: 30, color: gold)),
          At(w / 2, 60, child: OutlinedText(r.tagline, size: 15, color: const Color(0xffc8bca0))),
          At(w - 30, 36, ax: 1, child: OutlinedText('${clearedIn(r, g.progress)} / 20 explored', size: 18, color: const Color(0xff8ae0d8))),
          At(30, 36, ax: 0, child: _TextButton('◀ World', g.openWorld, size: 16)),
          Positioned(left: 0, right: 0, top: 404, bottom: 0, child: _panel(g, w)),
        ]),
      ),
    );
  }

  Widget _panel(MeetRaGame g, double w) {
    final l = _selected;
    if (l == null) {
      return const Center(child: OutlinedText('Tap a glowing place on the map.', size: 20));
    }
    final cleared = g.progress.isCleared(l);
    final open = isOpen(l, g.progress, g.state);
    final status = cleared ? 'Cleared' : (open ? 'Open' : (l.needsFeather && !g.state.hasFeather ? "Sealed: needs Saena's Feather" : 'Locked: clear a neighbouring place first'));
    final statusColor = cleared ? const Color(0xff8ae0d8) : (open ? gold : const Color(0xffc8bca0));
    final action = !open && !cleared
        ? null
        : l.kind.playable
            ? (cleared ? 'Replay' : 'Enter')
            : 'Rest';
    return Container(
      margin: const EdgeInsets.fromLTRB(40, 0, 40, 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: _lapis.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _goldDark, width: 3),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Row(children: [
              OutlinedText(l.name, size: 24, color: gold),
              const SizedBox(width: 12),
              OutlinedText('${l.kind.label}  ·  $status', size: 15, color: statusColor),
            ]),
            const SizedBox(height: 6),
            Text(
              _message.isNotEmpty ? _message.join('  ') : l.desc,
              style: const TextStyle(fontFamily: fontFamily, fontSize: 17, color: parch, decoration: TextDecoration.none),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ]),
        ),
        if (action != null)
          _TextButton(action, () {
            if (l.kind.playable) {
              g.enterLocation(l);
            } else {
              setState(() => _message = g.visit(l));
            }
          }),
      ]),
    );
  }
}

class _RealmPainter extends CustomPainter {
  _RealmPainter(this.game, this.realm, this.area, this.pulse, this.selected, this.visible) : super(repaint: pulse);
  final MeetRaGame game;
  final Realm realm;
  final Rect area;
  final Animation<double> pulse;
  final Location? selected;
  final bool Function(Location) visible;

  Offset _pos(Location l) => Offset(area.left + l.x * area.width, area.top + l.y * area.height);

  @override
  void paint(Canvas c, Size size) {
    final dark = realm.theme == RealmTheme.dark;
    c.drawRect(Offset.zero & size, _fill(const Color(0xff0d1233)));
    final mapRect = area.inflate(30);
    _parchment(c, mapRect, dark: dark);
    c.drawRect(mapRect, _fill(Color(realm.color).withValues(alpha: 0.12)));
    _decorate(c, mapRect);
    c.drawRect(mapRect, _stroke(_goldDark, 3));
    c.drawRect(mapRect.deflate(6), _stroke(_lapis, 1));

    final prog = game.progress;
    final s = game.state;
    final locs = realm.locations;

    // Roads
    for (final a in locs) {
      for (final b in a.links) {
        if (b.index < a.index || !visible(a) || !visible(b)) continue;
        final done = prog.isCleared(a) && prog.isCleared(b);
        final reachable = prog.isCleared(a) || prog.isCleared(b);
        final pa = _pos(a), pb = _pos(b);
        final mid = Offset((pa.dx + pb.dx) / 2, (pa.dy + pb.dy) / 2 - 10);
        final path = Path()
          ..moveTo(pa.dx, pa.dy)
          ..quadraticBezierTo(mid.dx, mid.dy, pb.dx, pb.dy);
        if (done) {
          c.drawPath(path, _stroke(_goldDark, 4));
        } else {
          _dashedPath(c, path, _stroke(reachable ? const Color(Palette.red) : (dark ? const Color(0x66f2e6c9) : const Color(0x66553a20)), 2.5));
        }
      }
    }

    // Locations
    final t = pulse.value;
    for (final l in locs) {
      if (!visible(l)) continue;
      final p = _pos(l);
      final cleared = prog.isCleared(l);
      final open = isOpen(l, prog, s);
      final big = l.kind == LocKind.boss || l.kind == LocKind.town;
      final r = big ? 22.0 : 17.0;
      if (open && !cleared) c.drawCircle(p, r + 3 + 8 * t, _stroke(gold.withValues(alpha: 1 - t), 3));
      if (l == selected) c.drawCircle(p, r + 6, _stroke(const Color(0xffffffff), 2.5));
      final fill = cleared
          ? _turq
          : open
              ? const Color(0xfffbf3df)
              : (dark ? const Color(0xff3a3848) : const Color(0xffcfc3a6));
      c.drawCircle(p, r, _fill(fill));
      c.drawCircle(p, r, _stroke(cleared || open ? _goldDark : const Color(0xff8a7a60), l.kind == LocKind.boss ? 3.5 : 2.5));
      _icon(c, l.kind, p, r * 0.55, cleared ? const Color(0xfffbf3df) : (open ? _lapis : const Color(0xff8a7a60)));
      if (open || cleared) {
        _label(c, l.name, p + Offset(0, r + 3), size: 12.5, color: dark ? const Color(0xfff2e6c9) : _inkBrown, maxW: 130);
      }
    }

    // Ra's marker
    final here = locs.where((l) => l.id == prog.lastLocation).firstOrNull ?? locs.first;
    final hp = _pos(here);
    final sheet = game.art.hero;
    final bob = math.sin(t * math.pi * 2) * 2;
    const scale = 2.2;
    final dst = Rect.fromLTWH(hp.dx - sheet.frameW * scale / 2, hp.dy - 30 - sheet.frameH * scale + bob, sheet.frameW * scale, sheet.frameH * scale);
    c.drawImageRect(sheet.image, sheet.src(0), dst, Paint()..filterQuality = FilterQuality.none);
  }

  void _dashedPath(Canvas c, Path path, Paint p) {
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 14) {
        c.drawPath(m.extractPath(d, math.min(m.length, d + 8)), p);
      }
    }
  }

  // A few theme motifs scattered on the map, kept away from the locations
  void _decorate(Canvas c, Rect r) {
    final rnd = math.Random(realm.index * 97 + 13);
    final nodes = realm.locations.map(_pos).toList();
    for (var i = 0; i < 70; i++) {
      final p = Offset(r.left + 14 + rnd.nextDouble() * (r.width - 28), r.top + 14 + rnd.nextDouble() * (r.height - 28));
      if (nodes.any((n) => (n - p).distance < 42)) continue;
      final s = 0.7 + rnd.nextDouble() * 0.6;
      switch (realm.theme) {
        case RealmTheme.vale:
          _cypress(c, p, s);
        case RealmTheme.city:
          rnd.nextBool() ? _arch(c, p, s) : _cypress(c, p, s * 0.8);
        case RealmTheme.desert:
          c.drawArc(Rect.fromCenter(center: p, width: 30 * s, height: 14 * s), math.pi, math.pi, false, _stroke(const Color(0x99a0783c), 1.6));
        case RealmTheme.mountain:
          _peak(c, p, s, snow: true);
        case RealmTheme.steppe:
          for (var k = -1; k <= 1; k++) {
            c.drawLine(p, p + Offset(k * 5.0 * s, -10 * s), _stroke(const Color(0x997a6a3a), 1.4));
          }
        case RealmTheme.coast:
          final w = Path()
            ..moveTo(p.dx - 12 * s, p.dy)
            ..quadraticBezierTo(p.dx - 6 * s, p.dy - 6 * s, p.dx, p.dy)
            ..quadraticBezierTo(p.dx + 6 * s, p.dy + 6 * s, p.dx + 12 * s, p.dy);
          c.drawPath(w, _stroke(const Color(0x995f908d), 1.6));
        case RealmTheme.dark:
          c.drawCircle(p, 1.2 * s, _fill(Color.fromRGBO(242, 230, 201, 0.3 + rnd.nextDouble() * 0.5)));
      }
    }
  }

  void _cypress(Canvas c, Offset p, double s) {
    final path = Path()
      ..moveTo(p.dx, p.dy - 22 * s)
      ..quadraticBezierTo(p.dx + 8 * s, p.dy - 8 * s, p.dx, p.dy)
      ..quadraticBezierTo(p.dx - 8 * s, p.dy - 8 * s, p.dx, p.dy - 22 * s);
    c.drawPath(path, _fill(const Color(0xaa3e6b4a)));
  }

  void _arch(Canvas c, Offset p, double s) {
    final rect = Rect.fromCenter(center: p, width: 16 * s, height: 18 * s);
    c.drawRect(rect, _fill(const Color(0x881b2a6b)));
    c.drawOval(Rect.fromCenter(center: rect.topCenter, width: 16 * s, height: 12 * s), _fill(const Color(0x88d4a845)));
  }

  void _peak(Canvas c, Offset p, double s, {bool snow = false}) {
    final m = Path()
      ..moveTo(p.dx - 16 * s, p.dy)
      ..lineTo(p.dx, p.dy - 20 * s)
      ..lineTo(p.dx + 16 * s, p.dy)
      ..close();
    c.drawPath(m, _fill(const Color(0x99b4935c)));
    if (snow) {
      final cap = Path()
        ..moveTo(p.dx - 5 * s, p.dy - 14 * s)
        ..lineTo(p.dx, p.dy - 20 * s)
        ..lineTo(p.dx + 5 * s, p.dy - 14 * s)
        ..close();
      c.drawPath(cap, _fill(const Color(0xccfbf7ee)));
    }
  }

  // Small symbol for each kind of place
  void _icon(Canvas c, LocKind k, Offset p, double s, Color col) {
    final f = _fill(col);
    final st = _stroke(col, 2);
    switch (k) {
      case LocKind.town:
        final h = Path()
          ..moveTo(p.dx - s, p.dy + s * 0.8)
          ..lineTo(p.dx - s, p.dy - s * 0.1)
          ..lineTo(p.dx, p.dy - s)
          ..lineTo(p.dx + s, p.dy - s * 0.1)
          ..lineTo(p.dx + s, p.dy + s * 0.8)
          ..close();
        c.drawPath(h, f);
      case LocKind.hearth:
        final fl = Path()
          ..moveTo(p.dx, p.dy - s)
          ..quadraticBezierTo(p.dx + s, p.dy, p.dx, p.dy + s)
          ..quadraticBezierTo(p.dx - s, p.dy, p.dx, p.dy - s);
        c.drawPath(fl, _fill(col == _lapis ? const Color(Palette.red) : col));
      case LocKind.trail:
        c.drawCircle(p, s * 0.45, f);
      case LocKind.cave:
        c.drawArc(Rect.fromCenter(center: p + Offset(0, s * 0.5), width: s * 2, height: s * 2.4), math.pi, math.pi, true, f);
      case LocKind.shrine:
        final d = Path()
          ..moveTo(p.dx, p.dy - s)
          ..lineTo(p.dx + s * 0.7, p.dy)
          ..lineTo(p.dx, p.dy + s)
          ..lineTo(p.dx - s * 0.7, p.dy)
          ..close();
        c.drawPath(d, f);
      case LocKind.ruin:
        c.drawRect(Rect.fromLTRB(p.dx - s * 0.8, p.dy - s * 0.3, p.dx - s * 0.3, p.dy + s * 0.8), f);
        c.drawRect(Rect.fromLTRB(p.dx + s * 0.3, p.dy - s * 0.9, p.dx + s * 0.8, p.dy + s * 0.8), f);
      case LocKind.arena:
        c.drawLine(p + Offset(-s, -s), p + Offset(s, s), st);
        c.drawLine(p + Offset(s, -s), p + Offset(-s, s), st);
      case LocKind.boss:
        final cr = Path()
          ..moveTo(p.dx - s, p.dy + s * 0.6)
          ..lineTo(p.dx - s, p.dy - s * 0.6)
          ..lineTo(p.dx - s * 0.5, p.dy)
          ..lineTo(p.dx, p.dy - s * 0.9)
          ..lineTo(p.dx + s * 0.5, p.dy)
          ..lineTo(p.dx + s, p.dy - s * 0.6)
          ..lineTo(p.dx + s, p.dy + s * 0.6)
          ..close();
        c.drawPath(cr, _fill(col == _lapis ? const Color(Palette.red) : col));
      case LocKind.secret:
        final star = Path();
        for (var i = 0; i < 10; i++) {
          final a = -math.pi / 2 + i * math.pi / 5;
          final rr = i.isEven ? s : s * 0.45;
          final q = p + Offset(math.cos(a) * rr, math.sin(a) * rr);
          i == 0 ? star.moveTo(q.dx, q.dy) : star.lineTo(q.dx, q.dy);
        }
        star.close();
        c.drawPath(star, f);
    }
  }

  @override
  bool shouldRepaint(_RealmPainter old) => true;
}

// Small round button in levels that leaves for the realm map
class MapButton extends StatelessWidget {
  const MapButton(this.game, {super.key, required this.w});
  final MeetRaGame game;
  final double w;

  @override
  Widget build(BuildContext context) => Stack(children: [
        At(w / 2, 30,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: game.leaveLevel,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0x991b2a6b),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xaad4a845), width: 2),
                ),
                child: const OutlinedText('Map', size: 16),
              ),
            )),
      ]);
}
