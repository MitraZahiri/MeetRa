import 'package:flutter/services.dart';

// Live state of the on-screen buttons (written by the touch controls, read by Controls)
class Touch {
  bool left = false, right = false, down = false, jump = false, attack = false, spell = false, drink = false, bomb = false;

  void clear() => left = right = down = jump = attack = spell = drink = bomb = false;

  void set(String key, bool v) {
    switch (key) {
      case 'left':
        left = v;
      case 'right':
        right = v;
      case 'down':
        down = v;
      case 'jump':
        jump = v;
      case 'attack':
        attack = v;
      case 'spell':
        spell = v;
      case 'drink':
        drink = v;
      case 'bomb':
        bomb = v;
    }
  }
}

final touch = Touch();

class ControlState {
  bool left = false, right = false, down = false, jump = false;
  bool jumpPressed = false, attackPressed = false, spellPressed = false, drinkPressed = false, bombPressed = false, actPressed = false;
}

// Merges keyboard and touch input into one state
class Controls {
  Set<LogicalKeyboardKey> keys = const {};
  bool _prevJump = false, _prevAttack = false, _prevSpell = false, _prevDrink = false, _prevBomb = false, _prevAct = false;
  final state = ControlState();

  bool _any(List<LogicalKeyboardKey> ks) => ks.any(keys.contains);

  ControlState update() {
    final s = state;
    s.left = _any([LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.keyA]) || touch.left;
    s.right = _any([LogicalKeyboardKey.arrowRight, LogicalKeyboardKey.keyD]) || touch.right;
    s.down = _any([LogicalKeyboardKey.arrowDown, LogicalKeyboardKey.keyS]) || touch.down;
    final jump = _any([LogicalKeyboardKey.space, LogicalKeyboardKey.arrowUp, LogicalKeyboardKey.keyW, LogicalKeyboardKey.keyZ]) || touch.jump;
    final attack = _any([LogicalKeyboardKey.keyJ, LogicalKeyboardKey.keyX]) || touch.attack;
    final spell = _any([LogicalKeyboardKey.keyK, LogicalKeyboardKey.keyC]) || touch.spell;
    final drink = _any([LogicalKeyboardKey.keyH, LogicalKeyboardKey.keyQ]) || touch.drink;
    s.jump = jump;
    s.jumpPressed = jump && !_prevJump;
    s.attackPressed = attack && !_prevAttack;
    s.spellPressed = spell && !_prevSpell;
    _prevJump = jump;
    _prevAttack = attack;
    _prevSpell = spell;
    s.drinkPressed = drink && !_prevDrink;
    _prevDrink = drink;
    final bomb = _any([LogicalKeyboardKey.keyB, LogicalKeyboardKey.keyL]) || touch.bomb;
    s.bombPressed = bomb && !_prevBomb;
    _prevBomb = bomb;
    final act = _any([LogicalKeyboardKey.keyE, LogicalKeyboardKey.enter]);
    s.actPressed = act && !_prevAct;
    _prevAct = act;
    return s;
  }
}
