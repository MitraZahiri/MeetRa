import 'dart:math' as math;
import 'dart:ui';

import '../art/pixel.dart';
import '../game/effects.dart';
import '../game/meetra_game.dart';
import '../game/physics.dart';

// Shared enemy behaviour: health, hit flash, squash and knockback, loot on death
abstract class Enemy {
  Enemy(this.game, this.body, {required this.hp, required this.contactDamage, required this.xpValue, required this.goldValue, required this.colors});

  final MeetRaGame game;
  final Body body;
  int hp;
  final int contactDamage;
  final int xpValue;
  final int goldValue;
  final List<int> colors;
  double stun = 0;
  bool dying = false;
  bool removed = false;
  double _flash = 0;
  double _squash = 0;
  bool flipX = false;

  double get x => body.x;
  double get y => body.y;
  Sheet get sheet;
  Anim get anim;

  void update(double dt);

  void hurt(int dmg, double dir, [double knock = 1]) {
    if (dying) return;
    hp -= dmg;
    _flash = 80;
    _squash = 160;
    game.floatText(x, y - sheet.frameH, '$dmg', const Color(0xffffe28a), size: knock > 1.5 ? 11 : 8);
    game.particles.spark(x + dir * -3, y - sheet.frameH / 2, size: knock > 1.5 ? 12 : 8);
    if (hp <= 0) {
      die();
      return;
    }
    stun = 300;
    body.vx = dir * 140 * knock;
    if (body.allowGravity) body.vy = -110 * knock;
  }

  void die() {
    dying = true;
    final cy = y - sheet.frameH / 2;
    game.burst(x, cy, colors, 16, 150);
    game.particles
      ..ring(x, cy, 0xfffff4c0, r1: 16, life: 300)
      ..spark(x, cy, size: 14);
    // A few wisps of the Hollow's shadow escape upwards
    for (var i = 0; i < 4; i++) {
      game.particles.ember(x, cy, 0xff9a7ab8);
    }
    game.spawnGold(x, y - 8, goldValue);
    game.spawnXp(x, y - 8, xpValue);
    removed = true;
  }

  void tick(double dt) {
    _flash = math.max(0, _flash - dt);
    _squash = math.max(0, _squash - dt);
    anim.update(dt);
    update(dt);
  }

  // Extra squash/stretch from the subclass (walking bob, wing beats)
  (double, double) get pose => (1, 1);

  void render(Canvas c) {
    final k = _squash / 160;
    final (px, py) = pose;
    drawFrame(c, sheet, anim.frame, x.roundToDouble(), y.roundToDouble(),
        flipX: flipX, scaleX: px * (1 + 0.3 * k), scaleY: py * (1 - 0.25 * k), tintFill: _flash > 0 ? 0xffffffff : null);
  }
}

class Imp extends Enemy {
  Imp(MeetRaGame game, double x, double y)
      : super(game, Body(x, y, 10, 14), hp: 3, contactDamage: 1, xpValue: 6, goldValue: 3, colors: [0xff4a8a3a, 0xff2e5a26, 0xffe8dcc0]);

  double dir = -1;
  bool _aggro = false;
  double _t = rand.nextDouble() * 10;
  @override
  final anim = Anim([0, 1], 6);
  @override
  Sheet get sheet => game.art.imp;

  @override
  (double, double) get pose {
    final b = math.sin(_t * (_aggro ? 18 : 9)) * 0.04;
    return (1 - b, 1 + b);
  }

  @override
  void update(double dt) {
    _t += dt / 1000;
    if (dying) return;
    if (y > game.level.height + 60) {
      removed = true;
      return;
    }
    if (stun > 0) {
      stun -= dt;
      return;
    }
    final p = game.player;
    final dx = p.x - x;
    final aggro = !p.dead && dx.abs() < 90 && (p.y - y).abs() < 24;
    // Spotting Ra: a '!' and a little hop of surprise
    if (aggro && !_aggro) {
      game.floatText(x, y - 20, '!', const Color(0xffff6a50), size: 10, rise: 6, duration: 700);
      if (body.blockedDown) body.vy = -90;
    }
    _aggro = aggro;
    if (aggro && dx != 0) dir = dx.sign;

    final b = body;
    if ((dir < 0 && b.blockedLeft) || (dir > 0 && b.blockedRight)) dir *= -1;
    // Turn around at ledges
    if (b.blockedDown && game.level.tileAtWorld(x + dir * 8, y + 4) < 0) dir *= -1;
    b.vx = dir * (aggro ? 70 : 30);
    flipX = dir > 0;
    anim.timeScale = aggro ? 2 : 1;
  }
}

class Bat extends Enemy {
  Bat(MeetRaGame game, double x, double y)
      : super(game, Body(x, y, 10, 6)..allowGravity = false,
            hp: 2, contactDamage: 1, xpValue: 4, goldValue: 2, colors: [0xff4b2a5e, 0xff7a4a8e]) {
    anim.timeScale = 0.3;
  }

  bool awake = false;
  double t = rand.nextDouble() * 10;
  double _zzz = rand.nextDouble() * 1400;
  @override
  final anim = Anim([0, 1], 8);
  @override
  Sheet get sheet => game.art.bat;

  @override
  (double, double) get pose => awake ? (1, 1) : (1 + math.sin(t * 2) * 0.04, 1 - math.sin(t * 2) * 0.04);

  @override
  void update(double dt) {
    if (dying) return;
    t += dt / 1000;
    if (stun > 0) {
      stun -= dt;
      body
        ..vx *= 0.9
        ..vy *= 0.9;
      return;
    }
    final p = game.player;
    final dx = p.x - x;
    final dy = p.y - 10 - y;
    final d = math.sqrt(dx * dx + dy * dy);
    if (!awake && d < 110 && !p.dead) {
      awake = true;
      anim.timeScale = 1;
      game.floatText(x, y - 10, '!', const Color(0xffff6a50), size: 10, rise: 6, duration: 700);
    }
    if (!awake) {
      // Sleeping: drifting z's
      _zzz -= dt;
      if (_zzz <= 0) {
        _zzz = 1400;
        game.floatText(x + 4, y - 8, 'z', const Color(0xffd8d0f0), size: 7, rise: 14, duration: 1400, drift: 6);
      }
      body
        ..vx = 0
        ..vy = math.sin(t * 2) * 8;
      return;
    }
    final dd = d == 0 ? 1 : d;
    body
      ..vx = (dx / dd) * 60
      ..vy = (dy / dd) * 60 + math.sin(t * 6) * 40;
    flipX = dx > 0;
  }
}
