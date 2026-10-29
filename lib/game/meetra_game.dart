import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as dui;

import 'package:flame/game.dart' hide Matrix4;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;
import 'package:flame/input.dart' show KeyboardEvents;

import '../art/pixel.dart';
import '../art/sprites.dart';
import '../art/sun_eye.dart';
import '../config.dart';
import '../entities/enemy.dart';
import '../entities/lion.dart';
import '../entities/player.dart';
import '../input.dart';
import '../music.dart';
import '../levels/build.dart';
import '../levels/generator.dart';
import '../levels/level1.dart';
import '../sfx.dart';
import '../world/progress.dart';
import '../world/world.dart';
import 'ambience.dart';
import 'effects.dart';
import 'physics.dart';

class BannerMsg {
  BannerMsg(this.title, [this.sub = '']);
  final String title;
  final String sub;
}

enum AppScreen { title, world, realm, playing }

// Everything the Flutter UI layer (HUD, menus) listens to
class UiBus {
  final screen = ValueNotifier<AppScreen>(AppScreen.title);
  final realm = ValueNotifier<int>(0); // realm shown on the realm map
  final sign = ValueNotifier<String?>(null);
  final banner = ValueNotifier<BannerMsg?>(null);
  final boss = ValueNotifier<BossDef?>(null);
  final bossFrac = ValueNotifier<double>(1);
  final title = ValueNotifier<bool>(true); // the title screen is mounted
  final levelUps = ValueNotifier<int>(0); // pending level-up choices; > 0 shows the panel
  final victory = ValueNotifier<bool>(false);
  final rewards = ValueNotifier<List<String>>(const []); // shown on the 'location cleared' screen
  final session = ValueNotifier<int>(0); // bumps on restart so overlays rebuild fresh
}

class Pickup {
  Pickup(this.body, this.life);
  final Body body;
  final double life;
  final double phase = rand.nextDouble() * 10;
  double age = 0;
  bool removed = false;
}

class Projectile {
  Projectile(this.body, this.dmg, this.dir);
  final Body body;
  final int dmg;
  final int dir;
  double age = 0;
  double trailT = 0;
  bool removed = false;
}

class Orb {
  Orb(this.x, this.y, this.vx, this.vy, this.value);
  double x, y, vx, vy;
  final int value;
  double t = 0;
}

class Altar {
  Altar(this.x, this.y);
  final double x, y;
  bool lit = false;
  final flame = Anim([0, 1], 8);
}

class Sign {
  Sign(this.x, this.y, this.text);
  final double x, y;
  final String text;
}

class Breakable {
  Breakable(this.x, this.y, this.kind, this.sheet);
  final double x, y;
  final String kind;
  final Sheet sheet;
  double wobble = 0; // bushes rustle when Ra pushes through
  Rect get bounds => Rect.fromLTWH(x - sheet.frameW / 2, y - sheet.frameH, sheet.frameW, sheet.frameH);
}

class Chest {
  Chest(this.x, this.y);
  final double x, y;
  bool opened = false;
  Rect get bounds => Rect.fromLTWH(x - 7, y - 10, 14, 10);
}

class FeatherItem {
  FeatherItem(this.x, this.baseY);
  final double x, baseY;
  double t = 0;
  double get y => baseY - 6 * (0.5 - 0.5 * math.cos(math.pi * t / 900));
}

class Gate {
  Gate(this.x, this.y);
  final double x, y;
  double glow = 0;
  bool opening = false;
}

// The game world: level, physics, entities, camera and parallax background.
// HUD, menus and touch buttons are Flutter widgets on top (see ui/).
class MeetRaGame extends Game with KeyboardEvents {
  MeetRaGame(this.art) {
    _startLevel();
  }

  final Art art;
  final state = GameState();
  final ui = UiBus();
  final controls = Controls();
  final keyDowns = StreamController<LogicalKeyboardKey>.broadcast();
  final progress = Progress();
  final mapSeen = <String>{}; // places and realms already shown out of the fog (reveals animate once)
  LevelDef def = level1;
  Location? location; // the location being played

  late Level level;
  late Physics physics;
  late Player player;
  late dui.Image _map;
  late Ambience ambience;

  final camera = Camera();
  final timers = Timers();
  final particles = Particles();
  final slashes = <Slash>[];
  final texts = <FloatText>[];

  final enemies = <Enemy>[];
  final coins = <Pickup>[];
  final hearts = <Pickup>[];
  final feathers = <Projectile>[];
  final orbs = <Orb>[];
  final altars = <Altar>[];
  final signs = <Sign>[];
  final breakables = <Breakable>[];
  final chests = <Chest>[];
  FeatherItem? featherPickup;
  Gate? gate;

  Offset checkpoint = Offset.zero;
  Sign? activeSign;
  double? arenaLeft, arenaRight;
  Offset? lionSpawn;
  Offset? waveSpawn; // a trial of waves instead of the lion
  Offset? sunKey; // where the Sun Key waits, until Ra takes it
  bool keyFound = false;
  int wave = 0;
  bool _waveComing = false;
  final _waveFoes = <Enemy>[];
  double _sealedHint = 0;
  Wall? leftWall, rightWall;
  Lion? lion;
  bool bossStarted = false;
  bool bossDefeated = false;
  bool victory = false;
  int pendingLevelUps = 0;

  bool started = false; // title screen dismissed
  double timeNow = 0;
  double _hitstop = 0;
  double _drift = 0;
  double _realT = 0; // keeps running while paused, for ambient motion
  double _winT = -1;
  bool _snapCamera = true;

  bool get simPaused => !started || ui.screen.value != AppScreen.playing || ui.levelUps.value > 0;
  // The map screens cover the whole level, so it is neither animated nor drawn behind them
  bool get mapOpen => ui.screen.value == AppScreen.world || ui.screen.value == AppScreen.realm;
  double get uiScale => size.y / gameH;
  double get virtualW => size.x / uiScale;

  // ---------- Setup ----------

  void _startLevel() {
    level = buildLevel(def);
    physics = Physics(level);
    for (final l in [enemies, coins, hearts, feathers, orbs, altars, signs, breakables, chests, slashes, texts]) {
      l.clear();
    }
    particles.clear();
    ambience = Ambience(level, location?.realm.theme ?? RealmTheme.vale, cave: location?.kind == LocKind.cave);
    featherPickup = null;
    gate = null;
    activeSign = null;
    arenaLeft = arenaRight = null;
    lionSpawn = waveSpawn = sunKey = null;
    keyFound = _waveComing = false;
    wave = 0;
    _waveFoes.clear();
    _sealedHint = 0;
    leftWall = rightWall = null;
    lion = null;
    bossStarted = bossDefeated = victory = false;
    pendingLevelUps = 0;
    _hitstop = 0;
    _winT = -1;
    _snapCamera = true;
    camera
      ..bounds = Rect.fromLTWH(0, 0, level.width, level.height)
      ..fade = 0;
    _map = _renderMap();
    _spawnObjects();
  }

  // The whole tilemap is drawn once into one image, so tiles never show seams when scaled
  dui.Image _renderMap() {
    final rec = dui.PictureRecorder();
    final c = Canvas(rec);
    final p = Paint()..filterQuality = FilterQuality.none;
    for (var ty = 0; ty < level.rows; ty++) {
      for (var tx = 0; tx < level.cols; tx++) {
        final t = level.data[ty][tx];
        if (t < 0) continue;
        c.drawImageRect(art.tiles.image, art.tiles.src(t), Rect.fromLTWH(tx * tile, ty * tile, tile, tile), p);
      }
    }
    return rec.endRecording().toImageSync(level.width.toInt(), level.height.toInt());
  }

  void _spawnObjects() {
    var signIndex = 0;
    Player? p;
    for (final o in level.objects) {
      switch (o.type) {
        case 'P':
          p = Player(this, o.x, o.y);
        case 'A':
          altars.add(Altar(o.x, o.y));
        case 'S':
          signs.add(Sign(o.x, o.y, def.signs[signIndex++]));
        case 'D' || 'V' || 'U' || 'K' || 'M':
          enemies.addAll(_foes(o.type, o.x, o.y));
        case 'W':
          waveSpawn = Offset(o.x, o.y);
        case 'O':
          sunKey = Offset(o.x, o.y - 6);
        case 'v':
          breakables.add(Breakable(o.x, o.y, 'vase', art.vase));
        case '*':
          breakables.add(Breakable(o.x, o.y, 'bush', art.bush));
        case 'C':
          chests.add(Chest(o.x, o.y));
        case 'F':
          featherPickup = FeatherItem(o.x, o.y - 10);
        case 'L':
          lionSpawn = Offset(o.x, o.y);
        case '[':
          arenaLeft = o.x - tile / 2;
        case ']':
          arenaRight = o.x + tile / 2;
          // The wall reaches from the ground up to the top of the map
          rightWall = Wall(Rect.fromCenter(center: Offset(o.x, o.y / 2), width: 16, height: 224));
          physics.walls.add(rightWall!);
        case 'G':
          gate = Gate(o.x, o.y);
      }
    }
    player = p!;
    checkpoint = Offset(player.x, player.y);
    // Levels without a fight have their exit gate open from the start, unless it is sealed
    if (lionSpawn == null && waveSpawn == null) {
      bossDefeated = true;
      gate?.opening = !def.sealed;
    }
  }

  // The creatures a map letter stands for (scorpions come in pairs)
  List<Enemy> _foes(String type, double x, double y) {
    final bonus = def.enemyBonus;
    return switch (type) {
      'D' => [Demon(this, x, y)..hp += bonus],
      'V' => [Fly(this, x, y - 40)..hp += bonus],
      'U' => [Ghoul(this, x, y)..hp += bonus],
      'K' => [for (final dx in [-7.0, 7.0]) Scorpion(this, x + dx, y)..hp += bonus ~/ 2],
      'M' => [Manticore(this, x, y)..hp += bonus * 2],
      _ => const [],
    };
  }

  // ---------- Input ----------

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    controls.keys = Set.of(keysPressed);
    if (event is KeyDownEvent) keyDowns.add(event.logicalKey);
    return KeyEventResult.handled;
  }

  // ---------- Loop ----------

  @override
  void update(double dtSeconds) {
    final dt = math.min(dtSeconds * 1000, 50.0);
    _drift += dt * 0.004;
    _realT += dt / 1000;
    if (mapOpen) return;
    ambience.update(dt, _view, simPaused ? const [] : _pushers());
    if (simPaused) {
      state.flush();
      return;
    }
    timeNow += dt;
    timers.update(dt);

    final c = controls.update();
    final P = player;
    P.update(c, dt);
    lion?.update(timeNow, dt);
    // Like the old consoles: creatures far off screen sleep until Ra comes near again
    final awake = _view.inflate(160);
    for (final e in enemies) {
      e.asleep = !awake.contains(Offset(e.x, e.y)) && !_waveFoes.contains(e);
      if (!e.asleep) e.tick(dt);
    }

    if (_hitstop > 0) {
      _hitstop -= dt;
    } else {
      _stepPhysics(dt / 1000);
    }

    if (!P.dead && P.y > level.height + 16) P.fallHurt();

    final pr = P.body.rect;
    _updateAltars(pr, dt);
    _updateSigns();
    _updatePickups(dt);
    _updateOrbs(dt);
    _updateChests(pr);

    final l = lion;
    if (l != null && l.state != LionState.dead && l.state != LionState.stunned && !P.dead) {
      if (overlaps(pr, l.body.rect)) P.hurt(l.contactDamage, l.x);
    }
    if (l != null && l.state != LionState.dead) {
      for (final f in feathers) {
        if (!f.removed && overlaps(f.body.rect, l.body.rect)) {
          l.hurt(f.dmg);
          _killFeather(f);
        }
      }
    }

    // Boss arena trigger
    if (!bossStarted && !bossDefeated && arenaLeft != null && P.x > arenaLeft! + tile * 3) _startBoss();

    _updateWaves();

    // The Sun Key
    final k = sunKey;
    if (k != null && !keyFound && !P.dead && overlaps(pr, Rect.fromCenter(center: k, width: 14, height: 14))) _takeKey(k);

    // Exit gate: open, or sealed until the Sun Key is found
    final g = gate;
    _sealedHint = math.max(0, _sealedHint - dt);
    if (g != null && !victory && (P.x - g.x).abs() < 10 && P.body.blockedDown) {
      if (g.opening) {
        _win();
      } else if (def.sealed && _sealedHint <= 0) {
        _sealedHint = 4000;
        ui.banner.value = BannerMsg('The gate is sealed', 'Find the Sun Key hidden in this place');
      }
    }

    _updateEffects(dt);
    enemies.removeWhere((e) => e.removed);
    coins.removeWhere((p) => p.removed);
    hearts.removeWhere((p) => p.removed);
    feathers.removeWhere((f) => f.removed);
    if (lion?.removed ?? false) lion = null;

    camera
      ..viewW = size.x / (uiScale * zoom)
      ..viewH = size.y / (uiScale * zoom);
    camera.follow(P.x, P.y - 20, dt, snap: _snapCamera);
    _snapCamera = false;
    camera.update(dt, virtualW);
    state.flush();
  }

  Rect get _view => Rect.fromLTWH(camera.scrollX, camera.scrollY, camera.viewW, camera.viewH);

  // Everything that parts the grass as it moves through
  List<Pusher> _pushers() => [
        (player.x, player.y, player.body.vx),
        for (final e in enemies)
          if (e.body.allowGravity) (e.x, e.y, e.body.vx),
        if (lion != null) ...[(lion!.x - 12, lion!.y, lion!.body.vx), (lion!.x + 12, lion!.y, lion!.body.vx)],
      ];

  void _stepPhysics(double s) {
    final P = player;
    var spikes = false;
    physics.step(P.body, s, skipPlatforms: P.dropTimer > 0, onTile: (t) => spikes |= t == T.spikes);
    if (spikes) P.fallHurt();
    for (final e in enemies) {
      if (!e.asleep) physics.step(e.body, s);
    }
    for (final c in [...coins, ...hearts]) {
      physics.step(c.body, s, useWalls: false);
    }
    for (final f in feathers) {
      var hit = false;
      physics.step(f.body, s, useWalls: false, onTile: (_) => hit = true);
      if (hit) _killFeather(f);
    }
    if (lion != null) physics.step(lion!.body, s);

    // Overlaps
    final pr = P.body.rect;
    if (P.body.collides) {
      for (final e in enemies) {
        if (!e.dying && !e.harmless && overlaps(pr, e.body.rect)) P.hurt(e.contactDamage, e.x);
      }
      for (final c in coins) {
        if (!c.removed && overlaps(pr, c.body.rect)) _collectCoin(c);
      }
      for (final h in hearts) {
        if (!h.removed && overlaps(pr, h.body.rect)) _collectHeart(h);
      }
    }
    for (final f in feathers) {
      for (final e in enemies) {
        if (f.removed || e.dying || !overlaps(f.body.rect, e.body.rect)) continue;
        e.hurt(f.dmg, f.body.vx.sign, 0.6);
        _killFeather(f);
      }
    }
  }

  void _updateAltars(Rect pr, double dt) {
    for (final a in altars) {
      if (a.lit) a.flame.update(dt);
      if (!overlaps(pr, Rect.fromLTWH(a.x - 10, a.y - 24, 20, 24))) continue;
      if (state.hp < state.maxHp) state.hp = state.maxHp;
      if (!a.lit) {
        a.lit = true;
        sfx.altar();
        burst(a.x, a.y - 16, [0xffffe066, 0xffff9a2a], 16, 90);
        particles
          ..ring(a.x, a.y - 14, 0xffffc060, r1: 34, life: 600, width: 2.5)
          ..ring(a.x, a.y - 14, 0xfffff0b0, r1: 20, life: 420);
        ui.banner.value = BannerMsg('Hearth lit', 'Checkpoint reached · health restored');
      }
      if (checkpoint.dx != a.x) checkpoint = Offset(a.x, a.y);
    }
  }

  void _updateSigns() {
    final P = player;
    Sign? near;
    for (final s in signs) {
      if ((P.x - s.x).abs() < 22 && (P.y - s.y).abs() < 30) near = s;
    }
    if (near != activeSign) {
      activeSign = near;
      ui.sign.value = near?.text;
    }
  }

  void _updatePickups(double dt) {
    final P = player;
    // Saena's feather
    final f = featherPickup;
    if (f != null) {
      f.t += dt;
      if (_dist(P.x, P.y - 9, f.x, f.y) < 14) {
        featherPickup = null;
        state
          ..hasFeather = true
          ..aura = state.auraMax.toDouble();
        sfx.pickup();
        burst(P.x, P.y - 10, [0xff2bb3a8, 0xff8ae0d8, 0xffd4a845], 24, 130);
        particles.ring(P.x, P.y - 10, 0xff8ae0d8, r1: 40, life: 600, width: 3);
        camera.flash(0xff8ae0d8, 0.3, 500);
        ui.banner.value = BannerMsg("Saena's Feather", 'Tap ✦ to throw it · costs Aura');
      }
    }
    // Coin magnet
    for (final c in coins) {
      c.age += dt;
      final b = c.body;
      final d = _dist(b.centerX, b.centerY, P.x, P.y - 8);
      if (c.age > 350 && d < 40 && d > 0) {
        b
          ..vx = (P.x - b.centerX) / d * 220
          ..vy = (P.y - 8 - b.centerY) / d * 220;
      }
      if (c.age > c.life) c.removed = true;
    }
    for (final h in hearts) {
      h.age += dt;
      if (h.age > h.life) h.removed = true;
    }
  }

  void _updateOrbs(double dt) {
    final P = player;
    for (var i = orbs.length - 1; i >= 0; i--) {
      final o = orbs[i];
      o.t += dt;
      if (o.t < 300) {
        o.x += o.vx * (dt / 1000);
        o.y += o.vy * (dt / 1000);
        o.vx *= 0.92;
        o.vy *= 0.92;
      } else {
        final dx = P.x - o.x;
        final dy = P.y - 9 - o.y;
        final d = math.sqrt(dx * dx + dy * dy);
        final sp = math.min(400, 120 + o.t * 0.4) * (dt / 1000);
        if (d < 8 || P.dead) {
          orbs.removeAt(i);
          if (!P.dead) gainXp(o.value);
          continue;
        }
        o.x += (dx / d) * sp;
        o.y += (dy / d) * sp;
      }
    }
  }

  void _updateChests(Rect pr) {
    for (final ch in chests) {
      if (ch.opened || !overlaps(pr, ch.bounds)) continue;
      ch.opened = true;
      sfx.pickup();
      particles
        ..ring(ch.x, ch.y - 6, 0xffffe28a, r1: 24, life: 450)
        ..spark(ch.x, ch.y - 8, size: 12, color: 0xffffe28a);
      spawnGold(ch.x, ch.y - 10, 12);
      spawnXp(ch.x, ch.y - 10, 8);
      ui.banner.value = BannerMsg('Treasure!', 'Hidden chests reward the curious');
    }
  }

  void _updateEffects(double dt) {
    particles.update(dt);
    for (final s in slashes) {
      s.t += dt;
    }
    slashes.removeWhere((s) => s.t >= Slash.duration);
    for (final t in texts) {
      t.t += dt;
    }
    texts.removeWhere((t) => t.t >= t.duration);
    for (final f in feathers) {
      f.age += dt;
      f.trailT += dt;
      while (f.trailT >= 25) {
        f.trailT -= 25;
        particles.trail(f.body.x, f.body.centerY, [0xff8ae0d8, 0xffd4a845]);
      }
      if (f.age > 1100) _killFeather(f);
    }
    final g = gate;
    if (g != null && g.opening) g.glow = math.min(1, g.glow + dt / 1200);
    _ambientSparkles(dt);
    if (_winT >= 0) {
      _winT += dt;
      player.fadeAlpha = 1 - ((_winT - 300) / 900).clamp(0.0, 1.0);
    }
  }

  // Embers over lit hearths, glints on coins and chests, light rising from an open gate
  void _ambientSparkles(double dt) {
    bool chance(double everyMs) => rand.nextDouble() < dt / everyMs;
    for (final a in altars) {
      if (a.lit && chance(90)) particles.ember(a.x, a.y - 18);
    }
    for (final c in coins) {
      if (chance(900)) particles.sparkle(c.body.x + between(-2, 2), c.body.y - between(2, 6));
    }
    for (final ch in chests) {
      if (!ch.opened && chance(600)) particles.sparkle(ch.x + between(-6, 6), ch.y - between(2, 10), 0xffffe28a);
    }
    for (final o in orbs) {
      if (chance(70)) particles.sparkle(o.x, o.y, 0xff8ae0d8);
    }
    final g = gate;
    if (g != null && g.glow > 0 && chance(110 / g.glow)) particles.ember(g.x + between(-8, 8), g.y - between(0, 30), 0xfffff0b0);
    final f = featherPickup;
    if (f != null && chance(160)) particles.sparkle(f.x + between(-8, 8), f.y + between(-6, 6), 0xff8ae0d8);
    // Bushes rustle when Ra pushes through them
    final pr = player.body.rect;
    for (final b in breakables) {
      if (b.kind == 'bush' && player.body.vx.abs() > 30 && overlaps(pr, b.bounds) && b.wobble < 0.4) b.wobble = 1;
      b.wobble = math.max(0, b.wobble - dt / 700);
    }
  }

  double _dist(double x1, double y1, double x2, double y2) => math.sqrt(math.pow(x2 - x1, 2) + math.pow(y2 - y1, 2));

  // ---------- Combat ----------

  int resolveMelee(Rect rect, int dmg, int dir, double knock) {
    var hits = 0;
    for (final e in enemies) {
      if (!e.dying && overlaps(rect, e.body.rect)) {
        e.hurt(dmg, dir.toDouble(), knock);
        hits++;
      }
    }
    final l = lion;
    if (l != null && l.state != LionState.dead && overlaps(rect, l.body.rect)) {
      l.hurt(dmg);
      hits++;
    }
    for (final b in [...breakables]) {
      if (overlaps(rect, b.bounds)) {
        _breakObject(b);
        hits++;
      }
    }
    if (hits > 0) {
      sfx.hit();
      if (_hitstop <= 0) _hitstop = 65;
      camera.shake(70, 0.003);
    }
    return hits;
  }

  void _breakObject(Breakable b) {
    breakables.remove(b);
    sfx.breakIt();
    final colors = b.kind == 'vase' ? [0xffb8683a, 0xffd8905a, 0xff1b2a6b] : [0xff3f7a34, 0xff5aa04a, 0xffe85a7a];
    burst(b.x, b.y - 6, colors, 12, 110);
    final r = rand.nextDouble();
    if (r < 0.15) {
      spawnHeart(b.x, b.y - 8);
    } else if (r < 0.75) {
      spawnGold(b.x, b.y - 8, betweenInt(1, b.kind == 'vase' ? 3 : 1));
    }
    if (b.kind == 'bush') spawnXp(b.x, b.y - 8, 1);
  }

  void spawnFeather(double x, double y, int dir, int dmg) {
    sfx.feather();
    final body = Body(x, y + 2, 10, 4)
      ..allowGravity = false
      ..vx = dir * 270;
    feathers.add(Projectile(body, dmg, dir));
  }

  void _killFeather(Projectile f) {
    if (f.removed) return;
    burst(f.body.x, f.body.centerY, [0xff8ae0d8, 0xffffffff], 6, 60);
    f.removed = true;
  }

  // ---------- Loot ----------

  void spawnGold(double x, double y, int n) {
    for (var i = 0; i < n; i++) {
      final b = Body(x, y + 3, 6, 6)
        ..bounceY = 0.45
        ..dragX = 90
        ..vx = betweenInt(-70, 70).toDouble()
        ..vy = betweenInt(-220, -130).toDouble();
      coins.add(Pickup(b, 9000));
    }
  }

  void spawnHeart(double x, double y) {
    final b = Body(x, y + 4, 9, 8)
      ..bounceY = 0.3
      ..dragX = 90
      ..vx = betweenInt(-40, 40).toDouble()
      ..vy = -180;
    hearts.add(Pickup(b, 10000));
  }

  void spawnXp(double x, double y, int total) {
    if (total <= 0) return;
    final n = math.min(total, 8);
    final base = total ~/ n;
    var rest = total - base * n;
    for (var i = 0; i < n; i++) {
      final value = base + (rest-- > 0 ? 1 : 0);
      final a = rand.nextDouble() * math.pi * 2;
      orbs.add(Orb(x, y, math.cos(a) * 120, math.sin(a) * 120 - 40, value));
    }
  }

  void _collectCoin(Pickup c) {
    if (c.age < 150) return;
    c.removed = true;
    state.gold++;
    sfx.coin();
    for (var i = 0; i < 3; i++) {
      particles.sparkle(c.body.x + between(-3, 3), c.body.y - between(0, 6), 0xffffe28a);
    }
  }

  void _collectHeart(Pickup h) {
    h.removed = true;
    state.hp = math.min(state.maxHp, state.hp + 2);
    sfx.pickup();
    particles.ring(h.body.x, h.body.y - 4, 0xffff8a9a, r1: 16, life: 360);
    floatText(h.body.x, h.body.y - 10, '+1', const Color(0xffff9aa8));
  }

  void gainXp(int n) {
    var xp = state.xp + n;
    var lv = state.level;
    var next = state.xpNext;
    var ups = 0;
    while (xp >= next) {
      xp -= next;
      lv++;
      next = xpForLevel(lv);
      ups++;
    }
    state
      ..xp = xp
      ..xpNext = next
      ..level = lv;
    if (ups > 0) {
      sfx.levelup();
      burst(player.x, player.y - 10, [0xffffe28a, 0xffffffff, 0xff8ae0d8], 30, 160);
      particles
        ..ring(player.x, player.y - 10, 0xffffe28a, r1: 50, life: 700, width: 3)
        ..ring(player.x, player.y - 10, 0xffffffff, r1: 30, life: 500);
      camera.flash(0xffffe28a, 0.3, 600);
      pendingLevelUps += ups;
      timers.after(350, _openLevelUp);
    }
  }

  void _openLevelUp() {
    if (pendingLevelUps == 0 || player.dead || victory) return;
    touch.clear();
    ui.levelUps.value += pendingLevelUps; // pauses the game until every choice is made
    pendingLevelUps = 0;
  }

  // ---------- Boss ----------

  void _startBoss() {
    bossStarted = true;
    leftWall = Wall(Rect.fromCenter(center: Offset(arenaLeft! + tile / 2, rightWall!.y), width: 16, height: 224));
    physics.walls.add(leftWall!);
    burst(leftWall!.x, level.height - 3 * tile, [0xffa88a60, 0xff5a4a38], 16, 120);
    particles.dust(leftWall!.x, level.height - 3 * tile, count: 10, spread: 50, color: 0xffa88a60);
    music.play(Track.boss);
    camera
      ..bounds = Rect.fromLTRB(arenaLeft!, 0, arenaRight!, level.height)
      ..shake(400, 0.008);
    sfx.roar();
    ui.bossFrac.value = 1;
    ui.sign.value = null;
    if (waveSpawn != null) {
      wave = 0;
      _spawnWave();
      return;
    }
    lion = Lion(this, lionSpawn!.dx, lionSpawn!.dy, maxHp: def.boss.hp);
    ui.boss.value = def.boss;
  }

  // ---------- Trial of waves ----------

  static const waves = 3;

  // Each wave brings more of the realm's creatures, rising out of puffs of dust; later realms send
  // ghouls, and from the Sky Spine on the last wave brings a man-eater
  void _spawnWave() {
    final tier = location?.realm.index ?? 0;
    final kinds = ['D', 'K', if (tier >= 1) 'V', if (tier >= 2) 'U'];
    final types = [
      for (var i = 0; i < 2 + wave + tier ~/ 3; i++) kinds[rand.nextInt(kinds.length)],
      if (wave == waves - 1) tier >= 3 ? 'M' : 'D',
    ];
    final left = arenaLeft! + tile * 3, right = arenaRight! - tile * 3;
    for (final t in types) {
      final x = left + rand.nextDouble() * (right - left);
      final foes = _foes(t, x, waveSpawn!.dy);
      for (final e in foes) {
        if (e is Ghoul) e.wake();
      }
      enemies.addAll(foes);
      _waveFoes.addAll(foes);
      burst(x, waveSpawn!.dy - 8, [0xffa88a60, 0xff5a4a38, 0xff9a7ab8], 12, 110);
      particles.ring(x, waveSpawn!.dy - 10, 0xff9a7ab8, r1: 22, life: 380);
    }
    ui.boss.value = BossDef(def.boss.name, 'Wave ${wave + 1} of $waves');
    ui.bossFrac.value = 1;
    camera.shake(200, 0.004);
    sfx.roar();
  }

  void _updateWaves() {
    if (waveSpawn == null || !bossStarted || bossDefeated || _waveComing) return;
    final alive = _waveFoes.where((e) => !e.dying && !e.removed).length;
    ui.bossFrac.value = _waveFoes.isEmpty ? 0 : alive / _waveFoes.length;
    if (alive > 0) return;
    final last = _waveFoes.last;
    _waveFoes.clear();
    if (wave == waves - 1) {
      onBossDefeated(last.x, last.y, won: 'The trial is won!');
      return;
    }
    _waveComing = true;
    ui.banner.value = BannerMsg('Wave ${wave + 2} of $waves', 'More are coming');
    timers.after(1400, () {
      _waveComing = false;
      if (!bossStarted || bossDefeated || player.dead) return;
      wave++;
      _spawnWave();
    });
  }

  // ---------- The Sun Key ----------

  void _takeKey(Offset k) {
    keyFound = true;
    sfx.altar();
    camera.flash(0xfffff0b0, 0.35, 700);
    particles
      ..ring(k.dx, k.dy, 0xfffff0c0, r1: 40, life: 700, width: 3)
      ..spark(k.dx, k.dy, size: 16);
    burst(k.dx, k.dy, [0xfff7d774, 0xffd4a845, 0xfffff4c0], 18, 140);
    gate?.opening = true;
    ui.banner.value = BannerMsg('The Sun Key!', 'The gate is open');
  }

  void onBossDefeated(double x, double y, {String? won}) {
    bossDefeated = true;
    spawnGold(x, y - 16, 25);
    spawnXp(x, y - 16, 60);
    spawnHeart(x, y - 16);
    for (final w in [leftWall, rightWall].nonNulls) {
      burst(w.x, w.y, [0xffa88a60, 0xff2a4a9a], 24, 160);
      physics.walls.remove(w);
    }
    leftWall = rightWall = null;
    camera
      ..bounds = Rect.fromLTWH(0, 0, level.width, level.height)
      ..flash(0xfffff0c0, 0.45, 900);
    particles
      ..ring(x, y - 14, 0xfffff0c0, r1: 70, life: 900, width: 4)
      ..ring(x, y - 14, 0xffffc060, r1: 44, life: 700, width: 3);
    music.play(Track.explore);
    ui.boss.value = null;
    ui.banner.value = BannerMsg(won ?? '${def.boss.name} falls!', 'The way out is open');
    gate?.opening = true;
  }

  void _resetBoss() {
    if (!bossStarted || bossDefeated) return;
    lion = null;
    for (final e in _waveFoes) {
      e.removed = true;
    }
    _waveFoes.clear();
    wave = 0;
    _waveComing = false;
    if (leftWall != null) physics.walls.remove(leftWall);
    leftWall = null;
    bossStarted = false;
    camera.bounds = Rect.fromLTWH(0, 0, level.width, level.height);
    ui.boss.value = null;
    music.play(Track.explore);
  }

  // ---------- Death / victory ----------

  void playerDied() {
    final P = player;
    if (P.dead) return;
    P.dead = true;
    P.tint = 0xff802020;
    P.body
      ..vx = 0
      ..vy = -150
      ..collides = false;
    camera.shake(300, 0.01);
    timers.after(900, () {
      camera.fadeOut(400, () {
        _resetBoss();
        final cp = checkpoint;
        P
          ..dead = false
          ..tint = null
          ..respawnAt(cp.dx, cp.dy)
          ..safe = cp;
        P.body.collides = true;
        state.hp = state.maxHp;
        camera.fadeIn(400);
        ui.banner.value = BannerMsg('Ra rises again', 'Back at the last hearth');
      });
    });
  }

  void _win() {
    victory = true;
    player.frozen = true;
    sfx.victory();
    _winT = 0;
    camera.flash(0xfffff0c0, 0.5, 1100);
    particles
      ..ring(player.x, player.y - 10, 0xfffff0c0, r1: 60, life: 900, width: 3)
      ..ring(player.x, player.y - 10, 0xffffc060, r1: 36, life: 700);
    final loc = location;
    if (loc != null) ui.rewards.value = completeLocation(loc);
    timers.after(1100, () => ui.victory.value = true);
  }

  // Marks a location cleared, hands out its first-time reward and saves. Returns lines for the UI.
  List<String> completeLocation(Location loc) {
    final wasRealmOpen = [for (final r in realms) realmUnlocked(r, progress)];
    final first = progress.clear(loc);
    final lines = <String>[];
    if (first) {
      switch (loc.kind) {
        case LocKind.shrine:
          if (loc.index == 15) {
            state
              ..maxHp += 2
              ..hp = state.maxHp;
            lines.add('Shrine blessing: +1 heart');
          } else {
            state
              ..auraMax += 20
              ..attack += 1;
            lines.add('Shrine blessing: +1 might, +20 aura');
          }
        case LocKind.ruin:
          state.gold += 50;
          lines.add('Ruin treasure: +50 gold');
        case LocKind.secret:
          lines.add(loc.realm.hidden ? 'The Water of Life! The saga is complete.' : 'Dawn Sigil found! (${sigilCount(progress)} / 6)');
        case LocKind.boss:
          lines.add('${loc.realm.name} is free!');
        default:
          break;
      }
      for (final r in realms) {
        if (!wasRealmOpen[r.index] && realmUnlocked(r, progress)) {
          lines.add(r.hidden ? 'A hidden realm appears: ${r.name}' : 'New realm unlocked: ${r.name}');
        }
      }
    }
    progress.save(state);
    return lines;
  }

  // ---------- Navigation (called by the map screens) ----------

  // Called by the title screen
  void begin() {
    if (started) return;
    started = true;
    ui.screen.value = AppScreen.world;
    music.play(Track.explore);
  }

  void openRealm(Realm r) {
    progress.realm = r.index;
    ui.realm.value = r.index;
    ui.screen.value = AppScreen.realm;
  }

  void openWorld() => ui.screen.value = AppScreen.world;

  // Towns and hearths: rest there, which clears them and opens the road beyond
  List<String> visit(Location loc) {
    state
      ..hp = state.maxHp
      ..aura = state.auraMax.toDouble();
    progress.moveTo(loc);
    final first = progress.clear(loc);
    progress.save(state);
    sfx.altar();
    return first ? ['You rest by the fire. The road ahead opens.'] : ['You rest by the fire. Health restored.'];
  }

  void enterLocation(Location loc) {
    location = loc;
    progress.moveTo(loc);
    def = levelFor(loc);
    state
      ..hp = state.maxHp
      ..aura = state.auraMax.toDouble();
    touch.clear();
    timers.clear();
    _startLevel();
    ui
      ..sign.value = null
      ..boss.value = null
      ..levelUps.value = 0
      ..victory.value = false
      ..rewards.value = const []
      ..screen.value = AppScreen.playing;
    ui.session.value++;
    timers.after(400, () => ui.banner.value = BannerMsg(def.title, def.subtitle));
  }

  // Back to the realm map, from the victory screen or the in-level map button
  void leaveLevel() {
    touch.clear();
    timers.clear();
    ui
      ..sign.value = null
      ..banner.value = null
      ..boss.value = null
      ..victory.value = false
      ..levelUps.value = 0;
    progress.save(state);
    ui.screen.value = AppScreen.realm;
  }

  // Called by the level-up panel after each choice
  void chooseLevelUp(void Function(GameState s) apply) {
    apply(state);
    sfx.pickup();
    state.flush();
    ui.levelUps.value = math.max(0, ui.levelUps.value - 1);
  }

  // Erases the save and starts the saga again
  Future<void> newGame() async {
    await progress.wipe(state);
    mapSeen.clear();
    ui.realm.value = 0;
    ui.screen.value = AppScreen.world;
  }

  // ---------- Effects ----------

  void burst(double x, double y, List<int> colors, [int count = 10, double speed = 100]) => particles.burst(x, y, colors, count, speed);

  void floatText(double x, double y, String text, Color color, {double size = 8, double rise = 16, double duration = 650, double drift = 0}) =>
      texts.add(FloatText(x, y, text, color, size: size, rise: rise, duration: duration, drift: drift));

  // ---------- Rendering ----------

  final _pixel = Paint()..filterQuality = FilterQuality.none;

  @override
  void render(Canvas c) {
    if (mapOpen) return;
    final z = uiScale * zoom; // screen pixels per world pixel
    _renderBackground(c, z);

    // Snap the camera to whole screen pixels, like Phaser's roundPixels
    final sx = (camera.scrollX * z).roundToDouble() / z;
    final sy = (camera.scrollY * z).roundToDouble() / z;
    c.save();
    c.translate(camera.shakeX * uiScale, camera.shakeY * uiScale);
    c.scale(z);
    c.translate(-sx, -sy);
    _renderWorld(c, Rect.fromLTWH(sx, sy, size.x / z, size.y / z));
    c.restore();

    final screen = Offset.zero & Size(size.x, size.y);
    paintVignette(c, screen.size, ambience.dark ? 0.8 : 0.38);
    if (camera.flashAlpha > 0) c.drawRect(screen, Paint()..color = Color(camera.flashColor).withValues(alpha: camera.flashAlpha));
    if (camera.fade > 0) c.drawRect(screen, Paint()..color = Color.fromRGBO(10, 6, 20, camera.fade));
  }

  // Parallax layers: each one scrolls at its own fraction of the camera's speed
  void _renderBackground(Canvas c, double z) {
    final viewH = size.y / z;
    // However tall the level, the backdrop scrolls only its own height, top to bottom
    final travel = math.max(1.0, level.height - viewH);
    final double y = (camera.scrollY / travel).clamp(0.0, 1.0) * math.max(0.0, 270 - viewH);
    final rect = Offset.zero & Size(size.x, size.y);
    final layers = [(art.bgSky, 0.0), (art.bgClouds, 0.06), (art.bgMountains, 0.15), (art.bgHills, 0.35)];
    for (var i = 0; i < layers.length; i++) {
      final (sheet, factor) = layers[i];
      final tx = camera.scrollX * factor + (factor > 0 && factor < 0.1 ? _drift : 0.0);
      final m = Matrix4.identity()
        ..scale(z, z)
        ..translate(-tx, -y);
      final paint = Paint()
        ..shader = ImageShader(sheet.image, TileMode.repeated, TileMode.repeated, m.storage, filterQuality: FilterQuality.none);
      c.drawRect(rect, paint);
      // Sun rays fan out from the painted sun, behind the clouds and mountains
      if (i == 0) {
        final sun = Offset(360 * z, (80 - y) * z);
        paintSunRays(c, sun, z, _realT, ambience.rays, ambience.rayColor);
        _paintWatcher(c, sun, z);
      }
    }
    // Each realm washes the sky in its own color; the Lightless Land is almost dark
    final tint = def.skyTint;
    if (tint != null) {
      final dark = location?.realm.theme == RealmTheme.dark;
      c.drawRect(rect, Paint()..color = Color(tint).withValues(alpha: dark ? 0.7 : 0.22));
    }
    // Below the surface rooms the sky gives way to the dark of the earth
    final depth = ((camera.scrollY + viewH / 2 - tile * 11) / (tile * 11)).clamp(0.0, 1.0);
    if (def.sealed && depth > 0) c.drawRect(rect, Paint()..color = Color.fromRGBO(30, 20, 18, 0.88 * depth));
  }

  double _eyeOpen = 1;

  // The Eye of Ra in the sun follows Ra across the level, blinks now and then,
  // and slowly closes when Ra falls
  void _paintWatcher(Canvas c, Offset sun, double z) {
    final ra = Offset(player.x - camera.scrollX, player.y - camera.scrollY) * z;
    final to = ra - sun;
    final d = to.distance;
    final look = d < 1 ? Offset.zero : to / d * math.min(1.0, d / (140 * z));
    final target = player.dead ? 0.0 : 1.0;
    _eyeOpen += (target - _eyeOpen) * (player.dead ? 0.03 : 0.12);
    paintSunEye(c, sun, z, look: look, open: _eyeOpen * sunBlink(_realT));
  }

  // The top of the nearest floor below a point, for drop shadows
  double? _groundBelow(double x, double y) {
    final tx = (x / tile).floor();
    for (var ty = (y / tile).floor(); ty < level.rows && ty * tile < y + 64; ty++) {
      final t = level.tileAt(tx, ty);
      if (t != T.empty && t != T.spikes && ty * tile >= y - 0.5) return ty * tile;
    }
    return null;
  }

  void _shadow(Canvas c, double x, double y, double w) {
    final gy = _groundBelow(x, y);
    if (gy == null) return;
    final k = 1 - ((gy - y) / 64).clamp(0.0, 1.0);
    c.drawOval(Rect.fromCenter(center: Offset(x, gy), width: w * (0.5 + 0.5 * k), height: 2.6 * (0.6 + 0.4 * k)),
        Paint()..color = Color.fromRGBO(16, 10, 30, 0.32 * k));
  }

  // Every light source in view this frame
  List<Light> _lights() {
    final t = _realT;
    return [
      for (final a in altars)
        a.lit
            ? Light(a.x, a.y - 16, 48 + math.sin(t * 13 + a.x) * 2 + math.sin(t * 7.3) * 2, 0xffffa040)
            : Light(a.x, a.y - 13, 12 + math.sin(t * 3) * 2, 0xffff6020, 0.6),
      if (featherPickup != null) Light(featherPickup!.x, featherPickup!.y, 32, 0xff8ae0d8),
      if (sunKey != null && !keyFound) Light(sunKey!.dx, sunKey!.dy, 40 + math.sin(t * 2) * 4, 0xfff7d774),
      for (final f in feathers) Light(f.body.x, f.body.centerY, 24, 0xff8ae0d8),
      for (final o in orbs) Light(o.x, o.y, 12, 0xff8ae0d8, 0.8),
      for (final co in coins) Light(co.body.x, co.body.y - 3, 9, 0xffffd060, 0.5),
      for (final h in hearts) Light(h.body.x, h.body.y - 4, 10, 0xffff6a7a, 0.5),
      for (final ch in chests)
        if (!ch.opened) Light(ch.x, ch.y - 5, 14, 0xffffd060, 0.35 + 0.15 * math.sin(t * 2.5)),
      for (final s in slashes) Light(s.x, s.y, 22, 0xffffe8b0, 1 - s.t / Slash.duration),
      if (gate != null && gate!.glow > 0) Light(gate!.x, gate!.y - 22, 64 * gate!.glow, 0xfffff0b0, gate!.glow),
      if (ambience.dark) Light(player.x, player.y - 8, 72, 0xfff0e8d0, 0.95),
      if (ambience.dark && lion != null) Light(lion!.x, lion!.y - 14, 30, 0xffff8040, 0.5),
    ];
  }

  void _renderWorld(Canvas c, Rect view) {
    final a = art;
    // depth 0: arena walls
    for (final w in physics.walls) {
      drawFrame(c, a.wall, 0, w.x, w.rect.bottom);
    }
    // depth 3: signs and the gate
    for (final s in signs) {
      drawFrame(c, a.sign, 0, s.x, s.y);
    }
    final g = gate;
    if (g != null) {
      drawFrame(c, a.gate, 0, g.x, g.y);
      drawFrame(c, a.gateGlow, 0, g.x, g.y, alpha: g.glow * (0.85 + 0.15 * math.sin(_realT * 3)));
    }
    // depth 4: altars, breakables, chests
    for (final al in altars) {
      drawFrame(c, a.altar, 0, al.x, al.y);
      if (al.lit) {
        final flick = 1 + math.sin(_realT * 17 + al.x) * 0.06;
        drawFrame(c, a.flame, al.flame.frame, al.x, al.y - 13, scaleX: 2 - flick, scaleY: flick);
      } else {
        drawFrame(c, a.px, 0, al.x, al.y - 13, oy: 0.5, tint: 0xff803020, alpha: 0.6 + 0.4 * math.sin(_realT * 3));
      }
    }
    for (final b in breakables) {
      final wob = b.wobble > 0 ? math.sin(_realT * 32) * b.wobble * 9 : 0.0;
      drawFrame(c, b.sheet, 0, b.x, b.y, angle: wob);
    }
    for (final ch in chests) {
      drawFrame(c, a.chest, ch.opened ? 1 : 0, ch.x, ch.y);
    }
    // depth 5: tiles (only the visible part of the map image)
    final src = view.intersect(Rect.fromLTWH(0, 0, level.width, level.height));
    if (!src.isEmpty) c.drawImageRect(_map, src, src, _pixel);
    // Soft shadows ground everything that moves
    if (!player.dead) _shadow(c, player.x, player.y, 10);
    // Only what is on screen (plus a margin for big sprites) gets drawn
    final near = view.inflate(64);
    bool seen(double x, double y) => near.contains(Offset(x, y));
    for (final e in enemies) {
      if (e.shadowW > 0 && seen(e.x, e.y)) _shadow(c, e.x, e.y, e.shadowW);
    }
    if (lion != null && lion!.state != LionState.dead) _shadow(c, lion!.x, lion!.y, 44);
    // depth 6-7: feather pickup, coins, hearts
    final f = featherPickup;
    if (f != null) {
      final k = 1 - ((f.t % 1400) - 700).abs() / 700; // 0 -> 1 -> 0 over 1.4 s
      c.drawCircle(Offset(f.x, f.y), 10 * (1 + 0.4 * k), Paint()..color = Color.fromRGBO(138, 224, 216, 0.25 - 0.15 * k));
      // Two motes circle the feather
      final glow = Paint()
        ..blendMode = BlendMode.plus
        ..color = const Color(0xffc8fff8);
      for (var i = 0; i < 2; i++) {
        final ang = _realT * 2.4 + i * math.pi;
        c.drawCircle(Offset(f.x + math.cos(ang) * 11, f.y + math.sin(ang) * 4), 0.9, glow);
      }
      drawFrame(c, a.feather, 0, f.x, f.y, oy: 0.5, scaleX: 1.5, scaleY: 1.5, angle: -30 + math.sin(_realT * 2) * 6);
    }
    for (final co in coins) {
      if (!seen(co.body.x, co.body.y)) continue;
      // Coins spin: squeeze the width with a cosine
      final spin = math.cos(co.age / 140 + co.phase).abs();
      drawFrame(c, a.coin, 0, co.body.x.roundToDouble(), co.body.y.roundToDouble(), scaleX: math.max(0.2, spin));
    }
    for (final h in hearts) {
      final bob = h.body.blockedDown ? math.sin(h.age / 180) * 1.2 - 1 : 0.0;
      final beat = 1 + math.max(0.0, math.sin(h.age / 120)) * 0.12;
      drawFrame(c, a.heart, 0, h.body.x.roundToDouble(), (h.body.y + bob).roundToDouble(), scaleX: beat, scaleY: beat);
    }
    // depth 8-9: enemies, feathers, boss, xp orbs
    for (final e in enemies) {
      if (seen(e.x, e.y)) e.render(c);
    }
    for (final fe in feathers) {
      drawFrame(c, a.feather, 0, fe.body.x, fe.body.centerY, oy: 0.5, flipX: fe.dir < 0);
    }
    // The Sun Key: a little sun bobbing in the air, its eye on Ra
    final k = sunKey;
    if (k != null && !keyFound && seen(k.dx, k.dy)) {
      final at = k + Offset(0, math.sin(_realT * 2.2) * 2);
      final to = Offset(player.x, player.y - 8) - at;
      paintSunDisc(c, at, 0.24);
      paintSunEye(c, at, 0.24, look: to / math.max(1.0, to.distance), open: sunBlink(_realT + 1.7));
    }
    lion?.render(c, a.lion);
    for (final o in orbs) {
      drawFrame(c, a.xp, 0, o.x, o.y, oy: 0.5, angle: o.t * 0.4);
    }
    // depth 10: Ra, then the grass in front of everyone's feet
    player.render(c, a.hero, timeNow);
    ambience.renderGrass(c, view);
    // depth 11-12: slashes, particles, light and darkness, weather, numbers
    for (final s in slashes) {
      s.render(c, a.slash);
    }
    particles.render(c);
    ambience
      ..renderLights(c, view, _lights())
      ..renderMotes(c);
    for (final t in texts) {
      t.render(c);
    }
  }
}
