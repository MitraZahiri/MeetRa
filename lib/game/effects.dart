// Particles, floating numbers, sword slashes, timers and the camera

import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../art/pixel.dart';
import '../config.dart';

final rand = math.Random();
double between(double a, double b) => a + rand.nextDouble() * (b - a);
int betweenInt(int a, int b) => a + rand.nextInt(b - a + 1);

class Particle {
  Particle(this.x, this.y, this.vx, this.vy, this.life, this.color, this.gravityY);
  double x, y, vx, vy;
  final double life;
  double age = 0;
  final int color;
  final double gravityY;
}

class Particles {
  final List<Particle> list = [];
  final _paint = Paint()..isAntiAlias = false;

  // One-shot explosion of 2x2 pixels (Phaser: emitter.explode)
  void burst(double x, double y, List<int> colors, [int count = 10, double speed = 100]) {
    for (var i = 0; i < count; i++) {
      final a = rand.nextDouble() * math.pi * 2;
      final s = between(speed * 0.3, speed);
      list.add(Particle(x, y, math.cos(a) * s, math.sin(a) * s, between(250, 550), colors[rand.nextInt(colors.length)], 300));
    }
  }

  void trail(double x, double y, List<int> colors) {
    final a = rand.nextDouble() * math.pi * 2;
    list.add(Particle(x, y, math.cos(a) * 10, math.sin(a) * 10, 220, colors[rand.nextInt(colors.length)], 0));
  }

  void update(double dt) {
    final s = dt / 1000;
    list.removeWhere((p) {
      p.age += dt;
      p.vy += p.gravityY * s;
      p.x += p.vx * s;
      p.y += p.vy * s;
      return p.age >= p.life;
    });
  }

  void render(Canvas c) {
    for (final p in list) {
      final size = 2 * (1 - p.age / p.life);
      _paint.color = Color(p.color);
      c.drawRect(Rect.fromCenter(center: Offset(p.x, p.y), width: size, height: size), _paint);
    }
  }
}

class FloatText {
  FloatText(this.x, this.y, String text, Color color)
      : painter = TextPainter(
          text: TextSpan(children: [
            TextSpan(
              text: text,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 8,
                fontWeight: FontWeight.bold,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 2
                  ..color = const Color(Palette.ink),
              ),
            ),
          ]),
          textDirection: TextDirection.ltr,
        )..layout(),
        fill = TextPainter(
          text: TextSpan(text: text, style: TextStyle(fontFamily: 'monospace', fontSize: 8, fontWeight: FontWeight.bold, color: color)),
          textDirection: TextDirection.ltr,
        )..layout();

  final double x, y;
  final TextPainter painter, fill;
  double t = 0;
  static const duration = 600.0;

  void render(Canvas c) {
    final k = t / duration;
    final pos = Offset(x - painter.width / 2, y - 14 * k - painter.height / 2);
    c.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, 1 - k));
    painter.paint(c, pos);
    fill.paint(c, pos);
    c.restore();
  }
}

class Slash {
  Slash(this.x, this.y, {this.flipX = false, this.flipY = false, this.scale = 1, this.angle = 0, this.tint});
  final double x, y, scale, angle;
  final bool flipX, flipY;
  final int? tint;
  double t = 0;
  static const duration = 160.0;

  void render(Canvas c, Sheet s) => drawFrame(c, s, 0, x, y,
      oy: 0.5, flipX: flipX, flipY: flipY, scaleX: scale, scaleY: scale, angle: angle, tint: tint, alpha: 1 - t / duration);
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
