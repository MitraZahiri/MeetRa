import 'dart:math' as math;
import 'dart:ui';

import '../art/pixel.dart';
import '../config.dart';
import '../game/effects.dart';
import '../game/meetra_game.dart';
import '../game/physics.dart';
import '../input.dart';
import '../sfx.dart';

const _solidUnder = {T.grass, T.dirt, T.brick, T.platform};

class Player {
  Player(this.game, double x, double y)
      : body = Body(x, y, 8, 16),
        safe = Offset(x, y) {
    body
      ..maxVy = 520
      ..collideWorldX = true;
  }

  final MeetRaGame game;
  final Body body;

  double get x => body.x;
  double get y => body.y;

  int facing = 1;
  double coyote = 0;
  double jumpBuffer = 0;
  bool canDouble = true;
  bool jumpCut = false;
  double attackTimer = 0;
  bool attackQueued = false;
  int comboStep = 0;
  double comboWindow = 0;
  double spellCooldown = 0;
  double invuln = 0;
  double hurtLock = 0;
  double dropTimer = 0;
  bool dead = false;
  bool frozen = false;
  Offset safe;
  double safeTimer = 0;

  // Visual state
  double _squash = 0; // ms left of the jump stretch
  double _flash = 0; // ms left of the red hurt flash
  int? tint;
  double fadeAlpha = 1;
  int _frame = 0;
  final _run = Anim([1, 2], 10);

  GameState get reg => game.state;
  bool get onGround => body.blockedDown;

  void update(ControlState c, double dt) {
    _squash = math.max(0, _squash - dt);
    _flash = math.max(0, _flash - dt);
    if (dead) return;
    if (frozen) {
      body.vx = 0;
      return;
    }
    final ground = onGround;

    coyote = ground ? PlayerTuning.coyote : math.max(0, coyote - dt);
    if (ground) canDouble = true;
    jumpBuffer = c.jumpPressed ? PlayerTuning.buffer : math.max(0, jumpBuffer - dt);
    invuln = math.max(0, invuln - dt);
    hurtLock = math.max(0, hurtLock - dt);
    dropTimer = math.max(0, dropTimer - dt);
    attackTimer = math.max(0, attackTimer - dt);
    comboWindow = math.max(0, comboWindow - dt);
    spellCooldown = math.max(0, spellCooldown - dt);

    // Horizontal movement
    var dir = (c.right ? 1 : 0) - (c.left ? 1 : 0);
    if (hurtLock > 0) dir = 0;
    if (dir != 0 && attackTimer <= 0) facing = dir;
    if (hurtLock <= 0) {
      final slow = attackTimer > 0 && ground ? 0.35 : 1.0;
      final accel = (ground ? PlayerTuning.accelGround : PlayerTuning.accelAir) * (dt / 1000);
      body.vx = approach(body.vx, dir * PlayerTuning.speed * slow, accel);
    }

    // Jumping (coyote time + buffer + double jump + drop through platforms)
    if (jumpBuffer > 0 && hurtLock <= 0) {
      if (c.down && ground && tileUnderIs(T.platform)) {
        dropTimer = 250;
        jumpBuffer = 0;
      } else if (coyote > 0) {
        jump(PlayerTuning.jump);
        coyote = 0;
      } else if (canDouble) {
        jump(PlayerTuning.doubleJump);
        canDouble = false;
        game.burst(x, y, [0xfff2e6c9, 0xff8ae0d8], 6, 60);
      }
    }
    if (!c.jump && body.vy < -120 && !jumpCut) {
      body.vy *= 0.45;
      jumpCut = true;
    }

    // Sword (presses during a swing are queued, so combos flow)
    if (c.attackPressed) attackQueued = true;
    if (attackQueued && attackTimer <= 0 && hurtLock <= 0) {
      attackQueued = false;
      attack(c, ground);
    }
    if (c.spellPressed) castFeather();

    // Aura regeneration
    if (reg.aura < reg.auraMax) reg.aura = math.min(reg.auraMax.toDouble(), reg.aura + 10 * (dt / 1000));

    trackSafeGround(ground, dt);
    _animate(ground, dt);
  }

  void jump(double v) {
    body.vy = -v;
    jumpCut = false;
    jumpBuffer = 0;
    sfx.jump();
    _squash = 160;
  }

  void attack(ControlState c, bool ground) {
    final down = !ground && c.down;
    comboStep = comboWindow > 0 && !down ? (comboStep + 1) % 3 : 0;
    final step = down ? -1 : comboStep; // -1 = down-strike
    attackTimer = step == 2 ? 300 : 190;
    comboWindow = attackTimer + 260;
    sfx.swing();

    final b = body;
    final atk = reg.attack;
    Rect rect;
    var dmg = atk;
    var knock = 1.0;
    if (step == -1) {
      rect = Rect.fromLTWH(b.centerX - 11, b.bottom - 4, 22, 22);
    } else {
      final w = step == 2 ? 28.0 : 22.0;
      rect = Rect.fromLTWH(facing > 0 ? b.right - 2 : b.left - w + 2, b.top - 5, w, 24);
      if (step == 2) {
        dmg = (atk * 1.6).ceil();
        knock = 1.8;
      }
    }

    // Slash trail
    game.slashes.add(Slash(
      rect.center.dx,
      rect.center.dy,
      flipX: step != -1 && facing < 0,
      flipY: step == 1,
      scale: step == 2 ? 1.3 : 1,
      tint: step == 2 ? 0xffffe28a : null,
      angle: step == -1 ? 90 : 0,
    ));

    final hits = game.resolveMelee(rect, dmg, facing, knock);
    if (step == -1 && hits > 0) {
      body.vy = -270; // bounce off enemies with a down strike (pogo)
      canDouble = true;
    }
  }

  void castFeather() {
    if (!reg.hasFeather || spellCooldown > 0 || hurtLock > 0) return;
    if (reg.aura < PlayerTuning.featherCost) {
      sfx.fizzle();
      spellCooldown = 200;
      return;
    }
    reg.aura -= PlayerTuning.featherCost;
    spellCooldown = 300;
    game.spawnFeather(x + facing * 8, y - 10, facing, reg.magic);
  }

  void hurt(int dmg, double fromX) {
    if (invuln > 0 || dead || frozen) return;
    reg.hp = math.max(0, reg.hp - dmg);
    sfx.hurt();
    game.camera.shake(150, 0.006);
    invuln = PlayerTuning.invuln;
    hurtLock = 260;
    final away = (x - fromX).sign != 0 ? (x - fromX).sign : -facing.toDouble();
    body
      ..vx = away * 160
      ..vy = -180;
    _flash = 90;
    if (reg.hp <= 0) game.playerDied();
  }

  // Pits and thorns: half a heart of damage, then back to the last safe ground
  void fallHurt() {
    if (dead) return;
    reg.hp = math.max(0, reg.hp - 1);
    sfx.hurt();
    if (reg.hp <= 0) {
      game.playerDied();
      return;
    }
    respawnAt(safe.dx, safe.dy);
    invuln = PlayerTuning.invuln;
  }

  void respawnAt(double px, double py) {
    body
      ..x = px
      ..y = py
      ..vx = 0
      ..vy = 0;
    hurtLock = 0;
    attackTimer = 0;
  }

  bool tileUnderIs(int index) => game.level.tileAtWorld(body.centerX, body.bottom + 2) == index;

  void trackSafeGround(bool ground, double dt) {
    if (!ground || invuln > 0) {
      safeTimer = 0;
      return;
    }
    final l = game.level.tileAtWorld(body.left - 2, body.bottom + 2);
    final r = game.level.tileAtWorld(body.right + 2, body.bottom + 2);
    if (_solidUnder.contains(l) && _solidUnder.contains(r)) {
      safeTimer += dt;
      if (safeTimer > 150) safe = Offset(x, y);
    }
  }

  void _animate(bool ground, double dt) {
    if (attackTimer > 0) {
      _frame = 4;
    } else if (!ground) {
      _frame = 3;
    } else if (body.vx.abs() > 10) {
      _run.update(dt);
      _frame = _run.frame;
    } else {
      _frame = 0;
    }
  }

  void render(Canvas c, Sheet sheet, double timeNow) {
    final k = _squash / 160;
    final blink = invuln > 0 && (timeNow / 60).floor() % 2 == 1 ? 0.35 : 1.0;
    drawFrame(c, sheet, _frame, x.roundToDouble(), y.roundToDouble(),
        flipX: facing < 0,
        scaleX: 1 - 0.15 * k,
        scaleY: 1 + 0.15 * k,
        alpha: blink * fadeAlpha,
        tint: tint,
        tintFill: _flash > 0 ? 0xffff4040 : null);
  }
}
