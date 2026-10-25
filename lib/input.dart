import 'package:flutter/services.dart';

// Live state of the on-screen buttons (written by the touch controls, read by Controls)
class Touch {
  bool left = false, right = false, down = false, jump = false, attack = false, spell = false;

  void clear() => left = right = down = jump = attack = spell = false;

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
    }
  }
}

final touch = Touch();

class ControlState {
  bool left = false, right = false, down = false, jump = false;
  bool jumpPressed = false, attackPressed = false, spellPressed = false;
}

// Merges keyboard and touch input into one state
class Controls {
  Set<LogicalKeyboardKey> keys = const {};
  bool _prevJump = false, _prevAttack = false, _prevSpell = false;
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
    s.jump = jump;
    s.jumpPressed = jump && !_prevJump;
    s.attackPressed = attack && !_prevAttack;
    s.spellPressed = spell && !_prevSpell;
    _prevJump = jump;
    _prevAttack = attack;
    _prevSpell = spell;
    return s;
  }
}
