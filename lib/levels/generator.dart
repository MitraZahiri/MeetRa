// Builds a level for every playable location from hand-made ASCII chunks.
// The location id seeds the random choices, so a place always has the same layout.
// See build.dart for the map legend. Lowercase markers are optional:
//   d  maybe a ground foe (demon, scorpions, ghoul or man-eater)  b  maybe a fly   x  maybe a vase   +  maybe a bush   c  maybe a chest

import 'dart:math' as math;

import '../world/world.dart';
import 'build.dart';
import 'level1.dart';
import 'rooms.dart';

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

// The arena of a trial: no lion, waves of the realm's creatures instead
final _trial = [for (final row in _arena) row.replaceAll('L', 'W')];

// What stands on a ground enemy spot. Small scorpions everywhere; ghouls buried in the ground
// from the Serpent Sands on; the big man-eater from the Sky Spine on.
String _foe(int tier, double roll) {
  if (tier >= 3 && roll < 0.12) return 'M';
  if (tier >= 2 && roll < 0.42) return 'U';
  if (roll > 0.72) return 'K';
  return 'D';
}

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

  // Everywhere but the fights: a winding network of rooms to explore, sealed until the Sun Key is found
  final fight = loc.kind == LocKind.arena || loc.kind == LocKind.boss;
  if (!fight) {
    final plan = switch (loc.kind) {
      LocKind.cave => RoomPlan(cols: 4, rows: 4, downward: true, underground: 'B'),
      LocKind.ruin => RoomPlan(cols: 4, rows: 3, underground: 'B', chests: 2),
      LocKind.shrine => const RoomPlan(cols: 3, rows: 2),
      LocKind.secret => RoomPlan(cols: 5, rows: 3, underground: 'B', chests: 2),
      _ => RoomPlan(cols: 4 + tier ~/ 3, rows: 2 + rnd.nextInt(2)),
    };
    return LevelDef(
      id: loc.id,
      title: loc.name,
      subtitle: r.name,
      rows: plan.rows * roomH,
      chunks: [buildRooms(plan, rnd, enemyChance: enemyChance, foe: (roll) => _foe(tier, roll))],
      signs: [loc.desc, 'The gate is sealed by the sun. Find the Sun Key hidden somewhere in this place.'],
      boss: const BossDef('', ''),
      enemyBonus: tier,
      skyTint: r.color,
      sealed: true,
    );
  }

  final chunks = <List<String>>[_start];
  for (var i = 0; i < middle; i++) {
    if (i == middle ~/ 2 && middle >= 4) chunks.add(_hearth);
    chunks.add(pool[rnd.nextInt(pool.length)]);
  }
  chunks.addAll([_hearth, loc.kind == LocKind.arena ? _trial : _arena]);
  chunks.add(_end);

  String resolve(String row) {
    final b = StringBuffer();
    for (final ch in row.split('')) {
      b.write(switch (ch) {
        'd' => rnd.nextDouble() < enemyChance ? _foe(tier, rnd.nextDouble()) : '.',
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
    LocKind.arena => BossDef('Trial of ${r.name}', 'Wave 1 of 3', hp: 18 + tier * 6),
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
