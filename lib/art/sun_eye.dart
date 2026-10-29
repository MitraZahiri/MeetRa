// The ornamental golden sun, with the Eye of Ra open inside it: the sky is always watching.
// Shared by the sky behind every level and the title screen.

import 'dart:math' as math;
import 'dart:ui';

const _gold = Color(0xffd4a845);
const _face = Color(0xfff7d774);
const _lid = Color(0xff7a4a10);
const _white = Color(0xfffff6dc);
const _iris = Color(0xffc0581a);
const _irisRim = Color(0xff7a2a10);
const _pupil = Color(0xff1a1020);

// Sixteen pointed rays round a gold disc, centred on [at], in units of [s]
void paintSunDisc(Canvas c, Offset at, double s) {
  final gold = Paint()..color = _gold;
  for (var i = 0; i < 16; i++) {
    final a = (i / 16) * math.pi * 2;
    Offset p(double ang, double r) => at + Offset(math.cos(ang), math.sin(ang)) * r * s;
    c.drawPath(Path()..addPolygon([p(a - 0.12, 24), p(a, 34), p(a + 0.12, 24)], true), gold);
  }
  c.drawCircle(at, 22 * s, Paint()..color = _face);
  c.drawCircle(
      at,
      17 * s,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * s
        ..color = _gold);
}

// How open the eye is at time [t] seconds: a slow blink every few seconds, sometimes twice
double sunBlink(double t) {
  final p = t % 5.3;
  double shut(double start) => p >= start && p < start + 0.2 ? math.sin((p - start) / 0.2 * math.pi) : 0;
  final twice = (t / 5.3).floor() % 3 == 2;
  return 1 - math.max(shut(0), twice ? shut(0.32) : 0);
}

// The eye inside the sun. [look] points where it gazes (length up to 1), [open] runs 0..1.
void paintSunEye(Canvas c, Offset at, double s, {Offset look = Offset.zero, double open = 1}) {
  c.save();
  c.translate(at.dx, at.dy);
  c.scale(s);
  final lid = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 1.6
    ..color = _lid;
  // A heavy brow arched over the eye
  c.drawPath(
      Path()
        ..moveTo(-12, -7)
        ..quadraticBezierTo(0, -13, 12, -7),
      lid..strokeWidth = 2);
  lid.strokeWidth = 1.6;
  final o = open.clamp(0.0, 1.0);
  if (o < 0.12) {
    // Shut: only the line of the lid
    c.drawPath(
        Path()
          ..moveTo(-12, 0)
          ..quadraticBezierTo(0, 4, 12, 0),
        lid);
    c.restore();
    return;
  }
  final almond = Path()
    ..moveTo(-12, 0)
    ..quadraticBezierTo(0, -11 * o, 12, 0)
    ..quadraticBezierTo(0, 11 * o, -12, 0)
    ..close();
  c.drawPath(almond, Paint()..color = _white);
  c.save();
  c.clipPath(almond);
  final d = look.distance;
  final iris = (d > 1 ? look / d : look) * 5;
  c.drawCircle(iris, 4.8, Paint()..color = _irisRim);
  c.drawCircle(iris, 3.8, Paint()..color = _iris);
  c.drawCircle(iris, 2, Paint()..color = _pupil);
  c.drawCircle(iris + const Offset(-1.3, -1.3), 0.9, Paint()..color = _white);
  // The upper lid casts a little shadow over the white
  c.drawPath(
      Path()
        ..moveTo(-12, 0)
        ..quadraticBezierTo(0, -11 * o, 12, 0)
        ..quadraticBezierTo(0, -7 * o, -12, 0),
      Paint()..color = const Color(0x557a4a10));
  c.restore();
  c.drawPath(almond, lid);
  // A painted wing at the outer corner, as on old eye charms
  c.drawPath(
      Path()
        ..moveTo(11, -0.5)
        ..lineTo(16, -2.5),
      lid);
  c.restore();
}
