// Helpers for generating pixel art from code.
// Each frame is a list of strings; each character maps to a palette color ('.' = transparent).

import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

// A horizontal strip of equally sized frames
class Sheet {
  Sheet(this.image, this.frameW, this.frameH, this.count);

  final ui.Image image;
  final double frameW;
  final double frameH;
  final int count;

  Rect src(int frame) => Rect.fromLTWH(frame * frameW, 0, frameW, frameH);
}

Color hex(String s) => Color(0xff000000 | int.parse(s.substring(1), radix: 16));

Future<ui.Image> _toImage(int w, int h, void Function(Canvas c) draw) {
  final rec = ui.PictureRecorder();
  draw(Canvas(rec));
  return rec.endRecording().toImage(w, h);
}

Future<Sheet> pixelSheet(List<List<String>> frames, Map<String, String> palette) async {
  final h = frames.map((f) => f.length).reduce((a, b) => a > b ? a : b);
  final w = frames.expand((f) => f.map((r) => r.length)).reduce((a, b) => a > b ? a : b);
  final paints = palette.map((k, v) => MapEntry(k, Paint()..color = hex(v)..isAntiAlias = false));
  final img = await _toImage(w * frames.length, h, (c) {
    for (var i = 0; i < frames.length; i++) {
      final rows = frames[i];
      for (var y = 0; y < rows.length; y++) {
        final row = rows[y];
        for (var x = 0; x < row.length; x++) {
          final p = paints[row[x]];
          if (p == null) continue;
          c.drawRect(Rect.fromLTWH((i * w + x).toDouble(), y.toDouble(), 1, 1), p);
        }
      }
    }
  });
  return Sheet(img, w.toDouble(), h.toDouble(), frames.length);
}

Future<Sheet> canvasTexture(int w, int h, void Function(Canvas c, double w, double h) draw, {int frames = 1}) async {
  final img = await _toImage(w, h, (c) => draw(c, w.toDouble(), h.toDouble()));
  return Sheet(img, w / frames, h.toDouble(), frames);
}

// Seeded random generator (mulberry32) so generated art is identical on every load
double Function() rng(int seed) {
  var s = seed;
  int imul(int a, int b) => (a * b).toSigned(32);
  return () {
    s = (s + 0x6d2b79f5).toSigned(32);
    var t = imul(s ^ ((s & 0xffffffff) >> 15), 1 | s);
    t = ((t + imul(t ^ ((t & 0xffffffff) >> 7), 61 | t)).toSigned(32) ^ t).toSigned(32);
    return ((t ^ ((t & 0xffffffff) >> 14)) & 0xffffffff) / 4294967296;
  };
}

List<String> mirror(List<String> rows) => rows.map((r) => r.split('').reversed.join()).toList();

// ---------- Drawing ----------

final _paint = Paint()..filterQuality = FilterQuality.none;

// Draws one frame with the origin at (x, y). Mirrors Phaser's sprite options.
void drawFrame(
  Canvas c,
  Sheet s,
  int frame,
  double x,
  double y, {
  double ox = 0.5,
  double oy = 1,
  bool flipX = false,
  bool flipY = false,
  double scaleX = 1,
  double scaleY = 1,
  double angle = 0, // degrees
  double alpha = 1,
  int? tint, // multiply
  int? tintFill, // solid colour
}) {
  if (alpha <= 0) return;
  c.save();
  c.translate(x, y);
  if (angle != 0) c.rotate(angle * 3.141592653589793 / 180);
  c.scale(flipX ? -scaleX : scaleX, flipY ? -scaleY : scaleY);
  final dst = Rect.fromLTWH(-s.frameW * ox, -s.frameH * oy, s.frameW, s.frameH);
  _paint.color = Color.fromRGBO(255, 255, 255, alpha.clamp(0, 1));
  if (tintFill != null) {
    _paint.colorFilter = ColorFilter.mode(Color(tintFill).withValues(alpha: alpha.clamp(0, 1)), BlendMode.srcIn);
  } else if (tint != null) {
    _paint.colorFilter = ColorFilter.mode(Color(tint), BlendMode.modulate);
  } else {
    _paint.colorFilter = null;
  }
  c.drawImageRect(s.image, s.src(frame), dst, _paint);
  c.restore();
}

// Frame-based looping animation
class Anim {
  Anim(this.frames, this.fps);

  final List<int> frames;
  final double fps;
  double t = 0;
  double timeScale = 1;

  void update(double dtMs) => t += dtMs / 1000 * fps * timeScale;
  int get frame => frames[t.floor() % frames.length];
}
