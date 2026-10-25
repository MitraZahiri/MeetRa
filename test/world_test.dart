import 'package:flutter_test/flutter_test.dart';
import 'package:meetra/art/sprites.dart';
import 'package:meetra/game/meetra_game.dart';
import 'package:meetra/config.dart';
import 'package:meetra/levels/build.dart';
import 'package:meetra/levels/generator.dart';
import 'package:meetra/world/progress.dart';
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
        final fight = l.kind == LocKind.boss || l.kind == LocKind.arena || (r.index == 0 && l.index == 1);
        expect(types.contains('L'), fight, reason: l.id);
      }
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
}
