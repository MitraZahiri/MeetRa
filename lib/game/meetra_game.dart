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
import '../art/backdrops.dart' show Backdrop, backdropParallax, backdropScale, paintBackdrop;
import '../art/sprites.dart';
import '../art/sun_eye.dart';
import '../config.dart';
import '../entities/enemy.dart';
import '../entities/elephant.dart';
import '../entities/lion.dart';
import '../entities/player.dart';
import '../input.dart';
import '../music.dart';
import '../levels/build.dart';
import '../levels/generator.dart';
import '../levels/level1.dart';
import '../levels/rooms.dart' show roomH;
import '../sfx.dart';
import '../world/arms.dart';
import '../world/progress.dart';
import '../world/saga.dart';
import '../world/shop.dart';
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

// Ra at a merchant's counter: who sells, what they say, and in which realm (prices follow the realm)
class ShopVisit {
  ShopVisit(this.merchant, this.greeting, this.realm, {this.travelling = false});
  final String merchant;
  final String greeting;
  final Realm realm;
  final bool travelling;
}

// Pages of the saga to read on a parchment scroll; [onDone] runs when the last page is turned
class StoryScroll {
  StoryScroll(this.title, this.pages, {this.onDone});
  final String title;
  final List<StoryPage> pages;
  final void Function()? onDone;
}

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
  final story = ValueNotifier<StoryScroll?>(null); // the scroll being read; the game waits meanwhile
  final action = ValueNotifier<String?>(null); // 'Trade' or 'Rest' when Ra stands at a stall or the inn
  final curtain = ValueNotifier<bool>(false); // a black curtain drawn between two screens
  final bossIntro = ValueNotifier<BossDef?>(null); // the guardian's name card during its entrance
  final shop = ValueNotifier<ShopVisit?>(null); // a merchant's counter; the game waits meanwhile
  final book = ValueNotifier<int?>(null); // the Book of Verses, open on this realm's page
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
  Sign(this.x, this.y, this.text, {this.post = true});
  final double x, y;
  final String text;
  final bool post; // a wooden signpost; a read Verse Stone keeps its words without one
}

// A lit bomb: it falls, rolls to a stop and bursts when the fuse burns down
class Bomb {
  Bomb(double x, double y) : body = Body(x, y, 8, 8)..bounceY = 0.25;
  final Body body;
  double fuse = 1400;
  bool removed = false;
}

// A bomb flower: its round fruit is a bomb for Ra's bag, and it grows a new one a while later
class BombFlower {
  BombFlower(this.x, this.y);
  final double x, y;
  double regrow = 0; // ms until the next fruit; 0 means one is ripe
  Rect get bounds => Rect.fromLTWH(x - 7, y - 14, 14, 14);
}

// An iron cage with a captive inside; three sword strikes break it open
class Cage {
  Cage(this.x, this.y, this.index, {this.freed = false});
  final double x, y;
  final int index; // 0..2
  bool freed;
  int hp = 3;
  double shake = 0;
  Rect get bounds => Rect.fromLTWH(x - 10, y - 24, 20, 24);
}

// A stone carved with one verse of the realm's legend, waiting off the road
class VerseStone {
  VerseStone(this.x, this.y, this.index, {this.read = false});
  final double x, y;
  final int index; // 0..6
  bool read;
  Rect get bounds => Rect.fromLTWH(x - 8, y - 18, 16, 18);
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
  Chest(this.x, this.y, this.id, {this.opened = false});
  final double x, y;
  final String id; // how the save remembers it
  bool opened;
  Rect get bounds => Rect.fromLTWH(x - 7, y - 10, 14, 10);
}

class FeatherItem {
  FeatherItem(this.x, this.baseY);
  final double x, baseY;
  double t = 0;
  double get y => baseY - 6 * (0.5 - 0.5 * math.cos(math.pi * t / 900));
}

// Someone who lives in town: strolls up and down near home, and stops to talk when Ra comes close
class Townsperson {
  Townsperson(this.x, this.y, this.index, this.page) : home = x;
  double x;
  final double y, home;
  final int index;
  final StoryPage page;
  int facing = 1;
  double walkT = 0, pause = 0;
  bool talking = false;
  String get line => '${page.speaker}:  ${page.text}';
}

// A merchant's stall: a striped awning over a counter, the merchant behind it.
// Stepping up to it opens the counter; Ra has to step away before it opens again.
class Stall {
  Stall(this.x, this.y, {this.travelling = false});
  final double x, y;
  final bool travelling;
  bool near = false;
}

// A house on a town street, drawn in the realm's own style
class House {
  House(this.x, this.y, this.variant);
  final double x, y;
  final int variant;
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
  dui.Image? _mapImage;
  dui.Image get _map => _mapImage!;
  late Ambience ambience;
  Backdrop? _backdrop; // the painted scenery of the realm being played
  RealmTheme? _backdropTheme;
  bool _backdropCave = false;
  Backdrop? _underground; // fades in below the surface rooms, painted the first time it is needed

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
  String? _talkShown; // the words of the sign or person next to Ra, as shown
  final townsfolk = <Townsperson>[];
  VerseStone? verseStone;
  final houses = <House>[];
  final stalls = <Stall>[];
  Offset? inn; // the inn's door
  bool _actWanted = false, _downTapped = false; // the Trade / Rest button (or E on a keyboard) was pressed
  bool _atInn = false;
  int _nights = 0;
  Cage? cage;
  final bombs = <Bomb>[];
  final flowers = <BombFlower>[];
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
  // The guardian's entrance: the camera turns to it while Ra stands still
  double _cineT = 0;
  Offset? _cineAt;
  static const cineMs = 2300.0;
  double _wallRise = 1;
  double _slow = 0; // real ms of slow motion left // 0 -> 1 while the wall behind Ra rises
  double timeNow = 0;
  double _hitstop = 0;
  double _drift = 0;
  double _realT = 0; // keeps running while paused, for ambient motion
  double _winT = -1;
  bool _snapCamera = true;

  bool get simPaused => !started || ui.screen.value != AppScreen.playing || ui.levelUps.value > 0 || ui.story.value != null || ui.shop.value != null;
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
    verseStone = null;
    cage = null;
    houses.clear();
    bombs.clear();
    flowers.clear();
    stalls.clear();
    inn = null;
    _atInn = false;
    gate = null;
    activeSign = null;
    _talkShown = null;
    ui.action.value = null;
    townsfolk.clear();
    arenaLeft = arenaRight = null;
    lionSpawn = waveSpawn = sunKey = null;
    keyFound = _waveComing = false;
    wave = 0;
    _waveFoes.clear();
    _sealedHint = 0;
    leftWall = rightWall = null;
    lion = null;
    bossStarted = bossDefeated = victory = false;
    _slow = 0;
    _cineT = 0;
    _cineAt = null;
    ui.bossIntro.value = null;
    pendingLevelUps = 0;
    _hitstop = 0;
    _winT = -1;
    _snapCamera = true;
    camera
      ..bounds = Rect.fromLTWH(0, 0, level.width, level.height)
      ..fade = 0;
    // The old level's map image is freed at once instead of waiting for the garbage collector
    _mapImage?.dispose();
    _mapImage = _renderMap();
    _backdropCave = location?.kind == LocKind.cave;
    _paintBackdrops();
    _spawnObjects();
  }

  // Caves show the underground all the way; other places their realm's scenery.
  // Only the backdrop in use is kept, so a new realm repaints and frees the last one.
  void _paintBackdrops() {
    final theme = location?.realm.theme ?? RealmTheme.vale;
    final cave = location?.kind == LocKind.cave;
    if (cave || def.sealed) _underground ??= paintBackdrop(null);
    if (cave) return;
    if (_backdrop != null && theme == _backdropTheme) return;
    _backdrop?.dispose();
    _backdrop = paintBackdrop(theme);
    _backdropTheme = theme;
  }

  // The whole tilemap is drawn once into one image, so tiles never show seams when scaled
  dui.Image _renderMap() {
    final rec = dui.PictureRecorder();
    final c = Canvas(rec);
    final p = Paint()..filterQuality = FilterQuality.none;
    final tiles = art.tiles[location?.realm.theme ?? RealmTheme.vale]!;
    for (var ty = 0; ty < level.rows; ty++) {
      for (var tx = 0; tx < level.cols; tx++) {
        final t = level.data[ty][tx];
        if (t < 0) continue;
        if (t == T.cracked || t == T.slab) {
          _drawCracked(c, tiles, tx, ty, p);
          continue;
        }
        c.drawImageRect(tiles.image, tiles.src(t), Rect.fromLTWH(tx * tile, ty * tile, tile, tile), p);
      }
    }
    return rec.endRecording().toImageSync(level.width.toInt(), level.height.toInt());
  }

  // Cracked rock: the brick tile, darker, split by a zigzag crack and chipped at the corners
  void _drawCracked(Canvas c, Sheet tiles, int tx, int ty, Paint p) {
    final r = Rect.fromLTWH(tx * tile, ty * tile, tile, tile);
    c.drawImageRect(tiles.image, tiles.src(T.brick), r, p);
    c.drawRect(r, Paint()..color = const Color(0x3a1a1008));
    final crack = Paint()..color = const Color(0xff1a1008);
    final light = Paint()..color = const Color(0x55f2e6c9);
    final x = r.left, y = r.top;
    for (final (cx, cy, w, h) in const [(7.0, 1.0, 2.0, 4.0), (5.0, 5.0, 3.0, 2.0), (4.0, 7.0, 2.0, 4.0), (6.0, 11.0, 2.0, 4.0), (9.0, 6.0, 4.0, 1.5), (12.0, 7.0, 2.0, 3.0)]) {
      c.drawRect(Rect.fromLTWH(x + cx, y + cy, w, h), crack);
    }
    c.drawRect(Rect.fromLTWH(x + 9, y + 2, 2, 1), light);
    c.drawRect(Rect.fromLTWH(x + 2, y + 12, 2, 1), light);
  }

  void _spawnObjects() {
    var signIndex = 0;
    var chestIndex = 0;
    Player? p;
    for (final o in level.objects) {
      switch (o.type) {
        case 'P':
          p = Player(this, o.x, o.y);
        case 'A':
          altars.add(Altar(o.x, o.y));
        case 'S':
          signs.add(Sign(o.x, o.y, def.signs[signIndex++]));
        case 'D' || 'V' || 'U' || 'K' || 'M' || 'H':
          enemies.addAll(_foes(o.type, o.x, o.y));
        case 'W':
          waveSpawn = Offset(o.x, o.y);
        case 'O':
          sunKey = Offset(o.x, o.y - 6);
        case 'v':
          breakables.add(Breakable(o.x, o.y, 'vase', art.vase));
        case '*':
          breakables.add(Breakable(o.x, o.y, 'bush', art.bush));
        case 'T':
          final loc = location;
          final i = loc == null ? null : verseIndex(loc);
          if (loc != null && i != null) {
            final read = progress.hasVerse(loc);
            verseStone = VerseStone(o.x, o.y, i, read: read);
            if (read) signs.add(_verseSign(verseStone!));
          }
        case 'R':
          final loc = location;
          final i = loc == null ? null : captiveIndex(loc);
          if (loc != null && i != null) {
            cage = Cage(o.x, o.y, i, freed: progress.isFreed(loc));
            if (cage!.freed) signs.add(Sign(o.x, o.y, '${chapterOf(loc.realm).captives[i].speaker} was freed from this cage and has gone home.', post: false));
          }
        case 'N':
          final loc = location;
          if (loc != null) {
            // The first is the town's keeper, with new words on each visit; the others are its folk
            final c = chapterOf(loc.realm);
            final n = townsfolk.length;
            final visit = _townVisits[loc.id] ?? 0;
            final page = n == 0 ? c.townTalk[visit % c.townTalk.length] : c.people[(n - 1) % c.people.length];
            townsfolk.add(Townsperson(o.x, o.y, n, page));
          }
        case 'I':
          inn = Offset(o.x, o.y);
        case 'Q':
          flowers.add(BombFlower(o.x, o.y));
        case r'$':
          stalls.add(Stall(o.x, o.y, travelling: !def.town));
        case '&':
          houses.add(House(o.x, o.y, houses.length));
        case 'C':
          final id = '${location?.id ?? def.title}#${chestIndex++}';
          chests.add(Chest(o.x, o.y, id, opened: progress.isChestOpen(id)));
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
    // The guardian rests in its arena from the start, so Ra sees what waits at the end of the road
    if (lionSpawn != null) lion = _makeBoss();
    // Levels without a fight have their exit gate open from the start, unless it is sealed
    if (lionSpawn == null && waveSpawn == null) {
      bossDefeated = true;
      gate?.opening = !def.sealed;
    }
  }

  // The creatures a map letter stands for (scorpions come in pairs).
  // Every realm makes them tougher: more health, and from the Sky Spine on their touch costs
  // a whole heart. In the Lightless Land everything hits harder still.
  List<Enemy> _foes(String type, double x, double y) {
    final tier = def.enemyBonus;
    final bonus = tier + tier ~/ 2;
    final foes = switch (type) {
      'D' => [Demon(this, x, y)..hp += bonus],
      'V' => [Fly(this, x, y - 40)..hp += bonus],
      'U' => [Ghoul(this, x, y)..hp += bonus],
      'K' => [for (final dx in [-7.0, 7.0]) Scorpion(this, x + dx, y)..hp += bonus ~/ 2],
      'M' => [Manticore(this, x, y)..hp += bonus * 2],
      'H' => [Shade(this, x, y - 4)..hp += bonus],
      _ => <Enemy>[],
    };
    final extra = (tier >= 3 ? 1 : 0) + (tier >= 6 ? 1 : 0);
    for (final e in foes) {
      e.contactDamage += extra;
    }
    return foes;
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
    var dt = math.min(dtSeconds * 1000, 50.0);
    _drift += dt * 0.004;
    _realT += dt / 1000;
    if (mapOpen) return;
    ambience.update(dt, _view, simPaused ? const [] : _pushers());
    if (simPaused) {
      state.flush();
      return;
    }
    // The world slows for a moment when a guardian falls
    if (_slow > 0) {
      _slow -= dt;
      dt *= 0.3;
    }
    timeNow += dt;
    timers.update(dt);

    final c = controls.update();
    final P = player;
    if (c.drinkPressed) _drink();
    if (c.bombPressed) _placeBomb();
    _updateBombs(dt);
    _updateFlowers(dt);
    _bombHint();
    _downTapped = _actWanted || c.actPressed;
    _actWanted = false;
    P.update(c, dt);
    // Until the fight starts the guardian only breathes
    if (bossStarted || bossDefeated) {
      lion?.update(timeNow, dt);
    } else {
      lion?.rest(dt);
    }
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
    _updateTownsfolk(dt);
    _updateStalls();
    _updateInn();
    _updateSigns();
    _updatePickups(dt);
    _updateOrbs(dt);
    _updateChests(pr);
    _updateVerse(pr);

    final l = lion;
    if (l != null && bossStarted && l.state != LionState.dead && l.state != LionState.stunned && !P.dead) {
      if (overlaps(pr, l.body.rect)) P.hurt(l.contactDamage, l.x);
    }
    if (l != null && !P.dead) {
      for (final h in l.hazards) {
        if (overlaps(pr, h)) P.hurt(1, h.center.dx);
      }
    }
    if (l != null && bossStarted && l.state != LionState.dead) {
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
      if (def.town) {
        // A town's gate leads straight back to the realm map
        victory = true;
        leaveLevel();
      } else if (g.opening) {
        _win();
      } else if (def.sealed && _sealedHint <= 0) {
        _sealedHint = 4000;
        ui.banner.value = BannerMsg('The gate is sealed', 'Follow the golden arrow to the Sun Key');
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
    final cine = _cineAt;
    if (_cineT > 0 && cine != null) {
      // Look at the guardian for most of the entrance, then swing back to Ra
      _cineT -= dt;
      final back = _cineT < 600;
      camera.follow(back ? P.x : cine.dx, back ? P.y - 20 : cine.dy - 20, dt);
      if (_cineT <= 0) {
        P.frozen = false;
        _cineAt = null;
        // How to beat it, as the fight begins
        if (lion != null) {
          ui.banner.value = BannerMsg(
              'Jump over its charge',
              def.boss.kind == BossKind.elephant
                  ? 'Leap its shockwaves; a charge into the wall dazes it: strike then!'
                  : 'A charge into the wall dazes it: strike then!');
        }
      }
    } else {
      camera.follow(P.x, P.y - 20, dt, snap: _snapCamera);
    }
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
      if (!e.asleep) physics.step(e.body, s, tiles: !e.ghost);
    }
    for (final c in [...coins, ...hearts]) {
      physics.step(c.body, s, useWalls: false);
    }
    for (final b in bombs) {
      physics.step(b.body, s);
      if (b.body.blockedDown) b.body.vx *= 0.85;
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
        if (f.removed || e.dying || e.untouchable || !overlaps(f.body.rect, e.body.rect)) continue;
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
        state.bombs = math.max(state.bombs, maxBombs);
        ui.banner.value = BannerMsg('Hearth lit', 'Checkpoint reached · health restored · bombs refilled');
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
    activeSign = near;
    // Without a sign close by: how to trade or rest, or else the nearest townsperson speaks
    var text = near?.text;
    String? action;
    final loc = location;
    for (final st in stalls) {
      if (text == null && loc != null && (P.x - st.x).abs() < 16 && (P.y - st.y).abs() < 24) {
        text = '${(st.travelling ? travellingMerchant : townMerchants[loc.realm.id]!).$1}: tap Trade to see the wares.';
        action = 'Trade';
      }
    }
    final d = inn;
    if (text == null && d != null && (P.x - d.dx).abs() < 12 && (P.y - d.dy).abs() < 24) {
      text = loc != null && !state.arms.contains(loc.realm.index)
          ? 'The inn. The innkeeper keeps something for you: ${arms[loc.realm.index].name}. Tap Rest to sleep the night and take it.'
          : 'The inn. Tap Rest to sleep the night: health and aura come back, and the journey is saved.';
      action = 'Rest';
    }
    if (ui.action.value != action) ui.action.value = action;
    for (final t in townsfolk) {
      t.talking = text == null && (P.x - t.x).abs() < 26 && (P.y - t.y).abs() < 30;
      if (t.talking) text = t.line;
    }
    if (text != _talkShown) {
      _talkShown = text;
      ui.sign.value = text;
    }
  }

  static const _innkeeper = [
    'A bed, a bowl of soup and a quiet night. The road will still be there in the morning.',
    'Sleep well? I kept the door barred and the fire high all night.',
    "You talked in your sleep. Something about a giant. Don't worry, I've heard worse.",
    'Breakfast is bread and honey. The honey comes from Hearthvale, if you are homesick.',
  ];

  // Stepping through the inn's door: a night passes, health and aura come back and the game is saved
  void _updateInn() {
    final d = inn;
    if (d == null) return;
    final close = (player.x - d.dx).abs() < 12 && (player.y - d.dy).abs() < 24 && !player.dead;
    if (close && _downTapped && !_atInn) {
      touch.clear();
      player.frozen = true;
      camera.fadeOut(600, () {
        state
          ..hp = state.maxHp
          ..aura = state.auraMax.toDouble()
          ..bombs = math.max(state.bombs, maxBombs);
        progress.save(state);
        sfx.altar();
        camera.fadeIn(700);
        player.frozen = false;
        // The first night in a realm's town, the innkeeper hands over the arm kept for Ra
        final realm = location?.realm;
        if (realm != null && !state.arms.contains(realm.index)) {
          final arm = arms[realm.index];
          state
            ..arms.add(realm.index)
            ..wield = realm.index;
          progress.save(state);
          camera.flash(arm.color, 0.3, 600);
          particles.ring(player.x, player.y - 10, arm.color, r1: 34, life: 700, width: 3);
          ui.banner.value = BannerMsg('A new arm: ${arm.name}', 'Tap the arms button to change weapons');
          tell(StoryScroll(location?.name ?? 'The inn', [
            StoryPage('The innkeeper', arm.gift),
            StoryPage(arm.name, '${arm.use} It adds ${arm.bonus} to every blow. Tap the arms button beside the sword to change weapons.'),
          ]));
        } else {
          ui.banner.value = BannerMsg('A night at the inn', 'Health, aura and bombs restored  ·  the journey is saved');
          tell(StoryScroll(location?.name ?? 'The inn', [StoryPage('The innkeeper', _innkeeper[_nights++ % _innkeeper.length])]));
        }
        _atInn = false;
      });
      _atInn = true; // resting: no second night until this one is over
    }
  }

  // Called by the Trade / Rest button
  void act() => _actWanted = true;

  // Something Ra's sword can hit inside [r]: a foe, the guardian in a fight, a vase or bush, or a cage
  bool targetIn(Rect r) =>
      enemies.any((e) => !e.dying && !e.untouchable && overlaps(r, e.body.rect)) ||
      (bossStarted && lion != null && lion!.state != LionState.dead && overlaps(r, lion!.body.rect)) ||
      breakables.any((b) => overlaps(r, b.bounds)) ||
      (cage != null && !cage!.freed && overlaps(r, cage!.bounds));

  void _updateStalls() {
    final loc = location;
    if (loc == null) return;
    for (final st in stalls) {
      final close = (player.x - st.x).abs() < 16 && (player.y - st.y).abs() < 24 && !player.dead;
      if (close && _downTapped) {
        final (name, greeting) = st.travelling ? travellingMerchant : townMerchants[loc.realm.id]!;
        openShop(ShopVisit(name, greeting, loc.realm, travelling: st.travelling));
      }
      st.near = close;
    }
  }

  // Townsfolk stroll a little way from home and back, pausing now and then; a talker turns to Ra
  void _updateTownsfolk(double dt) {
    for (final t in townsfolk) {
      if (t.talking) {
        t.facing = player.x >= t.x ? 1 : -1;
        continue;
      }
      if (t.pause > 0) {
        t.pause -= dt;
        continue;
      }
      t.x += t.facing * 14 * dt / 1000;
      t.walkT += dt;
      if ((t.x - t.home).abs() > 22 + t.index * 6) {
        t.x = t.home + (t.x - t.home).sign * (22 + t.index * 6);
        t.facing = -t.facing;
        t.pause = 900 + rand.nextDouble() * 1800;
      }
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

  Sign _verseSign(VerseStone v) =>
      Sign(v.x, v.y, 'Verse ${numerals[v.index]}:  ${chapterOf(location!.realm).verses[v.index]}', post: false);

  void openShop(ShopVisit v) {
    touch.clear();
    sfx.pickup();
    ui.shop.value = v;
  }

  void closeShop() => ui.shop.value = null;

  static const _thanks = [
    'A fine choice. May it serve you on the road.',
    'Paid in full. Come back alive, and buy more.',
    'My grandmother swore by those. She lived to a hundred.',
    'Spend it well, hearth-keeper.',
  ];

  // Called by the shop: pays, hands the ware over, saves, and returns the merchant's words
  String buyWare(Ware w, ShopVisit v) {
    if (!buy(w, v.realm, state, progress)) return 'Not today, I think.';
    sfx.altar();
    progress.save(state);
    return _thanks[rand.nextInt(_thanks.length)];
  }

  // Ra sets a bomb down at the feet, nudged a little forward
  void _placeBomb() {
    final P = player;
    if (P.dead || victory || P.frozen || def.town) return;
    if (state.bombs <= 0) {
      floatText(P.x, P.y - 26, 'No bombs left', const Color(0xffff8a7a), size: 8);
      return;
    }
    state.bombs -= 1;
    bombs.add(Bomb(P.x + P.facing * 6, P.y - 4)..body.vx = P.facing * 40);
    sfx.swing();
  }

  void _updateBombs(double dt) {
    for (final b in bombs) {
      b.fuse -= dt;
      if (rand.nextDouble() < dt / 60) particles.sparkle(b.body.x + 2, b.body.y - 9, 0xffffc040);
      if (b.fuse <= 0) {
        b.removed = true;
        explode(b.body.x, b.body.y - 4);
      }
    }
    bombs.removeWhere((b) => b.removed);
  }

  // The first time Ra comes close to cracked rock, a banner explains what to do with it (once per save)
  void _bombHint() {
    if (progress.wasTold('hint:bombs') || player.dead) return;
    final tx = (player.x / tile).floor(), ty = (player.y / tile).floor();
    for (var y = ty - 2; y <= ty + 2; y++) {
      for (var x = tx - 3; x <= tx + 3; x++) {
        final t = level.tileAt(x, y);
        if (t != T.cracked && t != T.slab) continue;
        progress.firstTelling('hint:bombs');
        progress.save(state);
        ui.banner.value = BannerMsg('Cracked rock', 'Tap the bomb button beside it to blast it open  ·  bomb flowers grow nearby');
        return;
      }
    }
  }

  void _updateFlowers(double dt) {
    final pr = player.body.rect;
    for (final f in flowers) {
      if (f.regrow > 0) {
        f.regrow = math.max(0, f.regrow - dt);
        continue;
      }
      if (player.dead || !overlaps(pr, f.bounds)) continue;
      if (state.bombs >= maxBombs) continue;
      state.bombs += 1;
      f.regrow = 7000;
      sfx.pickup();
      particles.spark(f.x, f.y - 10, size: 10, color: 0xffffc040);
      floatText(f.x, f.y - 20, '+1 bomb', const Color(0xffffd27a), size: 8);
    }
  }

  static const blastRadius = 30.0;

  // A bomb bursts: it hurts foes, the guardian and Ra if too close, and breaks vases, bushes and cages
  void explode(double x, double y) {
    sfx.thud();
    sfx.breakIt();
    camera
      ..shake(300, 0.012)
      ..flash(0xffffe0a0, 0.25, 300);
    burst(x, y, [0xffffc040, 0xffff7a2a, 0xff5a4a38, 0xfffff4c0], 26, 190);
    particles
      ..ring(x, y, 0xffffe0a0, r1: blastRadius + 6, life: 380, width: 4)
      ..dust(x, y + 4, count: 10, spread: 60, color: 0xff8a7a68);
    bool inBlast(Rect r) => Rect.fromCircle(center: Offset(x, y), radius: blastRadius).overlaps(r);
    final dmg = 2 + state.attack;
    for (final e in enemies) {
      if (!e.dying && !e.untouchable && inBlast(e.body.rect)) e.hurt(dmg, (e.x - x).sign, 1.6);
    }
    final l = lion;
    if (l != null && bossStarted && l.state != LionState.dead && inBlast(l.body.rect)) l.hurt(dmg);
    for (final b in [...breakables]) {
      if (inBlast(b.bounds)) _breakObject(b);
    }
    final cg = cage;
    if (cg != null && !cg.freed && inBlast(cg.bounds)) _freeCaptive(cg);
    final P = player;
    if (!P.dead && (Offset(P.x, P.y - 8) - Offset(x, y)).distance < blastRadius * 0.7) P.hurt(1, x);
    // Cracked rock in reach shatters, and the map is redrawn without it
    var broke = false;
    for (var ty = ((y - blastRadius) / tile).floor(); ty <= ((y + blastRadius) / tile).floor(); ty++) {
      for (var tx = ((x - blastRadius) / tile).floor(); tx <= ((x + blastRadius) / tile).floor(); tx++) {
        final t = level.tileAt(tx, ty);
        if (t != T.cracked && t != T.slab) continue;
        if ((Offset(tx * tile + tile / 2, ty * tile + tile / 2) - Offset(x, y)).distance > blastRadius + 6) continue;
        level.data[ty][tx] = T.empty;
        broke = true;
        burst(tx * tile + tile / 2, ty * tile + tile / 2, [0xff6a5a4a, 0xff8a7a68, 0xff3a2a1a], 6, 120);
      }
    }
    if (broke) {
      _mapImage?.dispose();
      _mapImage = _renderMap();
    }
  }

  // A healing draught from the satchel mends three hearts
  void _drink() {
    final P = player;
    if (state.draughts <= 0 || P.dead || victory) return;
    if (state.hp >= state.maxHp) {
      floatText(P.x, P.y - 26, 'Already whole', const Color(0xffc8bca0), size: 8);
      return;
    }
    state
      ..draughts -= 1
      ..hp = math.min(state.maxHp, state.hp + draughtHeal);
    sfx.pickup();
    particles
      ..ring(P.x, P.y - 10, 0xffff6a7a, r1: 26, life: 450)
      ..spark(P.x, P.y - 12, size: 12, color: 0xffff8a9a);
    burst(P.x, P.y - 10, [0xffff6a7a, 0xffffc0c8], 12, 80);
    floatText(P.x, P.y - 26, '+3 hearts', const Color(0xffff8a9a), size: 9, rise: 18, duration: 900);
    progress.save(state);
  }

  void _freeCaptive(Cage cg) {
    final loc = location!;
    cg.freed = true;
    progress.free(loc);
    sfx.breakIt();
    burst(cg.x, cg.y - 12, [0xff5a5a6a, 0xff8a8a9a, 0xffd0d0e0], 18, 140);
    particles.ring(cg.x, cg.y - 12, 0xfffff0c0, r1: 36, life: 650, width: 2.5);
    spawnGold(cg.x, cg.y - 14, 15);
    spawnHeart(cg.x, cg.y - 14);
    final page = chapterOf(loc.realm).captives[cg.index];
    signs.add(Sign(cg.x, cg.y, '${page.speaker} was freed from this cage and has gone home.', post: false));
    final n = progress.freedIn(loc.realm);
    tell(StoryScroll('A captive set free', [
      page,
      StoryPage(narrator, n < 3 ? '$n of the three captives of ${loc.realm.name} freed. The others wait in its caves and ruins.' : 'All three captives of ${loc.realm.name} are free and on their way home.'),
    ]));
    progress.save(state);
  }

  // Touching an unread Verse Stone reads it aloud; after that its words show like a signpost's
  void _updateVerse(Rect pr) {
    final v = verseStone, loc = location;
    if (v == null || v.read || loc == null || !overlaps(pr, v.bounds)) return;
    v.read = true;
    progress.findVerse(loc);
    signs.add(_verseSign(v));
    sfx.altar();
    camera.flash(0xff8ae0d8, 0.25, 600);
    particles
      ..ring(v.x, v.y - 10, 0xff8ae0d8, r1: 34, life: 600, width: 2.5)
      ..spark(v.x, v.y - 12, size: 14, color: 0xff8ae0d8);
    spawnXp(v.x, v.y - 12, 10);
    final c = chapterOf(loc.realm);
    final n = progress.versesIn(loc.realm);
    // The seventh verse makes the legend whole, and its old strength passes to Ra
    final whole = n == 7 && progress.firstTelling('legend:${loc.realm.id}');
    if (whole) {
      state.attack += 1;
      floatText(v.x, v.y - 24, '+1 might', const Color(0xff8ae0d8), size: 10, rise: 22, duration: 1400);
    }
    tell(StoryScroll('${c.legend}  ·  verse ${numerals[v.index]} of VII', [
      StoryPage('Carved on the stone', c.verses[v.index]),
      if (n < 7) StoryPage(narrator, '$n of the seven verses of ${loc.realm.name} found. The others wait on its trails.'),
      if (whole)
        StoryPage(narrator,
            "The seven verses of ${loc.realm.name} are whole again: ${c.legend}. The old poets' strength flows into Ra. Blessing: +1 might. The whole legend is kept in the Book of Verses."),
    ]));
    progress.save(state);
  }

  void _updateChests(Rect pr) {
    for (final ch in chests) {
      if (ch.opened || !overlaps(pr, ch.bounds)) continue;
      ch.opened = true;
      progress.openChest(ch.id);
      sfx.pickup();
      particles
        ..ring(ch.x, ch.y - 6, 0xffffe28a, r1: 24, life: 450)
        ..spark(ch.x, ch.y - 8, size: 12, color: 0xffffe28a);
      spawnGold(ch.x, ch.y - 10, 12);
      spawnXp(ch.x, ch.y - 10, 8);
      ui.banner.value = BannerMsg('Treasure!', 'Hidden chests reward the curious');
      // Saved at once, so leaving and coming back can't fill the same chest again
      progress.save(state);
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
    texts.removeWhere((t) {
      if (t.t < t.duration) return false;
      t.dispose();
      return true;
    });
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
    final vs = verseStone;
    if (vs != null && !vs.read && chance(260)) particles.sparkle(vs.x + between(-5, 5), vs.y - between(4, 16), 0xff8ae0d8);
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
    final cg = cage;
    if (cg != null) cg.shake = math.max(0, cg.shake - dt / 250);
    if (_wallRise < 1) {
      _wallRise = math.min(1, _wallRise + dt / 550);
      final w = leftWall;
      if (w != null && rand.nextDouble() < dt / 40) particles.dust(w.x, level.height - 3 * tile, count: 2, spread: 10, color: 0xffa88a60);
    }
  }

  double _dist(double x1, double y1, double x2, double y2) => math.sqrt(math.pow(x2 - x1, 2) + math.pow(y2 - y1, 2));

  // ---------- Combat ----------

  int resolveMelee(Rect rect, int dmg, int dir, double knock) {
    var hits = 0;
    for (final e in enemies) {
      if (!e.dying && !e.untouchable && overlaps(rect, e.body.rect)) {
        e.hurt(dmg, dir.toDouble(), knock);
        hits++;
      }
    }
    final l = lion;
    if (l != null && bossStarted && l.state != LionState.dead && overlaps(rect, l.body.rect)) {
      l.hurt(dmg);
      hits++;
    }
    for (final b in [...breakables]) {
      if (overlaps(rect, b.bounds)) {
        _breakObject(b);
        hits++;
      }
    }
    final cg = cage;
    if (cg != null && !cg.freed && overlaps(rect, cg.bounds)) {
      hits++;
      cg
        ..hp -= 1
        ..shake = 1;
      particles.spark(cg.x + dir * -6, cg.y - 12, size: 10, color: 0xffd0d0e0);
      if (cg.hp <= 0) _freeCaptive(cg);
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
    // One vase in eight hides a bomb, if the bag has room
    if (b.kind == 'vase' && state.bombs < maxBombs && rand.nextDouble() < 0.125) {
      state.bombs += 1;
      floatText(b.x, b.y - 18, '+1 bomb', const Color(0xffffd27a), size: 8);
    }
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
    _wallRise = 0;
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
      // The trial's entrance: the camera looks over the empty arena, then the first wave rises
      wave = 0;
      _entrance(Offset((arenaLeft! + arenaRight!) / 2, waveSpawn!.dy), BossDef(def.boss.name, '$waves waves  ·  the way back is sealed'));
      timers.after(cineMs - 400, () {
        if (bossStarted && !bossDefeated && wave == 0 && _waveFoes.isEmpty) _spawnWave();
      });
      return;
    }
    final boss = lion ??= _makeBoss();
    ui.boss.value = def.boss;
    // Ra stops before the guardian can move, even while it speaks
    player.frozen = true;
    boss.timer = cineMs + 250;
    void entrance() {
      _entrance(Offset(boss.x, boss.y), def.boss);
      // It wakes while the camera looks on, and only moves once the camera is back with Ra
      boss.timer = cineMs + 250;
      timers.after(800, () {
        if (!bossStarted || bossDefeated) return;
        sfx.roar();
        camera.shake(500, 0.01);
        burst(boss.x, boss.y - 6, [0xffa88a60, 0xff5a4a38], 14, 120);
      });
    }

    // A realm's guardian speaks before the first fight; its entrance follows the last word
    final loc = location;
    if (loc != null && loc.kind == LocKind.boss && progress.firstTelling('boss:${loc.realm.id}')) {
      tell(StoryScroll(loc.realm.name, [StoryPage(def.boss.name, chapterOf(loc.realm).bossWords)], onDone: entrance));
      progress.save(state);
    } else {
      entrance();
    }
  }

  // ---------- Trial of waves ----------

  // Three waves in the first realms, four from the Sky Spine on, five in the Lightless Land
  int get waves => trialWaves(location?.realm.index ?? 0);

  // Each wave brings more of the realm's creatures, rising out of puffs of dust; later realms send
  // ghouls, and from the Sky Spine on the last wave brings a man-eater
  void _spawnWave() {
    final tier = location?.realm.index ?? 0;
    final kinds = ['D', 'K', if (tier >= 1) 'V', if (tier >= 2) 'U', if (tier >= 4) 'H'];
    final last = wave == waves - 1;
    final types = [
      for (var i = 0; i < 2 + wave + tier ~/ 2; i++) kinds[rand.nextInt(kinds.length)],
      // The last wave brings a champion: a demon at first, a man-eater from the Sky Spine on,
      // two of them from the Marble West on
      if (last) tier >= 3 ? 'M' : 'D',
      if (last && tier >= 5) 'M',
      // From the Serpent Sands on, a shade rises in the middle of every later wave
      if (wave > 0 && tier >= 2) 'H',
    ];
    final left = arenaLeft! + tile * 3, right = arenaRight! - tile * 3;
    for (final t in types) {
      final x = left + rand.nextDouble() * (right - left);
      final foes = _foes(t, x, waveSpawn!.dy);
      for (final e in foes) {
        if (e is Ghoul) e.wake();
        if (e is Shade) e.emerge();
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
    // Nothing to count before the first wave has risen
    if (waveSpawn == null || !bossStarted || bossDefeated || _waveComing || _waveFoes.isEmpty) return;
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
    final tier = location?.realm.index ?? 0;
    ui.banner.value = BannerMsg('Wave ${wave + 2} of $waves', 'More are coming');
    timers.after(tier >= 3 ? 900 : 1200, () {
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
    _slow = 1100;
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

  // Ra stops and the camera turns to [at] for the guardian's entrance
  void _entrance(Offset at, BossDef card) {
    ui.bossIntro.value = card;
    timers.after(cineMs, () => ui.bossIntro.value = null);
    _cineT = cineMs;
    _cineAt = at;
    touch.clear();
    player
      ..frozen = true
      ..facing = at.dx >= player.x ? 1 : -1;
  }

  Lion _makeBoss() {
    final at = lionSpawn!;
    return switch (def.boss.kind) {
      BossKind.elephant => Elephant(this, at.dx, at.dy, maxHp: def.boss.hp),
      BossKind.lion => Lion(this, at.dx, at.dy, maxHp: def.boss.hp),
    };
  }

  void _resetBoss() {
    if (!bossStarted || bossDefeated) return;
    // A fresh guardian lies down in the arena again
    lion = _makeBoss();
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

  // Called by the title screen: picks the saga up on the realm map where Ra last stood
  void begin() {
    if (started) return;
    started = true;
    if (progress.hasSave) {
      openRealm(realms[progress.realm]);
    } else {
      ui.screen.value = AppScreen.world;
    }
    music.play(Track.explore);
  }

  // Called by the title screen: erases the save and starts from the first realm, with the prologue
  Future<void> beginNew() async {
    if (started) return;
    started = true;
    music.play(Track.explore);
    await newGame();
  }

  // ---------- The saga ----------

  final _townVisits = <String, int>{};

  // Someone by the fire has a word for Ra: in towns a different person each visit,
  // and at each hearth the traveller resting there
  void _talk(Location loc) {
    final c = chapterOf(loc.realm);
    final hearths = [for (final l in loc.realm.locations) if (l.kind == LocKind.hearth) l];
    final StoryPage page;
    if (loc.kind == LocKind.town) {
      final n = _townVisits[loc.id] = (_townVisits[loc.id] ?? -1) + 1;
      page = c.townTalk[n % c.townTalk.length];
    } else {
      page = c.hearthTalk[hearths.indexOf(loc) % c.hearthTalk.length];
    }
    tell(StoryScroll(loc.name, [page]));
  }

  final _stories = <StoryScroll>[];

  // Opens a scroll, or queues it behind the one being read
  void tell(StoryScroll s) {
    touch.clear();
    if (ui.story.value == null) {
      ui.story.value = s;
    } else {
      _stories.add(s);
    }
  }

  // Called by the scroll when its last page is turned
  void closeStory() {
    final done = ui.story.value;
    ui.story.value = _stories.isEmpty ? null : _stories.removeAt(0);
    done?.onDone?.call();
  }

  // The first time Ra reaches a realm, its chapter of the saga opens
  // Draws the black curtain, changes the screen behind it, then opens the curtain again
  static const curtainMs = 260;
  void _through(void Function() change) {
    if (ui.curtain.value) return;
    ui.curtain.value = true;
    Timer(const Duration(milliseconds: curtainMs + 20), () {
      change();
      Timer(const Duration(milliseconds: 80), () => ui.curtain.value = false);
    });
  }

  void openRealm(Realm r) => _through(() => _openRealm(r));

  void _openRealm(Realm r) {
    progress.realm = r.index;
    ui.realm.value = r.index;
    ui.screen.value = AppScreen.realm;
    if (progress.firstTelling('intro:${r.id}')) {
      final c = chapterOf(r);
      tell(StoryScroll(c.title, c.intro));
      progress.save(state);
    }
  }

  void openWorld() => _through(() => ui.screen.value = AppScreen.world);

  // Towns and hearths: rest there, which clears them and opens the road beyond
  List<String> visit(Location loc) {
    state
      ..hp = state.maxHp
      ..aura = state.auraMax.toDouble();
    progress.moveTo(loc);
    final first = progress.clear(loc);
    progress.save(state);
    sfx.altar();
    _talk(loc);
    return first ? ['You rest by the fire. The road ahead opens.'] : ['You rest by the fire. Health restored.'];
  }

  void enterLocation(Location loc) => _through(() => _enterLocation(loc));

  void _enterLocation(Location loc) {
    location = loc;
    progress
      ..moveTo(loc)
      ..save(state);
    def = levelFor(loc);
    // Walking into a town is visiting it: the roads beyond open, and its keeper has something new to say
    if (loc.kind == LocKind.town) {
      if (progress.clear(loc)) progress.save(state);
      _townVisits[loc.id] = (_townVisits[loc.id] ?? -1) + 1;
    }
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
    timers.after(400, () => ui.banner.value = BannerMsg(def.title, goalOf(loc)));
  }

  // What Ra has to do in a place, shown under its name on the way in
  String goalOf(Location loc) {
    final r = loc.realm;
    final extra = [
      if (verseIndex(loc) != null && !progress.hasVerse(loc)) 'A verse hides here',
      if (captiveIndex(loc) != null && !progress.isFreed(loc)) 'A captive waits here',
    ];
    final goal = switch (loc.kind) {
      LocKind.town => 'Talk to the people, trade, and rest at the inn',
      LocKind.boss => 'At the end of the road: ${r.bossName}',
      LocKind.arena => 'At the end of the road: a trial of $waves waves',
      _ when lionSpawn != null => 'At the end of the road: ${def.boss.name}',
      _ when def.sealed => 'Find the Sun Key to open the gate',
      _ => 'Reach the gate',
    };
    return [goal, ...extra].join('  ·  ');
  }

  // Back to the realm map, from the victory screen or the in-level map button
  void leaveLevel() => _through(_leaveLevel);

  void _leaveLevel() {
    touch.clear();
    timers.clear();
    ui
      ..sign.value = null
      ..banner.value = null
      ..boss.value = null
      ..victory.value = false
      ..levelUps.value = 0;
    ui.screen.value = AppScreen.realm;
    // Back from a cleared place, the saga goes on: a chapter closes when its guardian falls,
    // Saena speaks at shrines and about every Dawn Sigil
    final loc = location;
    if (loc != null && progress.isCleared(loc)) {
      final c = chapterOf(loc.realm);
      switch (loc.kind) {
        case LocKind.boss when progress.firstTelling('after:${loc.realm.id}'):
          tell(StoryScroll(c.title, c.after));
        case LocKind.shrine when progress.firstTelling('shrine:${loc.id}'):
          tell(StoryScroll(loc.name, [c.shrines[shrineStops.indexOf(loc.index)]]));
        case LocKind.secret when progress.firstTelling('sigil:${loc.realm.id}'):
          tell(StoryScroll(loc.realm.hidden ? 'The Water of Life' : 'Dawn Sigil ${sigilCount(progress)} of 6', [c.sigil]));
        default:
          break;
      }
    }
    progress.save(state);
  }

  // Called by the level-up panel after each choice
  void chooseLevelUp(void Function(GameState s) apply) {
    apply(state);
    sfx.pickup();
    state.flush();
    ui.levelUps.value = math.max(0, ui.levelUps.value - 1);
  }

  // Erases the save and starts the saga again, from the prologue
  Future<void> newGame() async {
    await progress.wipe(state);
    mapSeen.clear();
    ui.realm.value = 0;
    ui.screen.value = AppScreen.world;
    tell(StoryScroll('The Road of Seven Trials', prologue));
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
    _paintGuide(c);
    if (camera.flashAlpha > 0) c.drawRect(screen, Paint()..color = Color(camera.flashColor).withValues(alpha: camera.flashAlpha));
    if (camera.fade > 0) c.drawRect(screen, Paint()..color = Color.fromRGBO(10, 6, 20, camera.fade));
  }

  // In a sealed level, a golden arrow at the edge of the screen points the way to the Sun Key
  // while it is out of sight, and once the key is taken, the way to the gate
  void _paintGuide(Canvas c) {
    if (!def.sealed || victory || player.dead) return;
    final g = gate;
    final target = !keyFound ? sunKey : g == null ? null : Offset(g.x, g.y - 20);
    if (target == null) return;
    final z = uiScale * zoom;
    final p = Offset((target.dx - camera.scrollX) * z, (target.dy - camera.scrollY) * z);
    final w = size.x, h = size.y, m = 30 * uiScale;
    if (p.dx > 0 && p.dx < w && p.dy > 0 && p.dy < h) return; // in sight: no arrow needed
    final centre = Offset(w / 2, h / 2);
    final d = p - centre;
    final kx = d.dx == 0 ? double.infinity : (w / 2 - m) / d.dx.abs();
    final ky = d.dy == 0 ? double.infinity : (h / 2 - m) / d.dy.abs();
    final at = centre + d * math.min(kx, ky);
    final pulse = 1 + 0.12 * math.sin(_realT * 5);
    final s = 9 * uiScale * pulse;
    final gold = Color(keyFound ? 0xfffff0b0 : 0xfff7d774);
    c
      ..save()
      ..translate(at.dx, at.dy);
    c.drawCircle(Offset.zero, s * 1.9, Paint()..color = gold.withValues(alpha: 0.18));
    // The key: a small sun with rays; the gate: a little arch
    if (!keyFound) {
      final ray = Paint()
        ..color = gold
        ..strokeWidth = 1.5 * uiScale;
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4 + _realT;
        c.drawLine(Offset(math.cos(a), math.sin(a)) * s * 0.75, Offset(math.cos(a), math.sin(a)) * s * 1.15, ray);
      }
      c.drawCircle(Offset.zero, s * 0.55, Paint()..color = gold);
    } else {
      final arch = Path()
        ..moveTo(-s * 0.5, s * 0.6)
        ..lineTo(-s * 0.5, -s * 0.1)
        ..arcToPoint(Offset(s * 0.5, -s * 0.1), radius: Radius.circular(s * 0.5))
        ..lineTo(s * 0.5, s * 0.6)
        ..close();
      c.drawPath(arch, Paint()..color = gold);
    }
    // The arrowhead, just beyond the icon, towards the target
    c.rotate(math.atan2(d.dy, d.dx));
    final head = Path()
      ..moveTo(s * 2.4, 0)
      ..lineTo(s * 1.4, -s * 0.7)
      ..lineTo(s * 1.4, s * 0.7)
      ..close();
    c
      ..drawPath(
          head,
          Paint()
            ..color = const Color(0xff1a1020)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2 * uiScale)
      ..drawPath(head, Paint()..color = gold)
      ..restore();
  }

  // Parallax layers: each one scrolls at its own fraction of the camera's speed
  void _renderBackground(Canvas c, double z) {
    final viewH = size.y / z;
    // However tall the level, the backdrop scrolls only its own height, top to bottom.
    // In a level of rooms the scenery belongs to the surface row, so it shows its horizon there.
    final travel = math.max(1.0, (def.sealed ? tile * roomH : level.height) - viewH);
    final double y = (camera.scrollY / travel).clamp(0.0, 1.0) * math.max(0.0, 270 - viewH);
    final rect = Offset.zero & Size(size.x, size.y);
    // Below the surface rooms the underground fades in over the realm's scenery
    final depth = _backdropCave
        ? 1.0
        : def.sealed
            ? ((camera.scrollY + viewH / 2 - tile * 11) / (tile * 11)).clamp(0.0, 1.0)
            : 0.0;
    final dark = location?.realm.theme == RealmTheme.dark;
    if (depth < 1) {
      _drawBackdrop(c, z, y, rect, _backdrop!, 1, sky: () {
        // Sun rays and the Eye of Ra over the painted sun; the Lightless Land has no sun
        if (dark) return;
        final sun = Offset(360 * z, (80 - y) * z);
        paintSunRays(c, sun, z, _realT, ambience.rays, ambience.rayColor);
        _paintWatcher(c, sun, z);
      });
    }
    if (depth > 0) _drawBackdrop(c, z, y, rect, _underground!, depth);
  }

  void _drawBackdrop(Canvas c, double z, double y, Rect rect, Backdrop b, double alpha, {void Function()? sky}) {
    for (final (i, image) in b.layers.indexed) {
      final factor = backdropParallax[i];
      // The cloud layer drifts on its own as well
      final tx = camera.scrollX * factor + (i == 1 ? _drift : 0.0);
      final m = Matrix4.identity()
        ..scale(z, z)
        ..translate(-tx, -y)
        ..scale(1 / backdropScale, 1 / backdropScale);
      c.drawRect(
        rect,
        Paint()
          ..color = Color.fromRGBO(0, 0, 0, alpha)
          ..shader = ImageShader(image, TileMode.repeated, TileMode.clamp, m.storage, filterQuality: FilterQuality.low),
      );
      if (i == 0) sky?.call();
    }
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

  // Wall, roof and trim colours of the houses in each realm
  static const _houseStyle = {
    RealmTheme.vale: (0xffe0cfa6, 0xff9a4a32, 0xff6a4a2a),
    RealmTheme.city: (0xffeee3c8, 0xff2a4a9a, 0xffd4a845),
    RealmTheme.desert: (0xffd8a868, 0xffb07a40, 0xff7a4a22),
    RealmTheme.mountain: (0xff8a5a3a, 0xfff0f4f8, 0xff4a2e1c),
    RealmTheme.steppe: (0xffd6c6a8, 0xff7a4a8e, 0xff5a3a2a),
    RealmTheme.coast: (0xfff4f0e6, 0xff2bb3a8, 0xff6a7a8a),
    RealmTheme.dark: (0xff5a5868, 0xff2a2838, 0xff8a7ab8),
  };

  // A small house: walls, a stepped roof, a door and a warm window. [wide] makes it bigger (the inn)
  void _drawHouse(Canvas c, double cx, double ground, int variant, {double wide = 1}) {
    final style = _houseStyle[location?.realm.theme ?? RealmTheme.vale]!;
    final x = cx.roundToDouble(), y = ground;
    final w = (40 + (variant % 3) * 6) * wide, h = (26 + (variant % 2) * 6) * wide;
    void box(double l, double t, double bw, double bh, int color) => c.drawRect(Rect.fromLTWH(x + l, y + t, bw, bh), Paint()..color = Color(color));
    box(-w / 2 - 1, -h - 1, w + 2, h + 1, 0xff2a1e16); // outline
    box(-w / 2, -h, w, h, style.$1);
    box(-w / 2, -h, w, 2, style.$3); // beam under the roof
    // The roof, built up in steps
    final steps = (10 * wide).round();
    for (var i = 0; i < steps; i++) {
      final rw = w + 6 - i * (w + 6) / steps;
      box(-rw / 2, -h - 2 - i * 2, rw, 2, i == steps - 1 ? 0xff2a1e16 : style.$2);
    }
    // Door and window; windows glow, brighter at night in the Lightless Land
    final side = variant.isEven ? -1 : 1;
    box(side * w / 4 - 5, -16, 10, 16, style.$3);
    box(side * w / 4 - 4, -15, 8, 15, 0xff3a2418);
    final glow = 0.75 + 0.25 * math.sin(_realT * 1.3 + variant);
    box(-side * w / 4 - 5, -h + 7, 10, 8, 0xff2a1e16);
    c.drawRect(Rect.fromLTWH(x - side * w / 4 - 4, y - h + 8, 8, 6), Paint()..color = const Color(0xffffd27a).withValues(alpha: glow));
  }

  // Green leaves on a stalk; while ripe, a round dark fruit with a tiny spark of a fuse on top
  void _drawFlower(Canvas c, BombFlower f) {
    final x = f.x.roundToDouble(), y = f.y;
    void box(double l, double t, double w, double h, int color) => c.drawRect(Rect.fromLTWH(x + l, y + t, w, h), Paint()..color = Color(color));
    box(-1, -9, 2, 9, 0xff3f7a34); // stalk
    box(-6, -4, 5, 2, 0xff5aa04a); // leaves
    box(1, -6, 5, 2, 0xff5aa04a);
    box(-5, -3, 3, 1, 0xff3f7a34);
    if (f.regrow > 0) {
      // A green bud swelling again
      final k = 1 - f.regrow / 7000;
      c.drawCircle(Offset(x, y - 11), 1 + 2 * k, Paint()..color = const Color(0xff4a6a3a));
      return;
    }
    final sway = math.sin(_realT * 2 + x) * 0.6;
    c.drawCircle(Offset(x + sway, y - 12), 4.5, Paint()..color = const Color(0xff15151c));
    c.drawCircle(Offset(x + sway, y - 12), 3.6, Paint()..color = const Color(0xff3a3448));
    c.drawRect(Rect.fromLTWH(x + sway - 1.5, y - 14, 1.5, 1.5), Paint()..color = const Color(0x99f2e6c9));
    c.drawRect(Rect.fromLTWH(x + sway, y - 18, 1, 2), Paint()..color = const Color(0xff8a5a2a));
    if ((_realT * 4).floor().isEven) c.drawRect(Rect.fromLTWH(x + sway - 0.5, y - 19.5, 2, 2), Paint()..color = const Color(0xffffc040));
  }

  // A black bomb with a highlight; it flashes red faster as the fuse runs out
  void _drawBomb(Canvas c, Bomb b) {
    final x = b.body.x.roundToDouble(), y = b.body.y;
    final blink = ((1400 - b.fuse) / (b.fuse < 500 ? 70 : 160)).floor().isOdd;
    c.drawCircle(Offset(x, y - 4.5), 5, Paint()..color = const Color(0xff15151c));
    c.drawCircle(Offset(x, y - 4.5), 4, Paint()..color = Color(blink ? 0xffc0302a : 0xff2a2a34));
    c.drawRect(Rect.fromLTWH(x - 1.5, y - 7.5, 1.5, 1.5), Paint()..color = const Color(0xaaf2e6c9));
    c.drawRect(Rect.fromLTWH(x + 1, y - 11, 1.5, 3), Paint()..color = const Color(0xff8a5a2a));
  }

  // The inn: a bigger house with its door in the middle and a hanging sign with a crescent moon
  void _drawInn(Canvas c, Offset d) {
    _drawHouse(c, d.dx, d.dy, 4, wide: 1.45);
    final x = d.dx.roundToDouble(), y = d.dy;
    void box(double l, double t, double w, double h, int color) => c.drawRect(Rect.fromLTWH(x + l, y + t, w, h), Paint()..color = Color(color));
    box(-7, -20, 14, 20, 0xff2a1e16); // wide door in the middle
    box(-6, -19, 12, 19, 0xff5a3420);
    box(-1, -19, 2, 19, 0xff3a2418);
    // A sign on an arm over the door
    box(10, -34, 14, 2, 0xff4a2e1c);
    box(12, -32, 10, 10, 0xff2a1e16);
    box(13, -31, 8, 8, 0xff1b2a6b);
    c.drawCircle(Offset(x + 17, y - 27), 3, Paint()..color = const Color(0xfff7d774));
    c.drawCircle(Offset(x + 18.5, y - 28), 2.6, Paint()..color = const Color(0xff1b2a6b));
  }

  // The stall: posts, a striped awning, the merchant behind the counter, and jars on top
  void _drawStall(Canvas c, Stall st) {
    final x = st.x.roundToDouble(), y = st.y;
    void box(double l, double t, double w, double h, int color) => c.drawRect(Rect.fromLTWH(x + l, y + t, w, h), Paint()..color = Color(color));
    box(-15, -34, 2, 34, 0xff4a2e1c); // posts
    box(13, -34, 2, 34, 0xff4a2e1c);
    // The merchant, standing behind the counter
    box(-4, -24, 8, 12, 0xff2a1e16);
    box(-3, -23, 6, 11, st.travelling ? 0xff6a5a3a : 0xff8a2a3a);
    box(-3, -29, 6, 6, 0xffd9a37a);
    box(-4, -31, 8, 3, st.travelling ? 0xff5a4a2a : 0xffd4a845);
    // Awning in two colours, with a scalloped edge
    for (var i = 0; i < 8; i++) {
      box(-17 + i * 4.25, -40, 4.25, 6, i.isEven ? 0xffb83a2e : 0xfff2e6c9);
      box(-17 + i * 4.25 + 1, -34, 2.25, 2, i.isEven ? 0xffb83a2e : 0xfff2e6c9);
    }
    // Counter with jars and a flask
    box(-16, -13, 32, 13, 0xff2a1e16);
    box(-15, -12, 30, 12, 0xff8a5a3a);
    box(-15, -12, 30, 2, 0xffa47450);
    box(-12, -18, 4, 5, 0xffe0485a);
    box(-6, -17, 4, 4, 0xff8ae0d8);
    box(7, -19, 5, 6, 0xffd4a845);
  }

  static const _robes = [0xff7a4a6a, 0xff3a6a8a, 0xff8a6a2a, 0xff4a7a4a, 0xffa04a3a];

  // A small person in a robe, with headwear in the fashion of the realm, legs moving as they walk
  void _drawTownsperson(Canvas c, Townsperson t) {
    final x = t.x.roundToDouble(), y = t.y;
    void box(double l, double tp, double w, double h, int color) => c.drawRect(Rect.fromLTWH(x + l, y + tp, w, h), Paint()..color = Color(color));
    final walking = t.pause <= 0 && !t.talking;
    final step = walking && (t.walkT / 180).floor().isEven;
    final robe = _robes[(t.index + (location?.realm.index ?? 0)) % _robes.length];
    box(-3, -4, 2, 4, 0xff3a2418); // legs
    box(1, step ? -3 : -4, 2, step ? 3 : 4, 0xff3a2418);
    box(-4, -15, 8, 11, 0xff2a1e16); // robe outline
    box(-3, -14, 6, 10, robe);
    box(-3, -9, 6, 1, 0xff2a1e16); // sash
    box(-3, -20, 6, 6, 0xffd9a37a); // head
    box(t.facing > 0 ? 1 : -2, -18, 1, 1, 0xff2a1e16); // eye
    final bob = t.talking ? math.sin(_realT * 6).abs() : 0.0;
    switch (location?.realm.theme ?? RealmTheme.vale) {
      case RealmTheme.desert:
        box(-4, -23 - bob, 8, 4, 0xfff0e6d0); // turban
      case RealmTheme.mountain:
      case RealmTheme.dark:
        box(-4, -22 - bob, 8, 3, robe); // hood
        box(-4, -20, 1, 5, robe);
        box(3, -20, 1, 5, robe);
      case RealmTheme.steppe:
        box(-4, -22 - bob, 8, 2, 0xff5a3a2a); // fur cap
        box(-3, -24 - bob, 6, 2, 0xff5a3a2a);
      case RealmTheme.city:
        box(-3, -23 - bob, 6, 3, 0xff1b2a6b); // tall cap
      default:
        box(-3, -21 - bob, 6, 2, 0xff3a2418); // hair
    }
  }

  // Iron bars on a heavy base with the captive inside; once broken, only the base and two bent bars stay
  void _drawCage(Canvas c, Cage cg) {
    final x = (cg.x + math.sin(_realT * 50) * cg.shake * 1.5).roundToDouble(), y = cg.y;
    void box(double l, double t, double w, double h, int color) => c.drawRect(Rect.fromLTWH(x + l, y + t, w, h), Paint()..color = Color(color));
    box(-10, -3, 20, 3, 0xff2a2a34); // base
    if (cg.freed) {
      box(-9, -9, 1.5, 6, 0xff5a5a6a);
      box(7, -7, 1.5, 4, 0xff5a5a6a);
      return;
    }
    // The captive: a robed figure, sitting with its head bowed and now and then looking up
    final look = math.sin(_realT * 0.9 + cg.x) > 0.6 ? -1.0 : 0.0;
    box(-4, -13, 8, 10, 0xff7a4a6a); // robe
    box(-3, -18 + look, 6, 5, 0xffd9a37a); // head
    box(-3, -19 + look, 6, 2, 0xff3a2418); // hair
    // Bars and the domed top
    box(-9, -24, 18, 2, 0xff2a2a34);
    box(-7, -26, 14, 2, 0xff2a2a34);
    for (var bx = -9.0; bx <= 8; bx += 4.25) {
      box(bx, -22, 1.5, 19, 0xff5a5a6a);
    }
    box(-1, -29, 2, 3, 0xff2a2a34); // ring on top
  }

  // A grey standing stone with a rounded top and three carved lines, glowing turquoise until it is read
  void _drawVerseStone(Canvas c, VerseStone v) {
    final x = v.x.roundToDouble(), y = v.y;
    void box(double l, double t, double w, double h, int color) => c.drawRect(Rect.fromLTWH(x + l, y + t, w, h), Paint()..color = Color(color));
    box(-8, -2, 16, 2, 0xff3e3830); // plinth
    box(-6, -16, 12, 14, 0xff3e3830); // outline
    box(-4, -18, 8, 2, 0xff3e3830);
    box(-5, -15, 10, 13, 0xff8d8474); // face
    box(-3, -17, 6, 2, 0xff8d8474);
    box(-5, -15, 2, 13, 0xffa49b8a); // lit edge
    final glow = v.read ? 0.45 : 0.65 + 0.35 * math.sin(_realT * 2.2);
    final carve = v.read ? 0xff2bb3a8 : 0xff8ae0d8;
    for (final (dy, w) in const [(-13.0, 6.0), (-10.0, 4.0), (-7.0, 6.0)]) {
      c.drawRect(Rect.fromLTWH(x - w / 2, y + dy, w, 1.5), Paint()..color = Color(carve).withValues(alpha: glow));
    }
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
      for (final h in houses) Light(h.x, h.y - 18, 34, 0xffffd27a, 0.45),
      if (inn != null) Light(inn!.dx, inn!.dy - 16, 46, 0xffffd27a, 0.55),
      if (cage != null && !cage!.freed) Light(cage!.x, cage!.y - 12, 20, 0xffffd090, 0.45),
      if (verseStone != null)
        Light(verseStone!.x, verseStone!.y - 9, verseStone!.read ? 12 : 24 + math.sin(t * 2.2) * 3, 0xff8ae0d8, verseStone!.read ? 0.3 : 0.6),
      for (final ch in chests)
        if (!ch.opened) Light(ch.x, ch.y - 5, 14, 0xffffd060, 0.35 + 0.15 * math.sin(t * 2.5)),
      for (final s in slashes) Light(s.x, s.y, 22, 0xffffe8b0, 1 - s.t / Slash.duration),
      if (gate != null && gate!.glow > 0) Light(gate!.x, gate!.y - 22, 64 * gate!.glow, 0xfffff0b0, gate!.glow),
      if (ambience.dark) Light(player.x, player.y - 8, 72, 0xfff0e8d0, 0.95),
      if (ambience.dark && lion != null) Light(lion!.x, lion!.y - 14, 30, 0xffff8040, 0.5),
      for (final e in enemies)
        if (e is Shade && e.eyesOpen) Light(e.eyeX, e.eyeY, 10, 0xffff5a3a, 0.3 + 0.7 * e.alpha),
    ];
  }

  void _renderWorld(Canvas c, Rect view) {
    final a = art;
    // depth 0: arena walls
    for (final w in physics.walls) {
      // The wall behind Ra rises out of the ground (the tiles, drawn later, hide what is still below)
      final sunk = w == leftWall ? math.pow(1 - _wallRise, 3) * 160 : 0.0;
      drawFrame(c, a.wall, 0, w.x, w.rect.bottom + sunk);
    }
    // depth 3: signs and the gate
    for (final h in houses) {
      _drawHouse(c, h.x, h.y, h.variant);
    }
    for (final s in signs) {
      if (s.post) drawFrame(c, a.sign, 0, s.x, s.y);
    }
    final d = inn;
    if (d != null) _drawInn(c, d);
    for (final st in stalls) {
      _drawStall(c, st);
    }
    for (final f in flowers) {
      _drawFlower(c, f);
    }
    for (final b in bombs) {
      _drawBomb(c, b);
    }
    for (final t in townsfolk) {
      _drawTownsperson(c, t);
    }
    final vs = verseStone;
    if (vs != null) _drawVerseStone(c, vs);
    final cg = cage;
    if (cg != null) _drawCage(c, cg);
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
    if (lion != null && lion!.state != LionState.dead) _shadow(c, lion!.x, lion!.y, lion!.body.w + 4);
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
    lion?.render(c, lion is Elephant ? a.elephant : a.lion);
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
