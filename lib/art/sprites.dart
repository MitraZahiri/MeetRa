import 'dart:math' as math;
import 'dart:ui';

import 'pixel.dart';

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

// ---------- Hollow imp ----------
const _impPal = {'G': '#4a8a3a', 'H': '#2e5a26', 'h': '#e8dcc0', 'y': '#ffd23a', 'R': '#9a1a1a', 'n': '#6a3a1a'};
const _impTop = [
  '..h........h..',
  '..hh......hh..',
  '...hHGGGGHh...',
  '...GGGGGGGG...',
  '..GGyGGGGyGG..',
  '..GGGGGGGGGG..',
  '..GGRhRRhRGG..',
  '...GGGGGGGG...',
  '.GGGGGGGGGGGG.',
  'GG.GGGGGGGG.GG',
  'G..GGGGGGGG..G',
  '...nnnnnnnn...',
];
const _impF1 = [..._impTop, '...GGG..GGG...', '...GG....GG...', '..HHH....HHH..', '..............'];
const _impF2 = [..._impTop, '....GGG.GG....', '....GG..GG....', '...HHH..HHH...', '..............'];

// ---------- Bat ----------
const _batPal = {'p': '#4b2a5e', 'P': '#7a4a8e', 'y': '#ff4040'};
const _batF1 = [
  'P............P',
  'PP....pp....PP',
  '.PPP.pppp.PPP.',
  '..PPpyppypPP..',
  '....pppppp....',
  '.....pppp.....',
  '......pp......',
  '..............',
];
const _batF2 = [
  '..............',
  '......pp......',
  '.....pppp.....',
  '....pyppyp....',
  '..PPpppppPP...',
  '.PPP.pppp.PPP.',
  'PP....pp....PP',
  'P............P',
];

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

  late Sheet hero, imp, bat, lion, coin, heart, vase, bush, feather, sign, chest, altar, flame;
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
    a.imp = await pixelSheet([_impF1, _impF2], _impPal);
    a.bat = await pixelSheet([_batF1, _batF2], _batPal);
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
    // ornamental golden sun
    final gold = Paint()..color = hex('#d4a845');
    for (var i = 0; i < 16; i++) {
      final ang = (i / 16) * math.pi * 2;
      c.drawPath(
        Path()
          ..moveTo(360 + math.cos(ang - 0.12) * 24, 80 + math.sin(ang - 0.12) * 24)
          ..lineTo(360 + math.cos(ang) * 34, 80 + math.sin(ang) * 34)
          ..lineTo(360 + math.cos(ang + 0.12) * 24, 80 + math.sin(ang + 0.12) * 24)
          ..close(),
        gold,
      );
    }
    c.drawCircle(const Offset(360, 80), 22, Paint()..color = hex('#f7d774'));
    c.drawCircle(const Offset(360, 80), 17, _stroke(hex('#d4a845'), 2));
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

  // Stylized violet mountains
  a.bgMountains = await canvasTexture(iw, ih, (c, W, H) {
    final r = rng(21);
    final pts = <List<double>>[];
    for (var x = 0.0; x <= W; x += 24) {
      pts.add([x, 140 + r() * 60]);
    }
    pts.last[1] = pts.first[1];
    final body = Path()..moveTo(0, H);
    for (final p in pts) {
      body.lineTo(p[0], p[1]);
    }
    body
      ..lineTo(W, H)
      ..close();
    c.drawPath(body, Paint()..color = hex('#5a4a8a'));
    final ridge = Path()..moveTo(pts[0][0], pts[0][1]);
    for (final p in pts.skip(1)) {
      ridge.lineTo(p[0], p[1]);
    }
    c.drawPath(ridge, _stroke(hex('#9a8ac8'), 2));
    final dots = Paint()..color = hex('#7a6aa8');
    for (var i = 0; i < 30; i++) {
      final x = r() * W;
      final y = 190 + r() * 70;
      c.drawCircle(Offset(x, y), 3 + r() * 5, dots);
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
    hill('#1f6a5c', 228, 8, 3, 1.7);
  });
}
