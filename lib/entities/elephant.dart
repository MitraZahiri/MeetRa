import 'dart:math' as math;
import 'dart:ui';

import '../art/pixel.dart';
import '../game/effects.dart';
import '../sfx.dart';
import 'lion.dart';

// A shockwave rolling along the ground from where the elephant stamped
class _Quake {
  _Quake(this.x, this.y, this.dir, this.speed);
  double x;
  final double y, dir, speed;
  double t = 0;
  double dustT = 0;
  Rect get rect => Rect.fromLTWH(x - 5, y - 9, 10, 9);
}

// The White Elephant, boss of Hearthvale: a war elephant gone wild, still wearing its red cloth.
// Loop: plod towards Ra, then either rear up and stamp, sending shockwaves rolling along the
// ground both ways (jump over them), or lower its tusks and charge. A charge into a wall stuns it.
// Below half health it is enraged: it stamps twice and the waves run faster.
class Elephant extends Lion {
  Elephant(super.game, super.x, super.y, {super.maxHp}) : super(w: 40, h: 30, walk: const [0, 1, 2, 3], scale: 1);

  final _quakes = <_Quake>[];
  LionState _move = LionState.charge;
  int _stamps = 0;
  double _dustT = 0;

  @override
  bool get facesLeft => true;

  @override
  Offset get nose => Offset(x + facing * 22, y - 8);

  @override
  Iterable<Rect> get hazards => _quakes.map((q) => q.rect);

  @override
  void think(double time, double dt) {
    final p = game.player;
    final b = body;
    void faceP() {
      final s = (p.x - x).sign.toInt();
      if (s != 0) facing = s;
    }

    _updateQuakes(dt);
    switch (state) {
      case LionState.intro:
        b.vx = 0;
        stop(0);
        if (timer <= 0) setState(LionState.pace, 1100);

      case LionState.pace:
        faceP();
        b.vx = facing * (enraged ? 48 : 32);
        play(enraged ? 1.4 : 1);
        if (timer <= 0) {
          // Far from Ra it would rather stamp; close by, it would rather charge
          final far = (p.x - x).abs() > 90;
          final stamp = rand.nextDouble() < (far ? 0.65 : 0.35);
          _move = stamp ? LionState.pounce : LionState.charge;
          _stamps = stamp && enraged ? 2 : 1;
          setState(LionState.telegraph, enraged ? 450 : 650);
          game.floatText(x + facing * 20, y - 46, '!', const Color(0xffff5a3a), size: 14, rise: 6, duration: 600);
          sfx.trumpet();
        }

      case LionState.telegraph:
        faceP();
        b.vx = 0;
        // Rears up before a stamp; lowers its tusks and paws the ground before a charge
        stop(_move == LionState.pounce ? 4 : 5);
        tint = (time / 70).floor() % 2 == 1 ? 0xffff8060 : null;
        if (_move == LionState.charge) {
          _dustT -= dt;
          if (_dustT <= 0) {
            _dustT = 120;
            game.particles.dust(x - facing * 14, y, count: 2, dir: -facing.toDouble(), spread: 14, color: 0xffc8b8a0);
          }
        }
        if (timer <= 0) {
          tint = null;
          if (_move == LionState.charge) {
            setState(LionState.charge);
            game.camera.shake(200, 0.004);
          } else {
            _stamp();
          }
        }

      case LionState.charge:
        b.vx = facing * (enraged ? 230 : 190);
        play(2.2);
        _dustT -= dt;
        if (_dustT <= 0) {
          _dustT = 45;
          game.particles.dust(x - facing * 18, y, count: 2, dir: -facing.toDouble(), spread: 20, color: 0xffc8b8a0);
        }
        final hitWall = (facing < 0 && b.blockedLeft) || (facing > 0 && b.blockedRight);
        if (hitWall) {
          b
            ..vx = -facing * 50
            ..vy = -100;
          sfx.thud();
          game.camera.shake(350, 0.014);
          game.burst(x + facing * 22, y - 14, [0xffc8b8a0, 0xff8a7a68], 14, 120);
          game.particles
            ..ring(x + facing * 22, y - 14, 0xfffff4c0, r1: 32, life: 380, width: 3)
            ..spark(x + facing * 22, y - 16, size: 18);
          for (var i = 0; i < 3; i++) {
            game.floatText(x + (i - 1) * 9, y - 40, '*', const Color(0xfffff0a0), size: 9, rise: 10, duration: 1600, drift: (i - 1) * 6.0);
          }
          stop(0);
          setState(LionState.stunned, 1700);
        }

      // After a stamp it stands with its feet planted while the waves roll away
      case LionState.pounce:
        b.vx = 0;
        if (timer <= 0) {
          _stamps--;
          if (_stamps > 0) {
            _move = LionState.pounce;
            setState(LionState.telegraph, 320);
          } else {
            setState(LionState.pace, 1000 + rand.nextDouble() * 800);
          }
        }

      case LionState.stunned:
        if (b.blockedDown) b.vx *= 0.9;
        stop(0);
        angle = math.sin(time / 50) * 2;
        if (timer <= 0) {
          angle = 0;
          setState(LionState.pace, 700);
        }

      case LionState.dead:
        break;
    }
  }

  void _stamp() {
    stop(6);
    sfx.thud();
    game.camera.shake(320, 0.014);
    game.particles
      ..dust(x + facing * 14, y, count: 12, spread: 80, color: 0xffc8b8a0)
      ..ring(x + facing * 14, y - 2, 0xfffff4c0, r1: 30, life: 360, width: 3);
    final speed = enraged ? 165.0 : 135.0;
    for (final dir in [-1.0, 1.0]) {
      _quakes.add(_Quake(x + dir * 22, y, dir, speed));
    }
    setState(LionState.pounce, 520);
  }

  void _updateQuakes(double dt) {
    final left = game.arenaLeft ?? -1e9, right = game.arenaRight ?? 1e9;
    for (final q in _quakes) {
      q
        ..t += dt
        ..x += q.dir * q.speed * dt / 1000
        ..dustT -= dt;
      if (q.dustT <= 0) {
        q.dustT = 50;
        game.particles.dust(q.x, q.y, count: 1, dir: q.dir, spread: 10, color: 0xffd8c8a8);
      }
    }
    _quakes.removeWhere((q) => q.t > 3000 || q.x < left + 6 || q.x > right - 6);
  }

  @override
  void die() {
    _quakes.clear();
    super.die();
  }

  @override
  void render(Canvas c, Sheet sheet) {
    // Each wave is a hump of earth heaving up, with a pale crest
    final earth = Paint()..color = const Color(0xffa88a60);
    final crest = Paint()..color = const Color(0xfff4e8c8);
    for (final q in _quakes) {
      final grow = math.min(1.0, q.t / 150);
      final h = 9 * grow * (1 + 0.15 * math.sin(q.t / 40));
      final front = q.x + q.dir * 5;
      final back = q.x - q.dir * 7;
      c.drawPath(Path()..addPolygon([Offset(back, q.y), Offset(q.x, q.y - h), Offset(front, q.y)], true), earth);
      c.drawRect(Rect.fromLTWH(q.x - 1.5, q.y - h, 3, 1.5), crest);
    }
    super.render(c, sheet);
  }
}
