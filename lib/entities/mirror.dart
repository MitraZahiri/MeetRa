import 'dart:math' as math;
import 'dart:ui';

import '../art/pixel.dart';
import '../game/effects.dart';
import '../game/meetra_game.dart';
import '../levels/build.dart';
import '../sfx.dart';
import '../world/arms.dart';
import 'lion.dart';

// The Mirror of Ra: Ra's own shadow, waiting at the Heart of Night at the end of the saga.
// It prowls, charges and pounces like the beasts before it, but it knows every weapon Ra carries:
// it wears seven wards, one after another, and each ward gives way to only one of the seven inn arms.
// Break a ward and it raises the next, so the fight needs all seven, each in its turn.
class Mirror extends Lion {
  Mirror(super.game, super.x, super.y, {super.maxHp = 140}) : super(w: 14, h: 30, walk: const [1, 2], scale: 1.9) {
    _order.shuffle(rand);
  }

  final _order = [for (var i = 0; i < arms.length; i++) i];
  int ward = 0; // how many wards are broken
  double _turned = 0; // ms until a turned-aside blow is explained again
  double _glow = 0; // ms of a fresh ward's flare

  // The one arm that can strike it now
  int get open => _order[ward];
  // Its life is split into seven equal wards; this is where the current one ends
  int get _floor => math.max(0, maxHp - (maxHp / arms.length).ceil() * (ward + 1));

  @override
  Offset get nose => Offset(x + facing * 6, y - 26);

  @override
  void update(double time, double dt) {
    _turned = math.max(0, _turned - dt);
    _glow = math.max(0, _glow - dt);
    super.update(time, dt);
  }

  @override
  void hurt(int dmg, {int arm = -1}) {
    if (state == LionState.dead) return;
    final a = arms[open];
    if (arm != open) {
      // The ward turns the blow aside, and says what would get through
      game.particles.spark(x, y - 16, size: 10, color: a.color);
      sfx.fizzle();
      if (_turned <= 0) {
        _turned = 900;
        game.floatText(x, y - body.h - 14, 'Only the ${a.name}!', Color(a.color), size: 8, duration: 1000);
      }
      return;
    }
    final floor = _floor;
    if (floor > 0) {
      // A ward breaks on its own blow; the next one takes no damage from it
      final mult = state == LionState.stunned ? 1.5 : 1.0;
      dmg = math.max(1, math.min(dmg, ((hp - floor) / mult).floor()));
    }
    super.hurt(dmg, arm: arm);
    if (floor > 0 && hp <= floor) {
      hp = floor;
      game.ui.bossFrac.value = hp / maxHp;
      _nextWard();
    }
  }

  void _nextWard() {
    ward++;
    _glow = 900;
    final a = arms[open];
    sfx.roar();
    game.camera
      ..shake(350, 0.01)
      ..flash(a.color, 0.3, 500);
    game.particles.ring(x, y - 16, a.color, r1: 42, life: 600, width: 3);
    game.burst(x, y - 16, [0xff4a4658, 0xff9a90b8, a.color], 18, 150);
    // It leaps back, out of reach, to raise the new ward
    body
      ..vy = -260
      ..vx = -facing * 120;
    setState(LionState.pounce, 200);
    announce();
  }

  // The boss bar names the ward, and a banner says which arm breaks it
  void announce() {
    final a = arms[open];
    game.ui.boss.value = BossDef(game.def.boss.name, 'Ward ${ward + 1} of ${arms.length}  ·  only the ${a.name} breaks it');
    game.ui.banner.value = BannerMsg(ward == 0 ? 'Seven wards guard it' : 'A new ward rises', 'Only the ${a.name} can hurt it now  ·  tap the arms button to change');
  }

  @override
  void render(Canvas c, Sheet sheet) {
    // A shadow of Ra, dark and violet, ringed by the colour of the arm that can break its ward
    final a = arms[open];
    final pulse = 0.5 + 0.5 * math.sin(game.timeNow / 160);
    final ring = Paint()
      ..color = Color(a.color).withValues(alpha: (0.35 + 0.35 * pulse + _glow / 900 * 0.3) * alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    if (state != LionState.dead) c.drawOval(Rect.fromCenter(center: Offset(x, y - 15), width: 30 + 4 * pulse, height: 38 + 4 * pulse), ring);
    final saved = tint;
    tint ??= 0xff5a4a78;
    super.render(c, sheet);
    tint = saved;
    if (state == LionState.dead) return;
    // The ward's sign above its head: a small diamond in the arm's colour
    final top = y - body.h * 1.25 - 8 + math.sin(game.timeNow / 300) * 1.5;
    final diamond = Path()
      ..moveTo(x, top - 4)
      ..lineTo(x + 3, top)
      ..lineTo(x, top + 4)
      ..lineTo(x - 3, top)
      ..close();
    c.drawPath(diamond, Paint()..color = Color(a.color).withValues(alpha: alpha));
  }
}
