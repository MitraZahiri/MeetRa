// A hand-drawn ink kit for the maps: pen strokes on old paper.
// Every motif is filled with paper first so that later (lower) motifs overlap earlier ones,
// the way a pen drawing is built up from the back to the front.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'common.dart';

const inkColor = Color(0xff2b1e16);
const paperColor = Color(0xfff1e5cb);

final _paperFill = Paint()..color = paperColor;
final _inkFill = Paint()..color = inkColor;

Paint inkPen(double w, [Color color = inkColor]) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeJoin = StrokeJoin.round
  ..strokeCap = StrokeCap.round;

void _shape(Canvas c, Path p, double w) {
  c.drawPath(p, _paperFill);
  c.drawPath(p, inkPen(w));
}

// ---------- Paper ----------

// Aged paper: a warm centre, darker edges and a few faint stains
void paperSheet(Canvas c, Rect r, {int seed = 1}) {
  c.drawRect(r, Paint()..shader = const RadialGradient(colors: [Color(0xfff6ecd6), Color(0xffe3d2ae)], radius: 0.95).createShader(r));
  final rnd = math.Random(seed);
  for (var i = 0; i < 14; i++) {
    final p = Offset(r.left + rnd.nextDouble() * r.width, r.top + rnd.nextDouble() * r.height);
    final rad = 30 + rnd.nextDouble() * 90;
    c.drawCircle(p, rad, Paint()..shader = RadialGradient(colors: const [Color(0x14a0784a), Color(0x00a0784a)]).createShader(Rect.fromCircle(center: p, radius: rad)));
  }
  // Fibres
  final fibre = inkPen(0.6, const Color(0x0f5a3a1a));
  for (var i = 0; i < 60; i++) {
    final p = Offset(r.left + rnd.nextDouble() * r.width, r.top + rnd.nextDouble() * r.height);
    final a = rnd.nextDouble() * math.pi;
    final l = 6 + rnd.nextDouble() * 18;
    c.drawLine(p, p + Offset(math.cos(a) * l, math.sin(a) * l), fibre);
  }
  c.drawRect(r, Paint()..shader = const RadialGradient(colors: [Color(0x00000000), Color(0x00000000), Color(0x4a5a3a1a)], stops: [0, 0.7, 1], radius: 0.8).createShader(r));
}

// ---------- Shapes ----------

// A closed wobbly outline around [centre], built from a few slow waves so it reads as a coastline
Path wobblyBlob(Offset centre, double rx, double ry, int seed, {double grow = 0, int points = 72}) {
  final rnd = math.Random(seed);
  final waves = [for (var i = 0; i < 4; i++) (2 + rnd.nextInt(5), rnd.nextDouble() * math.pi * 2, 0.02 + rnd.nextDouble() * 0.05)];
  final pts = <Offset>[];
  for (var i = 0; i < points; i++) {
    final a = i / points * math.pi * 2;
    var k = 1.0;
    for (final (f, ph, amp) in waves) {
      k += math.sin(a * f + ph) * amp;
    }
    pts.add(centre + Offset(math.cos(a) * (rx * k + grow), math.sin(a) * (ry * k + grow)));
  }
  return smoothClosed(pts);
}

// A closed curve through the midpoints of [pts], with the points as control points
Path smoothClosed(List<Offset> pts) {
  final path = Path();
  Offset mid(int i) => (pts[i % pts.length] + pts[(i + 1) % pts.length]) / 2;
  final m0 = mid(0);
  path.moveTo(m0.dx, m0.dy);
  for (var i = 1; i <= pts.length; i++) {
    final p = pts[i % pts.length], m = mid(i);
    path.quadraticBezierTo(p.dx, p.dy, m.dx, m.dy);
  }
  return path..close();
}

// A scalloped round shape: tree crowns and clouds
Path lumpy(Offset centre, double r, int lumps, double phase, {double depth = 0.16}) {
  final pts = <Offset>[];
  const n = 40;
  for (var i = 0; i < n; i++) {
    final a = i / n * math.pi * 2;
    final k = 1 - depth + depth * 1.6 * math.sin(a * lumps / 2 + phase).abs();
    pts.add(centre + Offset(math.cos(a) * r * k, math.sin(a) * r * k));
  }
  return smoothClosed(pts);
}

void dashedPath(Canvas c, Path path, Paint p, {double dash = 5, double gap = 4}) {
  for (final m in path.computeMetrics()) {
    for (var d = 0.0; d < m.length; d += dash + gap) {
      c.drawPath(m.extractPath(d, math.min(m.length, d + dash)), p);
    }
  }
}

// ---------- Land motifs (p is the foot of the motif) ----------

void inkTree(Canvas c, Offset p, double s, double phase) {
  c.drawLine(p, p - Offset(0, 4 * s), inkPen(1.1 * s));
  final top = p - Offset(0, 8.5 * s);
  _shape(c, lumpy(top, 5.5 * s, 7, phase), 1.1 * s);
  c.drawArc(Rect.fromCircle(center: top, radius: 3.4 * s), 0.3, 1.3, false, inkPen(0.8 * s));
}

void inkPine(Canvas c, Offset p, double s) {
  c.drawLine(p, p - Offset(0, 3 * s), inkPen(1.1 * s));
  for (var i = 0; i < 2; i++) {
    final b = p.dy - 3 * s - i * 5 * s;
    final w = (5.5 - i * 1.5) * s;
    final tier = Path()
      ..moveTo(p.dx - w, b)
      ..quadraticBezierTo(p.dx - w * 0.3, b - 4 * s, p.dx, b - 9 * s)
      ..quadraticBezierTo(p.dx + w * 0.3, b - 4 * s, p.dx + w, b)
      ..close();
    _shape(c, tier, 1 * s);
  }
}

void inkMountain(Canvas c, Offset p, double s, double v, {bool snow = false}) {
  final h = 18 * s * (0.85 + 0.35 * v), w = 14 * s;
  final top = p + Offset((v - 0.5) * 4 * s, -h);
  final right = Offset(p.dx + w, p.dy);
  final m = Path()
    ..moveTo(p.dx - w, p.dy)
    ..lineTo(p.dx - w * 0.45, p.dy - h * 0.5)
    ..lineTo(p.dx - w * 0.3, p.dy - h * 0.46)
    ..lineTo(top.dx, top.dy)
    ..lineTo(p.dx + w * 0.45, p.dy - h * 0.48)
    ..lineTo(right.dx, right.dy)
    ..close();
  _shape(c, m, 1.2 * s);
  // Shade the right face with strokes that gather at the peak
  final spineFoot = Offset(p.dx + w * 0.12, p.dy - h * 0.12);
  final hatch = inkPen(0.7 * s);
  for (var k = 1; k <= 6; k++) {
    final t = k / 7;
    final a = Offset.lerp(top, right, t)!, b = Offset.lerp(top, spineFoot, t)!;
    c.drawLine(Offset.lerp(a, b, 0.1)!, b, hatch);
  }
  c.drawLine(top, spineFoot, inkPen(0.8 * s));
  if (snow) {
    final cap = Path()
      ..moveTo(Offset.lerp(top, Offset(p.dx - w * 0.3, p.dy - h * 0.46), 0.5)!.dx, top.dy + h * 0.27)
      ..lineTo(top.dx - 1 * s, top.dy + h * 0.2)
      ..lineTo(top.dx + 0.5 * s, top.dy + h * 0.3)
      ..lineTo(top.dx + 2 * s, top.dy + h * 0.22);
    c.drawPath(cap, inkPen(0.8 * s));
  }
}

void inkHouse(Canvas c, Offset p, double s) {
  final body = Rect.fromLTRB(p.dx - 4 * s, p.dy - 5 * s, p.dx + 4 * s, p.dy);
  c.drawRect(body, _paperFill);
  c.drawRect(body, inkPen(1 * s));
  final roof = Path()
    ..moveTo(p.dx - 5.5 * s, p.dy - 5 * s)
    ..lineTo(p.dx, p.dy - 10 * s)
    ..lineTo(p.dx + 5.5 * s, p.dy - 5 * s)
    ..close();
  _shape(c, roof, 1 * s);
  for (var k = 1; k <= 3; k++) {
    c.drawLine(p + Offset(k * 1.4 * s, -5 * s), p + Offset(k * 1.0 * s - 1 * s, -8.5 * s + k * 0.8 * s), inkPen(0.6 * s));
  }
  c.drawRect(Rect.fromLTWH(p.dx - 1 * s, p.dy - 2.6 * s, 2 * s, 2.6 * s), _inkFill);
}

// A walled keep with three towers, cone roofs and flags
void inkCastle(Canvas c, Offset p, double s, {bool dark = false}) {
  void tower(double dx, double h, double tw) {
    final x = p.dx + dx * s;
    final r = Rect.fromLTRB(x - tw * s, p.dy - h * s, x + tw * s, p.dy);
    c.drawRect(r, dark ? _inkFill : _paperFill);
    c.drawRect(r, inkPen(1.1 * s));
    final roof = Path()
      ..moveTo(r.left - 1.4 * s, r.top)
      ..lineTo(x, r.top - 9 * s)
      ..lineTo(r.right + 1.4 * s, r.top)
      ..close();
    c.drawPath(roof, dark ? _paperFill : _inkFill);
    c.drawPath(roof, inkPen(1 * s));
    c.drawLine(Offset(x, r.top - 9 * s), Offset(x, r.top - 14 * s), inkPen(0.8 * s));
    final flag = Path()
      ..moveTo(x, r.top - 14 * s)
      ..lineTo(x + 4.5 * s, r.top - 12.6 * s)
      ..lineTo(x, r.top - 11.4 * s)
      ..close();
    c.drawPath(flag, _inkFill);
    if (!dark) {
      for (var k = 0; k < 2; k++) {
        c.drawRect(Rect.fromCenter(center: Offset(x, r.top + (4 + k * 5) * s), width: 1.3 * s, height: 2.4 * s), _inkFill);
      }
    }
  }

  tower(-11, 18, 3.2);
  tower(11, 18, 3.2);
  final wall = Rect.fromLTRB(p.dx - 11 * s, p.dy - 10 * s, p.dx + 11 * s, p.dy);
  c.drawRect(wall, dark ? _inkFill : _paperFill);
  c.drawRect(wall, inkPen(1.1 * s));
  for (var x = wall.left + 1.5 * s; x < wall.right - 2 * s; x += 3.4 * s) {
    c.drawRect(Rect.fromLTWH(x, wall.top - 2 * s, 1.8 * s, 2 * s), _inkFill);
  }
  for (var y = wall.top + 2.5 * s; y < wall.bottom; y += 2.5 * s) {
    c.drawLine(Offset(wall.left, y), Offset(wall.left + 3 * s, y), inkPen(0.5 * s, dark ? paperColor : inkColor));
  }
  tower(0, 25, 4);
  final gate = Path()
    ..moveTo(p.dx - 2.4 * s, p.dy)
    ..lineTo(p.dx - 2.4 * s, p.dy - 4 * s)
    ..arcToPoint(Offset(p.dx + 2.4 * s, p.dy - 4 * s), radius: Radius.circular(2.4 * s))
    ..lineTo(p.dx + 2.4 * s, p.dy)
    ..close();
  c.drawPath(gate, dark ? _paperFill : _inkFill);
}

void inkTent(Canvas c, Offset p, double s) {
  final tent = Path()
    ..moveTo(p.dx - 6 * s, p.dy)
    ..lineTo(p.dx - 6 * s, p.dy - 3.5 * s)
    ..quadraticBezierTo(p.dx, p.dy - 11 * s, p.dx + 6 * s, p.dy - 3.5 * s)
    ..lineTo(p.dx + 6 * s, p.dy)
    ..close();
  _shape(c, tent, 1 * s);
  c.drawLine(p + Offset(-6 * s, -3.5 * s), p + Offset(6 * s, -3.5 * s), inkPen(0.7 * s));
  c.drawRect(Rect.fromLTWH(p.dx - 1.3 * s, p.dy - 3 * s, 2.6 * s, 3 * s), _inkFill);
  c.drawLine(p + Offset(0, -7.3 * s), p + Offset(0.6 * s, -10.5 * s), inkPen(0.8 * s));
}

void inkPalm(Canvas c, Offset p, double s, double v) {
  final lean = (v - 0.5) * 6 * s;
  final top = p + Offset(lean, -13 * s);
  final trunk = Path()
    ..moveTo(p.dx, p.dy)
    ..quadraticBezierTo(p.dx + lean * 0.2, p.dy - 7 * s, top.dx, top.dy);
  c.drawPath(trunk, inkPen(1.4 * s));
  for (var k = 0; k < 3; k++) {
    c.drawLine(Offset.lerp(p, top, 0.25 + k * 0.22)! - Offset(1.2 * s, 0), Offset.lerp(p, top, 0.25 + k * 0.22)! + Offset(1.2 * s, 0), inkPen(0.6 * s));
  }
  for (final a in [-2.7, -2.0, -1.2, -0.45, 0.2]) {
    final tip = top + Offset(math.cos(a) * 7 * s, math.sin(a) * 4 * s + 3 * s);
    final ctrl = top + Offset(math.cos(a) * 4 * s, math.sin(a) * 4 * s - 2 * s);
    c.drawPath(Path()
      ..moveTo(top.dx, top.dy)
      ..quadraticBezierTo(ctrl.dx, ctrl.dy, tip.dx, tip.dy), inkPen(1.1 * s));
  }
}

void inkDune(Canvas c, Offset p, double s) {
  final d = Path()
    ..moveTo(p.dx - 12 * s, p.dy)
    ..quadraticBezierTo(p.dx - 3 * s, p.dy - 7 * s, p.dx + 3 * s, p.dy - 5 * s)
    ..quadraticBezierTo(p.dx + 8 * s, p.dy - 3 * s, p.dx + 12 * s, p.dy);
  c.drawPath(d, inkPen(1 * s));
  for (var k = 0; k < 5; k++) {
    c.drawCircle(p + Offset(1 * s + k * 2 * s, -3.6 * s + k * 0.7 * s), 0.45 * s, _inkFill);
  }
}

void inkPyramid(Canvas c, Offset p, double s) {
  final top = p - Offset(0, 14 * s);
  final py = Path()
    ..moveTo(p.dx - 12 * s, p.dy)
    ..lineTo(top.dx, top.dy)
    ..lineTo(p.dx + 12 * s, p.dy)
    ..close();
  _shape(c, py, 1.2 * s);
  for (var k = 1; k <= 5; k++) {
    final t = k / 6;
    c.drawLine(Offset.lerp(top, p + Offset(12 * s, 0), t)!, Offset.lerp(top, p + Offset(2 * s, 0), t)!, inkPen(0.7 * s));
  }
  c.drawLine(top, p + Offset(2 * s, 0), inkPen(0.8 * s));
}

// A broken colonnade
void inkRuin(Canvas c, Offset p, double s) {
  final base = Rect.fromLTRB(p.dx - 10 * s, p.dy - 2 * s, p.dx + 10 * s, p.dy);
  c.drawRect(base, _paperFill);
  c.drawRect(base, inkPen(1 * s));
  const heights = [12.0, 9.0, 12.0, 5.0];
  for (var i = 0; i < 4; i++) {
    final x = p.dx - 7.5 * s + i * 5 * s;
    final col = Rect.fromLTRB(x - 1.4 * s, p.dy - 2 * s - heights[i] * s, x + 1.4 * s, p.dy - 2 * s);
    c.drawRect(col, _paperFill);
    c.drawRect(col, inkPen(0.9 * s));
    c.drawLine(Offset(x, col.top + 1 * s), Offset(x, col.bottom - 1 * s), inkPen(0.5 * s));
  }
  final lintel = Rect.fromLTRB(p.dx - 9.5 * s, p.dy - 16 * s, p.dx + 4 * s, p.dy - 14 * s);
  c.drawRect(lintel, _paperFill);
  c.drawRect(lintel, inkPen(1 * s));
}

void inkLighthouse(Canvas c, Offset p, double s) {
  final body = Path()
    ..moveTo(p.dx - 4 * s, p.dy)
    ..lineTo(p.dx - 2.4 * s, p.dy - 18 * s)
    ..lineTo(p.dx + 2.4 * s, p.dy - 18 * s)
    ..lineTo(p.dx + 4 * s, p.dy)
    ..close();
  _shape(c, body, 1.1 * s);
  c.save();
  c.clipPath(body);
  for (var k = 0; k < 3; k++) {
    c.drawRect(Rect.fromLTWH(p.dx - 5 * s, p.dy - (5 + k * 5.5) * s, 10 * s, 2.2 * s), _inkFill);
  }
  c.restore();
  final lamp = Rect.fromLTRB(p.dx - 2.6 * s, p.dy - 22 * s, p.dx + 2.6 * s, p.dy - 18 * s);
  c.drawRect(lamp, _paperFill);
  c.drawRect(lamp, inkPen(1 * s));
  final cap = Path()
    ..moveTo(p.dx - 3.4 * s, p.dy - 22 * s)
    ..lineTo(p.dx, p.dy - 25.5 * s)
    ..lineTo(p.dx + 3.4 * s, p.dy - 22 * s)
    ..close();
  c.drawPath(cap, _inkFill);
  for (final a in [-0.35, 0.0, 0.35]) {
    final o = Offset(p.dx, p.dy - 20 * s);
    c.drawLine(o + Offset(4.5 * s, a * 4.5 * s), o + Offset(10 * s, a * 10 * s), inkPen(0.7 * s));
    c.drawLine(o - Offset(4.5 * s, -a * 4.5 * s), o - Offset(10 * s, -a * 10 * s), inkPen(0.7 * s));
  }
}

void inkDeadTree(Canvas c, Offset p, double s, double v) {
  final pen = inkPen(1.2 * s);
  final top = p + Offset((v - 0.5) * 3 * s, -12 * s);
  c.drawLine(p, top, pen);
  final thin = inkPen(0.8 * s);
  for (final (t, dir, len) in [(0.45, -1.0, 5.0), (0.6, 1.0, 6.0), (0.8, -1.0, 4.0), (0.9, 1.0, 3.5)]) {
    final o = Offset.lerp(p, top, t)!;
    final tip = o + Offset(dir * len * s, -len * 0.7 * s);
    c.drawLine(o, tip, thin);
    c.drawLine(tip, tip + Offset(dir * 1.5 * s, -2.2 * s), inkPen(0.6 * s));
  }
}

// A black needle of rock
void inkSpire(Canvas c, Offset p, double s, double v) {
  final h = (14 + v * 10) * s;
  final sp = Path()
    ..moveTo(p.dx - 4.5 * s, p.dy)
    ..lineTo(p.dx - 1.5 * s, p.dy - h * 0.6)
    ..lineTo(p.dx + (v - 0.5) * 2 * s, p.dy - h)
    ..lineTo(p.dx + 2 * s, p.dy - h * 0.5)
    ..lineTo(p.dx + 4.5 * s, p.dy)
    ..close();
  c.drawPath(sp, _inkFill);
  c.drawLine(p + Offset(-1 * s, -2 * s), p + Offset(-0.6 * s, -h * 0.55), inkPen(0.5 * s, paperColor));
}

void inkGrass(Canvas c, Offset p, double s) {
  final pen = inkPen(0.7 * s);
  c.drawLine(p, p + Offset(-1.6 * s, -3 * s), pen);
  c.drawLine(p, p + Offset(0, -3.8 * s), pen);
  c.drawLine(p, p + Offset(1.6 * s, -3 * s), pen);
}

// A small round lake with ripples
void inkLake(Canvas c, Offset centre, double rx, double ry, int seed) {
  final lake = wobblyBlob(centre, rx, ry, seed, points: 36);
  _shape(c, lake, 1.3);
  final ripple = inkPen(0.7);
  for (var k = 0; k < 3; k++) {
    final y = centre.dy - ry * 0.4 + k * ry * 0.4;
    final x = centre.dx + (k - 1) * rx * 0.25;
    c.drawPath(Path()
      ..moveTo(x - rx * 0.3, y)
      ..quadraticBezierTo(x - rx * 0.15, y - 2, x, y)
      ..quadraticBezierTo(x + rx * 0.15, y + 2, x + rx * 0.3, y), ripple);
  }
}

// ---------- Sea motifs ----------

void inkWave(Canvas c, Offset p, double s) {
  final pen = inkPen(0.9 * s, const Color(0xaa2b1e16));
  for (var k = 0; k < 2; k++) {
    final o = p + Offset(k * 3 * s, k * 3.5 * s);
    c.drawPath(Path()
      ..moveTo(o.dx - 6 * s, o.dy)
      ..quadraticBezierTo(o.dx - 3 * s, o.dy - 2.6 * s, o.dx, o.dy)
      ..quadraticBezierTo(o.dx + 3 * s, o.dy + 2.6 * s, o.dx + 6 * s, o.dy), pen);
  }
}

void inkWhirlpool(Canvas c, Offset p, double r) {
  final path = Path()..moveTo(p.dx, p.dy);
  for (var a = 0.0; a < math.pi * 7; a += 0.15) {
    final rr = r * a / (math.pi * 7);
    path.lineTo(p.dx + math.cos(a) * rr, p.dy + math.sin(a) * rr * 0.55);
  }
  c.drawPath(path, inkPen(1));
  for (var k = 0; k < 4; k++) {
    final a = k * math.pi / 2 + 0.4;
    final o = p + Offset(math.cos(a) * r * 1.15, math.sin(a) * r * 0.62);
    c.drawArc(Rect.fromCenter(center: o, width: 10, height: 5), a + 1.2, 1.4, false, inkPen(0.8));
  }
}

// Three humps and a curled head in the waves
void inkSerpent(Canvas c, Offset p, double s) {
  final pen = inkPen(1.3 * s);
  for (var k = 0; k < 3; k++) {
    final o = p + Offset(k * 11 * s, 0);
    final hump = Path()
      ..moveTo(o.dx - 4 * s, o.dy)
      ..cubicTo(o.dx - 4 * s, o.dy - 8 * s, o.dx + 4 * s, o.dy - 8 * s, o.dx + 4 * s, o.dy);
    c.drawPath(hump, _paperFill);
    c.drawPath(hump, pen);
    c.drawLine(o + Offset(-1.5 * s, -4.5 * s), o + Offset(1.5 * s, -4.5 * s), inkPen(0.6 * s));
  }
  final h = p + Offset(-11 * s, 0);
  final neck = Path()
    ..moveTo(h.dx + 4 * s, h.dy)
    ..quadraticBezierTo(h.dx + 5 * s, h.dy - 10 * s, h.dx, h.dy - 11 * s)
    ..quadraticBezierTo(h.dx - 4 * s, h.dy - 11 * s, h.dx - 5 * s, h.dy - 8 * s);
  c.drawPath(neck, inkPen(2.4 * s));
  c.drawCircle(h + Offset(-0.5 * s, -10 * s), 0.8 * s, _paperFill);
  c.drawLine(h + Offset(-5 * s, -8 * s), h + Offset(-7.5 * s, -7 * s), inkPen(0.6 * s));
  for (var k = -1; k < 3; k++) {
    inkWave(c, p + Offset(k * 11 * s + 5 * s, 2 * s), 0.6 * s);
  }
}

void inkShip(Canvas c, Offset p, double s) {
  final hull = Path()
    ..moveTo(p.dx - 10 * s, p.dy - 4 * s)
    ..lineTo(p.dx + 10 * s, p.dy - 4 * s)
    ..quadraticBezierTo(p.dx + 7 * s, p.dy + 1 * s, p.dx, p.dy + 1 * s)
    ..quadraticBezierTo(p.dx - 7 * s, p.dy + 1 * s, p.dx - 10 * s, p.dy - 4 * s)
    ..close();
  _shape(c, hull, 1.1 * s);
  c.drawLine(p + Offset(0, -4 * s), p + Offset(0, -20 * s), inkPen(1 * s));
  final sail = Path()
    ..moveTo(p.dx - 7 * s, p.dy - 18 * s)
    ..quadraticBezierTo(p.dx - 4 * s, p.dy - 12 * s, p.dx - 7 * s, p.dy - 7 * s)
    ..lineTo(p.dx + 7 * s, p.dy - 7 * s)
    ..quadraticBezierTo(p.dx + 10 * s, p.dy - 12 * s, p.dx + 7 * s, p.dy - 18 * s)
    ..close();
  _shape(c, sail, 1 * s);
  c.drawLine(p + Offset(0, -20 * s), p + Offset(4 * s, -19 * s), inkPen(0.8 * s));
  inkWave(c, p + Offset(-12 * s, 3 * s), 0.6 * s);
  inkWave(c, p + Offset(10 * s, 3 * s), 0.6 * s);
}

// Eight-pointed compass rose, north up
void inkCompass(Canvas c, Offset p, double r) {
  for (var i = 0; i < 8; i++) {
    final long = i.isEven;
    final a = -math.pi / 2 + i * math.pi / 4;
    final len = long ? r : r * 0.55;
    final tip = p + Offset(math.cos(a), math.sin(a)) * len;
    final w = long ? r * 0.16 : r * 0.12;
    final l = p + Offset(math.cos(a - math.pi / 2), math.sin(a - math.pi / 2)) * w;
    final rr = p + Offset(math.cos(a + math.pi / 2), math.sin(a + math.pi / 2)) * w;
    c.drawPath(Path()..addPolygon([p, tip, l], true), _inkFill);
    c.drawPath(Path()..addPolygon([p, tip, rr], true), _paperFill);
    c.drawPath(Path()..addPolygon([l, tip, rr, p], true), inkPen(0.9));
  }
  c.drawCircle(p, r * 0.12, _paperFill);
  c.drawCircle(p, r * 0.12, inkPen(0.9));
  c.drawCircle(p, r * 0.72, inkPen(0.6));
  for (final (t, a) in [('N', -math.pi / 2), ('E', 0.0), ('S', math.pi / 2), ('W', math.pi)]) {
    inkText(c, t, p + Offset(math.cos(a), math.sin(a)) * (r + 9) - const Offset(0, 7), size: 12, halo: false);
  }
}

// A ribbon banner with curled ends and a title
void inkBanner(Canvas c, Offset centre, String text, {double size = 17}) {
  final tp = _textPainter(text, size, true, false, inkColor, 600);
  final w = tp.width + 36, h = size * 1.7;
  final body = Rect.fromCenter(center: centre, width: w, height: h);
  // Tails behind the ends, folded under
  for (final side in [-1.0, 1.0]) {
    final x = side < 0 ? body.left : body.right;
    final tail = Path()
      ..moveTo(x, body.top + 6)
      ..lineTo(x + side * 22, body.top + 6)
      ..lineTo(x + side * 14, body.center.dy + 6)
      ..lineTo(x + side * 22, body.bottom + 6)
      ..lineTo(x, body.bottom + 6)
      ..close();
    _shape(c, tail, 1.3);
    final fold = Path()
      ..moveTo(x, body.bottom)
      ..lineTo(x + side * 7, body.bottom + 6)
      ..lineTo(x, body.bottom + 6)
      ..close();
    c.drawPath(fold, _inkFill);
  }
  final ribbon = Path()
    ..moveTo(body.left, body.top)
    ..quadraticBezierTo(body.center.dx, body.top - 5, body.right, body.top)
    ..lineTo(body.right, body.bottom)
    ..quadraticBezierTo(body.center.dx, body.bottom - 5, body.left, body.bottom)
    ..close();
  _shape(c, ribbon, 1.5);
  c.drawPath(
      Path()
        ..moveTo(body.left + 4, body.top + 3)
        ..quadraticBezierTo(body.center.dx, body.top - 2, body.right - 4, body.top + 3),
      inkPen(0.6));
  tp.paint(c, Offset(centre.dx - tp.width / 2, centre.dy - tp.height / 2 - 2));
}

// ---------- Lettering ----------

final _texts = <(String, double, bool, bool, Color, double), TextPainter>{};

TextPainter _textPainter(String text, double size, bool bold, bool italic, Color color, double maxW) =>
    _texts.putIfAbsent((text, size, bold, italic, color, maxW), () {
      return TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: size,
            color: color,
            letterSpacing: bold ? size * 0.06 : 0,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            fontStyle: italic ? FontStyle.italic : FontStyle.normal,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: maxW);
    });

Size inkMeasure(String text, {double size = 12, bool bold = false, bool italic = false, double maxW = 220}) =>
    _textPainter(text, size, bold, italic, inkColor, maxW).size;

// Text centred on [at].dx with its top at [at].dy, with a paper halo so it reads over ink.
// Laid-out text is cached, so drawing the same label every frame is cheap.
Size inkText(Canvas c, String text, Offset at,
    {double size = 12, bool bold = false, bool italic = false, Color color = inkColor, bool halo = true, double maxW = 220}) {
  final tp = _textPainter(text, size, bold, italic, color, maxW);
  final o = at - Offset(tp.width / 2, 0);
  if (halo) {
    final h = _textPainter(text, size, bold, italic, paperColor.withValues(alpha: 0.85), maxW);
    for (final d in const [Offset(-1, 0), Offset(1, 0), Offset(0, -1), Offset(0, 1)]) {
      h.paint(c, o + d * (size / 9));
    }
  }
  tp.paint(c, o);
  return tp.size;
}
