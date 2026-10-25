// A small arcade physics engine in the spirit of Phaser's Arcade Physics:
// axis-aligned boxes, gravity, tile collision, one-way platforms and static walls.

import 'dart:math' as math;
import 'dart:ui';

import '../config.dart';
import '../levels/build.dart';

double approach(double v, double target, double step) => v < target ? math.min(v + step, target) : math.max(v - step, target);

// The body's position (x, y) is its bottom-centre: the point the sprite stands on.
class Body {
  Body(this.x, this.y, this.w, this.h);

  double x, y, w, h;
  double vx = 0, vy = 0;
  bool allowGravity = true;
  double maxVy = double.infinity;
  double bounceY = 0;
  double dragX = 0;
  bool collideWorldX = false;
  bool enabled = true;
  bool collides = true; // false = falls through everything (Phaser: checkCollision.none)

  bool blockedDown = false, blockedUp = false, blockedLeft = false, blockedRight = false;

  double get left => x - w / 2;
  double get right => x + w / 2;
  double get top => y - h;
  double get bottom => y;
  double get centerX => x;
  double get centerY => y - h / 2;
  Rect get rect => Rect.fromLTWH(left, top, w, h);
}

class Wall {
  Wall(this.rect);
  final Rect rect;
  double get x => rect.center.dx;
  double get y => rect.center.dy;
}

bool overlaps(Rect a, Rect b) => a.left < b.right && a.right > b.left && a.top < b.bottom && a.bottom > b.top;

class Physics {
  Physics(this.level);

  final Level level;
  final List<Wall> walls = [];

  static const _eps = 0.001;

  bool _solid(int t) => t == T.grass || t == T.dirt || t == T.brick || t == T.spikes;

  // Moves a body for dt seconds and separates it from tiles and walls.
  // [skipPlatforms] lets the player drop through one-way platforms; [onTile] reports touched solid tiles.
  void step(Body b, double dt, {bool tiles = true, bool useWalls = true, bool skipPlatforms = false, void Function(int tile)? onTile}) {
    if (!b.enabled) return;
    b.blockedDown = b.blockedUp = b.blockedLeft = b.blockedRight = false;
    if (b.allowGravity) b.vy += gravity * dt;
    if (b.vy > b.maxVy) b.vy = b.maxVy;
    if (b.dragX > 0) b.vx = approach(b.vx, 0, b.dragX * dt);

    final dist = math.max(b.vx.abs(), b.vy.abs()) * dt;
    final n = math.max(1, (dist / 4).ceil());
    final sdt = dt / n;
    final collide = b.collides;
    for (var i = 0; i < n; i++) {
      b.x += b.vx * sdt;
      if (collide) _separateX(b, tiles, useWalls, onTile);
      final dy = b.vy * sdt;
      b.y += dy;
      if (collide) _separateY(b, dy, tiles, useWalls, skipPlatforms, onTile);
    }
  }

  Iterable<(int, Rect)> _tilesIn(Rect r) sync* {
    final x0 = (r.left / tile).floor(), x1 = ((r.right - _eps) / tile).floor();
    final y0 = (r.top / tile).floor(), y1 = ((r.bottom - _eps) / tile).floor();
    for (var ty = y0; ty <= y1; ty++) {
      for (var tx = x0; tx <= x1; tx++) {
        final t = level.tileAt(tx, ty);
        if (t != T.empty) yield (t, Rect.fromLTWH(tx * tile, ty * tile, tile, tile));
      }
    }
  }

  void _separateX(Body b, bool tiles, bool useWalls, void Function(int)? onTile) {
    final dir = b.vx;
    if (tiles) {
      for (final (t, r) in _tilesIn(b.rect)) {
        if (!_solid(t) || !overlaps(b.rect, r)) continue;
        _pushX(b, r, dir);
        onTile?.call(t);
      }
    }
    if (useWalls) {
      for (final w in walls) {
        if (overlaps(b.rect, w.rect)) _pushX(b, w.rect, dir != 0 ? dir : (b.x < w.x ? 1 : -1));
      }
    }
    if (b.collideWorldX) {
      if (b.left < 0) {
        b.x = b.w / 2;
        b.vx = 0;
        b.blockedLeft = true;
      } else if (b.right > level.width) {
        b.x = level.width - b.w / 2;
        b.vx = 0;
        b.blockedRight = true;
      }
    }
  }

  void _pushX(Body b, Rect r, double dir) {
    if (dir > 0) {
      b.x = r.left - b.w / 2;
      b.blockedRight = true;
    } else {
      b.x = r.right + b.w / 2;
      b.blockedLeft = true;
    }
    b.vx = 0;
  }

  void _separateY(Body b, double dy, bool tiles, bool useWalls, bool skipPlatforms, void Function(int)? onTile) {
    if (tiles) {
      for (final (t, r) in _tilesIn(b.rect)) {
        if (!overlaps(b.rect, r)) continue;
        if (t == T.platform) {
          // One-way: only lands from above
          if (skipPlatforms || dy <= 0 || b.bottom - dy > r.top + _eps) continue;
        } else if (!_solid(t)) {
          continue;
        }
        _pushY(b, r, dy);
        onTile?.call(t);
      }
    }
    if (useWalls) {
      for (final w in walls) {
        if (overlaps(b.rect, w.rect)) _pushY(b, w.rect, dy);
      }
    }
  }

  void _pushY(Body b, Rect r, double dy) {
    if (dy >= 0) {
      b.y = r.top;
      b.blockedDown = true;
      b.vy = -b.vy * b.bounceY;
      if (b.vy.abs() < 30) b.vy = 0;
    } else {
      b.y = r.bottom + b.h;
      b.blockedUp = true;
      b.vy = 0;
    }
  }
}
