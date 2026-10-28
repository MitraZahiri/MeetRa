// The world map (seven realms) and the realm map (twenty locations each), drawn in ink on old paper.
// Everything that does not move is drawn once into an image (baked) and reused every frame;
// only the fog, the markers and Ra are painted live.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../config.dart';
import '../game/meetra_game.dart';
import '../world/world.dart';
import 'common.dart';
import 'ink.dart';

const _lapis = Color(Palette.lapis);
const _goldDark = Color(Palette.gold);
const _turq = Color(Palette.turquoise);
const _redInk = Color(0xffa8321f);

Paint _fill(Color c) => Paint()..color = c;

// Screen pixels per virtual pixel, so baked images are as sharp as the screen
double _pixelScale(BuildContext context) =>
    (MediaQuery.devicePixelRatioOf(context) * MediaQuery.sizeOf(context).height / gameH).clamp(1.0, 3.0);

// Draws [draw] (in virtual coordinates, covering [area]) into an image once
ui.Image _bake(Rect area, double px, void Function(Canvas c) draw) {
  final rec = ui.PictureRecorder();
  final c = Canvas(rec)
    ..scale(px)
    ..translate(-area.left, -area.top);
  draw(c);
  return rec.endRecording().toImageSync((area.width * px).ceil(), (area.height * px).ceil());
}

// Keeps one baked image until its key changes (screen size or what it shows)
class _Baked {
  ui.Image? _image;
  Object? _key;

  ui.Image get(Object key, ui.Image Function() make) {
    if (_image == null || key != _key) {
      _image?.dispose();
      _image = make();
      _key = key;
    }
    return _image!;
  }

  void dispose() => _image?.dispose();
}

final _imagePaint = Paint()..filterQuality = FilterQuality.medium;

void _drawBaked(Canvas c, ui.Image img, Rect area) =>
    c.drawImageRect(img, Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()), area, _imagePaint);

// ---------- Fog of war ----------

// A hole in the fog: centre, radii and how far it has opened (0..1)
typedef _Hole = (Offset centre, double rx, double ry, double reveal);

// Uncharted paper with hand-drawn clouds drifting over it. The clouds are baked once and slid along;
// soft holes are cut around everything Ra knows.
class _Fog {
  final _clouds = _Baked();

  void paint(Canvas c, Rect area, List<_Hole> holes, double t, double px, {bool dark = false}) {
    final clouds = _clouds.get((area, px, dark), () => _bake(area, px, (c) => _paintClouds(c, area, dark)));
    c.save();
    c.clipRect(area);
    c.saveLayer(area, Paint());
    c.drawRect(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark ? const [Color(0xff24212f), Color(0xff1a1824)] : const [Color(0xffd9cbad), Color(0xffc6b692)],
        ).createShader(area),
    );
    final drift = (t * 7) % area.width;
    _drawBaked(c, clouds, area.shift(Offset(drift, 0)));
    _drawBaked(c, clouds, area.shift(Offset(drift - area.width, 0)));
    final cut = Paint()..blendMode = BlendMode.dstOut;
    for (final (p, rx, ry, reveal) in holes) {
      if (reveal <= 0) continue;
      final r = ry * Curves.easeOutCubic.transform(reveal.clamp(0.0, 1.0));
      if (r < 1) continue;
      cut.shader = const RadialGradient(colors: [Color(0xff000000), Color(0xff000000), Color(0x00000000)], stops: [0, 0.6, 1])
          .createShader(Rect.fromCircle(center: Offset.zero, radius: r));
      c.save();
      c.translate(p.dx, p.dy);
      c.scale(rx / ry, 1);
      c.drawCircle(Offset.zero, r, cut);
      c.restore();
    }
    c.restore();
    c.restore();
  }

  // Scalloped clouds, repeated one map-width to each side so the drift wraps without a seam
  void _paintClouds(Canvas c, Rect area, bool dark) {
    final rnd = math.Random(5);
    final fill = _fill(dark ? const Color(0x553e3a52) : const Color(0x88efe4c8));
    final edge = inkPen(1.1, dark ? const Color(0x449890b0) : const Color(0x445a4632));
    for (var i = 0; i < 40; i++) {
      final x = area.left + rnd.nextDouble() * area.width;
      final y = area.top + rnd.nextDouble() * area.height;
      final r = 16 + rnd.nextDouble() * 34;
      final cloud = lumpy(Offset(x, y), r, 6 + rnd.nextInt(4), rnd.nextDouble() * 6, depth: 0.22);
      for (final dx in [-area.width, 0.0, area.width]) {
        final s = cloud.shift(Offset(dx, 0));
        c.drawPath(s, fill);
        c.drawPath(s, edge);
      }
    }
  }

  void dispose() => _clouds.dispose();
}

// Remembers which places have already been shown, so only new ones play the reveal
class _Reveals {
  _Reveals(this.seen);
  final Set<String> seen;
  final _clock = Stopwatch()..start();
  final _start = <String, double>{};

  double get now => _clock.elapsedMilliseconds / 1000;

  // 0..1: how far the fog has opened over [id]; first sightings animate, known ones are open
  double of(String id) {
    if (!seen.contains(id)) {
      seen.add(id);
      _start[id] = now + 0.35;
    }
    final s = _start[id];
    return s == null ? 1 : ((now - s) / 1.1).clamp(0.0, 1.0);
  }
}

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

// Lapis panel along the bottom of a map screen
Widget _infoPanel({required List<Widget> lines, Widget? action}) => Container(
      margin: const EdgeInsets.fromLTRB(40, 0, 40, 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: _lapis.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _goldDark, width: 3),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: lines)),
        if (action != null) action,
      ]),
    );

Widget _bodyText(String text) => Text(
      text,
      style: const TextStyle(fontFamily: fontFamily, fontSize: 16, color: parch, decoration: TextDecoration.none),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );

// ============================================================
// World map
// ============================================================

// Size of each realm's land (radii as fractions of the map), by realm index
const _realmShape = [(0.11, 0.24), (0.10, 0.26), (0.13, 0.20), (0.12, 0.18), (0.11, 0.22), (0.07, 0.24), (0.10, 0.13)];

// Land that joins the realms into one continent, then small islands: (x, y, rx, ry)
const _bridges = [(0.52, 0.62, 0.05, 0.12), (0.35, 0.36, 0.05, 0.12)];
const _islets = [(0.04, 0.12, 0.02, 0.05), (0.97, 0.45, 0.015, 0.04), (0.15, 0.95, 0.015, 0.035), (0.98, 0.75, 0.012, 0.035)];

// The Frost River runs from the Sky Spine down to the southern sea
const _riverPts = [(0.53, 0.33), (0.55, 0.45), (0.53, 0.58), (0.55, 0.7), (0.53, 0.84), (0.54, 1.0)];

enum _Mark { castle, darkCastle, village, ruin, lighthouse, pyramid, oasis, lake, peak, tents, spires, lantern, cave }

// The landmarks drawn on each realm: what, where (in units of the realm's radii) and which place it names
const _landmarks = <List<(_Mark, double, double, int?)>>[
  [(_Mark.village, -0.5, -0.3, 0), (_Mark.lake, -0.45, 0.5, 1), (_Mark.ruin, 0.45, 0.45, 13)],
  [(_Mark.castle, 0.05, -0.32, 0), (_Mark.lake, -0.4, 0.5, null), (_Mark.spires, 0.42, 0.55, 13)],
  [(_Mark.oasis, 0.5, -0.4, 0), (_Mark.pyramid, -0.68, 0.35, 14), (_Mark.darkCastle, 0.35, 0.68, 13)],
  [(_Mark.village, -0.6, 0.5, 0), (_Mark.peak, 0.78, 0.35, 19), (_Mark.cave, 0.25, 0.75, 13)],
  [(_Mark.tents, -0.45, -0.5, 0), (_Mark.castle, 0.6, 0.4, 12), (_Mark.lake, -0.4, 0.55, 13)],
  [(_Mark.lighthouse, 0.2, -0.72, 0), (_Mark.ruin, -0.35, -0.32, 8), (_Mark.spires, 0.1, 0.62, 13)],
  [(_Mark.lantern, -0.62, 0.45, 0), (_Mark.darkCastle, 0.62, 0.55, 13)],
];

// Where everything on the world map sits, worked out once for a given map rectangle
class _WorldLayout {
  _WorldLayout(this.area) {
    for (final r in realms) {
      final (rx, ry) = _realmShape[r.index];
      centre.add(_p(r.mapX, r.mapY));
      radii.add((rx * area.width, ry * area.height));
    }
    final blobs = <Path>[], grown = <Path>[];
    void add(Offset c, double rx, double ry, int seed) {
      blobs.add(wobblyBlob(c, rx, ry, seed));
      grown.add(wobblyBlob(c, rx, ry, seed, grow: 9));
    }

    for (final r in realms) {
      add(centre[r.index], radii[r.index].$1, radii[r.index].$2, 100 + r.index);
    }
    for (final (i, (x, y, rx, ry)) in [..._bridges, ..._islets].indexed) {
      add(_p(x, y), rx * area.width, ry * area.height, 200 + i);
    }
    land = blobs.reduce((a, b) => Path.combine(PathOperation.union, a, b));
    coastDash = grown.reduce((a, b) => Path.combine(PathOperation.union, a, b));
    for (final r in realms) {
      final (rx, ry) = radii[r.index];
      final name = inkMeasure(r.name, size: 15, bold: true, maxW: 170);
      nameRect.add(Rect.fromCenter(center: centre[r.index], width: name.width, height: name.height));
      for (final (mark, dx, dy, place) in _landmarks[r.index]) {
        final at = centre[r.index] + Offset(dx * rx, dy * ry);
        marks.add((r, mark, at, place == null ? null : r.locations[place].name));
        if (place == bossIndex) bossAt[r.index] = at;
        if (place == 0) townAt[r.index] = at;
      }
      outline.add(wobblyBlob(centre[r.index], rx, ry, 100 + r.index, grow: 7).computeMetrics().toList());
    }
  }

  final Rect area;
  final centre = <Offset>[];
  final radii = <(double, double)>[];
  final nameRect = <Rect>[];
  final marks = <(Realm, _Mark, Offset, String?)>[];
  final bossAt = <int, Offset>{}, townAt = <int, Offset>{};
  final outline = <List<ui.PathMetric>>[]; // each realm's shore, for the selection
  late final Path land, coastDash;

  Offset _p(double x, double y) => Offset(area.left + x * area.width, area.top + y * area.height);

  // How far inside a realm's oval a point is: below 1 is inside
  double reach(Realm r, Offset p) {
    final (rx, ry) = radii[r.index];
    final d = p - centre[r.index];
    return math.sqrt(d.dx * d.dx / (rx * rx) + d.dy * d.dy / (ry * ry));
  }

  Realm nearest(Offset p) => realms.reduce((a, b) => reach(a, p) <= reach(b, p) ? a : b);

  // ---------- The drawing ----------

  void paint(Canvas c) {
    paperSheet(c, area, seed: 3);
    _sea(c);
    dashedPath(c, coastDash, inkPen(1), dash: 4, gap: 4);
    _cliffs(c);
    c.save();
    c.clipPath(land);
    c.drawRect(area, _fill(const Color(0x40fbf4e2)));
    for (final r in realms) {
      final (rx, ry) = radii[r.index];
      final o = centre[r.index];
      c.drawOval(
        Rect.fromCenter(center: o, width: rx * 2.2, height: ry * 2.2),
        Paint()
          ..shader = RadialGradient(colors: [Color(r.color).withValues(alpha: 0.2), Color(r.color).withValues(alpha: 0)])
              .createShader(Rect.fromCenter(center: o, width: rx * 2.2, height: ry * 2.2)),
      );
    }
    _river(c);
    c.restore();
    c.drawPath(land, inkPen(2.2));
    _features(c);
    for (final r in realms) {
      inkText(c, r.name, nameRect[r.index].topCenter, size: 15, bold: true, maxW: 170);
    }
    c.drawRect(area.deflate(1.5), inkPen(2.5));
    c.drawRect(area.deflate(6), inkPen(0.8));
  }

  // Waves, a whirlpool, a sea serpent, ships and the compass
  void _sea(Canvas c) {
    final rnd = math.Random(11);
    final placed = <Offset>[];
    for (var i = 0; i < 160 && placed.length < 34; i++) {
      final p = _p(0.03 + rnd.nextDouble() * 0.94, 0.05 + rnd.nextDouble() * 0.9);
      if (coastDash.contains(p) || coastDash.contains(p + const Offset(0, 14)) || placed.any((q) => (q - p).distance < 60)) continue;
      if ([_whirlpool, _serpent, _ship1, _ship2, compassAt, bannerAt].any((q) => (q - p).distance < 70)) continue;
      placed.add(p);
      inkWave(c, p, 0.9 + rnd.nextDouble() * 0.3);
    }
    inkWhirlpool(c, _whirlpool, 20);
    inkSerpent(c, _serpent, 1.1);
    inkShip(c, _ship1, 1.1);
    inkShip(c, _ship2, 0.9);
  }

  Offset get _whirlpool => _p(0.21, 0.78);
  Offset get _serpent => _p(0.9, 0.9);
  Offset get _ship1 => _p(0.61, 0.08);
  Offset get _ship2 => _p(0.26, 0.9);
  Offset get compassAt => _p(0.96, 0.17);
  Offset get bannerAt => _p(0.68, 0.925);

  // The compass and the title ribbon sit on top of the fog
  void paintCartouche(Canvas c) {
    inkCompass(c, compassAt, 28);
    inkBanner(c, bannerAt, 'The Realm of the Dawnfire', size: 16);
  }

  // Cliffs: short strokes hanging below every south-facing shore
  void _cliffs(Canvas c) {
    final pen = inkPen(0.9);
    for (final m in land.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 2.6) {
        final tan = m.getTangentForOffset(d)!;
        var n = Offset(-tan.vector.dy, tan.vector.dx);
        if (land.contains(tan.position + n * 3)) n = -n;
        if (n.dy < 0.45) continue;
        c.drawLine(tan.position, tan.position + Offset(0, 3 + 7 * n.dy), pen);
      }
    }
  }

  void _river(Canvas c) {
    final river = Path();
    final pts = [for (final (x, y) in _riverPts) _p(x, y)];
    river.moveTo(pts[0].dx, pts[0].dy);
    for (var i = 1; i < pts.length; i++) {
      final a = pts[i - 1], b = pts[i];
      final mid = (a + b) / 2 + Offset(i.isEven ? 10 : -10, 0);
      river.quadraticBezierTo(mid.dx, mid.dy, b.dx, b.dy);
    }
    c.drawPath(river, inkPen(5));
    c.drawPath(river, inkPen(3, paperColor));
    inkText(c, 'Frost River', _p(0.575, 0.47), size: 9, italic: true);
  }

  // Landmarks, then filler (trees, peaks, dunes...) around them; drawn from the back to the front
  void _features(Canvas c) {
    final items = <(double, void Function())>[]; // (foot y, draw)
    final taken = <Rect>[...nameRect.map((r) => r.inflate(4))];
    for (final (r, mark, at, label) in marks) {
      taken.add(Rect.fromLTRB(at.dx - 18, at.dy - 26, at.dx + 18, at.dy + (label == null ? 2 : 16)));
      items.add((at.dy, () => _mark(c, mark, at, r.index)));
      if (label != null) items.add((1e9, () => inkText(c, label, at + const Offset(0, 2), size: 9.5, italic: true, maxW: 110)));
    }
    final rnd = math.Random(7);
    for (final r in realms) {
      final (rx, ry) = radii[r.index];
      final spots = <Offset>[];
      for (var i = 0; i < 260 && spots.length < (rx * ry / 260).round(); i++) {
        final a = rnd.nextDouble() * math.pi * 2, k = math.sqrt(rnd.nextDouble()) * 0.95;
        final p = centre[r.index] + Offset(math.cos(a) * rx * k, math.sin(a) * ry * k);
        final box = Rect.fromLTRB(p.dx - 7, p.dy - 16, p.dx + 7, p.dy);
        if (!land.contains(p) || !land.contains(p + const Offset(0, 6)) || nearest(p) != r) continue;
        if (taken.any((t) => t.overlaps(box)) || spots.any((q) => (q - p).distance < 14)) continue;
        if (_riverPts.any((q) => (_p(q.$1, q.$2) - p).distance < 22)) continue; // keep the river clear
        spots.add(p);
        final v = rnd.nextDouble(), ph = rnd.nextDouble() * 6;
        items.add((p.dy, () => _filler(c, r.theme, p, v, ph)));
      }
    }
    items.sort((a, b) => a.$1.compareTo(b.$1));
    for (final (_, draw) in items) {
      draw();
    }
  }

  void _filler(Canvas c, RealmTheme theme, Offset p, double v, double ph) {
    switch (theme) {
      case RealmTheme.vale:
        v < 0.75 ? inkTree(c, p, 1, ph) : inkGrass(c, p, 1.2);
      case RealmTheme.city:
        v < 0.5 ? inkTree(c, p, 0.95, ph) : (v < 0.75 ? inkHouse(c, p, 0.9) : inkGrass(c, p, 1.1));
      case RealmTheme.desert:
        v < 0.65 ? inkDune(c, p, 0.8) : inkPalm(c, p, 0.8, ph / 6);
      case RealmTheme.mountain:
        v < 0.7 ? inkMountain(c, p, 0.75, ph / 6, snow: true) : inkPine(c, p, 0.95);
      case RealmTheme.steppe:
        v < 0.55 ? inkGrass(c, p, 1.2) : (v < 0.85 ? inkTree(c, p, 0.85, ph) : inkTent(c, p, 0.8));
      case RealmTheme.coast:
        v < 0.55 ? inkTree(c, p, 0.8, ph) : (v < 0.8 ? inkGrass(c, p, 1.1) : inkHouse(c, p, 0.8));
      case RealmTheme.dark:
        v < 0.55 ? inkDeadTree(c, p, 0.95, ph / 6) : (v < 0.85 ? inkSpire(c, p, 0.7, ph / 6) : inkGrass(c, p, 1));
    }
  }

  void _mark(Canvas c, _Mark m, Offset p, int seed) {
    switch (m) {
      case _Mark.castle:
        inkCastle(c, p, 0.95);
      case _Mark.darkCastle:
        inkCastle(c, p, 0.85, dark: true);
      case _Mark.village:
        inkHouse(c, p + const Offset(-8, -5), 1);
        inkHouse(c, p + const Offset(7, -3), 1.1);
        inkHouse(c, p, 1.2);
      case _Mark.ruin:
        inkRuin(c, p, 1);
      case _Mark.lighthouse:
        inkLighthouse(c, p, 0.9);
      case _Mark.pyramid:
        inkPyramid(c, p + const Offset(5, -3), 0.8);
        inkPyramid(c, p, 1);
      case _Mark.oasis:
        inkLake(c, p - const Offset(0, 4), 11, 5, seed);
        inkPalm(c, p + const Offset(-10, -2), 0.85, 0.2);
        inkPalm(c, p + const Offset(9, 0), 0.9, 0.8);
      case _Mark.lake:
        inkLake(c, p - const Offset(0, 7), 17, 8, seed + 40);
      case _Mark.peak:
        inkMountain(c, p, 1.4, 0.8, snow: true);
      case _Mark.tents:
        inkTent(c, p + const Offset(-8, -4), 0.9);
        inkTent(c, p + const Offset(8, -2), 0.9);
        inkTent(c, p, 1);
      case _Mark.spires:
        inkSpire(c, p + const Offset(-7, -2), 0.8, 0.3);
        inkSpire(c, p + const Offset(7, -1), 0.9, 0.6);
        inkSpire(c, p, 1.1, 1);
      case _Mark.lantern:
        inkLighthouse(c, p, 0.8);
        inkDeadTree(c, p + const Offset(-12, 0), 0.8, 0.2);
      case _Mark.cave:
        inkMountain(c, p, 1.1, 0.3, snow: true);
        final mouth = Path()
          ..moveTo(p.dx - 4, p.dy)
          ..quadraticBezierTo(p.dx - 3, p.dy - 7, p.dx + 1, p.dy - 7)
          ..quadraticBezierTo(p.dx + 4, p.dy - 6, p.dx + 4, p.dy)
          ..close();
        c.drawPath(mouth, _fill(inkColor));
    }
  }
}

class WorldMapScreen extends StatefulWidget {
  const WorldMapScreen(this.game, {super.key, required this.w});
  final MeetRaGame game;
  final double w;

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  late final _reveals = _Reveals(widget.game.mapSeen);
  final _art = _Baked();
  final _fog = _Fog();
  static _WorldLayout? _layoutCache; // kept between visits: the geometry takes a moment to work out
  late Realm? _selected = _openAt(widget.game.progress.realm);
  String? _hint;
  bool _confirmWipe = false;

  Rect get _area => Rect.fromLTRB(16, 62, widget.w - 16, 436);

  _WorldLayout get _layout {
    final l = _layoutCache;
    if (l != null && l.area == _area) return l;
    return _layoutCache = _WorldLayout(_area);
  }

  Realm? _openAt(int i) => realmUnlocked(realms[i], widget.game.progress) ? realms[i] : null;

  @override
  void dispose() {
    _pulse.dispose();
    _art.dispose();
    _fog.dispose();
    super.dispose();
  }

  // Tap a known realm to read about it, tap it again (or Enter) to go there
  void _tap(Offset p) {
    final g = widget.game;
    final l = _layout;
    if (!l.area.contains(p)) return;
    final r = l.nearest(p);
    if (l.reach(r, p) < 1.15 && realmUnlocked(r, g.progress)) {
      if (_selected == r) {
        g.openRealm(r);
        return;
      }
      setState(() {
        _selected = r;
        _hint = null;
      });
      return;
    }
    // Anything else is still under the fog
    final next = realms.where((r) => !r.hidden && !realmUnlocked(r, g.progress)).firstOrNull;
    setState(() {
      _selected = null;
      _hint = next == null
          ? 'Something still hides in the far north. Find all six Dawn Sigils.'
          : 'Uncharted. The fog lifts when ${realms[next.index - 1].bossName} falls.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.game;
    final w = widget.w;
    final px = _pixelScale(context);
    return ListenableBuilder(
      listenable: g.progress,
      builder: (context, _) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => _tap(d.localPosition),
        child: Stack(children: [
          Positioned.fill(
            child: RepaintBoundary(child: CustomPaint(painter: _WorldPainter(g, _layout, _art, _fog, px, _pulse, _reveals, _selected))),
          ),
          At(w - 30, 32, ax: 1, child: OutlinedText('Dawn Sigils  ${sigilCount(g.progress)} / 6', size: 18, color: const Color(0xff8ae0d8))),
          At(30, 32, ax: 0, child: OutlinedText('Lv ${g.state.level}  ·  ${g.state.gold} gold', size: 18)),
          At(w / 2, 32,
              child: GestureDetector(
                onTap: () {
                  if (_confirmWipe) {
                    g.newGame();
                    setState(() {
                      _confirmWipe = false;
                      _selected = realms.first;
                      _hint = 'A new saga begins.';
                    });
                  } else {
                    setState(() => _confirmWipe = true);
                  }
                },
                child: OutlinedText(_confirmWipe ? 'Tap again to erase your save' : 'New game', size: 14, color: const Color(0xffc8bca0)),
              )),
          Positioned(left: 0, right: 0, top: 444, bottom: 0, child: _panel(g)),
        ]),
      ),
    );
  }

  Widget _panel(MeetRaGame g) {
    final r = _selected;
    if (r == null || _hint != null) {
      return Center(child: OutlinedText(_hint ?? 'Tap a realm on the map.', size: 19, color: parch));
    }
    final cleared = g.progress.isCleared(r.boss);
    return _infoPanel(
      lines: [
        Row(children: [
          OutlinedText(r.name, size: 24, color: gold),
          const SizedBox(width: 12),
          OutlinedText(
            '${clearedIn(r, g.progress)} / 20 explored  ·  ${cleared ? '${r.bossName} defeated' : 'Boss: ${r.bossName}'}',
            size: 15,
            color: cleared ? const Color(0xff8ae0d8) : const Color(0xffc8bca0),
          ),
        ]),
        const SizedBox(height: 4),
        _bodyText(r.lore),
      ],
      action: _TextButton('Enter', () => g.openRealm(r)),
    );
  }
}

class _WorldPainter extends CustomPainter {
  _WorldPainter(this.game, this.layout, this.art, this.fog, this.px, this.pulse, this.reveals, this.selected) : super(repaint: pulse);
  final MeetRaGame game;
  final _WorldLayout layout;
  final _Baked art;
  final _Fog fog;
  final double px;
  final Animation<double> pulse;
  final _Reveals reveals;
  final Realm? selected;

  @override
  void paint(Canvas c, Size size) {
    final area = layout.area;
    c.drawRect(Offset.zero & size, _fill(const Color(0xff0d1233)));
    _drawBaked(c, art.get((area, px), () => _bake(area, px, layout.paint)), area);

    final prog = game.progress;
    final t = pulse.value;
    // Red ink roads from each fallen boss to the next realm's first town; one runs on into the fog
    for (var i = 0; i < 5; i++) {
      final a = realms[i], b = realms[i + 1];
      if (!realmUnlocked(a, prog)) continue;
      _route(c, layout.bossAt[a.index]! + const Offset(0, -6), layout.townAt[b.index]! + const Offset(0, -6), realmUnlocked(b, prog));
    }

    // Only the realms Ra has opened are known; the rest of the world is uncharted
    final open = [for (final r in realms) if (realmUnlocked(r, prog)) r];
    final reveal = {for (final r in open) r: reveals.of('realm:${r.id}')};
    fog.paint(
      c,
      area,
      [for (final r in open) (layout.centre[r.index], layout.radii[r.index].$1 * 1.35, layout.radii[r.index].$2 * 1.35, reveal[r]!)],
      reveals.now,
      px,
    );
    c.drawRect(area.deflate(1.5), inkPen(2.5));
    layout.paintCartouche(c);

    for (final r in open) {
      final k = Curves.easeOut.transform(((reveal[r]! - 0.3) / 0.7).clamp(0.0, 1.0));
      if (k <= 0) continue;
      final name = layout.nameRect[r.index];
      final cleared = prog.isCleared(r.boss);
      inkText(c, '${clearedIn(r, prog)} / 20', name.bottomCenter + const Offset(0, 1), size: 11, color: inkColor.withValues(alpha: k));
      // The boss lair: a red X while it stands, a seal once it falls
      final x = layout.bossAt[r.index]! + const Offset(16, -16);
      final red = inkPen(2.4, _redInk.withValues(alpha: k));
      if (cleared) {
        c.drawCircle(x, 7, _fill(_redInk.withValues(alpha: 0.9 * k)));
        c.drawPath(
            Path()
              ..moveTo(x.dx - 3.5, x.dy)
              ..lineTo(x.dx - 1, x.dy + 3)
              ..lineTo(x.dx + 4, x.dy - 3),
            inkPen(1.6, paperColor.withValues(alpha: k)));
      } else {
        c.drawLine(x + const Offset(-5, -5), x + const Offset(5, 5), red);
        c.drawLine(x + const Offset(5, -5), x + const Offset(-5, 5), red);
        c.drawCircle(x, 9 + 9 * t, inkPen(1.5, _redInk.withValues(alpha: (1 - t) * k)));
      }
    }

    // Marching ants around the chosen realm's shore
    final sel = selected;
    if (sel != null && realmUnlocked(sel, prog)) {
      final ants = inkPen(1.8, _redInk);
      for (final m in layout.outline[sel.index]) {
        for (var d = -(t * 18) % 18; d < m.length; d += 18) {
          c.drawPath(m.extractPath(math.max(0, d), math.min(m.length, d + 9)), ants);
        }
      }
    }

    // Ra stands on the realm of the last journey
    final here = realms[prog.realm];
    if (realmUnlocked(here, prog)) {
      final sheet = game.art.hero;
      final foot = layout.nameRect[here.index].topCenter - const Offset(0, 2);
      final bob = math.sin(t * math.pi * 2) * 1.5;
      const scale = 1.8;
      final dst = Rect.fromLTWH(foot.dx - sheet.frameW * scale / 2, foot.dy - sheet.frameH * scale + bob, sheet.frameW * scale, sheet.frameH * scale);
      c.drawImageRect(sheet.image, sheet.src(0), dst, Paint()..filterQuality = FilterQuality.none);
    }
  }

  void _route(Canvas c, Offset a, Offset b, bool open) {
    final pen = inkPen(2.2, open ? _redInk : _redInk.withValues(alpha: 0.5));
    final d = (b - a).distance;
    final dir = (b - a) / d;
    final bend = Offset(-dir.dy, dir.dx) * 18;
    for (var s = 0.0; s < d; s += 11) {
      final t0 = s / d, t1 = math.min(1.0, (s + 5) / d);
      Offset at(double t) => a + (b - a) * t + bend * math.sin(t * math.pi);
      c.drawLine(at(t0), at(t1), pen);
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
  late final _reveals = _Reveals(widget.game.mapSeen);
  final _art = _Baked();
  final _fog = _Fog();
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
    _art.dispose();
    _fog.dispose();
    super.dispose();
  }

  // Places come out of the fog once a neighbouring place is cleared (the village is always known).
  // Secret places stay hidden until Ra can actually open them.
  bool _visible(Location l) {
    final p = widget.game.progress;
    if (p.isCleared(l) || l.id == p.lastLocation) return true;
    if (l.kind == LocKind.secret) return isOpen(l, p, widget.game.state);
    return l.index == 0 || l.links.any(p.isCleared);
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
    final px = _pixelScale(context);
    return ListenableBuilder(
      listenable: g.progress,
      builder: (context, _) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => _tap(d.localPosition),
        child: Stack(children: [
          Positioned.fill(
            child: RepaintBoundary(child: CustomPaint(painter: _RealmPainter(g, r, _area, _art, _fog, px, _pulse, _selected, _visible, _reveals))),
          ),
          At(w / 2, 32, child: OutlinedText(r.name, size: 30, color: gold)),
          At(w / 2, 60, child: OutlinedText(r.tagline, size: 15, color: const Color(0xffc8bca0))),
          At(w - 30, 36, ax: 1, child: OutlinedText('${clearedIn(r, g.progress)} / 20 explored', size: 18, color: const Color(0xff8ae0d8))),
          At(30, 36, ax: 0, child: _TextButton('‹  World', g.openWorld, size: 16)),
          Positioned(left: 0, right: 0, top: 428, bottom: 0, child: _panel(g)),
        ]),
      ),
    );
  }

  Widget _panel(MeetRaGame g) {
    final l = _selected;
    if (l == null) {
      return const Center(child: OutlinedText('Tap a glowing place. Clear it, and the fog lifts from the roads beyond.', size: 20));
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
    return _infoPanel(
      lines: [
        Row(children: [
          OutlinedText(l.name, size: 24, color: gold),
          const SizedBox(width: 12),
          OutlinedText('${l.kind.label}  ·  $status', size: 15, color: statusColor),
        ]),
        const SizedBox(height: 6),
        _bodyText(_message.isNotEmpty ? _message.join('  ') : l.desc),
      ],
      action: action == null
          ? null
          : _TextButton(action, () {
              if (l.kind.playable) {
                g.enterLocation(l);
              } else {
                setState(() => _message = g.visit(l));
              }
            }),
    );
  }
}

class _RealmPainter extends CustomPainter {
  _RealmPainter(this.game, this.realm, this.area, this.art, this.fog, this.px, this.pulse, this.selected, this.visible, this.reveals)
      : super(repaint: pulse);
  final MeetRaGame game;
  final Realm realm;
  final Rect area;
  final _Baked art;
  final _Fog fog;
  final double px;
  final Animation<double> pulse;
  final Location? selected;
  final bool Function(Location) visible;
  final _Reveals reveals;

  bool get dark => realm.theme == RealmTheme.dark;
  Rect get mapRect => area.inflate(30);
  Offset _pos(Location l) => Offset(area.left + l.x * area.width, area.top + l.y * area.height);

  @override
  void paint(Canvas c, Size size) {
    c.drawRect(Offset.zero & size, _fill(const Color(0xff0d1233)));
    _drawBaked(c, art.get((mapRect, px, realm.id), () => _bake(mapRect, px, _paintBackground)), mapRect);

    final prog = game.progress;
    final s = game.state;
    final locs = realm.locations;
    final faint = dark ? const Color(0x66f2e6c9) : const Color(0x66553a20);

    // Roads; one leading into the fog is drawn too, and the fog hides where it goes
    for (final a in locs) {
      for (final b in a.links) {
        if (b.index < a.index || (!visible(a) && !visible(b))) continue;
        if ((a.kind == LocKind.secret && !visible(a)) || (b.kind == LocKind.secret && !visible(b))) continue;
        final done = prog.isCleared(a) && prog.isCleared(b);
        final reachable = prog.isCleared(a) || prog.isCleared(b);
        final pa = _pos(a), pb = _pos(b);
        final mid = Offset((pa.dx + pb.dx) / 2, (pa.dy + pb.dy) / 2 - 10);
        final path = Path()
          ..moveTo(pa.dx, pa.dy)
          ..quadraticBezierTo(mid.dx, mid.dy, pb.dx, pb.dy);
        if (done) {
          c.drawPath(path, inkPen(3.5, dark ? parch : inkColor));
        } else {
          dashedPath(c, path, inkPen(2.5, reachable ? _redInk : faint), dash: 7, gap: 6);
        }
      }
    }

    // Fog of war over everything Ra has not found yet
    final known = [for (final l in locs) if (visible(l)) l];
    final reveal = {for (final l in known) l: reveals.of(l.id)};
    fog.paint(c, mapRect, [for (final l in known) (_pos(l), prog.isCleared(l) ? 92.0 : 62.0, prog.isCleared(l) ? 92.0 : 62.0, reveal[l]!)], reveals.now, px,
        dark: dark);
    c.drawRect(mapRect.deflate(1.5), inkPen(2.5, dark ? parch : inkColor));

    // Locations
    final t = pulse.value;
    for (final l in known) {
      final k = Curves.easeOut.transform(((reveal[l]! - 0.35) / 0.65).clamp(0.0, 1.0));
      if (k <= 0) continue;
      // Only places still fading in need their own layer
      if (k < 1) c.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, k));
      final p = _pos(l);
      final cleared = prog.isCleared(l);
      final open = isOpen(l, prog, s);
      final big = l.kind == LocKind.boss || l.kind == LocKind.town;
      final r = big ? 22.0 : 17.0;
      if (open && !cleared) c.drawCircle(p, r + 3 + 8 * t, inkPen(3, _redInk.withValues(alpha: 1 - t)));
      if (l == selected) c.drawCircle(p, r + 6, inkPen(2.5, dark ? parch : _lapis));
      final fill = cleared
          ? _turq
          : open
              ? const Color(0xfffbf3df)
              : (dark ? const Color(0xff3a3848) : const Color(0xffcfc3a6));
      c.drawCircle(p, r, _fill(fill));
      c.drawCircle(p, r, inkPen(l.kind == LocKind.boss ? 3.5 : 2.5, cleared || open ? inkColor : const Color(0xff8a7a60)));
      _icon(c, l.kind, p, r * 0.55, cleared ? const Color(0xfffbf3df) : (open ? _lapis : const Color(0xff8a7a60)));
      if (open || cleared) {
        inkText(c, l.name, p + Offset(0, r + 3), size: 12.5, bold: true, color: dark ? parch : inkColor, halo: !dark, maxW: 130);
      }
      if (k < 1) c.restore();
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

  // Paper, a wash of the realm's color and ink motifs kept away from the places (baked once)
  void _paintBackground(Canvas c) {
    final r = mapRect;
    if (dark) {
      c.drawRect(r, Paint()..shader = const RadialGradient(colors: [Color(0xff2c2a3a), Color(0xff14121c)], radius: 0.9).createShader(r));
    } else {
      paperSheet(c, r, seed: realm.index + 20);
    }
    c.drawRect(r, _fill(Color(realm.color).withValues(alpha: 0.1)));
    final rnd = math.Random(realm.index * 97 + 13);
    final nodes = realm.locations.map(_pos).toList();
    final spots = <Offset>[];
    for (var i = 0; i < 260 && spots.length < 70; i++) {
      final p = Offset(r.left + 20 + rnd.nextDouble() * (r.width - 40), r.top + 30 + rnd.nextDouble() * (r.height - 40));
      if (nodes.any((n) => (n - p).distance < 44) || spots.any((q) => (q - p).distance < 22)) continue;
      spots.add(p);
    }
    spots.sort((a, b) => a.dy.compareTo(b.dy));
    for (final p in spots) {
      final v = rnd.nextDouble(), ph = rnd.nextDouble() * 6;
      switch (realm.theme) {
        case RealmTheme.vale:
          v < 0.8 ? inkTree(c, p, 1.3, ph) : inkGrass(c, p, 1.5);
        case RealmTheme.city:
          v < 0.45 ? inkTree(c, p, 1.2, ph) : (v < 0.8 ? inkHouse(c, p, 1.2) : inkGrass(c, p, 1.4));
        case RealmTheme.desert:
          v < 0.7 ? inkDune(c, p, 1.1) : inkPalm(c, p, 1.1, ph / 6);
        case RealmTheme.mountain:
          v < 0.65 ? inkMountain(c, p, 1.05, ph / 6, snow: true) : inkPine(c, p, 1.2);
        case RealmTheme.steppe:
          v < 0.6 ? inkGrass(c, p, 1.5) : (v < 0.88 ? inkTree(c, p, 1.1, ph) : inkTent(c, p, 1.1));
        case RealmTheme.coast:
          v < 0.4 ? inkWave(c, p, 1.2) : (v < 0.8 ? inkTree(c, p, 1.05, ph) : inkRuin(c, p, 0.9));
        case RealmTheme.dark:
          // Pale stars and dead trees drawn in light ink on the dark ground
          c.drawCircle(p, 1.3, _fill(Color.fromRGBO(242, 230, 201, 0.3 + v * 0.5)));
          if (v < 0.3) inkSpire(c, p, 0.9, ph / 6);
      }
    }
    final frame = dark ? parch : inkColor;
    c.drawRect(r.deflate(1.5), inkPen(2.5, frame));
    c.drawRect(r.deflate(6), inkPen(0.8, frame));
  }

  // Small symbol for each kind of place
  void _icon(Canvas c, LocKind k, Offset p, double s, Color col) {
    final f = _fill(col);
    final st = inkPen(2, col);
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
