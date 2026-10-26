// Everything that makes a level feel alive without affecting play:
// grass that sways and parts around feet, weather motes for each realm, sun rays,
// glowing lights, and darkness in caves and the Lightless Land.

import 'dart:math' as math;
import 'dart:ui';

import '../art/pixel.dart' show rng, hex;
import '../config.dart';
import '../levels/build.dart';
import '../world/world.dart';

class Light {
  const Light(this.x, this.y, this.r, this.color, [this.intensity = 1]);
  final double x, y, r;
  final int color;
  final double intensity;
}

// Something that bends grass: a position and how fast it moves
typedef Pusher = (double x, double y, double vx);

class _Blade {
  _Blade(this.dx, this.h, this.color, this.flower);
  final double dx, h;
  final Color color;
  final Color? flower;
}

class _Tuft {
  _Tuft(this.x, this.y, this.blades, this.phase);
  final double x, y, phase;
  final List<_Blade> blades;
  double bend = 0; // radians, springs back to the wind
  double vel = 0;
}

enum _MoteKind { pollen, firefly, dust, sand, snow, leaf, ember, spray }

class _Mote {
  _Mote(this.kind, this.x, this.y, this.vx, this.vy, this.size, this.color, this.phase);
  final _MoteKind kind;
  double x, y, vx, vy;
  final double size, phase;
  final Color color;
}

class _Look {
  const _Look(this.grass, this.flowers, this.motes, {this.rays = 0.06, this.rayColor = 0xfffff0c8});
  final List<String> grass;
  final List<String> flowers;
  final List<(_MoteKind, int)> motes; // kind and how many on screen
  final double rays; // sun ray strength, 0 = none
  final int rayColor;
}

const _looks = {
  RealmTheme.vale: _Look(['#5aa04a', '#8ad06a', '#3f7a34'], ['#e85a7a', '#f0d060', '#ffffff'], [(_MoteKind.pollen, 22), (_MoteKind.firefly, 6)]),
  RealmTheme.city: _Look(['#5aa04a', '#7cbc5c', '#3f7a34'], ['#f0d060'], [(_MoteKind.dust, 22)], rays: 0.05),
  RealmTheme.desert:
      _Look(['#c8a050', '#e0c070', '#a07a38'], [], [(_MoteKind.sand, 34), (_MoteKind.dust, 8)], rays: 0.09, rayColor: 0xffffe0a0),
  RealmTheme.mountain: _Look(['#a8c8c0', '#d8e8e8', '#7a9a98'], [], [(_MoteKind.snow, 70)], rays: 0.04, rayColor: 0xffe0f0ff),
  RealmTheme.steppe: _Look(['#c0a040', '#d8c060', '#8a7a30'], ['#d83a3a'], [(_MoteKind.leaf, 18), (_MoteKind.pollen, 10)], rays: 0.06),
  RealmTheme.coast: _Look(['#6ab07a', '#9ad08a', '#4a8a5a'], ['#ffffff', '#8ae0d8'], [(_MoteKind.spray, 20), (_MoteKind.pollen, 8)]),
  RealmTheme.dark: _Look(['#4a4658', '#6a6478', '#3a3648'], [], [(_MoteKind.ember, 30)], rays: 0),
};

class Ambience {
  Ambience(this.level, this.theme, {this.cave = false}) : _look = _looks[theme]! {
    _plantGrass();
  }

  final Level level;
  final RealmTheme theme;
  final bool cave;
  final _Look _look;
  final _tufts = <_Tuft>[];
  final _motes = <_Mote>[];
  final _r = math.Random(5);
  double t = 0;

  bool get dark => theme == RealmTheme.dark || cave;
  double get rays => cave ? 0 : _look.rays;
  int get rayColor => _look.rayColor;

  // A few tufts on every grass tile with open air above it; the level width seeds the layout
  void _plantGrass() {
    final r = rng(level.cols * 31 + level.rows);
    final colors = _look.grass.map(hex).toList();
    final flowers = _look.flowers.map(hex).toList();
    for (var ty = 1; ty < level.rows; ty++) {
      for (var tx = 0; tx < level.cols; tx++) {
        if (level.data[ty][tx] != T.grass || level.data[ty - 1][tx] != T.empty) continue;
        final n = 1 + (r() * 2.4).floor();
        for (var i = 0; i < n; i++) {
          final blades = <_Blade>[];
          final count = 2 + (r() * 3).floor();
          for (var b = 0; b < count; b++) {
            final flower = flowers.isNotEmpty && r() < 0.12 ? flowers[(r() * flowers.length).floor()] : null;
            blades.add(_Blade(b - count / 2 + r() * 0.8, 2 + r() * (cave ? 2 : 4), colors[(r() * colors.length).floor()], flower));
          }
          _tufts.add(_Tuft(tx * tile + 2 + r() * 12, ty * tile.toDouble(), blades, r() * 6));
        }
      }
    }
  }

  double _wind(double x) => math.sin(t * 1.6 + x * 0.05) * 0.18 + math.sin(t * 0.7 + x * 0.013) * 0.1;

  void update(double dt, Rect view, List<Pusher> pushers) {
    final s = dt / 1000;
    t += s;
    // Grass: a damped spring towards the wind, shoved aside by anything walking through it
    final near = view.inflate(20);
    for (final g in _tufts) {
      if (g.x < near.left || g.x > near.right) continue;
      var target = _wind(g.x + g.phase);
      for (final (px, py, vx) in pushers) {
        final dx = g.x - px;
        if (dx.abs() < 9 && (g.y - py).abs() < 7) {
          target += (dx == 0 ? vx.sign : dx.sign) * 0.9 * (1 - dx.abs() / 9) + vx * 0.002;
        }
      }
      g.vel += ((target - g.bend) * 90 - g.vel * 9) * s;
      g.bend += g.vel * s;
    }
    _updateMotes(s, view);
  }

  void _updateMotes(double s, Rect view) {
    final want = _look.motes.fold<int>(0, (a, m) => a + m.$2);
    if (_motes.length < want) {
      for (final (kind, n) in _look.motes) {
        final have = _motes.where((m) => m.kind == kind).length;
        for (var i = have; i < n; i++) {
          _motes.add(_spawn(kind, view, anywhere: true));
        }
      }
    }
    final area = view.inflate(24);
    for (var i = 0; i < _motes.length; i++) {
      final m = _motes[i];
      switch (m.kind) {
        case _MoteKind.pollen || _MoteKind.dust || _MoteKind.spray:
          m.x += (m.vx + math.sin(t * 0.9 + m.phase) * 4) * s;
          m.y += (m.vy + math.cos(t * 1.3 + m.phase) * 3) * s;
        case _MoteKind.firefly:
          m.x += math.sin(t * 0.8 + m.phase) * 9 * s;
          m.y += math.cos(t * 1.1 + m.phase * 1.7) * 7 * s;
        case _MoteKind.snow:
          m.x += (m.vx + math.sin(t * 1.5 + m.phase) * 8) * s;
          m.y += m.vy * s;
        case _MoteKind.sand:
          m.x += m.vx * s;
          m.y += (m.vy + math.sin(t * 3 + m.phase) * 6) * s;
        case _MoteKind.leaf:
          m.x += (m.vx + math.sin(t * 2 + m.phase) * 12) * s;
          m.y += (m.vy + math.cos(t * 2.4 + m.phase) * 6) * s;
        case _MoteKind.ember:
          m.x += (m.vx + math.sin(t * 2 + m.phase) * 6) * s;
          m.y += m.vy * s;
      }
      if (!area.contains(Offset(m.x, m.y))) _motes[i] = _spawn(m.kind, view);
    }
  }

  // New motes enter from the side they drift in from, so the screen never empties or floods
  _Mote _spawn(_MoteKind kind, Rect view, {bool anywhere = false}) {
    double x = view.left + _r.nextDouble() * view.width;
    double y = view.top + _r.nextDouble() * view.height;
    double vx = 0, vy = 0, size = 1;
    var color = const Color(0xffffffff);
    final ph = _r.nextDouble() * 10;
    switch (kind) {
      case _MoteKind.pollen:
        vx = 4 + _r.nextDouble() * 6;
        vy = -2 + _r.nextDouble() * 3;
        color = const Color(0xfffff6c8);
        if (!anywhere) x = view.left - 10;
      case _MoteKind.dust:
        vx = 2 + _r.nextDouble() * 3;
        vy = -1;
        color = const Color(0xfff0dcb0);
        if (!anywhere) x = view.left - 10;
      case _MoteKind.spray:
        vx = 3;
        vy = -6 - _r.nextDouble() * 4;
        color = const Color(0xffc8f0f0);
        if (!anywhere) y = view.bottom + 10;
      case _MoteKind.firefly:
        size = 1.4;
        color = const Color(0xffffe070);
        y = view.top + view.height * (0.4 + _r.nextDouble() * 0.55);
      case _MoteKind.snow:
        vx = -6 - _r.nextDouble() * 6;
        vy = 14 + _r.nextDouble() * 16;
        size = _r.nextDouble() < 0.3 ? 2 : 1;
        if (!anywhere) y = view.top - 10;
      case _MoteKind.sand:
        vx = 90 + _r.nextDouble() * 60;
        vy = _r.nextDouble() * 6 - 3;
        size = 2;
        color = const Color(0xffe8c888);
        if (!anywhere) x = view.left - 10;
      case _MoteKind.leaf:
        vx = 10 + _r.nextDouble() * 10;
        vy = 8 + _r.nextDouble() * 8;
        size = 2;
        color = [const Color(0xffd88a30), const Color(0xffc8a040), const Color(0xffa04a20)][_r.nextInt(3)];
        if (!anywhere) {
          x = view.left - 10 + _r.nextDouble() * view.width * 0.5;
          y = view.top - 10;
        }
      case _MoteKind.ember:
        vx = _r.nextDouble() * 6 - 3;
        vy = -8 - _r.nextDouble() * 10;
        size = 1.2;
        color = [const Color(0xffff8a40), const Color(0xffffc060), const Color(0xffd84030)][_r.nextInt(3)];
        if (!anywhere) y = view.bottom + 10;
    }
    return _Mote(kind, x, y, vx, vy, size, color, ph);
  }

  // ---------- Rendering ----------

  final _blade = Paint()
    ..isAntiAlias = false
    ..strokeWidth = 1
    ..strokeCap = StrokeCap.square;

  void renderGrass(Canvas c, Rect view) {
    final dot = Paint()..isAntiAlias = false;
    for (final g in _tufts) {
      if (g.x < view.left - 6 || g.x > view.right + 6 || g.y < view.top || g.y > view.bottom + 8) continue;
      for (final b in g.blades) {
        final x0 = g.x + b.dx;
        final lean = g.bend * (0.8 + b.h * 0.06);
        final tip = Offset(x0 + math.sin(lean) * b.h, g.y - math.cos(lean) * b.h);
        _blade.color = b.color;
        c.drawLine(Offset(x0, g.y), tip, _blade);
        if (b.flower != null) {
          dot.color = b.flower!;
          c.drawRect(Rect.fromCenter(center: tip, width: 1.4, height: 1.4), dot);
        }
      }
    }
  }

  void renderMotes(Canvas c) {
    final p = Paint()..isAntiAlias = false;
    final glow = Paint()..blendMode = BlendMode.plus;
    for (final m in _motes) {
      switch (m.kind) {
        case _MoteKind.firefly || _MoteKind.ember:
          final blink = m.kind == _MoteKind.firefly ? (0.5 + 0.5 * math.sin(t * 3 + m.phase * 4)).clamp(0.0, 1.0) : 0.8;
          // A soft radial halo (a flat disc reads as a bubble against a bright sky), then a hot core
          final o = Offset(m.x, m.y);
          final r = m.size * (dark ? 3 : 2);
          glow.shader = Gradient.radial(o, r, [m.color.withValues(alpha: 0.3 * blink), m.color.withValues(alpha: 0)]);
          c.drawCircle(o, r, glow);
          glow
            ..shader = null
            ..color = m.color.withValues(alpha: blink);
          c.drawCircle(o, m.size * 0.6, glow);
        case _MoteKind.sand:
          p.color = m.color.withValues(alpha: 0.7);
          c.drawRect(Rect.fromLTWH(m.x, m.y, m.size * 2, 0.8), p);
        case _MoteKind.leaf:
          c.save();
          c.translate(m.x, m.y);
          c.rotate(t * 3 + m.phase);
          p.color = m.color;
          c.drawRect(const Rect.fromLTWH(-1, -0.5, 2.2, 1.1), p);
          c.restore();
        default:
          p.color = m.color.withValues(alpha: m.kind == _MoteKind.snow ? 0.9 : 0.6);
          c.drawRect(Rect.fromCenter(center: Offset(m.x, m.y), width: m.size, height: m.size), p);
      }
    }
  }

  // Darkness with holes cut by lights (caves, the Lightless Land), then a soft glow for every light
  void renderLights(Canvas c, Rect view, List<Light> lights) {
    if (dark) {
      final shade = theme == RealmTheme.dark ? 0.86 : 0.7;
      c.saveLayer(view, Paint());
      c.drawRect(view, Paint()..color = Color.fromRGBO(8, 6, 18, shade));
      final cut = Paint()..blendMode = BlendMode.dstOut;
      for (final l in lights) {
        final r = l.r * 1.6;
        cut.shader = Gradient.radial(Offset(l.x, l.y), r, [Color.fromRGBO(0, 0, 0, l.intensity.clamp(0.0, 1.0)), const Color(0x00000000)]);
        c.drawCircle(Offset(l.x, l.y), r, cut);
      }
      c.restore();
    }
    final glow = Paint()..blendMode = BlendMode.plus;
    for (final l in lights) {
      if (!view.inflate(l.r).contains(Offset(l.x, l.y))) continue;
      final a = (dark ? 0.32 : 0.22) * l.intensity;
      glow.shader = Gradient.radial(Offset(l.x, l.y), l.r, [Color(l.color).withValues(alpha: a.clamp(0.0, 1.0)), Color(l.color).withValues(alpha: 0)]);
      c.drawCircle(Offset(l.x, l.y), l.r, glow);
    }
  }
}

// Slow-turning shafts of light from the sun in the sky layer (screen space)
void paintSunRays(Canvas c, Offset sun, double scale, double t, double strength, int color) {
  if (strength <= 0) return;
  final p = Paint()..blendMode = BlendMode.plus;
  for (var i = 0; i < 9; i++) {
    final a = i / 9 * math.pi * 2 + t * 0.05 + math.sin(t * 0.3 + i) * 0.05;
    final w = 0.05 + 0.04 * math.sin(i * 2.3);
    final len = (260 + 60 * math.sin(i * 1.7 + t * 0.4)) * scale;
    final alpha = strength * (0.6 + 0.4 * math.sin(t * 0.5 + i * 1.3));
    p.shader = Gradient.radial(sun, len, [Color(color).withValues(alpha: alpha.clamp(0.0, 1.0)), Color(color).withValues(alpha: 0)]);
    c.drawPath(
      Path()
        ..moveTo(sun.dx, sun.dy)
        ..lineTo(sun.dx + math.cos(a - w) * len, sun.dy + math.sin(a - w) * len)
        ..lineTo(sun.dx + math.cos(a + w) * len, sun.dy + math.sin(a + w) * len)
        ..close(),
      p,
    );
  }
  p.shader = Gradient.radial(sun, 70 * scale, [Color(color).withValues(alpha: strength * 3), Color(color).withValues(alpha: 0)]);
  c.drawCircle(sun, 70 * scale, p);
}

// Darkens the screen edges; stronger in dark places
void paintVignette(Canvas c, Size size, double strength) {
  final rect = Offset.zero & size;
  c.drawRect(
    rect,
    Paint()
      ..shader = Gradient.radial(
        rect.center,
        size.longestSide * 0.62,
        [const Color(0x00000000), const Color(0x00000000), Color.fromRGBO(12, 8, 24, strength)],
        [0, 0.55, 1],
      ),
  );
}
