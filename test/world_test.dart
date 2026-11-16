import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meetra/art/sprites.dart';
import 'package:meetra/game/meetra_game.dart';
import 'package:meetra/config.dart';
import 'package:meetra/levels/build.dart';
import 'package:meetra/levels/generator.dart';
import 'package:meetra/levels/level1.dart';
import 'package:meetra/world/progress.dart';
import 'package:meetra/world/saga.dart';
import 'package:meetra/world/world.dart';

void main() {
  test('seven realms with twenty locations each, the seventh hidden', () {
    expect(realms.length, 7);
    for (final r in realms) {
      expect(r.locations.length, 20, reason: r.id);
      expect(r.locations.map((l) => l.id).toSet().length, 20);
      expect(r.boss.kind, LocKind.boss);
      expect(r.secret.kind, LocKind.secret);
    }
    expect(realms.where((r) => r.hidden).map((r) => r.index), [6]);
  });

  test('every location can be reached from the town', () {
    for (final r in realms) {
      final seen = {r.locations.first};
      final queue = [r.locations.first];
      while (queue.isNotEmpty) {
        for (final n in queue.removeLast().links) {
          if (seen.add(n)) queue.add(n);
        }
      }
      expect(seen.length, 20, reason: r.id);
    }
  });

  test('every playable location builds a level with a start and an exit', () {
    for (final r in realms) {
      for (final l in r.locations.where((l) => l.kind.playable)) {
        final level = buildLevel(levelFor(l));
        final types = level.objects.map((o) => o.type).toList();
        expect(types.where((t) => t == 'P').length, 1, reason: l.id);
        expect(types, contains('G'), reason: l.id);
        expect(types.where((t) => t == 'S').length, levelFor(l).signs.length, reason: l.id);
        // The lion only guards realm bosses (and the first trial); arenas are trials of waves;
        // everything else is sealed until the one Sun Key is found
        final lionFight = l.kind == LocKind.boss || (r.index == 0 && l.index == 1);
        expect(types.contains('L'), lionFight, reason: l.id);
        expect(types.contains('W'), l.kind == LocKind.arena, reason: l.id);
        final explore = !lionFight && l.kind != LocKind.arena;
        expect(types.where((t) => t == 'O').length, explore ? 1 : 0, reason: l.id);
        expect(levelFor(l).sealed, explore, reason: l.id);
      }
    }
  });

  test('foes by realm: scorpions everywhere, ghouls from the Sands, man-eaters from the Sky Spine', () {
    int count(Realm r, String type) => [
          for (final l in r.locations.where((l) => l.kind.playable))
            ...buildLevel(levelFor(l)).objects.where((o) => o.type == type),
        ].length;
    expect(count(realms[0], 'K'), greaterThan(0));
    expect(count(realms[0], 'U') + count(realms[1], 'U'), 0);
    expect(count(realms[2], 'U'), greaterThan(0));
    expect(count(realms[2], 'M'), 0);
    expect(count(realms[3], 'M'), greaterThan(0));
  });

  test('in every sealed level Ra can reach the Sun Key, and from there the gate', () {
    for (final r in realms) {
      for (final l in r.locations.where((l) => levelFor(l).sealed)) {
        final level = buildLevel(levelFor(l));
        Offset find(String t) {
          final o = level.objects.firstWhere((o) => o.type == t);
          return Offset(o.tx.toDouble(), o.ty.toDouble());
        }

        final start = find('P'), key = find('O'), gate = find('G');
        final fromStart = _standable(level, start);
        expect(fromStart.any((p) => p.dx == key.dx && (p.dy - key.dy).abs() <= 1), isTrue, reason: '${l.id}: key');
        final fromKey = _standable(level, Offset(key.dx, key.dy + 1));
        expect(fromKey.contains(gate), isTrue, reason: '${l.id}: gate');
      }
    }
  });

  test('seven trails in every realm hide one Verse Stone each, and Ra can reach it', () {
    for (final r in realms) {
      for (final l in r.locations.where((l) => l.kind.playable)) {
        final level = buildLevel(levelFor(l));
        final stones = level.objects.where((o) => o.type == 'T').toList();
        expect(stones.length, verseIndex(l) == null ? 0 : 1, reason: l.id);
        if (stones.isEmpty) continue;
        final start = level.objects.firstWhere((o) => o.type == 'P');
        final reach = _standable(level, Offset(start.tx.toDouble(), start.ty.toDouble()));
        expect(reach.contains(Offset(stones[0].tx.toDouble(), stones[0].ty.toDouble())), isTrue, reason: '${l.id}: stone');
      }
    }
  });

  test('on every road to an arena or a realm boss, even the hard ones, Ra can reach the gate', () {
    for (final r in realms) {
      for (final l in r.locations.where((l) => l.kind == LocKind.arena || l.kind == LocKind.boss)) {
        final level = buildLevel(levelFor(l));
        Offset find(String t) {
          final o = level.objects.firstWhere((o) => o.type == t);
          return Offset(o.tx.toDouble(), o.ty.toDouble());
        }

        expect(_standable(level, find('P')).contains(find('G')), isTrue, reason: l.id);
      }
    }
  });

  test('the White Elephant guards Hearthvale; the other realms keep the lion for now', () {
    expect(levelFor(realms[0].boss).boss.kind, BossKind.elephant);
    expect(levelFor(realms[0].boss).boss.name, 'The White Elephant');
    expect(levelFor(realms[1].boss).boss.kind, BossKind.lion);
    expect(level1.boss.kind, BossKind.lion);
  });

  test('the save keeps cleared places, opened chests and stats, and a new game erases them', () async {
    SharedPreferences.setMockInitialValues({});
    final p = Progress();
    final s = GameState();
    expect(p.hasSave, isFalse);
    final place = realms[0].locations[3];
    p
      ..clear(realms[0].locations[0])
      ..moveTo(place)
      ..openChest('${place.id}#0');
    expect(p.firstTelling('intro:hearthvale'), isTrue);
    expect(p.firstTelling('intro:hearthvale'), isFalse);
    s.gold = 120;
    await p.save(s);

    final p2 = Progress();
    final s2 = GameState();
    await p2.load(s2);
    expect(p2.hasSave, isTrue);
    expect(p2.isCleared(realms[0].locations[0]), isTrue);
    expect(p2.isChestOpen('${place.id}#0'), isTrue);
    expect(p2.isChestOpen('${place.id}#1'), isFalse);
    expect(p2.lastLocation, place.id);
    expect(s2.gold, 120);
    expect(p2.firstTelling('intro:hearthvale'), isFalse);
    expect(p2.firstTelling('intro:crownhold'), isTrue);

    await p2.wipe(s2);
    final p3 = Progress();
    await p3.load(GameState());
    expect(p3.hasSave, isFalse);
    expect(p3.isChestOpen('${place.id}#0'), isFalse);
  });

  test('every realm has a chapter: an opening, guardian words, an ending and a legend in seven verses', () {
    for (final r in realms) {
      final c = chapterOf(r);
      expect(c.intro, isNotEmpty, reason: r.id);
      expect(c.after, isNotEmpty, reason: r.id);
      expect(c.bossWords, isNotEmpty, reason: r.id);
      expect(c.townTalk, isNotEmpty, reason: r.id);
      expect(c.hearthTalk.length, r.locations.where((l) => l.kind == LocKind.hearth).length, reason: r.id);
      expect(c.verses.length, 7, reason: r.id);
      // One Verse Stone on each of seven trails
      expect([for (final l in r.locations) verseIndex(l)].nonNulls.toList(), [0, 1, 2, 3, 4, 5, 6], reason: r.id);
    }
  });

  test('levels are the same every time a place is generated', () {
    final l = realms[3].locations[8];
    expect(levelFor(l).chunks, levelFor(l).chunks);
  });

  test('unlock rules: neighbours, realms in order, hidden realm needs six sigils', () {
    final p = Progress();
    final s = GameState();
    final vale = realms[0];
    expect(isOpen(vale.locations[0], p, s), isTrue);
    expect(isOpen(vale.locations[1], p, s), isFalse);
    p.clear(vale.locations[0]);
    expect(isOpen(vale.locations[1], p, s), isTrue);

    // Secret places need the feather
    p.clear(vale.locations[12]);
    expect(isOpen(vale.secret, p, s), isFalse);
    s.hasFeather = true;
    expect(isOpen(vale.secret, p, s), isTrue);

    expect(realmUnlocked(realms[1], p), isFalse);
    p.clear(vale.boss);
    expect(realmUnlocked(realms[1], p), isTrue);

    expect(realmUnlocked(realms[6], p), isFalse);
    for (final r in realms.take(6)) {
      p.clear(r.secret);
    }
    expect(sigilCount(p), 6);
    expect(realmUnlocked(realms[6], p), isTrue);
  });

  testWidgets('clearing places hands out rewards and opens the next realm', (tester) async {
    final art = await tester.runAsync(Art.generate);
    final game = MeetRaGame(art!);
    final vale = realms[0];

    game.enterLocation(vale.locations[15]); // a shrine
    expect(game.ui.screen.value, AppScreen.playing);
    expect(game.def.title, vale.locations[15].name);
    final hp = game.state.maxHp;
    expect(game.completeLocation(vale.locations[15]), ['Shrine blessing: +1 heart']);
    expect(game.state.maxHp, hp + 2);
    // A second clear gives nothing more
    expect(game.completeLocation(vale.locations[15]), isEmpty);

    game.enterLocation(vale.boss);
    expect(game.lionSpawn, isNotNull);
    final lines = game.completeLocation(vale.boss);
    expect(lines, contains('New realm unlocked: Crownhold'));
    expect(realmUnlocked(realms[1], game.progress), isTrue);

    game.leaveLevel();
    expect(game.ui.screen.value, AppScreen.realm);
  });

  test("shades lurk in the dark: none on Hearthvale's trails, most in the Lightless Land", () {
    int shades(Realm r, {bool Function(Location l)? where}) => [
          for (final l in r.locations.where((l) => l.kind.playable && (where?.call(l) ?? true)))
            ...buildLevel(levelFor(l)).objects.where((o) => o.type == 'H'),
        ].length;
    expect(shades(realms[0], where: (l) => l.kind == LocKind.trail), 0);
    expect(shades(realms[2]), greaterThan(0));
    expect(shades(realms[6]), greaterThan(shades(realms[2])));
  });
}

// Every tile Ra can stand in, starting from [from], with a rough model of Ra's moves:
// walk, fall, drop through ledges, and jump up to five tiles high and five across.
Set<Offset> _standable(Level level, Offset from) {
  bool air(int x, int y) {
    final t = level.tileAt(x, y);
    return x >= 0 && x < level.cols && y < level.rows && (t == T.empty);
  }

  bool passUp(int x, int y) => air(x, y) || level.tileAt(x, y) == T.platform;
  bool floor(int x, int y) => level.tileAt(x, y) != T.empty && level.tileAt(x, y) != T.spikes;
  bool stand(int x, int y) => air(x, y) && floor(x, y + 1);

  // Where something falling down column x from row y comes to rest
  int? land(int x, int y) {
    for (var yy = y; yy < level.rows; yy++) {
      if (!air(x, yy)) return null;
      if (floor(x, yy + 1)) return yy;
    }
    return null;
  }

  final seen = <Offset>{};
  final queue = <(int, int)>[];
  final (sx, sy) = (from.dx.toInt(), from.dy.toInt());
  final first = land(sx, sy);
  if (first == null) return seen;
  queue.add((sx, first));
  seen.add(Offset(sx.toDouble(), first.toDouble()));
  void visit(int x, int y) {
    if (seen.add(Offset(x.toDouble(), y.toDouble()))) queue.add((x, y));
  }

  while (queue.isNotEmpty) {
    final (x, y) = queue.removeLast();
    // Drop through a ledge
    if (level.tileAt(x, y + 1) == T.platform) {
      final l = land(x, y + 2);
      if (l != null) visit(x, l);
    }
    // Rise straight up, then move across at that height and fall wherever that ends
    for (var up = 0; up <= 5; up++) {
      final yy = y - up;
      if (up > 0 && !passUp(x, yy)) break;
      if (!air(x, yy)) continue;
      for (final dir in const [-1, 1]) {
        for (var dx = 1; dx <= 5; dx++) {
          final xx = x + dir * dx;
          if (!air(xx, yy)) break;
          final l = land(xx, yy);
          if (l != null) visit(xx, l);
        }
      }
      if (stand(x, yy)) visit(x, yy);
    }
  }
  return seen;
}
