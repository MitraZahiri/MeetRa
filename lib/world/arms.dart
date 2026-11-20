// The seven arms of the inns. In the town of every realm an innkeeper keeps one weapon for Ra, handed
// over after the first night under their roof. Each is stronger than the one before and fights in its
// own way, and the Mirror of Ra at the end of the saga can only be broken by all seven in turn.
// Ra's own sword is always carried too; it is arm -1.

enum ArmKind { spear, hammer, bow, mace, lasso, shield, dawnfire }

class Arm {
  const Arm(this.kind, this.name, this.bonus, this.color, this.use, this.gift);

  final ArmKind kind;
  final String name;
  final int bonus; // added to Ra's attack with every blow
  final int color; // the arm's glow, for its swing, its button and the Mirror's ward
  final String use; // how it fights, in one line
  final String gift; // the innkeeper's words when handing it over
}

// One arm for each realm, in realm order: arms[realm.index] waits at that realm's inn
const arms = <Arm>[
  Arm(ArmKind.spear, 'Reed Spear', 1, 0xffc8d870, 'A long thrust: strike foes from twice a sword\'s reach.',
      'My father cut this spear from the reeds where the lion hunted, and walked the marsh with it alone. '
          'It reaches farther than any sword. Take it: the road east is longer than it looks.'),
  Arm(ArmKind.hammer, "Smith's Hammer", 2, 0xffe08a4a, 'A heavy, slow blow that hurls foes back and smashes cracked rock in front of Ra.',
      'Bram the Smith left this hammer by my fire the night he raised his apron as a banner. '
          'It was made for iron, but it breaks stone just as well. Swing it at cracked rock and see.'),
  Arm(ArmKind.bow, 'Tamarisk Bow', 3, 0xffe8c070, 'Shoots arrows straight ahead: strike from far away.',
      'Tamarisk wood, strung with camel sinew. In the desert you see your enemy long before he reaches you. '
          'An old archer told me the dark fears an arrow aimed true. Shoot first.'),
  Arm(ArmKind.mace, 'Ox-Head Mace', 4, 0xffb0b8d0, 'Strikes the ground: a shockwave runs both ways and dazes everything it touches.',
      'A smith shaped its head like an ox, for the one who chained the serpent king inside the mountain. '
          'Strike the ground with it, and the ground answers.'),
  Arm(ArmKind.lasso, 'Horsehair Lasso', 5, 0xffd8a868, 'Thrown ahead: it catches a foe, drags it to Ra\'s feet and holds it dazed.',
      'Sixty coils of braided horsehair. The riders of the steppe say a good lasso catches a lion as surely as a horse. '
          'Throw it, and pull whatever it catches to your feet.'),
  Arm(ArmKind.shield, 'Sea-Glass Shield', 6, 0xff7ad8d0, 'A charging bash: Ra rushes forward behind it, and nothing can hurt Ra during the rush.',
      'Sea-glass, gathered from the tide for a hundred years and set in bronze. '
          'Raise it and walk into the blow. Nothing passes it.'),
  Arm(ArmKind.dawnfire, 'Dawnfire Blade', 7, 0xffffb040, 'A burning blade: every swing also sends a wave of fire through foes.',
      'This blade was dipped in a spark of the Dawnfire, the last light before the dark. It burns what the dark hides. '
          'Across the black water your shadow waits, and it knows every weapon you carry. Bring them all.'),
];

String armName(int i) => i < 0 ? "Ra's Sword" : arms[i].name;
