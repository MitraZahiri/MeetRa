import 'package:flutter_test/flutter_test.dart';
import 'package:meetra/config.dart';
import 'package:meetra/game/physics.dart';
import 'package:meetra/levels/build.dart';
import 'package:meetra/levels/level1.dart';

void main() {
  final level = buildLevel(level1);

  test('level 1 builds with every key object', () {
    expect(level.rows, 17);
    final types = level.objects.map((o) => o.type).toSet();
    expect(types, containsAll(['P', 'A', 'S', 'D', 'V', 'F', 'L', '[', ']', 'G', 'C']));
    expect(level.objects.where((o) => o.type == 'S').length, level1.signs.length);
  });

  test('a falling body lands on the ground', () {
    final p = level.objects.firstWhere((o) => o.type == 'P');
    final physics = Physics(level);
    final b = Body(p.x, p.y - 40, 8, 16);
    for (var i = 0; i < 120; i++) {
      physics.step(b, 1 / 60);
    }
    expect(b.blockedDown, isTrue);
    expect(b.y, p.y);
  });

  test('one-way platforms hold from above but not from below', () {
    final physics = Physics(level);
    // First platform of chunk 2 ("......====" in row 12)
    final ty = level.data.indexWhere((r) => r.contains(T.platform));
    final tx = level.data[ty].indexOf(T.platform);
    final x = tx * tile + 8;
    final fromAbove = Body(x, ty * tile - 20, 8, 16);
    for (var i = 0; i < 60; i++) {
      physics.step(fromAbove, 1 / 60);
    }
    expect(fromAbove.y, ty * tile);

    final fromBelow = Body(x, (ty + 2) * tile, 8, 16)..vy = -300;
    physics.step(fromBelow, 1 / 60);
    expect(fromBelow.blockedUp, isFalse);
  });

  test('xp curve matches the web version', () {
    expect([1, 2, 3, 4].map(xpForLevel), [20, 40, 70, 110]);
  });
}
