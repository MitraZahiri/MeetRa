import 'dart:math' as math;
import 'dart:ui';

import '../art/pixel.dart';
import '../config.dart';
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
  bool asleep = false; // far off screen: neither thinks nor moves

  double get x => body.x;
  double get y => body.y;
  Sheet get sheet;
  Anim get anim;
  int get frame => anim.frame;
  // True while it cannot hurt Ra by touch (a ghoul still buried in the sand)
  bool get harmless => false;
  // True while blows and feathers pass straight through it (Al, vanished into the air)
  bool get hidden => false;
  double get alpha => 1;
  // Width of the drop shadow; 0 for none
  double get shadowW => 14;

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
    drawFrame(c, sheet, frame, x.roundToDouble(), y.roundToDouble(),
        flipX: flipX, scaleX: px * (1 + 0.3 * k), scaleY: py * (1 - 0.25 * k), alpha: alpha, tintFill: _flash > 0 ? 0xffffffff : null);
  }
}

// The horned demon: patrols, charges when it sees Ra, and up close raises its club and lunges
class Demon extends Enemy {
  Demon(MeetRaGame game, double x, double y)
      : super(game, Body(x, y, 12, 18), hp: 3, contactDamage: 1, xpValue: 6, goldValue: 3, colors: [0xff3d4f8a, 0xffc8602a, 0xffe8dcc0]);

  double dir = -1;
  bool _aggro = false;
  double _t = rand.nextDouble() * 10;
  double _windup = 0; // ms the club is held high before the lunge
  double _lunge = 0;
  double _rest = 0; // ms before it may lunge again
  @override
  final anim = Anim([0, 1, 2, 3], 7);
  @override
  Sheet get sheet => game.art.demon;
  @override
  int get frame => _windup > 0 ? 4 : anim.frame;

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
      _windup = _lunge = 0;
      return;
    }
    final p = game.player;
    final dx = p.x - x;
    final b = body;
    _rest = math.max(0, _rest - dt);
    if (_windup > 0) {
      b.vx = 0;
      _windup -= dt;
      if (_windup <= 0) {
        _lunge = 220;
        game.particles.dust(x - dir * 4, y);
      }
      return;
    }
    if (_lunge > 0) {
      _lunge -= dt;
      b.vx = dir * 170;
      if (_lunge <= 0) _rest = 900;
      return;
    }
    final aggro = !p.dead && dx.abs() < 90 && (p.y - y).abs() < 24;
    // Spotting Ra: a '!' and a little hop of surprise
    if (aggro && !_aggro) {
      game.floatText(x, y - 20, '!', const Color(0xffff6a50), size: 10, rise: 6, duration: 700);
      if (body.blockedDown) body.vy = -90;
    }
    _aggro = aggro;
    if (aggro && dx != 0) dir = dx.sign;
    flipX = dir > 0;
    if (aggro && dx.abs() < 34 && _rest <= 0 && b.blockedDown) {
      _windup = 380;
      b.vx = 0;
      return;
    }

    if ((dir < 0 && b.blockedLeft) || (dir > 0 && b.blockedRight)) dir *= -1;
    // Turn around at ledges
    if (b.blockedDown && game.level.tileAtWorld(x + dir * 8, y + 4) < 0) dir *= -1;
    b.vx = dir * (aggro ? 70 : 30);
    flipX = dir > 0;
    anim.timeScale = aggro ? 2 : 1;
  }
}

// The carrion fly: hovers lazily until Ra comes near, then buzzes after Ra in a zigzag
class Fly extends Enemy {
  Fly(MeetRaGame game, double x, double y)
      : super(game, Body(x, y, 12, 8)..allowGravity = false,
            hp: 2, contactDamage: 1, xpValue: 4, goldValue: 2, colors: [0xff3a7a5a, 0xffc8302a, 0xffd8eef0]) {
    anim.timeScale = 0.35;
  }

  bool awake = false;
  double t = rand.nextDouble() * 10;
  @override
  final anim = Anim([0, 1], 24);
  @override
  Sheet get sheet => game.art.fly;
  @override
  double get shadowW => 9;

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
      // Idle: a slow figure-of-eight in the air
      body
        ..vx = math.cos(t * 1.3) * 10
        ..vy = math.sin(t * 2.6) * 8;
      return;
    }
    // Hunting: darts at Ra with sudden sideways jinks, like a fly at a window
    final dd = d == 0 ? 1 : d;
    final jink = math.sin(t * 9) * 55;
    body
      ..vx = (dx / dd) * 64 - (dy / dd) * jink
      ..vy = (dy / dd) * 64 + (dx / dd) * jink * 0.6;
    flipX = dx > 0;
  }
}

// The ghoul of the waste: lies buried as a heap of sand until Ra walks close, bursts out,
// lopes after Ra on all fours and pounces. If Ra gets away it sinks back into the sand.
class Ghoul extends Enemy {
  Ghoul(MeetRaGame game, double x, double y)
      : super(game, Body(x, y, 14, 14), hp: 4, contactDamage: 1, xpValue: 8, goldValue: 4, colors: [0xff9a9078, 0xffe8e4d8, 0xffd8b878]);

  double dir = -1;
  bool buried = true;
  double _rise = 0; // ms left of climbing out of the sand
  double _lost = 0; // ms since Ra was last in reach
  double _rest = 0; // ms before it may pounce again
  bool _pouncing = false;
  @override
  final anim = Anim([2, 3, 4, 5], 9);
  @override
  Sheet get sheet => game.art.ghoul;
  @override
  bool get harmless => buried || _rise > 0;
  @override
  double get shadowW => buried ? 0 : 16;
  @override
  int get frame => buried ? 0 : _rise > 0 ? 1 : _pouncing ? 6 : anim.frame;

  // Bursts out of the sand (also used when a trial calls it up)
  void wake() {
    buried = false;
    _rise = 420;
    _lost = 0;
    game.burst(x, y - 4, const [0xffd8b878, 0xffb08a50], 10, 90);
    game.particles.dust(x, y);
  }

  @override
  void hurt(int dmg, double dir, [double knock = 1]) {
    if (buried) wake();
    super.hurt(dmg, dir, knock);
  }

  @override
  void update(double dt) {
    if (dying) return;
    if (y > game.level.height + 60) {
      removed = true;
      return;
    }
    final p = game.player;
    final dx = p.x - x;
    final b = body;
    final near = !p.dead && dx.abs() < 64 && (p.y - y).abs() < 40;
    if (buried) {
      b.vx = 0;
      if (near) wake();
      return;
    }
    if (_rise > 0) {
      _rise -= dt;
      b.vx = 0;
      if (_rise <= 0) game.floatText(x, y - 22, '!', const Color(0xffff6a50), size: 10, rise: 6, duration: 700);
      return;
    }
    if (stun > 0) {
      stun -= dt;
      _pouncing = false;
      return;
    }
    _rest = math.max(0, _rest - dt);
    if (_pouncing) {
      if (b.blockedDown && b.vy >= 0) {
        _pouncing = false;
        _rest = 700;
        b.vx = 0;
        game.particles.dust(x, y);
      }
      return;
    }
    // Ra slipped away: wait a little, then sink back into the sand
    final chasing = !p.dead && dx.abs() < 200 && (p.y - y).abs() < 60;
    _lost = chasing ? 0 : _lost + dt;
    if (_lost > 2500 && b.blockedDown) {
      buried = true;
      b.vx = 0;
      game.particles.dust(x, y);
      return;
    }
    if (chasing && dx != 0) dir = dx.sign;
    if (chasing && dx.abs() < 56 && dx.abs() > 16 && _rest <= 0 && b.blockedDown) {
      _pouncing = true;
      b
        ..vx = dir * 150
        ..vy = -190;
      flipX = dir > 0;
      return;
    }
    if ((dir < 0 && b.blockedLeft) || (dir > 0 && b.blockedRight)) dir *= -1;
    if (b.blockedDown && game.level.tileAtWorld(x + dir * 9, y + 4) < 0) {
      // A chasing ghoul leaps over the gap after Ra; a wandering one turns back
      if (chasing && (p.x - x).sign == dir) {
        b.vy = -230;
      } else {
        dir *= -1;
      }
    }
    b.vx = dir * (chasing ? 88 : 24);
    flipX = dir > 0;
    anim.timeScale = chasing ? 1.6 : 0.6;
  }
}

// The scorpion, one of the noxious creatures the dark spirit set loose on the world.
// Small, low and quick: it scuttles in fits and starts, then darts in with its sting raised.
// They come in pairs.
class Scorpion extends Enemy {
  Scorpion(MeetRaGame game, double x, double y)
      : super(game, Body(x, y, 12, 7), hp: 1, contactDamage: 1, xpValue: 3, goldValue: 1, colors: [0xffb8762a, 0xffe8b060, 0xffd83a2a]);

  double dir = rand.nextBool() ? 1 : -1;
  double _t = rand.nextDouble() * 2000; // ms into its scuttle-and-stop rhythm
  double _windup = 0;
  double _dart = 0;
  double _rest = 0;
  @override
  final anim = Anim([0, 1], 14);
  @override
  Sheet get sheet => game.art.scorpion;
  @override
  int get frame => _windup > 0 || _dart > 0 ? 2 : anim.frame;
  @override
  double get shadowW => 11;

  @override
  void update(double dt) {
    if (dying) return;
    if (y > game.level.height + 60) {
      removed = true;
      return;
    }
    final b = body;
    if (stun > 0) {
      stun -= dt;
      _windup = _dart = 0;
      return;
    }
    _t += dt;
    _rest = math.max(0, _rest - dt);
    if (_windup > 0) {
      b.vx = 0;
      _windup -= dt;
      if (_windup <= 0) _dart = 160;
      return;
    }
    if (_dart > 0) {
      _dart -= dt;
      b.vx = dir * 150;
      if (_dart <= 0) _rest = 700;
      return;
    }
    final p = game.player;
    final dx = p.x - x;
    if (!p.dead && dx.abs() < 46 && (p.y - y).abs() < 18 && _rest <= 0 && b.blockedDown) {
      dir = dx.sign == 0 ? dir : dx.sign;
      flipX = dir > 0;
      _windup = 260;
      return;
    }
    if ((dir < 0 && b.blockedLeft) || (dir > 0 && b.blockedRight)) dir *= -1;
    if (b.blockedDown && game.level.tileAtWorld(x + dir * 7, y + 4) < 0) dir *= -1;
    // Scuttle for a moment, freeze, scuttle again
    final moving = _t % 1000 < 620;
    b.vx = moving ? dir * 46 : 0;
    anim.timeScale = moving ? 1 : 0;
    flipX = dir > 0;
  }
}

// The man-eater: a red lion with a bearded man's face, three rows of teeth and a scorpion's tail.
// Big and heavy: it paces, roars when it sees Ra, then charges until it passes Ra or hits a wall.
// Blows barely push it back.
class Manticore extends Enemy {
  Manticore(MeetRaGame game, double x, double y)
      : super(game, Body(x, y, 30, 22), hp: 10, contactDamage: 2, xpValue: 24, goldValue: 12, colors: [0xffb8442a, 0xff5a2a1a, 0xffd8a070]);

  double dir = -1;
  double _roar = 0; // ms of standing and roaring before the charge
  double _charge = 0; // ms the charge may still last
  double _rest = 0;
  @override
  final anim = Anim([0, 1, 2, 3], 6);
  @override
  Sheet get sheet => game.art.manticore;
  @override
  int get frame => _roar > 0 ? 4 : _charge > 0 ? 5 : anim.frame;
  @override
  double get shadowW => 36;

  @override
  void hurt(int dmg, double dir, [double knock = 1]) {
    super.hurt(dmg, dir, knock);
    if (dying) return;
    // Too heavy to be thrown about, and only a blink of a stagger
    body
      ..vx *= 0.2
      ..vy = 0;
    stun = 120;
  }

  void _stop() {
    _charge = 0;
    _rest = 1000;
    body.vx = 0;
    game.particles.dust(x + dir * 14, y);
  }

  @override
  void update(double dt) {
    if (dying) return;
    if (y > game.level.height + 60) {
      removed = true;
      return;
    }
    final b = body;
    if (stun > 0) {
      stun -= dt;
      return;
    }
    final p = game.player;
    final dx = p.x - x;
    _rest = math.max(0, _rest - dt);
    if (_roar > 0) {
      b.vx = 0;
      _roar -= dt;
      if (_roar <= 0) _charge = 1500;
      return;
    }
    if (_charge > 0) {
      _charge -= dt;
      b.vx = dir * 175;
      anim.timeScale = 2.5;
      if (rand.nextDouble() < 0.15) game.particles.dust(x - dir * 12, y);
      final passed = dx.sign != dir && dx.abs() > 70;
      final ledge = b.blockedDown && game.level.tileAtWorld(x + dir * 18, y + 4) < 0;
      if (_charge <= 0 || passed || ledge || (dir < 0 && b.blockedLeft) || (dir > 0 && b.blockedRight)) _stop();
      return;
    }
    if (!p.dead && dx.abs() < 170 && (p.y - y).abs() < 40 && _rest <= 0 && b.blockedDown) {
      dir = dx.sign == 0 ? dir : dx.sign;
      flipX = dir > 0;
      _roar = 650;
      game.camera.shake(250, 0.004);
      game.particles.ring(x - dir * 14, y - 16, 0xfff0d8a8, r1: 26, life: 400);
      return;
    }
    if ((dir < 0 && b.blockedLeft) || (dir > 0 && b.blockedRight)) dir *= -1;
    if (b.blockedDown && game.level.tileAtWorld(x + dir * 18, y + 4) < 0) dir *= -1;
    b.vx = dir * 22;
    anim.timeScale = 1;
    flipX = dir > 0;
  }
}

// The stone-hurling div: slow and heavy. When Ra is in sight it stops, heaves a boulder over its
// head and lobs it in an arc to where Ra stands. Swing at the boulder to smash it in the air.
class Div extends Enemy {
  Div(MeetRaGame game, double x, double y)
      : super(game, Body(x, y, 16, 26), hp: 5, contactDamage: 2, xpValue: 14, goldValue: 6, colors: [0xff9a5a34, 0xff8a8a96, 0xffe8c050]);

  double dir = -1;
  double _heave = 0; // ms the boulder is held overhead
  double _throw = 0; // ms of the follow-through
  double _rest = rand.nextDouble() * 800;
  @override
  final anim = Anim([0, 1], 4);
  @override
  Sheet get sheet => game.art.div;
  @override
  int get frame => _heave > 0 ? 2 : _throw > 0 ? 3 : anim.frame;
  @override
  double get shadowW => 20;

  @override
  void hurt(int dmg, double dir, [double knock = 1]) {
    super.hurt(dmg, dir, knock);
    if (dying) return;
    body.vx *= 0.4;
    stun = 180;
    _heave = 0;
  }

  @override
  void update(double dt) {
    if (dying) return;
    if (y > game.level.height + 60) {
      removed = true;
      return;
    }
    final b = body;
    if (stun > 0) {
      stun -= dt;
      return;
    }
    _rest = math.max(0, _rest - dt);
    final p = game.player;
    final dx = p.x - x;
    if (_heave > 0) {
      b.vx = 0;
      _heave -= dt;
      if (_heave <= 0) {
        _throw = 300;
        // Aim for where Ra stands: a fixed flight time, so far throws fly faster
        const t = 0.85;
        final dy = (p.y - 6) - (y - 30);
        game.enemyShot(x + dir * 4, y - 30, dx / t, dy / t - gravity * t / 2, rock: true, dmg: 2);
      }
      return;
    }
    if (_throw > 0) {
      _throw -= dt;
      if (_throw <= 0) _rest = math.max(900, 2000 - game.def.enemyBonus * 150);
      return;
    }
    final sees = !p.dead && dx.abs() < 210 && dx.abs() > 36 && (p.y - y).abs() < 90;
    if (sees && dx != 0) dir = dx.sign;
    flipX = dir > 0;
    if (sees && _rest <= 0 && b.blockedDown) {
      _heave = 520;
      b.vx = 0;
      game.floatText(x, y - 34, '!', const Color(0xffff6a50), size: 10, rise: 6, duration: 600);
      return;
    }
    if ((dir < 0 && b.blockedLeft) || (dir > 0 && b.blockedRight)) dir *= -1;
    if (b.blockedDown && game.level.tileAtWorld(x + dir * 10, y + 4) < 0) dir *= -1;
    // Close in slowly on Ra, or stomp about
    b.vx = dir * (sees ? 26 : 18);
    flipX = dir > 0;
  }
}

// A serpent of the snake-shouldered king. It slithers low; when Ra is level with it, it rears
// up and spits a glob of venom straight at Ra. Jump the venom or cut it out of the air.
class Serpent extends Enemy {
  Serpent(MeetRaGame game, double x, double y)
      : super(game, Body(x, y, 16, 8), hp: 2, contactDamage: 1, xpValue: 8, goldValue: 3, colors: [0xff22302a, 0xffd8b050, 0xff8ae04a]);

  double dir = rand.nextBool() ? 1 : -1;
  double _rear = 0; // ms reared up before the spit
  double _rest = rand.nextDouble() * 1000;
  @override
  final anim = Anim([0, 1], 6);
  @override
  Sheet get sheet => game.art.serpent;
  @override
  int get frame => _rear > 0 ? 2 : anim.frame;
  @override
  double get shadowW => 14;

  @override
  void update(double dt) {
    if (dying) return;
    if (y > game.level.height + 60) {
      removed = true;
      return;
    }
    final b = body;
    if (stun > 0) {
      stun -= dt;
      _rear = 0;
      return;
    }
    _rest = math.max(0, _rest - dt);
    final p = game.player;
    final dx = p.x - x;
    if (_rear > 0) {
      b.vx = 0;
      _rear -= dt;
      if (_rear <= 0) {
        _rest = math.max(1000, 2200 - game.def.enemyBonus * 150);
        final dy = (p.y - 8) - (y - 10);
        final d = math.max(1.0, math.sqrt(dx * dx + dy * dy));
        game.enemyShot(x + dir * 8, y - 10, dx / d * 170, dy / d * 170, dmg: 1);
      }
      return;
    }
    final level = !p.dead && dx.abs() < 170 && (p.y - y).abs() < 40;
    if (level && _rest <= 0 && b.blockedDown) {
      dir = dx.sign == 0 ? dir : dx.sign;
      flipX = dir > 0;
      _rear = 420;
      return;
    }
    if ((dir < 0 && b.blockedLeft) || (dir > 0 && b.blockedRight)) dir *= -1;
    if (b.blockedDown && game.level.tileAtWorld(x + dir * 9, y + 4) < 0) dir *= -1;
    b.vx = dir * 34;
    flipX = dir > 0;
  }
}

enum _AlMood { drift, gone, rising, claw }

// Al, the hag-spirit: drifts half-seen in the air, melts away, and comes back right behind Ra
// with her claws out. She flickers for a moment before she strikes: turn and hit her then.
class Al extends Enemy {
  Al(MeetRaGame game, double x, double y)
      : super(game, Body(x, y, 12, 18)..allowGravity = false,
            hp: 3, contactDamage: 2, xpValue: 12, goldValue: 5, colors: [0xff8a1a2a, 0xffd8d0c0, 0xff141018]);

  _AlMood _mood = _AlMood.drift;
  double _t = rand.nextDouble() * 10;
  double _timer = 1500 + rand.nextDouble() * 1500;
  double _fade = 1;
  bool _noticed = false;
  @override
  final anim = Anim([0, 1], 5);
  @override
  Sheet get sheet => game.art.al;
  @override
  int get frame => _mood == _AlMood.claw ? 2 : anim.frame;
  @override
  double get shadowW => 0;
  @override
  bool get hidden => _mood == _AlMood.gone;
  @override
  bool get harmless => _mood == _AlMood.gone || _mood == _AlMood.rising;
  @override
  double get alpha => switch (_mood) {
        _AlMood.gone => 0,
        _AlMood.rising => (_timer / 60).floor().isEven ? 0.85 : 0.35,
        _ => 0.55 + 0.45 * _fade,
      };

  @override
  void update(double dt) {
    if (dying) return;
    _t += dt / 1000;
    final b = body;
    if (stun > 0) {
      stun -= dt;
      b
        ..vx *= 0.9
        ..vy *= 0.9;
      return;
    }
    final p = game.player;
    final dx = p.x - x, dy = p.y - 14 - y;
    final near = !p.dead && dx.abs() < 150 && dy.abs() < 90;
    _timer -= dt;
    switch (_mood) {
      case _AlMood.drift:
        // A slow, swaying float towards Ra, flickering in and out of sight
        _fade = 0.5 + 0.5 * math.sin(_t * 3);
        b
          ..vx = (near ? dx.sign * 22 : 0) + math.cos(_t * 1.1) * 12
          ..vy = (near ? dy.sign * 10 : 0) + math.sin(_t * 2.2) * 10;
        flipX = dx > 0;
        if (near && !_noticed) {
          _noticed = true;
          game.floatText(x, y - 24, '!', const Color(0xffff6a50), size: 10, rise: 6, duration: 700);
        }
        if (near && _timer <= 0) {
          _mood = _AlMood.gone;
          _timer = 700;
          b.vx = b.vy = 0;
          game.particles.ring(x, y - 10, 0xff8a1a2a, r1: 18, life: 320);
        }
      case _AlMood.gone:
        if (_timer <= 0) {
          // Come back right behind Ra
          b
            ..x = (p.x - p.facing * 26).clamp(8.0, game.level.width - 8)
            ..y = p.y - 6;
          flipX = p.facing > 0;
          _mood = _AlMood.rising;
          _timer = math.max(300, 520 - game.def.enemyBonus * 30);
          game.particles.ring(b.x, b.y - 10, 0xff8a1a2a, r1: 14, life: 300);
        }
      case _AlMood.rising:
        b.vx = b.vy = 0;
        if (_timer <= 0) {
          _mood = _AlMood.claw;
          _timer = 360;
          final d = math.max(1.0, math.sqrt(dx * dx + dy * dy));
          b
            ..vx = dx / d * 190
            ..vy = dy / d * 190;
          flipX = dx > 0;
        }
      case _AlMood.claw:
        if (_timer <= 0) {
          _mood = _AlMood.drift;
          _timer = 2200 + rand.nextDouble() * 1200;
          b
            ..vx = -b.vx * 0.3
            ..vy = -60;
        }
    }
  }
}
