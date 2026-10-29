// Explorable levels: a grid of rooms joined by doors, drops through the floor and climbs back up.
// The main road winds up and down from the first room to the gate; every other room hangs off it.
// The gate is sealed until Ra finds the Sun Key, hidden in the room farthest from the start.
// The top row of rooms lies under the open sky; the rows below are underground.
// See build.dart for the map legend.

import 'dart:math' as math;

const roomW = 20;
const roomH = 11; // row 0 ceiling, rows 1-9 air, row 10 floor

class _Room {
  _Room(this.c, this.r);
  final int c, r;
  bool path = false;
  bool left = false, right = false, up = false, down = false;
  int hole = 7; // first column of the drop in this room's floor
  int links = 0;
}

// Shape of the room grid and how it plays, per kind of place
class RoomPlan {
  const RoomPlan({required this.cols, required this.rows, this.downward = false, this.underground = '#', this.chests = 1});
  final int cols, rows;
  final bool downward; // a cave: the road only ever goes down, to a gate at the bottom
  final String underground; // tile for the rock below the surface
  final int chests; // chests per dead-end room
}

// [foe] picks what stands on a ground spot, from a random roll
List<String> buildRooms(RoomPlan plan, math.Random rnd, {required double enemyChance, required String Function(double roll) foe}) {
  final cols = plan.cols, rows = plan.rows;
  final w = cols * roomW, h = rows * roomH;
  final rooms = [
    for (var r = 0; r < rows; r++) [for (var c = 0; c < cols; c++) _Room(c, r)],
  ];
  _Room at(int c, int r) => rooms[r][c];

  void linkH(_Room a) {
    a.right = true;
    at(a.c + 1, a.r).left = true;
    a.links++;
    at(a.c + 1, a.r).links++;
  }

  void linkV(_Room upper) {
    upper.down = true;
    at(upper.c, upper.r + 1).up = true;
    upper.links++;
    at(upper.c, upper.r + 1).links++;
  }

  // The main road: across every column, climbing or dropping inside some of them
  final startRow = plan.downward ? 0 : rnd.nextInt(rows);
  var row = startRow;
  final road = <_Room>[];
  for (var c = 0; c < cols; c++) {
    var out = rnd.nextInt(rows);
    if (plan.downward) out = c == cols - 1 ? rows - 1 : row + rnd.nextInt(rows - row);
    if (out == row && rnd.nextDouble() < 0.6 && !plan.downward) out = (row + 1 + rnd.nextInt(rows - 1)) % rows;
    final step = out > row ? 1 : -1;
    for (var r = row;; r += step) {
      at(c, r).path = true;
      road.add(at(c, r));
      if (r == out) break;
      linkV(at(c, math.min(r, r + step)));
    }
    if (c < cols - 1) linkH(at(c, out));
    row = out;
  }
  final start = at(0, startRow), end = road.last;

  // Every other room joins the network through a neighbour, so the whole grid can be explored
  final joined = {for (final r in road) r};
  while (joined.length < rows * cols) {
    final options = <(_Room, _Room)>[];
    for (final a in joined) {
      for (final (dc, dr) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
        final c = a.c + dc, r = a.r + dr;
        if (c < 0 || r < 0 || c >= cols || r >= rows) continue;
        final b = at(c, r);
        if (!joined.contains(b)) options.add((a, b));
      }
    }
    final (a, b) = options[rnd.nextInt(options.length)];
    if (a.r == b.r) {
      linkH(a.c < b.c ? a : b);
    } else {
      linkV(a.r < b.r ? a : b);
    }
    joined.add(b);
  }
  // A few extra openings make loops, so the way back is not always the way in
  for (var r = 0; r < rows; r++) {
    for (var c = 0; c < cols; c++) {
      final a = at(c, r);
      if (c < cols - 1 && !a.right && rnd.nextDouble() < 0.2) linkH(a);
      if (r < rows - 1 && !a.down && rnd.nextDouble() < 0.15) linkV(a);
    }
  }

  // Walk the network to find how far each room is from the start
  final dist = <_Room, int>{start: 0};
  final queue = [start];
  while (queue.isNotEmpty) {
    final a = queue.removeAt(0);
    final next = [
      if (a.right) at(a.c + 1, a.r),
      if (a.left) at(a.c - 1, a.r),
      if (a.down) at(a.c, a.r + 1),
      if (a.up) at(a.c, a.r - 1),
    ];
    for (final b in next) {
      if (dist.containsKey(b)) continue;
      dist[b] = dist[a]! + 1;
      queue.add(b);
    }
  }
  final side = [for (final row in rooms) ...row.where((r) => !r.path)];
  final keyRoom = side.isNotEmpty
      ? side.reduce((a, b) => dist[a]! >= dist[b]! ? a : b)
      : road[road.length ~/ 2] == start || road[road.length ~/ 2] == end
          ? road[1]
          : road[road.length ~/ 2];
  final hearthRoom = road[road.length ~/ 2];

  // ---- Carve the rock ----
  final rock = plan.underground;
  final g = List.generate(h, (y) => List.filled(w, y < roomH ? '#' : rock));
  void set(int x, int y, String ch) {
    if (x >= 0 && y >= 0 && x < w && y < h) g[y][x] = ch;
  }

  bool solid(int x, int y) => y >= h || (x >= 0 && x < w && y >= 0 && (g[y][x] == '#' || g[y][x] == 'B' || g[y][x] == '='));

  for (final row in rooms) {
    for (final a in row) {
      final ox = a.c * roomW, oy = a.r * roomH;
      a.hole = 5 + rnd.nextInt(5);
      for (var y = oy + 1; y <= oy + 9; y++) {
        for (var x = ox + 1; x <= ox + roomW - 2; x++) {
          set(x, y, '.');
        }
      }
      // Under the open sky there is no ceiling
      if (a.r == 0) {
        for (var x = ox + 1; x <= ox + roomW - 2; x++) {
          set(x, oy, '.');
        }
      }
      if (a.right) {
        // A doorway; on the surface the wall between two linked rooms is gone altogether
        for (var y = a.r == 0 ? oy : oy + 6; y <= oy + 9; y++) {
          set(ox + roomW - 1, y, '.');
          set(ox + roomW, y, '.');
        }
      }
    }
  }
  for (final row in rooms) {
    for (final a in row) {
      if (!a.down) continue;
      // A drop through the floor, covered by a ledge Ra can stand on or drop through,
      // and a zigzag of ledges in the room below to climb back up
      final ox = a.c * roomW, oy = a.r * roomH, hx = ox + a.hole;
      for (var x = hx - 1; x <= hx + 4; x++) {
        set(x, oy + roomH, '.');
      }
      for (var x = hx; x <= hx + 3; x++) {
        set(x, oy + 10, '=');
      }
      // Three steps of about three tiles each; the top one sits half under the drop,
      // so Ra can jump straight up through it
      final below = oy + roomH;
      for (var x = hx + 5; x <= hx + 7; x++) {
        set(x, below + 7, '=');
      }
      for (var x = hx; x <= hx + 2; x++) {
        set(x, below + 4, '=');
      }
      for (var x = hx + 3; x <= hx + 5; x++) {
        set(x, below + 2, '=');
      }
    }
  }

  // ---- Furnish each room ----
  // Columns kept clear: by the doors, around the drop, and under the climb
  Set<int> reserved(_Room a) => {
        1, 2, 3, roomW - 4, roomW - 3, roomW - 2,
        if (a.down) for (var x = a.hole - 1; x <= a.hole + 4; x++) x,
        if (a.up) for (var x = at(a.c, a.r - 1).hole - 1; x <= at(a.c, a.r - 1).hole + 8; x++) x,
        if (a == end) ...[roomW - 6, roomW - 5],
      };

  // The lowest open spot a thing can stand on in a column of a room
  int? ground(_Room a, int col) {
    final x = a.c * roomW + col, oy = a.r * roomH;
    for (var y = oy + 9; y >= oy + 1; y--) {
      if (g[y][x] == '.' && solid(x, y + 1) && g[y + 1][x] != '^') return y;
    }
    return null;
  }

  bool place(_Room a, int col, String ch, {int lift = 0}) {
    final y = ground(a, col);
    if (y == null || y - lift < a.r * roomH + 1) return false;
    final x = a.c * roomW + col;
    if (g[y - lift][x] != '.') return false;
    g[y - lift][x] = ch;
    return true;
  }

  final deadEnds = side.where((r) => r.links == 1 && r != keyRoom).toList();
  for (final row in rooms) {
    for (final a in row) {
      final ox = a.c * roomW, oy = a.r * roomH;
      final busy = reserved(a);
      final free = [for (var x = 4; x < roomW - 4; x++) if (!busy.contains(x)) x];

      // A run of free columns at least [n] wide, or null
      int? run(int n) {
        final starts = [for (final x in free) if (List.generate(n, (i) => x + i).every(free.contains)) x];
        return starts.isEmpty ? null : starts[rnd.nextInt(starts.length)];
      }

      void claim(int x0, int n) => free.removeWhere((x) => x >= x0 - 1 && x < x0 + n + 1);

      // The first room stays clear and calm
      final features = a == start ? 0 : 1 + rnd.nextInt(2);
      for (var f = 0; f < features; f++) {
        switch (rnd.nextInt(a.r == 0 ? 3 : 4)) {
          case 0: // a mound or a raised step
            final n = 3 + rnd.nextInt(3);
            final x0 = run(n);
            if (x0 == null) break;
            final tall = 1 + rnd.nextInt(2);
            for (var x = x0; x < x0 + n; x++) {
              for (var y = 0; y < tall; y++) {
                set(ox + x, oy + 9 - y, a.r == 0 ? '#' : rock);
              }
            }
            claim(x0, n);
          case 1: // a floating ledge
            final n = 3 + rnd.nextInt(2);
            final x0 = run(n);
            if (x0 == null) break;
            for (var x = x0; x < x0 + n; x++) {
              set(ox + x, oy + 6, '=');
            }
            if (rnd.nextDouble() < 0.5) set(ox + x0 + n ~/ 2, oy + 5, rnd.nextDouble() < 0.3 ? 'C' : 'v');
            claim(x0, n);
          case 2: // thorns, with a ledge above to cross on
            final n = 2 + rnd.nextInt(2);
            final x0 = run(n + 2);
            if (x0 == null) break;
            for (var x = x0 + 1; x <= x0 + n; x++) {
              set(ox + x, oy + 9, '^');
            }
            for (var x = x0; x <= x0 + n + 1; x++) {
              set(ox + x, oy + 6, '=');
            }
            claim(x0, n + 2);
          case 3: // rock hanging from the ceiling
            final n = 2 + rnd.nextInt(2);
            final x0 = run(n);
            if (x0 == null) break;
            for (var x = x0; x < x0 + n; x++) {
              for (var y = 1; y <= 2 + (x == x0 ? 0 : 1); y++) {
                set(ox + x, oy + y, rock);
              }
            }
        }
      }

      // Things on the ground
      if (a == start) {
        place(a, 2, 'A');
        place(a, 4, 'P');
        place(a, 7, 'S');
        place(a, 10, 'S');
        continue;
      }
      if (a == end) place(a, roomW - 5, 'G');
      if (a == hearthRoom) place(a, 3, 'A');
      if (a == keyRoom) {
        if (!place(a, roomW ~/ 2, 'O', lift: 1)) place(a, roomW - 6, 'O', lift: 1);
      }
      if (deadEnds.contains(a)) {
        for (var i = 0; i < plan.chests; i++) {
          place(a, 12 + i * 3, 'C');
        }
      }
      final spots = [...free]..shuffle(rnd);
      var foes = 0;
      for (final x in spots.take(3)) {
        if (foes < 2 && rnd.nextDouble() < enemyChance) {
          if (place(a, x, foe(rnd.nextDouble()))) foes++;
        } else if (rnd.nextDouble() < 0.4) {
          place(a, x, a.r == 0 && rnd.nextBool() ? '*' : 'v');
        }
      }
      // A carrion fly hovering in the air
      if (rnd.nextDouble() < enemyChance * 0.5 && spots.isNotEmpty && g[oy + 4][ox + spots.last] == '.') set(ox + spots.last, oy + 4, 'V');
    }
  }
  return [for (final row in g) row.join()];
}
