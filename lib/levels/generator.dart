// Builds a level for every playable location from hand-made ASCII chunks.
// The location id seeds the random choices, so a place always has the same layout.
// See build.dart for the map legend. Lowercase markers are optional:
//   d  maybe an imp   b  maybe a bat   x  maybe a vase   +  maybe a bush   c  maybe a chest

import 'dart:math' as math;

import '../world/world.dart';
import 'build.dart';
import 'level1.dart';

const _g = '########################################';

List<String> _ground(String top) => [top, _g.substring(0, top.length), _g.substring(0, top.length), _g.substring(0, top.length)];

final _start = _ground('..A.P...S.......');
final _hearth = _ground('.....A........');
final _end = _ground('..........G.....');

final _flat = [
  '...........b.......',
  ..._ground('....+....d....x....'),
];

final _pit = [
  '..........b.........',
  '....................',
  '......===...........',
  '..d.............x...',
  '####........########',
  '####........########',
  '####........########',
];

final _steps = [
  '...................c....',
  '.................=====..',
  '............b...........',
  '.........####...........',
  '....=====####...........',
  ..._ground('..+......####....d...x..'),
];

final _thorns = [
  '...........b..............',
  '......===...===...===.....',
  '..........................',
  ..._ground('..d....^^^^^^^^^^^^^^^..d.'),
];

final _hill = [
  '..........x.........',
  '.......######.......',
  '......########...b..',
  ..._ground('..+..##########...d.'),
];

final _ledges = [
  '..........c...........',
  '........=====.........',
  '......................',
  '....====.......====...',
  '..............b.......',
  ..._ground('..d.................+.'),
];

final _cave = [
  'BBBBBBBBBBBBBBBBBB',
  'BBBBBBBBBBBBBBBBBB',
  '..................',
  '........b.........',
  '..................',
  ..._ground('..d....x.....d..c.'),
];

final _gaps = [
  '......................',
  '....b.............b...',
  '......................',
  '..x..............+....',
  '#####...####...#######',
  '#####...####...#######',
  '#####...####...#######',
];

final _treasure = [
  '.....c..........c.....',
  '....====......====....',
  '......................',
  ..._ground('..x..x...d....x..x..+.'),
];

final _arena = [
  '.....====..............====.....',
  '................................',
  ..._ground('[......................L.......]'),
];

// Stable string hash (FNV-1a), the same on phones and in the browser
int _seed(String s) {
  var h = 0x811c9dc5;
  for (final c in s.codeUnits) {
    h = ((h ^ c) * 0x01000193) & 0x7fffffff;
  }
  return h;
}

LevelDef levelFor(Location loc) {
  // The tutorial trial is hand-made
  if (loc.realm.index == 0 && loc.index == 1) return level1;

  final r = loc.realm;
  final rnd = math.Random(_seed(loc.id));
  final tier = r.index; // 0..6
  final depth = loc.index / bossIndex; // 0..1 along the realm road

  var pool = [_flat, _pit, _steps, _hill, _ledges, _gaps];
  if (tier > 0 || depth > 0.3) pool = [...pool, _thorns];
  var middle = 5 + tier ~/ 2;
  var enemyChance = (0.45 + tier * 0.07 + depth * 0.1).clamp(0.0, 0.9);
  var chestChance = 0.35;
  var vaseChance = 0.6;

  switch (loc.kind) {
    case LocKind.cave:
      pool = [_cave, _cave, _pit, _gaps];
      chestChance = 0.6;
    case LocKind.ruin:
      pool = [_treasure, _steps, _flat, _hill];
      chestChance = 0.9;
      vaseChance = 0.9;
    case LocKind.shrine:
      middle = 3;
      enemyChance *= 0.6;
    case LocKind.secret:
      pool = [_thorns, _pit, _gaps, _ledges, _cave];
      middle += 2;
      enemyChance = math.min(0.95, enemyChance + 0.15);
      chestChance = 0.8;
    case LocKind.arena:
    case LocKind.boss:
      middle = 2;
    default:
      break;
  }

  final chunks = <List<String>>[_start];
  for (var i = 0; i < middle; i++) {
    if (i == middle ~/ 2 && middle >= 4) chunks.add(_hearth);
    chunks.add(pool[rnd.nextInt(pool.length)]);
  }
  final fight = loc.kind == LocKind.arena || loc.kind == LocKind.boss;
  if (fight) chunks.addAll([_hearth, _arena]);
  chunks.add(_end);

  String resolve(String row) {
    final b = StringBuffer();
    for (final ch in row.split('')) {
      b.write(switch (ch) {
        'd' => rnd.nextDouble() < enemyChance ? 'D' : '.',
        'b' => rnd.nextDouble() < enemyChance * 0.8 ? 'V' : '.',
        'x' => rnd.nextDouble() < vaseChance ? 'v' : '.',
        '+' => rnd.nextDouble() < 0.7 ? '*' : '.',
        'c' => rnd.nextDouble() < chestChance ? 'C' : '.',
        _ => ch,
      });
    }
    return b.toString();
  }

  final boss = switch (loc.kind) {
    LocKind.boss => BossDef(r.bossName, r.bossTitle, hp: 30 + tier * 10),
    LocKind.arena => BossDef('${r.name} Champion', loc.name, hp: 18 + tier * 6),
    _ => const BossDef('', ''),
  };

  return LevelDef(
    id: loc.id,
    title: loc.name,
    subtitle: r.name,
    rows: 17,
    chunks: [for (final c in chunks) c.map(resolve).toList()],
    signs: [loc.desc],
    boss: boss,
    enemyBonus: tier,
    skyTint: r.color,
  );
}
