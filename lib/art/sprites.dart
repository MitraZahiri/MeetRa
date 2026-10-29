import 'dart:math' as math;
import 'dart:ui';

import 'pixel.dart';
import 'sun_eye.dart';

// Placeholder art for the prototype. Final hand-drawn sprites arrive in M1.

// ---------- Ra (hero) ----------
const _heroPal = {
  'k': '#1a1020', 's': '#e0a878', 'b': '#2a1a14', 'o': '#d9822b', 't': '#3a2010',
  'r': '#b83a2e', 'g': '#d4a845', 'w': '#f2e6c9', 'l': '#1b2a6b', 'm': '#9aa4b0', 'n': '#5a3420', 'e': '#000000',
};
const _heroTop = [
  '....gggg....',
  '...gmmmmg...',
  '...mmmmmmm..',
  '...ssssess..',
  '...bsssss...',
  '...bbbbbb...',
  '..rrbbbbo...',
  '.rrooototo..',
  '.rrotooooos.',
  '.rrooototo..',
  '.rr.oooooo..',
  '.r..gggggg..',
  '....otooto..',
  '....oooooo..',
];
final _heroAttackTop = [
  for (var i = 0; i < _heroTop.length; i++)
    i == 7 ? '.rrooototoss' : i == 8 ? '.rrotoooooss' : i == 9 ? '.rrooototo..' : _heroTop[i],
];
const _legs = {
  'idle': ['....oo..oo..', '....ll..ll..', '....nn..nn..', '...nnn..nnn.'],
  'run1': ['...oo...oo..', '..ll.....ll.', '.nn......nn.', '.nn.......nn'],
  'run2': ['....oooo....', '.....ll.....', '.....nn.....', '....nnn.....'],
  'jump': ['....oo.oo...', '...ll..ll...', '...nn...nn..', '............'],
};

// ---------- Hollows: creatures of the darkness, out of old Persian lore ----------

// The horned demon of the old miniatures: spotted indigo hide, horns, tusks, bulging eyes,
// a leopard-skin skirt, gold rings on arms and ankles, and a knotted club. Faces left.
// Frames 0-3 walk; frame 4 raises the club.
void _drawDemon(Canvas c, int f) {
  const body = Color(0xff3d4f8a), shade = Color(0xff28335a), belly = Color(0xff6478b4), spot = Color(0xffe8e0d0);
  const horn = Color(0xffe8dcc0), hornTip = Color(0xffb8a888), gold = Color(0xffd4a845), skirt = Color(0xffc8602a);
  const skirtSpot = Color(0xff5a2a10), eye = Color(0xffffd23a), mouth = Color(0xff9a1a1a), wood = Color(0xff6a4420), dark = Color(0xff1a1020);
  final raise = f == 4;
  final ph = (f % 4) * math.pi / 2;
  final front = raise ? 0.0 : (math.sin(ph) * 2).roundToDouble();
  final bob = raise ? 0.0 : (f.isOdd ? 1.0 : 0.0);

  // Back leg and back arm sit behind everything
  pxRect(c, shade, 13 - front, 20, 3, 5);
  pxRect(c, dark, 12 - front, 24, 5, 1);
  pxRect(c, gold, 13 - front, 22, 3, 1);
  pxRect(c, shade, 16, 12 + bob, 3, 6);
  // Front leg
  pxRect(c, body, 9 + front, 20, 3, 5);
  pxRect(c, dark, 8 + front, 24, 5, 1);
  pxRect(c, gold, 9 + front, 22, 3, 1);
  // Leopard skirt with a gold belt
  pxPoly(c, skirt, [Offset(7, 17 + bob), Offset(18, 17 + bob), Offset(19, 21), Offset(6, 21)]);
  for (final (x, y) in [(8.0, 18.0), (11.0, 19.0), (14.0, 18.0), (16.0, 20.0), (9.0, 20.0)]) {
    pxRect(c, skirtSpot, x, y + (y < 20 ? bob : 0), 1, 1);
  }
  pxRect(c, gold, 7, 17 + bob, 11, 1);
  // Torso: a barrel chest, lighter belly and pale spots
  pxOval(c, body, 5, 9 + bob, 14, 9);
  pxOval(c, belly, 7, 12 + bob, 7, 5);
  for (final (x, y) in [(15.0, 11.0), (17.0, 14.0), (9.0, 10.0), (13.0, 15.0)]) {
    pxRect(c, spot, x, y + bob, 1, 1);
  }
  // Horns curl up from the brow
  pxPoly(c, horn, [Offset(5, 6 + bob), Offset(2, 2 + bob), Offset(2, 0 + bob), Offset(4, 1 + bob), Offset(7, 5 + bob)]);
  pxRect(c, hornTip, 2, 0 + bob, 1, 2);
  pxPoly(c, horn, [Offset(11, 5 + bob), Offset(13, 1 + bob), Offset(15, 0 + bob), Offset(15, 2 + bob), Offset(13, 6 + bob)]);
  pxRect(c, hornTip, 14, 0 + bob, 1, 2);
  // Head, set forward on the shoulders
  pxOval(c, body, 3, 4 + bob, 11, 8);
  pxRect(c, dark, 4, 5 + bob, 3, 1);
  pxRect(c, dark, 8, 5 + bob, 3, 1);
  pxRect(c, eye, 4, 6 + bob, 2, 2);
  pxRect(c, eye, 8, 6 + bob, 2, 2);
  pxRect(c, dark, 4, 7 + bob, 1, 1);
  pxRect(c, dark, 8, 7 + bob, 1, 1);
  pxRect(c, mouth, 4, 10 + bob, 6, 1);
  pxRect(c, spot, 4, 9 + bob, 1, 1);
  pxRect(c, spot, 9, 9 + bob, 1, 1);
  // Front arm and the club: swinging with the stride, or raised high before a blow
  final hand = raise ? Offset(4, 9 + bob) : Offset(4, 15 + bob);
  final top = raise ? const Offset(9, 0) : Offset(2.5, 6 + bob + front * 0.5);
  pxPoly(c, body, [Offset(8, 11 + bob), Offset(10, 12 + bob), hand + const Offset(1, 1), hand + const Offset(-1, 0)]);
  pxRect(c, gold, (8 + hand.dx) / 2 - 1, (11 + bob + hand.dy) / 2, 2, 1);
  final dir = top - hand;
  final n = Offset(-dir.dy, dir.dx) / dir.distance;
  pxPoly(c, wood, [hand + n * 0.8, hand - n * 0.8, top - n * 1.8, top + n * 1.8]);
  pxRect(c, gold, (hand.dx + top.dx) / 2, (hand.dy + top.dy) / 2, 2, 1);
  pxRect(c, spot, top.dx - 1, top.dy, 1, 1);
}

// The carrion fly: the corpse demon of the old tales comes as a fly the size of a dog.
// Metallic body, banded abdomen, huge red eyes, dangling legs. Faces left. Frames: wings up, wings down.
void _drawFly(Canvas c, int f) {
  const wing = Color(0xccd8eef0), vein = Color(0xff9ab8c0), thorax = Color(0xff2a4a4a), abdomen = Color(0xff3a7a5a);
  const band = Color(0xff1f3a30), shine = Color(0xff8ad0a0), eye = Color(0xffc8302a), eyeShine = Color(0xffff9a7a), dark = Color(0xff1a1020);
  // Legs dangle below
  for (final (x, lean) in [(5.0, -1.0), (8.0, 0.0), (11.0, 1.0)]) {
    pxRect(c, dark, x, 10, 1, 3);
    pxRect(c, dark, x + lean, 13, 1, 1);
  }
  // Far wing behind the body
  if (f == 0) {
    pxOval(c, wing, 9, 0, 6, 6);
  } else {
    pxOval(c, wing, 10, 6, 7, 4);
  }
  // Abdomen with dark bands, thorax, head
  pxOval(c, abdomen, 9, 5, 9, 7);
  for (final x in [11.0, 13.0, 15.0]) {
    pxRect(c, band, x, 6, 1, 5);
  }
  pxRect(c, shine, 10, 6, 1, 1);
  pxOval(c, thorax, 5, 4, 7, 7);
  pxRect(c, shine, 7, 5, 2, 1);
  pxOval(c, eye, 1, 4, 6, 6);
  pxRect(c, eyeShine, 2, 5, 2, 1);
  pxRect(c, dark, 2, 10, 1, 3);
  // Near wing over the body: raised, or swept back and down
  if (f == 0) {
    pxPoly(c, wing, [const Offset(8, 5), const Offset(9, 0), const Offset(14, 0), const Offset(13, 3)]);
    pxRect(c, vein, 10, 1, 3, 1);
  } else {
    pxPoly(c, wing, [const Offset(9, 6), const Offset(17, 4), const Offset(18, 7), const Offset(11, 8)]);
    pxRect(c, vein, 12, 6, 4, 1);
  }
}

// The ghoul of the waste: an ash-grey shape-shifter with a wild white mane, green eyes and
// the hooves of a donkey, which lies buried in the sand for travellers. Faces left.
// Frames: 0 buried, 1 rising, 2-5 loping run, 6 pounce.
void _drawGhoul(Canvas c, int f) {
  const skin = Color(0xff9a9078), shade = Color(0xff6a6250), hair = Color(0xffe8e4d8), hairShade = Color(0xffb8b4a8);
  const eye = Color(0xff9aff6a), mouth = Color(0xff7a1a1a), hoof = Color(0xff3a2a20), rags = Color(0xff7a5a3a);
  const sand = Color(0xffd8b878), sandShade = Color(0xffb08a50), dark = Color(0xff1a1020);

  void mound(double y) {
    pxOval(c, sandShade, 1, y, 22, 20 - y + 1);
    pxOval(c, sand, 3, y, 18, (20 - y) * 0.6);
    for (final (x, gy) in [(5.0, 2.0), (12.0, 1.0), (17.0, 3.0)]) {
      pxRect(c, sandShade, x, y + gy, 1, 1);
    }
  }

  if (f == 0) {
    // Only a heap of sand, a tuft of white hair and two eyes in the dark
    mound(14);
    pxRect(c, hair, 13, 12, 4, 2);
    pxRect(c, hairShade, 15, 11, 2, 1);
    pxRect(c, dark, 7, 15, 6, 1);
    pxRect(c, eye, 8, 15, 1, 1);
    pxRect(c, eye, 11, 15, 1, 1);
    return;
  }
  if (f == 1) {
    // Head and shoulders break out of the heap
    pxOval(c, skin, 7, 9, 12, 9);
    pxPoly(c, hair, [const Offset(6, 6), const Offset(11, 5), const Offset(19, 9), const Offset(20, 14), const Offset(14, 11), const Offset(8, 10)]);
    pxOval(c, skin, 4, 7, 8, 7);
    pxRect(c, dark, 5, 9, 4, 1);
    pxRect(c, eye, 5, 10, 1, 1);
    pxRect(c, eye, 8, 10, 1, 1);
    pxRect(c, mouth, 5, 12, 4, 1);
    mound(15);
    return;
  }

  final leap = f == 6;
  final ph = (f - 2) * math.pi / 2;
  final stride = leap ? 0.0 : (math.sin(ph) * 2).roundToDouble();
  final bob = leap ? -2.0 : (f.isOdd ? 1.0 : 0.0);

  // A donkey's leg: thigh, a backward-bent shin and a hoof. Trailing straight out in the pounce.
  void leg(Color col, double s) {
    if (leap) {
      pxRect(c, col, 15, 11 + s, 5, 3);
      pxRect(c, hoof, 20, 11 + s, 2, 3);
      return;
    }
    pxRect(c, col, 14 + s, 12 + bob, 4, 3);
    pxRect(c, col, 16 + s, 15 + bob, 2, 4 - bob);
    pxRect(c, hoof, 15 + s, 19, 3, 2);
  }

  void arm(Color col, Offset hand) {
    final sh = Offset(9, 10 + bob);
    pxPoly(c, col, [sh + const Offset(-1, -1), sh + const Offset(2, 0), hand + const Offset(1, 0), hand + const Offset(-1, 0)]);
  }

  // Far leg and far arm behind everything
  leg(shade, leap ? 0 : -stride);
  arm(shade, leap ? const Offset(4, 12) : Offset(7 + stride, 19));
  leg(skin, leap ? 3 : stride);
  // Ragged loincloth
  pxPoly(c, rags, [Offset(13, 11 + bob), Offset(19, 10 + bob), Offset(19, 14 + bob), Offset(17, 15 + bob), Offset(16, 13 + bob), Offset(14, 15 + bob)]);
  // Hunched, starved body: ribs show along the flank, the spine ridges along the back
  pxOval(c, skin, 6, 6 + bob, 14, 8);
  pxRect(c, shade, 11, 13 + bob, 6, 1);
  for (final x in [10.0, 12.0, 14.0]) {
    pxRect(c, shade, x, 9 + bob, 1, 3);
  }
  for (final x in [15.0, 17.0]) {
    pxRect(c, shade, x, 6 + bob, 1, 1);
  }
  // A wild white mane falls from the crown down the neck
  final tail = leap ? 2.0 : stride.abs() * 0.5;
  pxPoly(c, hair, [Offset(2, 4 + bob), Offset(7, 2 + bob), Offset(12, 4 + bob), Offset(15 + tail, 8 + bob), Offset(11, 8 + bob), Offset(5, 6 + bob)]);
  pxRect(c, hairShade, 8, 4 + bob, 3, 1);
  pxRect(c, hairShade, 11, 6 + bob, 2, 1);
  // Head thrust low and forward, with a pointed ear
  pxOval(c, skin, 1, 5 + bob, 9, 7);
  pxPoly(c, skin, [Offset(7, 6 + bob), Offset(10, 3 + bob), Offset(9, 7 + bob)]);
  pxRect(c, dark, 2, 7 + bob, 5, 1);
  pxRect(c, eye, 2, 8 + bob, 2, 1);
  pxRect(c, eye, 5, 8 + bob, 1, 1);
  pxRect(c, mouth, 1, 10 + bob, 5, 1);
  pxRect(c, hair, 2, 11 + bob, 1, 1);
  pxRect(c, hair, 4, 11 + bob, 1, 1);
  // Long near arm: clawing at the ground, or reaching out in the pounce
  final hand = leap ? const Offset(2, 9) : Offset(3 - stride, 19);
  arm(skin, hand);
  if (leap) {
    pxRect(c, hair, 1, 8, 1, 3);
  } else {
    pxRect(c, hair, math.max(1, hand.dx - 2), 20, 3, 1);
  }
}

// The scorpion: amber armour, raised pincers, a curled tail with a red sting. Faces left.
// Frames: 0-1 scuttle, 2 sting thrust forward over the head.
void _drawScorpion(Canvas c, int f) {
  const shell = Color(0xffb8762a), shade = Color(0xff7a4a18), light = Color(0xffe8b060);
  const sting = Color(0xffd83a2a), eye = Color(0xff1a1020), leg = Color(0xff5a3410);
  final strike = f == 2;
  // Four pairs of legs, stepping in turn
  for (var i = 0; i < 4; i++) {
    final step = (i + f).isEven ? 0.0 : 1.0;
    pxRect(c, leg, 5 + i * 2 - step, 9, 1, 2);
  }
  // Pincers on short arms
  pxRect(c, shade, 3, 7, 3, 1);
  pxOval(c, shell, 0, strike ? 5 : 6, 4, 3);
  pxRect(c, shade, 0, strike ? 6 : 7, 1, 1);
  // Segmented body
  pxOval(c, shell, 4, 5, 9, 5);
  pxRect(c, light, 5, 6, 3, 1);
  for (final x in [8.0, 10.0]) {
    pxRect(c, shade, x, 5, 1, 4);
  }
  pxRect(c, eye, 5, 6, 1, 1);
  // The tail: curled up over the back, or thrown forward over the head
  final segs = strike
      ? const [Offset(12, 5), Offset(13, 2), Offset(11, 0.5), Offset(8, 0.5)]
      : const [Offset(12, 6), Offset(14, 4), Offset(15, 2), Offset(14, 0.5)];
  for (final o in segs) {
    pxRect(c, shell, o.dx, o.dy, 2, 2);
  }
  pxRect(c, shade, segs[1].dx, segs[1].dy + 1, 2, 1);
  final tip = segs.last;
  pxRect(c, sting, strike ? tip.dx - 2 : tip.dx - 2, tip.dy + (strike ? 1 : 0.5), 2, 1);
}

// The man-eater: a red lion's body, a dark mane round a bearded human face with three rows of
// teeth, and a scorpion's tail tipped with spikes. Faces left.
// Frames: 0-3 prowl, 4 roar, 5 charge.
void _drawManticore(Canvas c, int f) {
  const fur = Color(0xffb8442a), shade = Color(0xff7a2a1a), light = Color(0xffd87a4a), mane = Color(0xff4a2016);
  const skin = Color(0xffd8a070), skinShade = Color(0xffa8704a), eye = Color(0xffffe060), mouth = Color(0xff5a0a0a);
  const teeth = Color(0xfff8f0e0), tail = Color(0xff6a3a2a), spike = Color(0xffe8dcc0), paw = Color(0xff3a1a10), dark = Color(0xff1a1020);
  final roar = f == 4, charge = f == 5;
  final st = roar || charge ? 0.0 : (math.sin(f * math.pi / 2) * 2).roundToDouble();
  final bob = roar || charge ? 0.0 : (f.isOdd ? 1.0 : 0.0);

  void leg(Color col, double hipX, double footX) {
    pxPoly(c, col, [Offset(hipX - 2, 21 + bob), Offset(hipX + 3, 21 + bob), Offset(footX + 2, 29), Offset(footX - 2, 29)]);
    pxRect(c, paw, footX - 3, 29, 6, 2);
  }

  // Far legs
  leg(shade, 15, charge ? 8 : 14 - st);
  leg(shade, 32, charge ? 39 : 32 + st);
  // Scorpion tail arching up from the rump
  final segs = charge
      ? const [Offset(37, 14), Offset(40, 12), Offset(41, 9), Offset(40, 6), Offset(37, 4)]
      : roar
          ? const [Offset(37, 14), Offset(40, 10), Offset(40, 5), Offset(37, 2), Offset(32, 1.5)]
          : [Offset(37, 14), Offset(40, 11 + bob), Offset(41, 7 + bob), Offset(39, 3 + bob), Offset(35, 2 + bob)];
  for (var i = 0; i < segs.length; i++) {
    final r = 3.0 - i * 0.3;
    pxOval(c, tail, segs[i].dx - r, segs[i].dy - r, r * 2, r * 2);
    pxRect(c, spike, segs[i].dx, segs[i].dy - r - 1, 1, 1);
  }
  final end = segs.last;
  pxPoly(c, dark, [end + const Offset(0, -1.5), end + const Offset(0, 1.5), end + const Offset(-5, 0)]);
  pxRect(c, spike, end.dx - 2, end.dy - 3, 1, 2);
  pxRect(c, spike, end.dx - 1, end.dy + 2, 1, 2);
  // Body: a long lion's barrel with a pale belly
  pxOval(c, fur, 10, 12 + bob, 29, 12);
  pxOval(c, light, 15, 19 + bob, 18, 4);
  pxRect(c, shade, 22, 13 + bob, 10, 1);
  // Near legs
  leg(fur, 18, charge ? 11 : 17 + st);
  leg(fur, 34, charge ? 40 : 34 - st);
  // Mane and face
  pxOval(c, mane, 1, 5 + bob, 17, 19);
  pxOval(c, skin, 3, 9 + bob, 11, 12);
  pxRect(c, skinShade, 3, 18 + bob, 11, 2);
  pxRect(c, dark, 4, 12 + bob, 3, 1);
  pxRect(c, dark, 9, 12 + bob, 3, 1);
  pxRect(c, eye, 4, 13 + bob, 2, 1);
  pxRect(c, eye, 9, 13 + bob, 2, 1);
  pxRect(c, skinShade, 7, 14 + bob, 2, 3);
  if (roar || charge) {
    // Jaws wide open: three rows of teeth
    pxRect(c, mouth, 4, 17 + bob, 7, 5);
    for (final y in [17.0, 19.0, 21.0]) {
      for (var x = 4.0; x < 11; x += 2) {
        pxRect(c, teeth, x, y + bob, 1, 1);
      }
    }
  } else {
    pxRect(c, mouth, 5, 18 + bob, 5, 1);
    pxRect(c, teeth, 5, 17 + bob, 5, 1);
  }
  // A forked beard under the jaw
  pxPoly(c, mane, [Offset(4, 21 + bob), Offset(11, 21 + bob), Offset(9, 26 + bob), Offset(7.5, 24 + bob), Offset(6, 26 + bob)]);
}

// ---------- The Reed Lion (boss) ----------
const _lionPal = {'y': '#d9a441', 'Y': '#f0c870', 'm': '#8a4a1a', 'M': '#5a2a0e', 'k': '#1a1010', 'w': '#ffffff', 'r': '#a01818'};
const _lionTop = [
  '........................mmmmmm..........',
  '......................mmMmmmMmmm........',
  '.....................mMmmmmmmmMmm.......',
  '....................mmmmmYYYYmmmmm......',
  '...................mMmmYYYYYYYYmmMm.....',
  '...................mmmYYYYkYYYYYYmm.....',
  '..................mMmmYYYYYYYYYYYYYY....',
  '..................mmmYYYYYYYYYYYkkYY....',
  '..y...............mMmmYYYYYYYYYrwwwY....',
  '.yy...............mmmmYYYYYYYYYrrrr.....',
  'yy...yyyyyyyyyyyyymmMmmYYYYYYYwww.......',
  'y...yyyyyyyyyyyyyyymmmmmmYYYYYY.........',
  'y..yyYYYYYYYYYYYYyyymMmmmmmmmm..........',
  'yyyyYYYYYYYYYYYYYYYyymmMmmmmm...........',
  '.yyyyYYYYYYYYYYYYYYYyyymmmm.............',
  '..yyyyyyyyyyyyyyyyyyyyyyyy..............',
  '...yyyyyyyyyyyyyyyyyyyyyy...............',
];
const _lionF1 = [
  ..._lionTop,
  '...yyy.yyy.......yyy.yyy................',
  '...yyy.yyy.......yyy.yyy................',
  '...yyy.yyy.......yyy.yyy................',
  '...yyy.yyy.......yyy.yyy................',
  '..yyyy.yyyy.....yyyy.yyyy...............',
  '..kkkk.kkkk.....kkkk.kkkk...............',
  '........................................',
];
const _lionF2 = [
  ..._lionTop,
  '....yyy..yyy....yyy...yyy...............',
  '....yyy..yyy...yyy....yyy...............',
  '...yyy....yyy..yyy.....yyy..............',
  '...yyy....yyy.yyy......yyy..............',
  '..yyyy....yyyyyyy......yyyy.............',
  '..kkkk....kkkkkkk......kkkk.............',
  '........................................',
];

// ---------- Small objects ----------
const _coin = ['.gggg.', 'gGGggd', 'gGgggd', 'ggggdd', 'gggddd', '.dddd.'];
const _coinPal = {'g': '#d4a845', 'G': '#f7d774', 'd': '#9a7420'};

const _heart = ['.rr...rr.', 'rRRr.rrrr', 'rRrrrrrrr', 'rrrrrrrrr', '.rrrrrrr.', '..rrrrr..', '...rrr...', '....r....'];
const _heartPal = {'r': '#d83a3a', 'R': '#ff9a8a', 'e': '#3a2a3a'};
List<String> _toEmpty(List<String> rows, int fromCol) => [
      for (final r in rows)
        [for (var x = 0; x < r.length; x++) r[x] != '.' && x >= fromCol ? 'e' : r[x]].join(),
    ];

const _vase = [
  '...dddd...', '...cCCc...', '....cc....', '..cCCCCc..', '.cCCcccccd', '.clwlwlwld',
  '.cCcccccd.', 'cCCccccccd', 'cCcccccccd', '.ccccccdd.', '..cccddd..', '...dddd...',
];
const _vasePal = {'c': '#b8683a', 'C': '#d8905a', 'd': '#7a3a1a', 'l': '#1b2a6b', 'w': '#f2e6c9'};

const _bush = [
  '......GGG.......', '...GGGGgGGG.....', '..GGgGGGGgGGG...', '.GGGGfGGGGGgGG..', 'GGgGGGGGGfGGGGG.',
  'GgGGGGgGGGGGgGGG', 'dGGGgGGGGgGGGGGd', 'ddGGGGdGGGGGdGdd', '.ddddddddddddd..', '..dd.ddd.ddd....',
];
const _bushPal = {'g': '#3f7a34', 'G': '#5aa04a', 'd': '#2a5424', 'f': '#e85a7a'};

const _feather = ['..tttt......', '.tTTTTtttt..', 'gggggggggggg', '.tTTTTtttt..', '..tttt......'];
const _featherPal = {'t': '#2bb3a8', 'T': '#8ae0d8', 'g': '#d4a845'};

const _sign = [
  'WWWWWWWWWWWW', 'WddddddddddW', 'WdWWWWWWWWdW', 'WdWddddddWdW', 'WdWWWWWWWWdW', 'WddddddddddW', 'WWWWWWWWWWWW',
  '.....ww.....', '.....ww.....', '.....ww.....', '.....ww.....', '.....ww.....', '....wwww....', '...wwwwww...',
];
const _signPal = {'w': '#6a4420', 'W': '#b07a3a', 'd': '#7a5028'};

const _chestClosed = [
  '..............', '..............', '.dddddddddddd.', 'dbbbbbbbbbbbbd', 'dggggggggggggd',
  'dbbbbbgGbbbbbd', 'dbbbbbggbbbbbd', 'dggggggggggggd', 'dbbbbbbbbbbbbd', '.dddddddddddd.',
];
const _chestOpen = [
  '.dddddddddddd.', 'dbbbbbbbbbbbbd', 'dggggggggggggd', 'dkkkkkkkkkkkkd', 'dggggggggggggd',
  'dbbbbbbbbbbbbd', 'dbbbbbbbbbbbbd', 'dggggggggggggd', 'dbbbbbbbbbbbbd', '.dddddddddddd.',
];
const _chestPal = {'d': '#3a2010', 'b': '#8a5a2a', 'g': '#d4a845', 'G': '#fff0a0', 'k': '#1a1010'};

const _altar = [
  '..gggggggggggg..', '...gSSSSSSSSg...', '....sSSSSSSs....', '.....ssssss.....', '......SSSS......',
  '......SllS......', '......SSSS......', '......SllS......', '......SSSS......', '.....SSSSSS.....',
  '....ssssssss....', '...SSSSSSSSSS...', '..ssssssssssss..', '..ssssssssssss..',
];
const _altarPal = {'S': '#c8b8a0', 's': '#8a7a68', 'g': '#d4a845', 'l': '#2bb3a8'};

const _flame = [
  '...r....', '...rr...', '..rorr..', '..roor..', '.rooyor.', '.royyor.', 'rooyyoor', 'royyyyor', '.rooyor.', '..rrrr..',
];
const _flamePal = {'y': '#ffe066', 'o': '#ff9a2a', 'r': '#e0402a'};

// ---------- Canvas helpers (the Canvas 2D calls the original art was drawn with) ----------

Paint _fill(Color c) => Paint()
  ..color = c
  ..isAntiAlias = false;

void _rect(Canvas c, Color col, double x, double y, double w, double h) => c.drawRect(Rect.fromLTWH(x, y, w, h), _fill(col));

Paint _stroke(Color c, double w) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w;

const _white = Color(0xffffffff);

// All generated textures
class Art {
  Art._();

  late Sheet hero, demon, fly, ghoul, scorpion, manticore, lion, coin, heart, vase, bush, feather, sign, chest, altar, flame;
  late Sheet px, xp, slash, tiles, wall, gate, gateGlow;
  late Sheet bgSky, bgClouds, bgMountains, bgHills;

  static Future<Art> generate() async {
    final a = Art._();
    a.hero = await pixelSheet([
      [..._heroTop, ..._legs['idle']!],
      [..._heroTop, ..._legs['run1']!],
      [..._heroTop, ..._legs['run2']!],
      [..._heroTop, ..._legs['jump']!],
      [..._heroAttackTop, ..._legs['run1']!],
    ], _heroPal);
    a.demon = await outlinedSheet(22, 26, 5, _drawDemon);
    a.fly = await outlinedSheet(20, 16, 2, _drawFly);
    a.ghoul = await outlinedSheet(24, 22, 7, _drawGhoul);
    a.scorpion = await outlinedSheet(18, 12, 3, _drawScorpion);
    a.manticore = await outlinedSheet(44, 32, 6, _drawManticore);
    a.lion = await pixelSheet([_lionF1, _lionF2], _lionPal);
    a.coin = await pixelSheet([_coin], _coinPal);
    a.heart = await pixelSheet([_heart, _toEmpty(_heart, 5), _toEmpty(_heart, 0)], _heartPal);
    a.vase = await pixelSheet([_vase], _vasePal);
    a.bush = await pixelSheet([_bush], _bushPal);
    a.feather = await pixelSheet([_feather], _featherPal);
    a.sign = await pixelSheet([_sign], _signPal);
    a.chest = await pixelSheet([_chestClosed, _chestOpen], _chestPal);
    a.altar = await pixelSheet([_altar], _altarPal);
    a.flame = await pixelSheet([_flame, mirror(_flame)], _flamePal);

    a.px = await canvasTexture(2, 2, (c, w, h) => _rect(c, _white, 0, 0, 2, 2));
    a.xp = await canvasTexture(5, 5, (c, w, h) {
      final t = hex('#8ae0d8');
      _rect(c, t, 2, 0, 1, 5);
      _rect(c, t, 0, 2, 5, 1);
      _rect(c, t, 1, 1, 3, 3);
      _rect(c, _white, 2, 2, 1, 1);
    });
    a.slash = await canvasTexture(26, 26, (c, w, h) {
      final outer = _stroke(const Color.fromRGBO(255, 250, 235, 0.95), 4)..strokeCap = StrokeCap.round;
      c.drawArc(Rect.fromCircle(center: const Offset(5, 13), radius: 16), -1.15, 2.3, false, outer);
      final inner = _stroke(hex('#f7d774'), 1.5)..strokeCap = StrokeCap.round;
      c.drawArc(Rect.fromCircle(center: const Offset(5, 13), radius: 13), -1.0, 2.0, false, inner);
    });

    a.tiles = await _drawTiles();
    a.wall = await _drawWall();
    a.gate = await _drawGate();
    a.gateGlow = await _drawGateGlow();
    await _drawBackgrounds(a);
    return a;
  }
}

Future<Sheet> _drawTiles() => canvasTexture(16 * 5, 16, (c, w, h) {
      final r = rng(7);
      void dirt(double ox) {
        _rect(c, hex('#6b4a2e'), ox, 0, 16, 16);
        for (var i = 0; i < 16; i++) {
          final col = r() < 0.5 ? hex('#5a3c24') : hex('#7d5836');
          _rect(c, col, ox + (r() * 15).floor(), (r() * 15).floorToDouble(), 2, 1);
        }
        _rect(c, hex('#8a6a4a'), ox + 3, 10, 2, 2);
        _rect(c, hex('#8a6a4a'), ox + 11, 4, 2, 1);
      }

      // 0: grass
      dirt(0);
      _rect(c, hex('#3f7a34'), 0, 0, 16, 5);
      _rect(c, hex('#5aa04a'), 0, 0, 16, 3);
      _rect(c, hex('#8ad06a'), 0, 0, 16, 1);
      for (var x = 0; x < 16; x += 2) {
        _rect(c, hex('#3f7a34'), x.toDouble(), 5, 1, x % 4 == 0 ? 2 : 1);
        _rect(c, hex('#2a5424'), x + 1.0, 5, 1, 1);
      }
      _rect(c, hex('#e85a7a'), 4, 1, 1, 1);
      _rect(c, hex('#f0d060'), 11, 1, 1, 1);
      // 1: dirt
      dirt(16);
      // 2: one-way platform (wooden beam, gold trim)
      _rect(c, hex('#d4a845'), 32, 0, 16, 1);
      _rect(c, hex('#8a5a2a'), 32, 1, 16, 4);
      _rect(c, hex('#6a4420'), 32, 5, 16, 1);
      _rect(c, hex('#1b2a6b'), 34, 2, 2, 2);
      _rect(c, hex('#1b2a6b'), 44, 2, 2, 2);
      _rect(c, hex('#6a4420'), 35, 6, 2, 3);
      _rect(c, hex('#6a4420'), 43, 6, 2, 3);
      // 3: stone brick
      _rect(c, hex('#7a6448'), 48, 0, 16, 16);
      _rect(c, hex('#b89a70'), 49, 1, 14, 6);
      _rect(c, hex('#b89a70'), 48, 9, 6, 6);
      _rect(c, hex('#b89a70'), 56, 9, 8, 6);
      _rect(c, hex('#d0b48a'), 49, 1, 14, 1);
      _rect(c, hex('#d0b48a'), 48, 9, 6, 1);
      _rect(c, hex('#d0b48a'), 56, 9, 8, 1);
      // Glazed tile: a lapis diamond with a turquoise heart, like the old mosque walls
      for (final (dx, dy, w) in [(0.0, -2.0, 2.0), (-2.0, 0.0, 6.0), (-1.0, -1.0, 4.0), (-1.0, 1.0, 4.0), (0.0, 2.0, 2.0)]) {
        _rect(c, hex('#1b2a6b'), 55 + dx, 4 + dy, w, 1);
      }
      _rect(c, hex('#2bb3a8'), 55, 3, 2, 3);
      _rect(c, hex('#8ae0d8'), 55, 3, 1, 1);
      // 4: thorn bush (transparent background)
      for (var i = 0; i < 4; i++) {
        final bx = 64.0 + i * 4;
        _rect(c, hex('#5a2a2a'), bx + 1, 6, 2, 10);
        _rect(c, hex('#c8c0b0'), bx + 1, 3, 1, 3);
        _rect(c, hex('#c8c0b0'), bx + 2, 1, 1, 3);
        _rect(c, hex('#7a3a3a'), bx, 9, 1, 1);
        _rect(c, hex('#7a3a3a'), bx + 3, 12, 1, 1);
      }
      _rect(c, hex('#2a5424'), 64, 13, 16, 3);
    }, frames: 5);

Future<Sheet> _drawWall() => canvasTexture(16, 224, (c, w, h) {
      _rect(c, hex('#5a4a38'), 0, 0, w, h);
      for (var y = 0; y < h; y += 8) {
        final row = y ~/ 8;
        final off = row % 2 == 1 ? 4 : 0;
        for (var x = -off; x < w; x += 8) {
          _rect(c, row % 6 == 2 ? hex('#2a4a9a') : hex('#a88a60'), x + 1.0, y + 1.0, 7, 6);
          _rect(c, const Color.fromRGBO(255, 255, 255, 0.15), x + 1.0, y + 1.0, 7, 1);
        }
      }
      _rect(c, hex('#d4a845'), 0, 0, w, 2);
    });

// Pointed arch gate
Future<Sheet> _drawGate() => canvasTexture(40, 56, (c, w, h) {
      _rect(c, hex('#d4a845'), 0, 0, w, h);
      _rect(c, hex('#1b2a6b'), 2, 2, w - 4, h - 2);
      for (var y = 6.0; y < h; y += 8) {
        for (var x = 5.0; x < w - 4; x += 8) {
          _rect(c, hex('#2bb3a8'), x, y, 2, 2);
        }
      }
      _rect(c, hex('#d4a845'), 2, 8, w - 4, 1);
      // arch opening
      c.drawPath(
        Path()
          ..moveTo(8, h)
          ..lineTo(8, 26)
          ..quadraticBezierTo(8, 14, 20, 10)
          ..quadraticBezierTo(32, 14, 32, 26)
          ..lineTo(32, h)
          ..close(),
        Paint()..color = hex('#d4a845'),
      );
      c.drawPath(
        Path()
          ..moveTo(10, h)
          ..lineTo(10, 27)
          ..quadraticBezierTo(10, 16, 20, 12.5)
          ..quadraticBezierTo(30, 16, 30, 27)
          ..lineTo(30, h)
          ..close(),
        Paint()..color = hex('#120a1a'),
      );
    });

Future<Sheet> _drawGateGlow() => canvasTexture(20, 44, (c, w, h) {
      final paint = Paint()
        ..shader = Gradient.linear(
          Offset.zero,
          Offset(0, h),
          const [Color.fromRGBO(255, 240, 180, 0), Color.fromRGBO(255, 230, 150, 0.8), Color.fromRGBO(255, 250, 220, 1)],
          const [0, 0.5, 1],
        );
      c.drawPath(
        Path()
          ..moveTo(0, h)
          ..lineTo(0, 15)
          ..quadraticBezierTo(0, 4, 10, 0.5)
          ..quadraticBezierTo(20, 4, 20, 15)
          ..lineTo(20, h)
          ..close(),
        paint,
      );
    });

Future<void> _drawBackgrounds(Art a) async {
  const iw = 480;
  const ih = 270;

  a.bgSky = await canvasTexture(iw, ih, (c, W, H) {
    c.drawRect(
      Rect.fromLTWH(0, 0, W, H),
      Paint()
        ..shader = Gradient.linear(
          Offset.zero,
          Offset(0, H),
          [hex('#16225a'), hex('#3a5aa8'), hex('#e9c98f'), hex('#f2e0b0')],
          const [0, 0.45, 0.8, 1],
        ),
    );
    final r = rng(3);
    for (var i = 0; i < 40; i++) {
      _rect(c, const Color.fromRGBO(255, 245, 210, 0.8), (r() * W).floorToDouble(), (r() * 90).floorToDouble(), 1, 1);
    }
    // The ornamental golden sun; its eye is drawn live over it, so it can follow Ra
    paintSunDisc(c, const Offset(360, 80), 1);
  });

  // Curly ribbon clouds
  a.bgClouds = await canvasTexture(iw, ih, (c, W, H) {
    final r = rng(11);
    final fill = Paint()..color = hex('#f2e6c9');
    final line = _stroke(hex('#d4a845'), 1);
    void cloud(double x, double y, double s) {
      for (final dx in [-W, 0.0, W]) {
        const blobs = [[0.0, 0.0, 8.0], [10.0, -4.0, 10.0], [22.0, 0.0, 8.0], [14.0, 4.0, 7.0], [-8.0, 3.0, 6.0]];
        for (final b in blobs) {
          final o = Offset(x + dx + b[0] * s, y + b[1] * s);
          c.drawCircle(o, b[2] * s, fill);
          c.drawCircle(o, b[2] * s, line);
        }
        for (final b in blobs) {
          c.drawCircle(Offset(x + dx + b[0] * s, y + b[1] * s), b[2] * s - 1, fill);
        }
        c.drawArc(Rect.fromCircle(center: Offset(x + dx + 10 * s, y - 4 * s), radius: 4 * s), 0, math.pi * 1.5, false, line);
        c.drawPath(
          Path()
            ..moveTo(x + dx + 26 * s, y)
            ..quadraticBezierTo(x + dx + 36 * s, y + 6 * s, x + dx + 44 * s, y),
          line,
        );
      }
    }

    for (var i = 0; i < 6; i++) {
      cloud(i * 80 + r() * 30, 30 + r() * 70, 0.7 + r() * 0.5);
    }
  });

  // Rocks as the old miniatures paint them: domes of stone nested inside each other,
  // each layer paler than the one below, with a dark contour and scalloped tops
  a.bgMountains = await canvasTexture(iw, ih, (c, W, H) {
    final r = rng(21);
    void layer(double cx, double base, double w, double h, Color fill, Color edge, Color light) {
      for (final dx in [-W, 0.0, W]) {
        final x0 = cx + dx;
        double top(double x) => base - h * math.pow(math.max(0.0, 1 - math.pow((x - x0) / w, 2)), 0.6);
        final p = Path()..moveTo(x0 - w, base);
        const bump = 9.0;
        for (var x = x0 - w; x < x0 + w - 0.1; x += bump) {
          final nx = math.min(x0 + w, x + bump);
          p.quadraticBezierTo((x + nx) / 2, math.min(top(x), top(nx)) - bump * 0.55, nx, top(nx));
        }
        p.close();
        c.drawPath(p, Paint()..color = fill);
        c.drawPath(p, _stroke(edge, 1.2));
        // A pale rim on the sunlit left of each dome
        c.save();
        c.clipPath(p);
        c.drawPath(p.shift(const Offset(2, 2)), _stroke(light, 1.5));
        c.restore();
      }
    }

    void rock(double cx, double base, double w, double h, List<String> pal) {
      for (var k = 0; k < 4; k++) {
        layer(cx + (k.isEven ? -1 : 1) * w * 0.08 * k, base + k * 2, w * (1 - 0.2 * k), h * (1 - 0.22 * k),
            hex(pal[k]), hex(pal[4]), hex(pal[5]));
      }
    }

    const far = ['#7a6aa8', '#8a7ab8', '#9a8cc6', '#ac9ed2', '#4a3a6a', '#c8bce8'];
    const near = ['#a8708a', '#b8829a', '#c896aa', '#d8aabb', '#5a2e48', '#f0d0dc'];
    const ochre = ['#a8804a', '#ba9458', '#cca86a', '#dcbc80', '#5a3e1e', '#f4dca8'];
    for (var i = 0; i < 6; i++) {
      rock(i * 80 + r() * 30, 250, 34 + r() * 20, 95 + r() * 40, far);
    }
    for (var i = 0; i < 5; i++) {
      rock(i * 96 + 40 + r() * 30, 262, 30 + r() * 18, 70 + r() * 30, i.isEven ? near : ochre);
    }
  });

  // Turquoise hills and cypress trees
  a.bgHills = await canvasTexture(iw, ih, (c, W, H) {
    final r = rng(33);
    void hill(String color, double base, double amp, double freq, double phase) {
      final p = Path()..moveTo(0, H);
      for (var x = 0.0; x <= W; x += 4) {
        p.lineTo(x, base - math.sin((x / W) * math.pi * 2 * freq + phase) * amp);
      }
      p
        ..lineTo(W, H)
        ..close();
      c.drawPath(p, Paint()..color = hex(color));
    }

    hill('#2b8a78', 205, 14, 2, 0.5);
    void cypress(double x, double y, double hgt) {
      for (final dx in [-W, 0.0, W]) {
        c.drawOval(Rect.fromCenter(center: Offset(x + dx, y - hgt / 2), width: 8, height: hgt), Paint()..color = hex('#1a4a3a'));
        c.drawOval(Rect.fromCenter(center: Offset(x + dx - 1, y - hgt / 2), width: 4, height: hgt - 4), Paint()..color = hex('#245e4a'));
      }
    }

    for (var i = 0; i < 9; i++) {
      final x = i * 53 + r() * 20;
      cypress(x, 212 - math.sin((x / W) * math.pi * 4 + 0.5) * 14, 22 + r() * 16);
    }
    // Plane trees with round crowns and slim poplars between the cypresses
    void plane(double x, double y, double s) {
      for (final dx in [-W, 0.0, W]) {
        c.drawRect(Rect.fromLTWH(x + dx - 1, y - 8 * s, 2, 8 * s), Paint()..color = hex('#3a2a1a'));
        for (final (ox, oy, rr) in [(0.0, -14.0, 7.0), (-6.0, -10.0, 5.0), (6.0, -10.0, 5.0), (0.0, -19.0, 5.0)]) {
          c.drawCircle(Offset(x + dx + ox * s, y + oy * s), rr * s, Paint()..color = hex('#2f6e3e'));
        }
        c.drawCircle(Offset(x + dx - 2 * s, y - 16 * s), 3 * s, Paint()..color = hex('#4a9a52'));
      }
    }

    void poplar(double x, double y, double hgt) {
      for (final dx in [-W, 0.0, W]) {
        c.drawOval(Rect.fromCenter(center: Offset(x + dx, y - hgt / 2), width: 5, height: hgt), Paint()..color = hex('#5a8a3a'));
        c.drawOval(Rect.fromCenter(center: Offset(x + dx - 1, y - hgt / 2 - 1), width: 2, height: hgt - 6), Paint()..color = hex('#8ab85a'));
      }
    }

    for (var i = 0; i < 6; i++) {
      final x = i * 80 + 30 + r() * 30;
      final y = 220 - math.sin((x / W) * math.pi * 4 + 0.5) * 6;
      r() < 0.5 ? plane(x, y, 0.9 + r() * 0.3) : poplar(x, y, 26 + r() * 10);
    }
    hill('#1f6a5c', 228, 8, 3, 1.7);
  });
}
