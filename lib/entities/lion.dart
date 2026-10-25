import 'dart:math' as math;
import 'dart:ui';

import '../art/pixel.dart';
import '../game/effects.dart';
import '../game/meetra_game.dart';
import '../game/physics.dart';
import '../sfx.dart';

enum LionState { intro, pace, telegraph, charge, pounce, stunned, dead }

// The Reed Lion, boss of the First Trial.
// Loop: prowl, then (roar and) charge or pounce. A charge into a wall stuns it: that is your opening.
// Below half health it is enraged: faster, with double pounces.
class Lion {
  Lion(this.game, double x, double y) : body = Body(x, y, 40, 21);

  final MeetRaGame game;
  final Body body;
  final int maxHp = 30;
  late int hp = maxHp;
  int facing = -1;
  LionState state = LionState.intro;
  double timer = 1300;
  bool enraged = false;
  int pounces = 0;
  final int contactDamage = 2;
  LionState _next = LionState.charge;

  // Visual state
  final _walk = Anim([0, 1], 6);
  int _frame = 0;
  bool _animating = false;
  double scaleX = 1.25, scaleY = 1.25;
  double angle = 0;
  int? tint;
  double _flash = 0;
  double alpha = 1;
  double _deathT = 0;
  bool removed = false;

  double get x => body.x;
  double get y => body.y;

  void setState(LionState s, [double t = 0]) {
    state = s;
    timer = t;
  }

  void _play(double timeScale) {
    _animating = true;
    _walk.timeScale = timeScale;
  }

  void _stop([int? frame]) {
    _animating = false;
    if (frame != null) _frame = frame;
  }

  void update(double time, double dt) {
    _flash = math.max(0, _flash - dt);
    if (_animating) {
      _walk.update(dt);
      _frame = _walk.frame;
    }
    if (state == LionState.dead) {
      _updateDeath(dt);
      return;
    }
    final p = game.player;
    final b = body;
    final onGround = b.blockedDown;
    timer -= dt;
    void faceP() {
      final s = (p.x - x).sign.toInt();
      if (s != 0) facing = s;
    }

    switch (state) {
      case LionState.intro:
        b.vx = 0;
        if (timer <= 0) setState(LionState.pace, 900);

      case LionState.pace:
        faceP();
        b.vx = facing * (enraged ? 75 : 50);
        _play(1);
        if (timer <= 0) {
          final pounce = rand.nextDouble() < (enraged ? 0.5 : 0.4);
          _next = pounce ? LionState.pounce : LionState.charge;
          pounces = enraged && pounce ? 2 : 1;
          setState(LionState.telegraph, enraged ? 380 : 550);
          if (!pounce) sfx.roar();
        }

      case LionState.telegraph:
        faceP();
        b.vx = 0;
        _stop();
        scaleX = 1.3; // crouch
        scaleY = 1.15;
        tint = (time / 70).floor() % 2 == 1 ? 0xffff8060 : null;
        if (timer <= 0) {
          scaleX = scaleY = 1.25;
          tint = null;
          if (_next == LionState.charge) {
            setState(LionState.charge);
            game.camera.shake(200, 0.004);
          } else {
            doPounce(p.x);
          }
        }

      case LionState.charge:
        b.vx = facing * (enraged ? 290 : 240);
        _play(2.5);
        final hitWall = (facing < 0 && b.blockedLeft) || (facing > 0 && b.blockedRight);
        if (hitWall) {
          _walk.timeScale = 1;
          b
            ..vx = -facing * 60
            ..vy = -120;
          sfx.thud();
          game.camera.shake(300, 0.012);
          game.burst(x + facing * 20, y - 10, [0xffc8b8a0, 0xff8a7a68], 12, 120);
          setState(LionState.stunned, 1500);
        }

      case LionState.pounce:
        if (onGround && timer <= 0) {
          sfx.thud();
          game.camera.shake(120, 0.006);
          game.burst(x, y, [0xffc8b8a0], 8, 80);
          pounces--;
          if (pounces > 0) {
            doPounce(p.x);
          } else {
            setState(LionState.pace, 900 + rand.nextDouble() * 900);
          }
        }

      case LionState.stunned:
        if (onGround) b.vx *= 0.9;
        _stop(0);
        angle = math.sin(time / 50) * 3;
        if (timer <= 0) {
          angle = 0;
          setState(LionState.pace, 700);
        }

      case LionState.dead:
        break;
    }
  }

  void doPounce(double px) {
    final s = (px - x).sign.toInt();
    if (s != 0) facing = s;
    body
      ..vy = -340
      ..vx = ((px - x) * 1.5).clamp(-220, 220);
    _stop(1);
    setState(LionState.pounce, 150);
  }

  void hurt(int dmg) {
    if (state == LionState.dead) return;
    final real = state == LionState.stunned ? (dmg * 1.5).ceil() : dmg;
    hp = math.max(0, hp - real);
    _flash = 70;
    game.floatText(x, y - 32, '$real', Color(state == LionState.stunned ? 0xffff9a5a : 0xffffe28a));
    game.ui.bossFrac.value = hp / maxHp;
    if (!enraged && hp <= maxHp / 2) {
      enraged = true;
      sfx.roar();
      game.camera.shake(400, 0.01);
    }
    if (hp <= 0) die();
  }

  void die() {
    state = LionState.dead;
    body.enabled = false;
    _stop();
    tint = null;
    sfx.roar();
    game.camera.shake(800, 0.01);
  }

  // Fades out while tipping over and shedding sparks, then hands over to the game
  void _updateDeath(double dt) {
    _deathT += dt;
    final k = math.min(1.0, _deathT / 1400);
    alpha = 1 - k;
    angle = facing * -15 * k;
    if (rand.nextDouble() < 0.3) {
      game.burst(x + betweenInt(-20, 20), y - betweenInt(4, 28), [0xffd9a441, 0xfff0c870, 0xff8a4a1a], 4, 90);
    }
    if (k >= 1 && !removed) {
      removed = true;
      game.onBossDefeated(x, y);
    }
  }

  void render(Canvas c, Sheet sheet) => drawFrame(c, sheet, _frame, x.roundToDouble(), y.roundToDouble(),
      flipX: facing < 0,
      scaleX: scaleX,
      scaleY: scaleY,
      angle: angle,
      alpha: alpha,
      tint: tint,
      tintFill: _flash > 0 && state != LionState.dead ? 0xffffffff : null);
}
