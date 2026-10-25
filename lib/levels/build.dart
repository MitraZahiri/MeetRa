import '../config.dart';

class LevelObject {
  LevelObject(this.type, this.tx, this.ty)
      : x = tx * tile + tile / 2,
        y = (ty + 1) * tile;

  final String type;
  final int tx;
  final int ty;
  final double x; // bottom-centre of the tile
  final double y;
}

class BossDef {
  const BossDef(this.name, this.title, {this.hp = 30});
  final String name;
  final String title;
  final int hp;
}

class LevelDef {
  const LevelDef({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.rows,
    required this.chunks,
    required this.signs,
    required this.boss,
    this.enemyBonus = 0,
    this.skyTint,
  });

  final String id;
  final String title;
  final String subtitle;
  final int rows;
  final List<List<String>> chunks;
  final List<String> signs;
  final BossDef boss;
  final int enemyBonus; // extra health for every enemy in later realms
  final int? skyTint; // ARGB wash over the background, per realm
}

class Level {
  Level(this.data, this.objects, this.cols, this.rows)
      : width = cols * tile,
        height = rows * tile;

  final List<List<int>> data;
  final List<LevelObject> objects;
  final int cols;
  final int rows;
  final double width;
  final double height;

  int tileAt(int tx, int ty) {
    if (ty < 0 || ty >= rows || tx < 0 || tx >= cols) return T.empty;
    return data[ty][tx];
  }

  int tileAtWorld(double x, double y) => tileAt((x / tile).floor(), (y / tile).floor());
}

// Joins ASCII chunks side by side into tilemap data plus an object list.
// Each chunk is bottom-aligned; short rows are padded with '.'.
//
// Legend:
//   #  ground (grass on top, dirt below)   =  one-way platform
//   B  stone brick   ^  thorns
//   P  player        A  hearth (checkpoint)   S  signpost
//   D  imp           V  bat      v  vase     *  bush     C  chest
//   F  Saena's feather   L  lion boss   [ ]  boss arena walls   G  exit gate
Level buildLevel(LevelDef def) {
  final height = def.rows;
  final rows = List.filled(height, '');
  for (final chunk in def.chunks) {
    final w = chunk.map((r) => r.length).reduce((a, b) => a > b ? a : b);
    final padded = [...List.filled(height - chunk.length, ''), ...chunk].map((r) => r.padRight(w, '.')).toList();
    for (var i = 0; i < height; i++) {
      rows[i] += padded[i];
    }
  }

  final cols = rows[0].length;
  final data = <List<int>>[];
  final objects = <LevelObject>[];
  for (var y = 0; y < height; y++) {
    final line = <int>[];
    for (var x = 0; x < cols; x++) {
      final c = rows[y][x];
      var t = T.empty;
      if (c == '#') {
        t = y > 0 && rows[y - 1][x] == '#' ? T.dirt : T.grass;
      } else if (c == '=') {
        t = T.platform;
      } else if (c == 'B') {
        t = T.brick;
      } else if (c == '^') {
        t = T.spikes;
      } else if (c != '.' && c != ' ') {
        objects.add(LevelObject(c, x, y));
      }
      line.add(t);
    }
    data.add(line);
  }

  return Level(data, objects, cols, height);
}
