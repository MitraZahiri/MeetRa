// Game-wide constants

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

const double tile = 16;
const double zoom = 3;
// The virtual screen is 540 high (width follows the phone's aspect ratio).
// The world camera zooms 3x, so 180 world pixels are visible vertically.
const double gameH = 540;
const double gravity = 900;

// Palette: lapis, turquoise, gold, vermilion, parchment
abstract final class Palette {
  static const lapis = 0xff1b2a6b;
  static const turquoise = 0xff2bb3a8;
  static const gold = 0xffd4a845;
  static const red = 0xffb83a2e;
  static const parchment = 0xfff2e6c9;
  static const ink = 0xff1a1020;
}

// Tileset frame indices
abstract final class T {
  static const empty = -1;
  static const grass = 0;
  static const dirt = 1;
  static const platform = 2;
  static const brick = 3;
  static const spikes = 4;
}

abstract final class PlayerTuning {
  static const speed = 110.0;
  static const accelGround = 1600.0;
  static const accelAir = 950.0;
  static const jump = 310.0;
  static const doubleJump = 270.0;
  static const coyote = 90.0; // ms you can still jump after walking off a ledge
  static const buffer = 120.0; // ms a jump pressed before landing is remembered
  static const invuln = 1000.0;
  static const featherCost = 20.0;
}

// XP needed to go from level N to N+1
int xpForLevel(int lv) => (20 + (lv - 1) * 15 + math.pow(lv - 1, 2) * 5).floor();

// Player progress, shared by the game and the HUD.
// Health is counted in half hearts: 6 = 3 hearts.
class GameState extends ChangeNotifier {
  int hp = 6;
  int maxHp = 6;
  double aura = 60;
  int auraMax = 60;
  int attack = 1;
  int magic = 2;
  int gold = 0;
  int xp = 0;
  int level = 1;
  int xpNext = xpForLevel(1);
  bool hasFeather = false;

  void reset() {
    hp = 6;
    maxHp = 6;
    aura = 60;
    auraMax = 60;
    attack = 1;
    magic = 2;
    gold = 0;
    xp = 0;
    level = 1;
    xpNext = xpForLevel(1);
    hasFeather = false;
    notifyListeners();
  }

  Map<String, Object> toJson() => {
        'maxHp': maxHp,
        'auraMax': auraMax,
        'attack': attack,
        'magic': magic,
        'gold': gold,
        'xp': xp,
        'level': level,
        'hasFeather': hasFeather,
      };

  // Health and aura always start full
  void fromJson(Map<String, dynamic> j) {
    maxHp = j['maxHp'] as int? ?? 6;
    auraMax = j['auraMax'] as int? ?? 60;
    attack = j['attack'] as int? ?? 1;
    magic = j['magic'] as int? ?? 2;
    gold = j['gold'] as int? ?? 0;
    xp = j['xp'] as int? ?? 0;
    level = j['level'] as int? ?? 1;
    xpNext = xpForLevel(level);
    hasFeather = j['hasFeather'] as bool? ?? false;
    hp = maxHp;
    aura = auraMax.toDouble();
    notifyListeners();
  }

  Object get _snapshot => (hp, maxHp, aura.floor(), auraMax, attack, magic, gold, xp, level, xpNext, hasFeather);
  Object? _last;

  // Called once per frame: the HUD only rebuilds when something visible changed
  void flush() {
    final s = _snapshot;
    if (s != _last) {
      _last = s;
      notifyListeners();
    }
  }
}
