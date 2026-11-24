// Painted parallax backdrops: a sky and four layers of scenery for every realm, plus the
// underground, which fades in as Ra goes down into the rooms below the surface.
// Unlike the pixel-art level they are drawn with smooth shapes, gradients, glows and mist
// at twice the world resolution, so they read as soft painted scenery behind the play.
// Every layer is 480 x 270 world pixels and wraps left to right without a seam.
// A realm can also bring things to life on a layer: they are drawn every frame on top of
// that layer, in its own coordinates, so they scroll with it (leaves sway, a caravan walks).

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';

import '../world/world.dart';
import 'pixel.dart';
import 'sun_eye.dart';

const backdropW = 480.0;
const backdropH = 270.0;
const backdropScale = 2.0; // image pixels per world pixel

// How far each layer moves with the camera: sky, clouds, far, middle, near
const backdropParallax = [0.0, 0.05, 0.15, 0.32, 0.55];

// Draws the moving things of one layer at time [t] (seconds), in layer coordinates.
// Anything placed within 0..backdropW is repeated a tile width apart by the renderer.
typedef BackdropLive = void Function(Canvas c, double t);

class Backdrop {
  Backdrop(this.layers, [this.live = const {}]);
  final List<ui.Image> layers;
  final Map<int, BackdropLive> live; // layer index -> its moving things

  void dispose() {
    for (final l in layers) {
      l.dispose();
    }
  }
}

typedef _Painter = void Function(Canvas c, math.Random r);

// [theme] null paints the underground
Backdrop paintBackdrop(RealmTheme? theme) {
  final painters = theme == null ? _underground : _realms[theme]!;
  return Backdrop([
    for (final (i, p) in painters.indexed)
      () {
        final rec = ui.PictureRecorder();
        final c = Canvas(rec)..scale(backdropScale);
        final seed = theme == null ? 900 + i : theme.index * 10 + i;
        p(c, math.Random(seed));
        _grain(c, math.Random(seed + 5000));
        return rec.endRecording().toImageSync((backdropW * backdropScale).toInt(), (backdropH * backdropScale).toInt());
      }(),
  ], theme == null ? const {} : _live[theme] ?? const {});
}

// ---------- Helpers ----------

const W = backdropW;
const H = backdropH;

Paint _fill(String c, [double a = 1]) => Paint()..color = hex(c).withValues(alpha: a);

// A fine grain of light and dark specks, like ink on rough paper. It lands only where the
// layer is already painted, so a layer's open sky stays clear for the layers behind it.
void _grain(Canvas c, math.Random r, {int n = 4000, double a = 0.07}) {
  Float32List specks() => Float32List.fromList([for (var i = 0; i < n; i++) ...[r.nextDouble() * W, r.nextDouble() * H]]);
  for (final color in ['#ffffff', '#000000']) {
    c.drawRawPoints(
        PointMode.points,
        specks(),
        Paint()
          ..color = hex(color).withValues(alpha: a)
          ..strokeWidth = 0.7
          ..blendMode = BlendMode.srcATop);
  }
}

// Colors spread evenly from top to bottom unless [stops] place them
Paint _vgrad(double top, double bottom, List<String> colors, [List<double>? stops]) => Paint()
  ..shader = Gradient.linear(Offset(0, top), Offset(0, bottom), colors.map(hex).toList(),
      stops ?? [for (var i = 0; i < colors.length; i++) i / (colors.length - 1)]);

// Draws [f] three times, a tile width apart, so shapes crossing an edge wrap round
void _wrap(void Function(double dx) f) {
  for (final dx in [-W, 0.0, W]) {
    f(dx);
  }
}

void _sky(Canvas c, List<String> colors, [List<double>? stops]) => c.drawRect(const Rect.fromLTWH(0, 0, W, H), _vgrad(0, H, colors, stops));

// A soft horizontal band of mist
void _mist(Canvas c, double y, double h, String color, double a) => c.drawRect(
      Rect.fromLTWH(0, y - h, W, h * 2),
      Paint()
        ..shader = Gradient.linear(Offset(0, y - h), Offset(0, y + h),
            [hex(color).withValues(alpha: 0), hex(color).withValues(alpha: a), hex(color).withValues(alpha: 0)], const [0, 0.5, 1]),
    );

void _glow(Canvas c, Offset o, double r, String color, double a) => c.drawCircle(
      o,
      r,
      Paint()..shader = Gradient.radial(o, r, [hex(color).withValues(alpha: a), hex(color).withValues(alpha: 0)]),
    );

// A ridge across the whole tile: [n] random heights joined smoothly (or as sharp peaks),
// closed down to the bottom. Point n is point 0 again, so the ridge wraps.
Path _ridge(math.Random r, double base, double amp, int n, {bool sharp = false, double bottom = H}) {
  final hs = List.generate(n, (_) => r.nextDouble());
  double y(int i) => base - hs[i % n] * amp;
  final step = W / n;
  final p = Path()
    ..moveTo(-step, bottom)
    ..lineTo(-step, y(n - 1));
  for (var i = 0; i <= n + 1; i++) {
    final x = i * step;
    if (sharp) {
      p.lineTo(x - step / 2, y(i) + amp * 0.35 + (i.isEven ? 4 : -2));
      p.lineTo(x, y(i));
    } else {
      p.quadraticBezierTo(x - step / 2, y(i - 1 < 0 ? n - 1 : i - 1), x, y(i));
    }
  }
  return p
    ..lineTo(W + step, bottom)
    ..close();
}

// A shape filled with a vertical gradient, with a lit rim on its upper-left edge
void _shape(Canvas c, Path p, Rect box, List<String> colors, {String? rim, double rimA = 0.6}) {
  c.drawPath(p, _vgrad(box.top, box.bottom, colors));
  if (rim == null) return;
  c.save();
  c.clipPath(p);
  c.drawPath(
      p.shift(const Offset(1.5, 1.5)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = hex(rim).withValues(alpha: rimA));
  c.restore();
}

// Soft painted clouds: overlapping puffs, lit on top, shadowed below
void _clouds(Canvas c, math.Random r, int n, String light, String shade, double a, {double yMin = 20, double yMax = 110}) {
  for (var i = 0; i < n; i++) {
    final x = i * W / n + r.nextDouble() * 40;
    final y = yMin + r.nextDouble() * (yMax - yMin);
    final s = 0.7 + r.nextDouble() * 0.7;
    final puffs = [for (var k = 0; k < 6; k++) (k * 9.0 * s - 22 * s, -math.sin(k / 5 * math.pi) * 9 * s + r.nextDouble() * 3, (7 + r.nextDouble() * 6) * s)];
    _wrap((dx) {
      for (final (px, py, pr) in puffs) {
        c.drawCircle(Offset(x + dx + px, y + py + 2), pr, _fill(shade, a));
      }
      for (final (px, py, pr) in puffs) {
        c.drawCircle(
            Offset(x + dx + px, y + py),
            pr * 0.92,
            Paint()
              ..shader = Gradient.linear(Offset(0, y + py - pr), Offset(0, y + py + pr), [hex(light).withValues(alpha: a), hex(shade).withValues(alpha: a)]));
      }
    });
  }
}

// A round tree crown made of puffs, darker underneath
// [seed] fixes its shape, so the copies drawn by _wrap match across the seam
void _crown(Canvas c, int seed, Offset at, double size, String dark, String mid, String light) {
  final r = math.Random(seed);
  final puffs = [for (var k = 0; k < 7; k++) (Offset((r.nextDouble() - 0.5) * size * 1.4, (r.nextDouble() - 0.6) * size * 0.9), size * (0.45 + r.nextDouble() * 0.3))];
  for (final (o, rr) in puffs) {
    c.drawCircle(at + o + const Offset(0, 3), rr, _fill(dark));
  }
  for (final (o, rr) in puffs) {
    c.drawCircle(at + o, rr * 0.9, Paint()..shader = Gradient.radial(at + o - Offset(rr * 0.3, rr * 0.4), rr * 1.2, [hex(light), hex(mid)]));
  }
}

/// ---------- Flat painted plants, shared by the green realms ----------

Offset _dir(double a) => Offset(math.cos(a), math.sin(a));

// A fan palm like a paper parasol: a round crown of leaf spokes on a slim ringed trunk.
// [tilt] squashes the crown, as if seen a little from below.
void _fanPalm(Canvas c, Offset top, double radius, double trunkH, String trunk, String crown, String spoke, {double tilt = 1, double turn = 0}) {
  final tw = math.max(2.0, radius * 0.14);
  c.drawRect(Rect.fromLTWH(top.dx - tw / 2, top.dy, tw, trunkH), _fill(trunk));
  for (var y = top.dy + radius * 0.6; y < top.dy + trunkH; y += 4) {
    c.drawRect(Rect.fromLTWH(top.dx - tw / 2, y, tw, 0.8), _fill('#000000', 0.18));
  }
  c.save();
  c.translate(top.dx, top.dy);
  c.scale(1, tilt);
  // The crown's rim is notched where the leaves split
  const n = 18;
  final rim = Path();
  for (var k = 0; k <= n * 2; k++) {
    final p = _dir(turn + k / (n * 2) * math.pi * 2) * radius * (k.isEven ? 1 : 0.9);
    k == 0 ? rim.moveTo(p.dx, p.dy) : rim.lineTo(p.dx, p.dy);
  }
  c.drawPath(rim..close(), _fill(crown));
  final ink = Paint()
    ..color = hex(spoke)
    ..strokeWidth = math.max(0.7, radius * 0.05)
    ..strokeCap = StrokeCap.round;
  for (var k = 0; k < n; k++) {
    final a = turn + (k + 0.5) / n * math.pi * 2;
    c.drawLine(_dir(a) * radius * 0.1, _dir(a) * radius * 0.88, ink);
  }
  c.drawCircle(Offset.zero, radius * 0.1, _fill(spoke));
  c.restore();
}

// A long leaf from [base] along [angle], with a midrib and slashes down its sides
void _leaf(Canvas c, Offset base, double angle, double len, double width, String fill, {String? vein, int slits = 0}) {
  c.save();
  c.translate(base.dx, base.dy);
  c.rotate(angle);
  c.drawPath(
      Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(len * 0.35, -width, len, 0)
        ..quadraticBezierTo(len * 0.35, width, 0, 0)
        ..close(),
      _fill(fill));
  if (vein != null) {
    final v = Paint()
      ..color = hex(vein)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.6, width * 0.09)
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset.zero, Offset(len * 0.92, 0), v);
    for (var k = 1; k <= slits; k++) {
      final x = len * k / (slits + 1);
      final w = width * 0.75 * math.sin(math.pi * (0.25 + 0.75 * x / len));
      for (final s in [-1.0, 1.0]) {
        c.drawLine(Offset(x, 0), Offset(x + len * 0.12, s * w), v);
      }
    }
  }
  c.restore();
}

// A star flower of five slim petals round a dark eye
void _flower(Canvas c, Offset at, double size, String petal, String eye, double turn) {
  for (var k = 0; k < 5; k++) {
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(turn + k * math.pi * 2 / 5);
    c.drawOval(Rect.fromLTWH(size * 0.1, -size * 0.17, size, size * 0.34), _fill(petal));
    c.restore();
  }
  c.drawCircle(at, size * 0.16, _fill(eye));
}

// A fan of narrow upright blades, like a clump of sword plants
void _blades(Canvas c, math.Random r, Offset base, double h, int n, String color) {
  for (var k = 0; k < n; k++) {
    final a = -math.pi / 2 + (k / (n - 1) - 0.5) * 1.1 + (r.nextDouble() - 0.5) * 0.15;
    _leaf(c, base, a, h * (0.6 + r.nextDouble() * 0.4), h * 0.07, color);
  }
}

// A round bush covered in rows of small oval leaves
void _scaleBush(Canvas c, math.Random r, Offset base, double w, double h, String body, String leaf) {
  final dome = Path()
    ..moveTo(base.dx - w, base.dy)
    ..cubicTo(base.dx - w, base.dy - h * 1.3, base.dx + w, base.dy - h * 1.3, base.dx + w, base.dy)
    ..close();
  c.drawPath(dome, _fill(body));
  c.save();
  c.clipPath(dome);
  var row = 0;
  for (var y = base.dy - h; y < base.dy; y += 5, row++) {
    for (var x = base.dx - w + (row.isEven ? 0 : 3); x < base.dx + w; x += 6) {
      c.save();
      c.translate(x + r.nextDouble() * 2, y + r.nextDouble() * 2);
      c.rotate(-0.5 + r.nextDouble() * 0.3);
      c.drawOval(const Rect.fromLTWH(-2.6, -1.3, 5.2, 2.6), _fill(leaf));
      c.restore();
    }
  }
  c.restore();
}

// ---------- Hearthvale: a deep green jungle round a sunny clearing ----------

final List<_Painter> _vale = [
  (c, r) {
    _sky(c, ['#2e5a48', '#5f9474', '#b8d49a', '#e8eebc'], [0, 0.35, 0.72, 1]);
    _glow(c, const Offset(240, 200), 170, '#fff4c0', 0.5);
    _glow(c, const Offset(360, 80), 90, '#fff8d8', 0.45);
    paintSunDisc(c, const Offset(360, 80), 1);
  },
  (c, r) => _clouds(c, r, 4, '#f4f8e0', '#b4d0a8', 0.55, yMax: 90),
  (c, r) {
    // Far fan palms fading into the green haze
    for (var i = 0; i < 9; i++) {
      final x = i * W / 9 + r.nextDouble() * 20;
      final y = 95 + r.nextDouble() * 55;
      final rad = 14 + r.nextDouble() * 10;
      final turn = r.nextDouble();
      _wrap((dx) => _fanPalm(c, Offset(x + dx, y), rad, 240 - y, '#6a8a6a', '#7fa88a', '#a4c8a4', tilt: 0.8, turn: turn));
    }
    c.drawPath(_ridge(r, 205, 26, 10), _vgrad(170, 240, ['#5e8c6c', '#7aa47c']));
    _mist(c, 200, 34, '#dcecc0', 0.6);
  },
  (c, r) {
    // Tall fan palms, flowering trees, dark sword plants and leafy bushes
    for (var i = 0; i < 4; i++) {
      final x = i * 120.0 + r.nextDouble() * 40;
      final y = 45 + r.nextDouble() * 40;
      final rad = 26 + r.nextDouble() * 10;
      final turn = r.nextDouble();
      final (crown, spoke) = i.isEven ? ('#4f8a60', '#2f5e40') : ('#2a5a3c', '#5a9a68');
      _wrap((dx) => _fanPalm(c, Offset(x + dx, y), rad, 250 - y, '#b08a48', crown, spoke, tilt: 0.85, turn: turn));
    }
    for (var i = 0; i < 2; i++) {
      final x = i * 240.0 + 60 + r.nextDouble() * 60;
      final seed = r.nextInt(1 << 20);
      _wrap((dx) {
        final rr = math.Random(seed);
        c.drawPath(
            Path()
              ..moveTo(x + dx - 7, 250)
              ..quadraticBezierTo(x + dx - 2, 200, x + dx - 3, 160)
              ..lineTo(x + dx + 3, 160)
              ..quadraticBezierTo(x + dx + 2, 200, x + dx + 9, 250)
              ..close(),
            _fill('#3a2a22'));
        c.drawCircle(Offset(x + dx, 140), 34, _fill('#8a9a3a'));
        c.drawCircle(Offset(x + dx - 12, 132), 20, _fill('#9aaa44'));
        for (var k = 0; k < 9; k++) {
          final a = rr.nextDouble() * math.pi * 2;
          final d = rr.nextDouble() * 30;
          _flower(c, Offset(x + dx, 140) + _dir(a) * d, 5 + rr.nextDouble() * 3, '#f0a890', '#3a2a22', rr.nextDouble());
        }
      });
    }
    for (var i = 0; i < 5; i++) {
      final x = i * 96.0 + r.nextDouble() * 40;
      final seed = r.nextInt(1 << 20);
      final color = r.nextBool() ? '#6aa8a0' : '#1e3a2a';
      _wrap((dx) => _blades(c, math.Random(seed), Offset(x + dx, 252), 60.0 + seed % 30, 9, color));
    }
    for (var i = 0; i < 2; i++) {
      final x = i * 240.0 + 170 + r.nextDouble() * 40;
      final seed = r.nextInt(1 << 20);
      _wrap((dx) => _scaleBush(c, math.Random(seed), Offset(x + dx, 252), 38, 46, '#1e4a2c', '#4a8a4a'));
    }
    // The sunny clearing floor
    c.drawRect(const Rect.fromLTWH(0, 248, W, 22), _vgrad(248, 270, ['#a8a83a', '#8a8a2e']));
    for (var i = 0; i < 60; i++) {
      c.drawOval(Rect.fromLTWH(r.nextDouble() * W, 250 + r.nextDouble() * 18, 3 + r.nextDouble() * 3, 1.4), _fill('#c8c058', 0.7));
    }
  },
  (c, r) {
    // Grass tufts and dark red star flowers at the bottom edge
    final grass = Paint()
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 70; i++) {
      final x = r.nextDouble() * W;
      final h = 5 + r.nextDouble() * 9;
      final lean = (r.nextDouble() - 0.5) * 5;
      grass.color = hex(r.nextBool() ? '#3e5a2a' : '#6a7a34');
      _wrap((dx) => c.drawLine(Offset(x + dx, 270), Offset(x + dx + lean, 270 - h), grass));
    }
    for (var i = 0; i < 4; i++) {
      final x = i * 120.0 + r.nextDouble() * 60;
      final seed = r.nextInt(1 << 20);
      _wrap((dx) {
        final rr = math.Random(seed);
        c.drawOval(Rect.fromCenter(center: Offset(x + dx, 272), width: 60, height: 26), _fill('#1e3a26'));
        for (var k = 0; k < 4; k++) {
          _flower(c, Offset(x + dx - 20 + k * 13 + rr.nextDouble() * 4, 258 + rr.nextDouble() * 8), 9 + rr.nextDouble() * 4, '#8a4a40', '#1a1014', rr.nextDouble());
        }
      });
    }
  },
];

// ---------- Crownhold: domes and towers of the walled capital at dusk ----------

final List<_Painter> _city = [
  (c, r) {
    _sky(c, ['#14204e', '#3e5ca6', '#d8a878', '#f2d8a8'], [0, 0.45, 0.82, 1]);
    paintSunDisc(c, const Offset(360, 80), 1);
  },
  (c, r) => _clouds(c, r, 5, '#f8e0c0', '#7a7aa8', 0.75),
  (c, r) {
    // The skyline: domes on drums and slim towers
    void dome(double x, double base, double w, String color) {
      _wrap((dx) {
        c.drawRect(Rect.fromLTWH(x + dx - w, base - w * 0.8, w * 2, w * 0.8 + 60), _fill(color));
        final d = Path()
          ..moveTo(x + dx - w * 1.05, base - w * 0.8)
          ..cubicTo(x + dx - w * 1.2, base - w * 2.0, x + dx - w * 0.1, base - w * 2.0, x + dx, base - w * 2.6)
          ..cubicTo(x + dx + w * 0.1, base - w * 2.0, x + dx + w * 1.2, base - w * 2.0, x + dx + w * 1.05, base - w * 0.8)
          ..close();
        c.drawPath(d, _fill(color));
      });
    }

    void tower(double x, double base, double h, String color) {
      _wrap((dx) {
        c.drawRect(Rect.fromLTWH(x + dx - 3, base - h, 6, h + 60), _fill(color));
        c.drawRect(Rect.fromLTWH(x + dx - 5, base - h * 0.75, 10, 3), _fill(color));
        c.drawPath(
            Path()
              ..moveTo(x + dx - 4, base - h)
              ..lineTo(x + dx, base - h - 10)
              ..lineTo(x + dx + 4, base - h)
              ..close(),
            _fill(color));
      });
    }

    for (var i = 0; i < 6; i++) {
      final x = i * 80.0 + r.nextDouble() * 30;
      dome(x, 200, 12 + r.nextDouble() * 10, '#6a76a8');
      tower(x + 30, 205, 60 + r.nextDouble() * 30, '#6a76a8');
    }
    _mist(c, 215, 30, '#e8c8a8', 0.6);
  },
  (c, r) {
    // The city wall, crenellated, with lit arches
    final top = 210.0;
    c.drawRect(Rect.fromLTWH(0, top, W, H - top), _vgrad(top, H, ['#8a6a5a', '#5a4038']));
    for (var x = 0.0; x < W; x += 12) {
      c.drawRect(Rect.fromLTWH(x, top - 6, 7, 6), _fill('#8a6a5a'));
    }
    for (var i = 0; i < 6; i++) {
      final x = i * 80.0 + 40;
      final arch = Path()
        ..moveTo(x - 7, 250)
        ..lineTo(x - 7, 232)
        ..quadraticBezierTo(x - 7, 222, x, 219)
        ..quadraticBezierTo(x + 7, 222, x + 7, 232)
        ..lineTo(x + 7, 250)
        ..close();
      c.drawPath(arch, _fill('#2a1a28'));
      _glow(c, Offset(x, 240), 14, '#ffc070', 0.35);
    }
    c.drawRect(Rect.fromLTWH(0, top, W, 2), _fill('#c8a078', 0.6));
  },
  (c, r) {
    for (var i = 0; i < 8; i++) {
      final x = i * 60.0 + r.nextDouble() * 30;
      final h = 50 + r.nextDouble() * 30;
      _wrap((dx) {
        c.drawOval(Rect.fromCenter(center: Offset(x + dx, 270 - h / 2), width: 14, height: h), _fill('#12301f'));
        c.drawOval(Rect.fromCenter(center: Offset(x + dx - 2, 270 - h / 2), width: 6, height: h - 8), _fill('#1f4a32'));
      });
    }
  },
];

// ---------- The Serpent Sands: a canyon of balanced rock pillars ----------

final List<_Painter> _desert = [
  (c, r) {
    _sky(c, ['#3a7ab0', '#8cc0d8', '#f0d8a8', '#f8e8c8'], [0, 0.4, 0.8, 1]);
    paintSunDisc(c, const Offset(360, 80), 1);
  },
  (c, r) => _clouds(c, r, 4, '#ffffff', '#d8c8b0', 0.7, yMax: 80),
  (c, r) {
    // Flat-topped mesas, pale in the heat
    for (var i = 0; i < 4; i++) {
      final x = i * 120.0 + r.nextDouble() * 40;
      final w = 30 + r.nextDouble() * 30;
      final h = 50 + r.nextDouble() * 40;
      _wrap((dx) {
        final p = Path()
          ..moveTo(x + dx - w - 14, 240)
          ..lineTo(x + dx - w, 200 - h)
          ..lineTo(x + dx + w, 200 - h)
          ..lineTo(x + dx + w + 14, 240)
          ..close();
        c.drawPath(p, _vgrad(200 - h, 240, ['#e0c098', '#d8b890']));
      });
    }
    _mist(c, 215, 30, '#f8e8c8', 0.8);
  },
  (c, r) {
    // Stacks of rounded boulders, lit from the left
    for (var i = 0; i < 4; i++) {
      final x = i * 120.0 + 50 + r.nextDouble() * 30;
      var y = 250.0;
      var w = 26 + r.nextDouble() * 10;
      final stones = 3 + r.nextInt(3);
      for (var k = 0; k < stones; k++) {
        final h = 22 + r.nextDouble() * 14;
        final ox = (r.nextDouble() - 0.5) * 8;
        final box = Rect.fromLTWH(x + ox - w, y - h, w * 2, h);
        _wrap((dx) {
          final rr = RRect.fromRectAndRadius(box.shift(Offset(dx, 0)), Radius.circular(h * 0.45));
          final p = Path()..addRRect(rr);
          _shape(c, p, box, ['#e8a858', '#b87038', '#8a4e28'], rim: '#ffe0a0', rimA: 0.8);
          c.drawLine(Offset(box.left + dx + 6, y - 4), Offset(box.right + dx - 6, y - 4), _fill('#6a3a1e', 0.4)..strokeWidth = 1.5);
        });
        y -= h - 2;
        w *= 0.82 + r.nextDouble() * 0.2;
      }
    }
  },
  (c, r) {
    // Dark canyon walls at the edges of the view
    for (var i = 0; i < 2; i++) {
      final x = i * 240.0 + r.nextDouble() * 40;
      _wrap((dx) {
        final p = Path()..moveTo(x + dx - 50, 270);
        for (var k = 0; k <= 6; k++) {
          p.lineTo(x + dx - 40 + k * 14 + (k.isEven ? 0 : 6), 270 - 60 - math.sin(k / 6 * math.pi) * 50 + r.nextDouble() * 10);
        }
        p
          ..lineTo(x + dx + 60, 270)
          ..close();
        _shape(c, p, const Rect.fromLTWH(0, 160, 0, 110), ['#7a4a2e', '#3a2418'], rim: '#d89858', rimA: 0.5);
      });
    }
  },
];

// ---------- Sky Spine & Frostwood: jagged peaks in mist, and a demon carved in the rock ----------

final List<_Painter> _mountain = [
  (c, r) {
    _sky(c, ['#7a9a98', '#b8ccc4', '#e4ece0', '#f0f2e8'], [0, 0.4, 0.8, 1]);
    paintSunDisc(c, const Offset(360, 80), 1);
  },
  (c, r) => _clouds(c, r, 6, '#ffffff', '#b8c8c8', 0.65),
  (c, r) {
    final p = _ridge(r, 190, 110, 14, sharp: true);
    c.drawPath(p, _vgrad(80, 240, ['#a8b8b8', '#c8d4d0']));
    // Snow on the peaks
    c.save();
    c.clipPath(p);
    c.drawRect(const Rect.fromLTWH(0, 0, W, 125), _fill('#ffffff', 0.75));
    c.restore();
    _mist(c, 200, 40, '#eef4f0', 0.85);
  },
  (c, r) {
    final p = _ridge(r, 225, 90, 9, sharp: true);
    _shape(c, p, const Rect.fromLTWH(0, 130, 0, 140), ['#6a7a80', '#3e4a50'], rim: '#dce8ec', rimA: 0.7);
    // The demon's face, hewn into the mountain long ago, its eyes still glowing
    const fx = 330.0, fy = 200.0;
    final face = Path()
      ..moveTo(fx - 42, 270)
      ..lineTo(fx - 46, fy - 10)
      ..lineTo(fx - 30, fy - 46)
      ..lineTo(fx - 18, fy - 40)
      ..lineTo(fx, fy - 58)
      ..lineTo(fx + 18, fy - 40)
      ..lineTo(fx + 30, fy - 46)
      ..lineTo(fx + 46, fy - 10)
      ..lineTo(fx + 42, 270)
      ..close();
    _shape(c, face, const Rect.fromLTWH(0, fy - 58, 0, 128), ['#4e5a5e', '#2a3236'], rim: '#a8b8bc', rimA: 0.5);
    for (final s in [-1.0, 1.0]) {
      final eye = Path()
        ..moveTo(fx + s * 8, fy - 22)
        ..lineTo(fx + s * 24, fy - 28)
        ..lineTo(fx + s * 20, fy - 18)
        ..close();
      c.drawPath(eye, _fill('#1a1416'));
      _glow(c, Offset(fx + s * 17, fy - 22), 12, '#ff5020', 0.6);
      c.drawCircle(Offset(fx + s * 17, fy - 22), 2.5, _fill('#ff8a3a'));
    }
    // The open mouth, a cave lined with fangs
    final mouth = Path()
      ..moveTo(fx - 26, 270)
      ..lineTo(fx - 26, fy + 8)
      ..quadraticBezierTo(fx, fy - 6, fx + 26, fy + 8)
      ..lineTo(fx + 26, 270)
      ..close();
    c.drawPath(mouth, _vgrad(fy, 270, ['#0e0c10', '#2a2a30']));
    for (var k = 0; k < 6; k++) {
      final tx = fx - 22 + k * 8.8;
      c.drawPath(
          Path()
            ..moveTo(tx - 3, fy + 4 - (k == 0 || k == 5 ? -4 : 0))
            ..lineTo(tx, fy + 14)
            ..lineTo(tx + 3, fy + 4 - (k == 0 || k == 5 ? -4 : 0))
            ..close(),
          _fill('#5a6468'));
    }
    _mist(c, 250, 22, '#e0eae8', 0.6);
  },
  (c, r) {
    // Sharp dark shards in front, with wisps of mist
    for (var i = 0; i < 6; i++) {
      final x = i * 80.0 + r.nextDouble() * 40;
      final h = 30 + r.nextDouble() * 40;
      _wrap((dx) {
        final p = Path()
          ..moveTo(x + dx - 16, 270)
          ..lineTo(x + dx - 4, 270 - h)
          ..lineTo(x + dx + 4, 270 - h * 0.8)
          ..lineTo(x + dx + 18, 270)
          ..close();
        _shape(c, p, Rect.fromLTWH(0, 270 - h, 0, h), ['#4a5458', '#22282c'], rim: '#c8d8dc', rimA: 0.5);
      });
    }
    _mist(c, 262, 14, '#ffffff', 0.4);
  },
];

// ---------- The Duskland: endless grass under a red evening, and the Khan's tents ----------

final List<_Painter> _steppe = [
  (c, r) {
    _sky(c, ['#2a1e4a', '#7a3e6a', '#e07a5a', '#f8c070'], [0, 0.4, 0.75, 1]);
    _glow(c, const Offset(150, 220), 160, '#ffd080', 0.5);
    paintSunDisc(c, const Offset(360, 80), 1);
  },
  (c, r) => _clouds(c, r, 6, '#f8a080', '#5a2e5a', 0.7, yMax: 120),
  (c, r) {
    c.drawPath(_ridge(r, 215, 20, 6), _vgrad(190, 240, ['#7a4a6a', '#a06070']));
    _mist(c, 220, 20, '#f8b080', 0.6);
  },
  (c, r) {
    c.drawPath(_ridge(r, 235, 25, 5), _vgrad(205, 270, ['#9a6a3a', '#6a4428']));
    // Round felt tents with smoke holes and banners
    for (var i = 0; i < 3; i++) {
      final x = i * 160.0 + 40 + r.nextDouble() * 60;
      const y = 232.0;
      _wrap((dx) {
        final tent = Path()
          ..moveTo(x + dx - 16, y)
          ..lineTo(x + dx - 16, y - 10)
          ..quadraticBezierTo(x + dx, y - 26, x + dx + 16, y - 10)
          ..lineTo(x + dx + 16, y)
          ..close();
        _shape(c, tent, const Rect.fromLTWH(0, y - 26, 0, 26), ['#e8d0a8', '#a88860'], rim: '#fff0d0');
        c.drawRect(Rect.fromLTWH(x + dx - 3, y - 9, 6, 9), _fill('#3a2018'));
        c.drawLine(Offset(x + dx + 22, y), Offset(x + dx + 22, y - 34), _fill('#3a2a1a')..strokeWidth = 1);
        c.drawPath(
            Path()
              ..moveTo(x + dx + 22, y - 34)
              ..lineTo(x + dx + 34, y - 30)
              ..lineTo(x + dx + 22, y - 26)
              ..close(),
            _fill('#c83a3a'));
      });
    }
  },
  (c, r) {
    // Tall grass waving in the foreground
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 90; i++) {
      final x = r.nextDouble() * W;
      final h = 14 + r.nextDouble() * 26;
      final lean = (r.nextDouble() - 0.3) * 10;
      paint
        ..strokeWidth = 1 + r.nextDouble() * 1.5
        ..color = hex(r.nextBool() ? '#5a4a22' : '#8a7a3a');
      _wrap((dx) => c.drawPath(
          Path()
            ..moveTo(x + dx, 270)
            ..quadraticBezierTo(x + dx, 270 - h * 0.6, x + dx + lean, 270 - h),
          paint));
    }
  },
];

// ---------- The Marble West: a turquoise sea, white cliffs and olive trees ----------

final List<_Painter> _coast = [
  (c, r) {
    _sky(c, ['#2a7ac0', '#7ac0e0', '#d8f0f0', '#f0f8f0'], [0, 0.45, 0.8, 1]);
    paintSunDisc(c, const Offset(360, 80), 1);
  },
  (c, r) => _clouds(c, r, 5, '#ffffff', '#c0d8e8', 0.85),
  (c, r) {
    // The sea, with glints, and a far white town on a headland
    c.drawRect(const Rect.fromLTWH(0, 200, W, 70), _vgrad(200, 270, ['#7ad0d0', '#2bb3a8', '#1a7a8a']));
    for (var i = 0; i < 40; i++) {
      c.drawRect(Rect.fromLTWH(r.nextDouble() * W, 203 + r.nextDouble() * 40, 4 + r.nextDouble() * 6, 0.8), _fill('#ffffff', 0.6));
    }
    final x = 120 + r.nextDouble() * 200;
    _wrap((dx) {
      c.drawPath(
          Path()
            ..moveTo(x + dx - 70, 201)
            ..quadraticBezierTo(x + dx - 30, 170, x + dx + 10, 172)
            ..quadraticBezierTo(x + dx + 50, 175, x + dx + 80, 201)
            ..close(),
          _fill('#d8d4c8'));
      for (var k = 0; k < 7; k++) {
        c.drawRect(Rect.fromLTWH(x + dx - 30 + k * 9, 168 - (k % 3) * 4, 7, 8), _fill('#f8f8f0'));
      }
    });
    _mist(c, 200, 8, '#ffffff', 0.5);
  },
  (c, r) {
    // White cliffs with little houses on top
    for (var i = 0; i < 2; i++) {
      final x = i * 240.0 + r.nextDouble() * 60;
      _wrap((dx) {
        final p = Path()
          ..moveTo(x + dx - 70, 270)
          ..lineTo(x + dx - 60, 210)
          ..quadraticBezierTo(x + dx - 20, 196, x + dx + 30, 200)
          ..lineTo(x + dx + 55, 225)
          ..lineTo(x + dx + 70, 270)
          ..close();
        _shape(c, p, const Rect.fromLTWH(0, 196, 0, 74), ['#f4f0e4', '#b8b0a0'], rim: '#ffffff', rimA: 0.9);
        for (var k = 0; k < 4; k++) {
          final hx = x + dx - 40 + k * 16;
          c.drawRect(Rect.fromLTWH(hx, 190 - (k % 2) * 3, 12, 10), _fill('#fcfcf8'));
          c.drawRect(Rect.fromLTWH(hx + 4, 195 - (k % 2) * 3, 3, 5), _fill('#2a5aa8'));
        }
      });
    }
  },
  (c, r) {
    // Silver-green olive trees
    for (var i = 0; i < 4; i++) {
      final x = i * 120.0 + r.nextDouble() * 50;
      final seed = r.nextInt(1 << 20);
      _wrap((dx) {
        c.drawPath(
            Path()
              ..moveTo(x + dx - 4, 270)
              ..quadraticBezierTo(x + dx + 6, 250, x + dx - 2, 232)
              ..lineTo(x + dx + 3, 232)
              ..quadraticBezierTo(x + dx + 12, 250, x + dx + 5, 270)
              ..close(),
            _fill('#4a3a2a'));
        _crown(c, seed, Offset(x + dx, 226), 20, '#3a4a30', '#6a7a4a', '#a8b880');
      });
    }
  },
];

// ---------- The Lightless Land: a moonlit waste of dead trees and old stones ----------

// A twisted branch that ends in a curl
void _branch(Canvas c, math.Random r, Offset from, double angle, double len, double width, int depth, Paint paint) {
  final bend = (r.nextDouble() - 0.5) * 0.9;
  final to = from + Offset(math.cos(angle), math.sin(angle)) * len;
  final ctrl = from + Offset(math.cos(angle + bend), math.sin(angle + bend)) * len * 0.6;
  paint.strokeWidth = width;
  c.drawPath(
      Path()
        ..moveTo(from.dx, from.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, to.dx, to.dy),
      paint);
  if (depth == 0) {
    // the curl at the tip
    paint.strokeWidth = math.max(0.8, width * 0.7);
    final dir = r.nextBool() ? 1.0 : -1.0;
    c.drawArc(Rect.fromCircle(center: to + Offset(math.cos(angle + dir * 1.57), math.sin(angle + dir * 1.57)) * 3, radius: 3), angle + dir * 1.57 + math.pi,
        dir * 4.5, false, paint);
    return;
  }
  final n = 2 + (r.nextDouble() < 0.3 ? 1 : 0);
  for (var k = 0; k < n; k++) {
    _branch(c, r, to, angle + (r.nextDouble() - 0.5) * 1.6, len * (0.55 + r.nextDouble() * 0.2), width * 0.6, depth - 1, paint);
  }
}

final List<_Painter> _dark = [
  (c, r) {
    _sky(c, ['#06161c', '#0f3a40', '#1f6a6a', '#3a8a80'], [0, 0.4, 0.8, 1]);
    for (var i = 0; i < 60; i++) {
      c.drawCircle(Offset(r.nextDouble() * W, r.nextDouble() * 120), 0.5 + r.nextDouble() * 0.6, _fill('#d8fff0', 0.3 + r.nextDouble() * 0.5));
    }
    // No sun here: a pale moon hangs where the sun would be
    _glow(c, const Offset(360, 80), 70, '#c8fff0', 0.35);
    c.drawCircle(const Offset(360, 80), 20, Paint()..shader = Gradient.radial(const Offset(354, 74), 24, [hex('#ffffff'), hex('#c8f0e8')]));
  },
  (c, r) => _clouds(c, r, 5, '#4a9a90', '#0c2a30', 0.8, yMax: 130),
  (c, r) {
    // Old round towers of the dead and broken walls on the horizon
    c.drawPath(_ridge(r, 220, 12, 6), _fill('#14403e'));
    for (var i = 0; i < 4; i++) {
      final x = i * 120.0 + r.nextDouble() * 60;
      final h = 26 + r.nextDouble() * 30;
      _wrap((dx) {
        c.drawRect(Rect.fromLTWH(x + dx - 14, 215 - h, 28, h + 10), _fill('#14403e'));
        for (var k = 0; k < 4; k++) {
          c.drawRect(Rect.fromLTWH(x + dx - 14 + k * 8, 211 - h - (k.isEven ? 0 : 2), 5, 4), _fill('#14403e'));
        }
        c.drawRect(Rect.fromLTWH(x + dx + 20, 205, 30, 15), _fill('#14403e'));
      });
    }
    _mist(c, 222, 22, '#4aa098', 0.55);
  },
  (c, r) {
    // Dead trees with curling branches
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = hex('#081e22');
    for (var i = 0; i < 3; i++) {
      final x = i * 160.0 + r.nextDouble() * 80;
      final seed = r.nextInt(1 << 20);
      _wrap((dx) {
        final rr = math.Random(seed);
        final trunk = Path()
          ..moveTo(x + dx - 12, 270)
          ..quadraticBezierTo(x + dx - 2, 220, x + dx - 6, 170)
          ..lineTo(x + dx + 4, 170)
          ..quadraticBezierTo(x + dx + 4, 220, x + dx + 14, 270)
          ..close();
        c.drawPath(trunk, _fill('#081e22'));
        for (var k = 0; k < 4; k++) {
          _branch(c, rr, Offset(x + dx - 1, 172 + k * 8), -math.pi / 2 + (k - 1.5) * 0.7, 26 + rr.nextDouble() * 10, 4, 3, paint);
        }
      });
    }
    _mist(c, 255, 20, '#3a8a80', 0.45);
  },
  (c, r) {
    // Leaning stones, skulls and a broken fence
    for (var i = 0; i < 6; i++) {
      final x = i * 80.0 + r.nextDouble() * 40;
      final h = 14 + r.nextDouble() * 12;
      final lean = (r.nextDouble() - 0.5) * 0.3;
      _wrap((dx) {
        c.save();
        c.translate(x + dx, 270);
        c.rotate(lean);
        final stone = Path()..addRRect(RRect.fromRectAndCorners(Rect.fromLTWH(-7, -h, 14, h + 4), topLeft: const Radius.circular(7), topRight: const Radius.circular(7)));
        _shape(c, stone, Rect.fromLTWH(0, -h, 0, h), ['#5a7a78', '#2a3e40'], rim: '#a8d8d0', rimA: 0.5);
        c.restore();
        final sx = x + dx + 14;
        c.drawCircle(Offset(sx, 266), 3.2, _fill('#c8d8d0'));
        c.drawCircle(Offset(sx - 1.2, 265.5), 0.9, _fill('#0a1a1c'));
        c.drawCircle(Offset(sx + 1.2, 265.5), 0.9, _fill('#0a1a1c'));
      });
    }
    final fence = Paint()
      ..color = hex('#0a2226')
      ..strokeWidth = 1.5;
    for (var x = 0.0; x < W; x += 9) {
      if ((x ~/ 9) % 7 == 3) continue;
      c.drawLine(Offset(x, 270), Offset(x + ((x ~/ 9) % 3 - 1) * 1.5, 248 + (x ~/ 9) % 4 * 2), fence);
    }
    c.drawLine(const Offset(0, 256), const Offset(W, 258), fence);
  },
];

// ---------- Underground: a cavern of hanging stone and glowing crystals ----------

final List<_Painter> _underground = [
  (c, r) {
    _sky(c, ['#0e0a0c', '#22181a', '#2e2222', '#1a1214'], [0, 0.4, 0.7, 1]);
    // A shaft of pale light from a crack far above
    c.drawPath(
        Path()
          ..moveTo(200, 0)
          ..lineTo(230, 0)
          ..lineTo(300, 270)
          ..lineTo(220, 270)
          ..close(),
        _vgrad(0, 270, ['#fff0c8', '#fff0c8'])..color = const Color(0x18ffffff));
    _glow(c, const Offset(250, 140), 120, '#ffe8b0', 0.08);
  },
  (c, r) {
    // Drifting dust specks
    for (var i = 0; i < 70; i++) {
      c.drawCircle(Offset(r.nextDouble() * W, r.nextDouble() * H), 0.4 + r.nextDouble() * 0.7, _fill('#ffe0b0', 0.15 + r.nextDouble() * 0.3));
    }
  },
  (c, r) {
    // The far cave wall: stalactites above, stalagmites below
    c.drawPath(_ridge(r, 60, -40, 14, sharp: true, bottom: 0), _vgrad(0, 110, ['#3a2a26', '#4a3630']));
    c.drawPath(_ridge(r, 235, 50, 12, sharp: true), _vgrad(180, 270, ['#4a3630', '#2a1e1c']));
    _mist(c, 200, 30, '#6a4a3a', 0.3);
  },
  (c, r) {
    // Rock columns and clusters of glowing crystals
    for (var i = 0; i < 3; i++) {
      final x = i * 160.0 + r.nextDouble() * 60;
      final w = 12 + r.nextDouble() * 8;
      _wrap((dx) {
        final col = Path()
          ..moveTo(x + dx - w * 1.6, 0)
          ..quadraticBezierTo(x + dx - w * 0.6, 135, x + dx - w * 1.6, 270)
          ..lineTo(x + dx + w * 1.6, 270)
          ..quadraticBezierTo(x + dx + w * 0.6, 135, x + dx + w * 1.6, 0)
          ..close();
        _shape(c, col, const Rect.fromLTWH(0, 0, 0, 270), ['#2e2220', '#4a3a32', '#2a1e1c'], rim: '#8a6a50', rimA: 0.35);
      });
    }
    for (var i = 0; i < 5; i++) {
      final x = i * 96.0 + r.nextDouble() * 50;
      final y = r.nextBool() ? 250.0 : 230.0 + r.nextDouble() * 20;
      _wrap((dx) {
        _glow(c, Offset(x + dx, y - 8), 34, '#2bb3a8', 0.35);
        for (var k = 0; k < 4; k++) {
          final a = -math.pi / 2 + (k - 1.5) * 0.4;
          final len = 10 + (k == 1 || k == 2 ? 8 : 0) + r.nextDouble() * 4;
          final tip = Offset(x + dx + math.cos(a) * len, y + math.sin(a) * len);
          final side = Offset(math.cos(a + 1.57), math.sin(a + 1.57)) * 2.5;
          final p = Path()
            ..moveTo(x + dx + side.dx, y + side.dy)
            ..lineTo(tip.dx, tip.dy)
            ..lineTo(x + dx - side.dx, y - side.dy)
            ..close();
          c.drawPath(p, Paint()..shader = Gradient.linear(Offset(x + dx, y), tip, [hex('#1a7a7a'), hex('#a8fff0')]));
        }
      });
    }
  },
  (c, r) {
    // Dark rocks hanging into the view and heaped below
    c.drawPath(_ridge(r, 22, -26, 8, sharp: true, bottom: 0), _fill('#120c0c'));
    c.drawPath(_ridge(r, 262, 22, 7), _fill('#120c0c'));
  },
];

final Map<RealmTheme, List<_Painter>> _realms = {
  RealmTheme.vale: _vale,
  RealmTheme.city: _city,
  RealmTheme.desert: _desert,
  RealmTheme.mountain: _mountain,
  RealmTheme.steppe: _steppe,
  RealmTheme.coast: _coast,
  RealmTheme.dark: _dark,
};

// ---------- Moving things ----------

// Big jungle leaves rising from the bottom edge, swaying in a slow breeze
void _valeLeaves(Canvas c, double t) {
  const leaves = [
    // x, lean, length, width, fill, vein
    (24.0, -0.5, 62.0, 28.0, '#2e6a44', '#173a26'),
    (44.0, -0.15, 48.0, 22.0, '#d8c890', '#6a7a40'),
    (210.0, 0.35, 56.0, 25.0, '#3a7a50', '#1a4228'),
    (330.0, -0.3, 44.0, 20.0, '#2e6a44', '#173a26'),
    (452.0, 0.45, 60.0, 27.0, '#d8c890', '#6a7a40'),
  ];
  for (final (k, (x, lean, len, w, fill, vein)) in leaves.indexed) {
    final sway = math.sin(t * 1.1 + k * 1.7) * 0.07 + math.sin(t * 2.3 + k) * 0.02;
    _leaf(c, Offset(x, 274), -math.pi / 2 + lean + sway, len, w, fill, vein: vein, slits: 5);
  }
}

// Butterflies flitting across the clearing, wings beating
void _valeButterflies(Canvas c, double t) {
  const colors = [('#f0a890', '#c86a5a'), ('#f8d870', '#c89a30'), ('#f0a890', '#c86a5a'), ('#ffffff', '#b8c8a8')];
  for (final (k, (wing, edge)) in colors.indexed) {
    final x = (k * 120 + 40 + t * (9 + k * 2) + math.sin(t * 0.8 + k) * 20) % W;
    final y = 170 + math.sin(t * 0.6 + k * 2.1) * 35 + math.sin(t * 5 + k) * 3;
    final beat = 0.25 + 0.75 * math.sin(t * 16 + k * 2).abs();
    c.save();
    c.translate(x, y);
    c.scale(beat, 1);
    for (final s in [-1.0, 1.0]) {
      c.drawOval(Rect.fromCenter(center: Offset(s * 3, -1.5), width: 6, height: 5), _fill(edge));
      c.drawOval(Rect.fromCenter(center: Offset(s * 3, -1.5), width: 4.4, height: 3.6), _fill(wing));
      c.drawOval(Rect.fromCenter(center: Offset(s * 2.2, 2), width: 3.6, height: 3), _fill(wing));
    }
    c.restore();
    c.drawLine(Offset(x, y - 2.5), Offset(x, y + 2.5), _fill('#2a1a14')..strokeWidth = 0.8);
  }
}

final Map<RealmTheme, Map<int, BackdropLive>> _live = {
  RealmTheme.vale: {3: _valeButterflies, 4: _valeLeaves},
};
