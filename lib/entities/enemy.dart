import 'dart:math' as math;
import 'dart:ui';

import '../art/pixel.dart';
import '../game/effects.dart';
import '../game/meetra_game.dart';
import '../game/physics.dart';

// Shared enemy behaviour: health, hit flash and knockback, loot on death
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
    game.floatText(x, y - sheet.frameH, '$dmg', const Color(0xffffe28a));
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
    game.burst(x, y - sheet.frameH / 2, colors, 14, 140);
    game.spawnGold(x, y - 8, goldValue);
    game.spawnXp(x, y - 8, xpValue);
    removed = true;
  }

  void tick(double dt) {
    _flash = math.max(0, _flash - dt);
    anim.update(dt);
    update(dt);
  }

  void render(Canvas c) => drawFrame(c, sheet, anim.frame, x.roundToDouble(), y.roundToDouble(),
      flipX: flipX, tintFill: _flash > 0 ? 0xffffffff : null);
}

class Imp extends Enemy {
  Imp(MeetRaGame game, double x, double y)
      : super(game, Body(x, y, 10, 14), hp: 3, contactDamage: 1, xpValue: 6, goldValue: 3, colors: [0xff4a8a3a, 0xff2e5a26, 0xffe8dcc0]);

  double dir = -1;
  @override
  final anim = Anim([0, 1], 6);
  @override
  Sheet get sheet => game.art.imp;

  @override
  void update(double dt) {
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
  @override
  final anim = Anim([0, 1], 8);
  @override
  Sheet get sheet => game.art.bat;

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
    }
    if (!awake) {
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
