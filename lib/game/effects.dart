// Particles, shockwave rings, hit sparks, floating numbers, sword slashes, timers and the camera

import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../art/pixel.dart';
import '../config.dart';

final rand = math.Random();
double between(double a, double b) => a + rand.nextDouble() * (b - a);
int betweenInt(int a, int b) => a + rand.nextInt(b - a + 1);

enum PShape { square, soft }

class Particle {
  Particle(this.x, this.y, this.vx, this.vy, this.life, this.color,
      {this.gravityY = 0, this.size = 2, this.endSize = 0, this.drag = 0, this.shape = PShape.square, this.fade = false, this.glow = false});

  double x, y, vx, vy;
  final double life;
  double age = 0;
  final int color;
  final double gravityY, size, endSize, drag;
  final PShape shape;
  final bool fade, glow;
}

// Expanding circle, for impacts, level-ups and the lion's landings
class Ring {
  Ring(this.x, this.y, this.r0, this.r1, this.life, this.color, {this.width = 2});
  final double x, y, r0, r1, life, width;
  final int color;
  double age = 0;
}

// Four-pointed flash where a hit lands
class Spark {
  Spark(this.x, this.y, this.size, this.color);
  final double x, y, size;
  final int color;
  double age = 0;
  static const life = 140.0;
}

class Particles {
  final List<Particle> list = [];
  final List<Ring> rings = [];
  final List<Spark> sparks = [];
  final _paint = Paint()..isAntiAlias = false;
  final _glow = Paint()..blendMode = BlendMode.plus;

  void clear() {
    list.clear();
    rings.clear();
    sparks.clear();
  }

  // One-shot explosion of pixels, with a few glowing embers mixed in
  void burst(double x, double y, List<int> colors, [int count = 10, double speed = 100]) {
    for (var i = 0; i < count; i++) {
      final a = rand.nextDouble() * math.pi * 2;
      final s = between(speed * 0.3, speed);
      final c = colors[rand.nextInt(colors.length)];
      list.add(Particle(x, y, math.cos(a) * s, math.sin(a) * s, between(250, 550), c,
          gravityY: 300, size: between(1.5, 2.5), drag: 1.5, glow: i % 4 == 0));
    }
  }

  void trail(double x, double y, List<int> colors) {
    final a = rand.nextDouble() * math.pi * 2;
    list.add(Particle(x, y, math.cos(a) * 10, math.sin(a) * 10, 260, colors[rand.nextInt(colors.length)], size: 2, glow: true));
  }

  // Soft puffs of dust: [dir] pushes them sideways (running, landing)
  void dust(double x, double y, {int count = 3, double dir = 0, double spread = 30, int color = 0xffd8c8a8}) {
    for (var i = 0; i < count; i++) {
      final vx = dir * between(10, 40) + between(-spread, spread);
      list.add(Particle(x + between(-2, 2), y - between(0, 2), vx, between(-22, -6), between(300, 520), color,
          size: between(2, 3.5), endSize: between(4.5, 7), drag: 3, shape: PShape.soft, fade: true));
    }
  }

  void sparkle(double x, double y, [int color = 0xfffff4c0]) =>
      list.add(Particle(x, y, 0, between(-6, -2), between(300, 500), color, size: between(1, 2), shape: PShape.soft, glow: true, fade: true));

  void ember(double x, double y, [int color = 0xffffa040]) => list.add(Particle(x + between(-3, 3), y, between(-6, 6), between(-30, -14),
      between(600, 1100), color, size: between(1, 1.8), endSize: 0.4, shape: PShape.soft, glow: true));

  void ring(double x, double y, int color, {double r0 = 2, double r1 = 18, double life = 320, double width = 2}) =>
      rings.add(Ring(x, y, r0, r1, life, color, width: width));

  void spark(double x, double y, {double size = 8, int color = 0xfffff8e0}) => sparks.add(Spark(x, y, size, color));

  void update(double dt) {
    final s = dt / 1000;
    list.removeWhere((p) {
      p.age += dt;
      p.vy += p.gravityY * s;
      if (p.drag > 0) {
        final k = math.max(0.0, 1 - p.drag * s);
        p.vx *= k;
        p.vy *= k;
      }
      p.x += p.vx * s;
      p.y += p.vy * s;
      return p.age >= p.life;
    });
    rings.removeWhere((r) => (r.age += dt) >= r.life);
    sparks.removeWhere((sp) => (sp.age += dt) >= Spark.life);
  }

  void render(Canvas c) {
    for (final p in list) {
      if (!p.glow) _draw(c, p, _paint);
    }
    for (final p in list) {
      if (p.glow) _draw(c, p, _glow);
    }
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..blendMode = BlendMode.plus;
    for (final r in rings) {
      final k = r.age / r.life;
      final e = 1 - math.pow(1 - k, 3).toDouble(); // ease out
      stroke
        ..strokeWidth = r.width * (1 - k) + 0.3
        ..color = Color(r.color).withValues(alpha: (1 - k) * 0.9);
      c.drawCircle(Offset(r.x, r.y), r.r0 + (r.r1 - r.r0) * e, stroke);
    }
    for (final sp in sparks) {
      final k = sp.age / Spark.life;
      final len = sp.size * (k < 0.3 ? k / 0.3 : 1 - (k - 0.3) / 0.7);
      final line = Paint()
        ..blendMode = BlendMode.plus
        ..strokeCap = StrokeCap.round
        ..color = Color(sp.color).withValues(alpha: 1 - k * 0.5);
      for (final (dx, dy, w) in [(1.0, 0.0, 1.6), (0.0, 1.0, 1.6), (0.7, 0.7, 0.8), (0.7, -0.7, 0.8)]) {
        final l = (w > 1 ? len : len * 0.55);
        line.strokeWidth = w;
        c.drawLine(Offset(sp.x - dx * l, sp.y - dy * l), Offset(sp.x + dx * l, sp.y + dy * l), line);
      }
      c.drawCircle(Offset(sp.x, sp.y), len * 0.35, Paint()
        ..blendMode = BlendMode.plus
        ..color = const Color(0xffffffff).withValues(alpha: 1 - k));
    }
  }

  void _draw(Canvas c, Particle p, Paint paint) {
    final k = p.age / p.life;
    final size = p.size + (p.endSize - p.size) * k;
    if (size <= 0.05) return;
    final alpha = p.fade ? (1 - k) * (p.shape == PShape.soft ? 0.55 : 1) : 1.0;
    paint.color = Color(p.color).withValues(alpha: alpha.clamp(0.0, 1.0));
    if (p.shape == PShape.soft) {
      c.drawCircle(Offset(p.x, p.y), size / 2, paint);
      if (p.glow) {
        paint.color = Color(p.color).withValues(alpha: alpha * 0.25);
        c.drawCircle(Offset(p.x, p.y), size * 1.6, paint);
      }
    } else {
      c.drawRect(Rect.fromCenter(center: Offset(p.x, p.y), width: size, height: size), paint);
    }
  }
}

// Numbers and marks that pop up, rise and fade (damage, '!', 'z')
class FloatText {
  FloatText(this.x, this.y, String text, Color color, {double size = 8, this.rise = 16, this.duration = 650, this.drift = 0})
      : painter = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: size,
              fontWeight: FontWeight.bold,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2
                ..color = const Color(Palette.ink),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(),
        fill = TextPainter(
          text: TextSpan(text: text, style: TextStyle(fontFamily: 'monospace', fontSize: size, fontWeight: FontWeight.bold, color: color)),
          textDirection: TextDirection.ltr,
        )..layout();

  final double x, y, rise, duration, drift;
  final TextPainter painter, fill;
  double t = 0;

  void render(Canvas c) {
    final k = (t / duration).clamp(0.0, 1.0);
    // Pop in big, settle, then rise with an ease-out and fade in the last third
    final scale = k < 0.12 ? 1.7 - 0.7 * (k / 0.12) : 1.0;
    final up = rise * (1 - math.pow(1 - k, 2));
    final alpha = k < 0.66 ? 1.0 : 1 - (k - 0.66) / 0.34;
    c.save();
    c.translate(x + drift * k, y - up);
    c.scale(scale);
    final pos = Offset(-painter.width / 2, -painter.height / 2);
    c.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, alpha));
    painter.paint(c, pos);
    fill.paint(c, pos);
    c.restore();
    c.restore();
  }
}

class Slash {
  Slash(this.x, this.y, {this.flipX = false, this.flipY = false, this.scale = 1, this.angle = 0, this.tint});
  final double x, y, scale, angle;
  final bool flipX, flipY;
  final int? tint;
  double t = 0;
  static const duration = 170.0;

  void render(Canvas c, Sheet s) {
    final k = t / duration;
    final a = 1 - k;
    // A soft glow under the crisp arc
    c.saveLayer(null, Paint()..blendMode = BlendMode.plus);
    drawFrame(c, s, 0, x, y,
        oy: 0.5, flipX: flipX, flipY: flipY, scaleX: scale * 1.2, scaleY: scale * 1.2, angle: angle, tint: tint ?? 0xffffe8b0, alpha: a * 0.45);
    c.restore();
    drawFrame(c, s, 0, x, y,
        oy: 0.5, flipX: flipX, flipY: flipY, scaleX: scale * (1 + 0.1 * k), scaleY: scale * (1 + 0.1 * k), angle: angle, tint: tint, alpha: a);
  }
}

// Phaser-style delayed calls that only tick while the game runs
class Timers {
  final List<(double, void Function())> _list = [];

  void after(double ms, void Function() fn) => _list.add((ms, fn));

  void update(double dt) {
    final due = <void Function()>[];
    for (var i = _list.length - 1; i >= 0; i--) {
      final (left, fn) = _list[i];
      if (left - dt <= 0) {
        _list.removeAt(i);
        due.add(fn);
      } else {
        _list[i] = (left - dt, fn);
      }
    }
    for (final fn in due.reversed) {
      fn();
    }
  }

  void clear() => _list.clear();
}

class Camera {
  double scrollX = 0, scrollY = 0;
  double viewW = 320, viewH = 180;
  Rect bounds = Rect.zero;

  double _shakeLeft = 0, _shakeIntensity = 0;
  double shakeX = 0, shakeY = 0;

  // Fade: 0 = clear, 1 = fully covered
  double fade = 0;
  double _fadeDir = 0, _fadeDur = 1;
  void Function()? _fadeDone;

  // Short full-screen colour flash (hurt, level up, boss hits)
  int flashColor = 0xffffffff;
  double flashAlpha = 0;
  double _flashDecay = 1;

  double get left => scrollX;
  double get top => scrollY;

  void follow(double tx, double ty, double dt, {bool snap = false}) {
    final dx = tx - viewW / 2, dy = ty - viewH / 2;
    if (snap) {
      scrollX = dx;
      scrollY = dy;
    } else {
      // Phaser lerps 0.12 per frame at 60 fps
      final k = 1 - math.pow(0.88, dt / (1000 / 60)).toDouble();
      scrollX += (dx - scrollX) * k;
      scrollY += (dy - scrollY) * k;
    }
    _clamp();
  }

  void _clamp() {
    if (bounds.width <= viewW) {
      scrollX = bounds.left + (bounds.width - viewW) / 2;
    } else {
      scrollX = scrollX.clamp(bounds.left, bounds.right - viewW);
    }
    if (bounds.height <= viewH) {
      scrollY = bounds.top + (bounds.height - viewH) / 2;
    } else {
      scrollY = scrollY.clamp(bounds.top, bounds.bottom - viewH);
    }
  }

  void shake(double ms, double intensity) {
    if (_shakeLeft > 0 && intensity < _shakeIntensity) return;
    _shakeLeft = ms;
    _shakeIntensity = intensity;
  }

  void flash(int color, double alpha, double ms) {
    if (alpha < flashAlpha) return;
    flashColor = color;
    flashAlpha = alpha;
    _flashDecay = alpha / ms;
  }

  void fadeOut(double ms, void Function() done) {
    _fadeDir = 1;
    _fadeDur = ms;
    _fadeDone = done;
  }

  void fadeIn(double ms) {
    fade = 1;
    _fadeDir = -1;
    _fadeDur = ms;
    _fadeDone = null;
  }

  void update(double dt, double virtualW) {
    if (_shakeLeft > 0) {
      _shakeLeft -= dt;
      // Offsets in virtual screen pixels, like Phaser's camera.width * intensity
      shakeX = (rand.nextDouble() * 2 - 1) * _shakeIntensity * virtualW;
      shakeY = (rand.nextDouble() * 2 - 1) * _shakeIntensity * gameH;
    } else {
      shakeX = shakeY = 0;
    }
    if (flashAlpha > 0) flashAlpha = math.max(0, flashAlpha - _flashDecay * dt);
    if (_fadeDir != 0) {
      fade = (fade + _fadeDir * dt / _fadeDur).clamp(0, 1);
      if ((_fadeDir > 0 && fade >= 1) || (_fadeDir < 0 && fade <= 0)) {
        _fadeDir = 0;
        final done = _fadeDone;
        _fadeDone = null;
        done?.call();
      }
    }
  }
}
