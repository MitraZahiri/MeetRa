import { pixelSheet, canvasTexture, rng, mirror } from './pixel.js';

// Placeholder art for the prototype. Final hand-drawn sprites arrive in M1.

// ---------- Ra (hero) ----------
const HERO_PAL = {
  k: '#1a1020', s: '#e0a878', b: '#2a1a14', o: '#d9822b', t: '#3a2010',
  r: '#b83a2e', g: '#d4a845', w: '#f2e6c9', l: '#1b2a6b', m: '#9aa4b0', n: '#5a3420', e: '#000000',
};
const HERO_TOP = [
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
const HERO_ATTACK_TOP = HERO_TOP.map((r, i) =>
  i === 7 ? '.rrooototoss' : i === 8 ? '.rrotoooooss' : i === 9 ? '.rrooototo..' : r,
);
const LEGS = {
  idle: ['....oo..oo..', '....ll..ll..', '....nn..nn..', '...nnn..nnn.'],
  run1: ['...oo...oo..', '..ll.....ll.', '.nn......nn.', '.nn.......nn'],
  run2: ['....oooo....', '.....ll.....', '.....nn.....', '....nnn.....'],
  jump: ['....oo.oo...', '...ll..ll...', '...nn...nn..', '............'],
};

// ---------- Hollow imp ----------
const IMP_PAL = { G: '#4a8a3a', H: '#2e5a26', h: '#e8dcc0', y: '#ffd23a', R: '#9a1a1a', n: '#6a3a1a' };
const IMP_TOP = [
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
const IMP_F1 = [...IMP_TOP, '...GGG..GGG...', '...GG....GG...', '..HHH....HHH..', '..............'];
const IMP_F2 = [...IMP_TOP, '....GGG.GG....', '....GG..GG....', '...HHH..HHH...', '..............'];

// ---------- Bat ----------
const BAT_PAL = { p: '#4b2a5e', P: '#7a4a8e', y: '#ff4040' };
const BAT_F1 = [
  'P............P',
  'PP....pp....PP',
  '.PPP.pppp.PPP.',
  '..PPpyppypPP..',
  '....pppppp....',
  '.....pppp.....',
  '......pp......',
  '..............',
];
const BAT_F2 = [
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
const LION_PAL = { y: '#d9a441', Y: '#f0c870', m: '#8a4a1a', M: '#5a2a0e', k: '#1a1010', w: '#ffffff', r: '#a01818' };
const LION_TOP = [
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
const LION_F1 = [
  ...LION_TOP,
  '...yyy.yyy.......yyy.yyy................',
  '...yyy.yyy.......yyy.yyy................',
  '...yyy.yyy.......yyy.yyy................',
  '...yyy.yyy.......yyy.yyy................',
  '..yyyy.yyyy.....yyyy.yyyy...............',
  '..kkkk.kkkk.....kkkk.kkkk...............',
  '........................................',
];
const LION_F2 = [
  ...LION_TOP,
  '....yyy..yyy....yyy...yyy...............',
  '....yyy..yyy...yyy....yyy...............',
  '...yyy....yyy..yyy.....yyy..............',
  '...yyy....yyy.yyy......yyy..............',
  '..yyyy....yyyyyyy......yyyy.............',
  '..kkkk....kkkkkkk......kkkk.............',
  '........................................',
];

// ---------- Small objects ----------
const COIN = ['.gggg.', 'gGGggd', 'gGgggd', 'ggggdd', 'gggddd', '.dddd.'];
const COIN_PAL = { g: '#d4a845', G: '#f7d774', d: '#9a7420' };

const HEART = ['.rr...rr.', 'rRRr.rrrr', 'rRrrrrrrr', 'rrrrrrrrr', '.rrrrrrr.', '..rrrrr..', '...rrr...', '....r....'];
const HEART_PAL = { r: '#d83a3a', R: '#ff9a8a', e: '#3a2a3a' };
const toEmpty = (rows, fromCol) => rows.map((r) => [...r].map((c, x) => (c !== '.' && x >= fromCol ? 'e' : c)).join(''));

const VASE = [
  '...dddd...', '...cCCc...', '....cc....', '..cCCCCc..', '.cCCcccccd', '.clwlwlwld',
  '.cCcccccd.', 'cCCccccccd', 'cCcccccccd', '.ccccccdd.', '..cccddd..', '...dddd...',
];
const VASE_PAL = { c: '#b8683a', C: '#d8905a', d: '#7a3a1a', l: '#1b2a6b', w: '#f2e6c9' };

const BUSH = [
  '......GGG.......', '...GGGGgGGG.....', '..GGgGGGGgGGG...', '.GGGGfGGGGGgGG..', 'GGgGGGGGGfGGGGG.',
  'GgGGGGgGGGGGgGGG', 'dGGGgGGGGgGGGGGd', 'ddGGGGdGGGGGdGdd', '.ddddddddddddd..', '..dd.ddd.ddd....',
];
const BUSH_PAL = { g: '#3f7a34', G: '#5aa04a', d: '#2a5424', f: '#e85a7a' };

const FEATHER = ['..tttt......', '.tTTTTtttt..', 'gggggggggggg', '.tTTTTtttt..', '..tttt......'];
const FEATHER_PAL = { t: '#2bb3a8', T: '#8ae0d8', g: '#d4a845' };

const SIGN = [
  'WWWWWWWWWWWW', 'WddddddddddW', 'WdWWWWWWWWdW', 'WdWddddddWdW', 'WdWWWWWWWWdW', 'WddddddddddW', 'WWWWWWWWWWWW',
  '.....ww.....', '.....ww.....', '.....ww.....', '.....ww.....', '.....ww.....', '....wwww....', '...wwwwww...',
];
const SIGN_PAL = { w: '#6a4420', W: '#b07a3a', d: '#7a5028' };

const CHEST_CLOSED = [
  '..............', '..............', '.dddddddddddd.', 'dbbbbbbbbbbbbd', 'dggggggggggggd',
  'dbbbbbgGbbbbbd', 'dbbbbbggbbbbbd', 'dggggggggggggd', 'dbbbbbbbbbbbbd', '.dddddddddddd.',
];
const CHEST_OPEN = [
  '.dddddddddddd.', 'dbbbbbbbbbbbbd', 'dggggggggggggd', 'dkkkkkkkkkkkkd', 'dggggggggggggd',
  'dbbbbbbbbbbbbd', 'dbbbbbbbbbbbbd', 'dggggggggggggd', 'dbbbbbbbbbbbbd', '.dddddddddddd.',
];
const CHEST_PAL = { d: '#3a2010', b: '#8a5a2a', g: '#d4a845', G: '#fff0a0', k: '#1a1010' };

const ALTAR = [
  '..gggggggggggg..', '...gSSSSSSSSg...', '....sSSSSSSs....', '.....ssssss.....', '......SSSS......',
  '......SllS......', '......SSSS......', '......SllS......', '......SSSS......', '.....SSSSSS.....',
  '....ssssssss....', '...SSSSSSSSSS...', '..ssssssssssss..', '..ssssssssssss..',
];
const ALTAR_PAL = { S: '#c8b8a0', s: '#8a7a68', g: '#d4a845', l: '#2bb3a8' };

const FLAME = [
  '...r....', '...rr...', '..rorr..', '..roor..', '.rooyor.', '.royyor.', 'rooyyoor', 'royyyyor', '.rooyor.', '..rrrr..',
];
const FLAME_PAL = { y: '#ffe066', o: '#ff9a2a', r: '#e0402a' };

export function generateTextures(scene) {
  pixelSheet(scene, 'hero', [
    [...HERO_TOP, ...LEGS.idle],
    [...HERO_TOP, ...LEGS.run1],
    [...HERO_TOP, ...LEGS.run2],
    [...HERO_TOP, ...LEGS.jump],
    [...HERO_ATTACK_TOP, ...LEGS.run1],
  ], HERO_PAL);
  pixelSheet(scene, 'imp', [IMP_F1, IMP_F2], IMP_PAL);
  pixelSheet(scene, 'bat', [BAT_F1, BAT_F2], BAT_PAL);
  pixelSheet(scene, 'lion', [LION_F1, LION_F2], LION_PAL);
  pixelSheet(scene, 'coin', [COIN], COIN_PAL);
  pixelSheet(scene, 'heart', [HEART, toEmpty(HEART, 5), toEmpty(HEART, 0)], HEART_PAL);
  pixelSheet(scene, 'vase', [VASE], VASE_PAL);
  pixelSheet(scene, 'bush', [BUSH], BUSH_PAL);
  pixelSheet(scene, 'feather', [FEATHER], FEATHER_PAL);
  pixelSheet(scene, 'sign', [SIGN], SIGN_PAL);
  pixelSheet(scene, 'chest', [CHEST_CLOSED, CHEST_OPEN], CHEST_PAL);
  pixelSheet(scene, 'altar', [ALTAR], ALTAR_PAL);
  pixelSheet(scene, 'flame', [FLAME, mirror(FLAME)], FLAME_PAL);

  canvasTexture(scene, 'px', 2, 2, (c) => { c.fillStyle = '#fff'; c.fillRect(0, 0, 2, 2); });
  canvasTexture(scene, 'xp', 5, 5, (c) => {
    c.fillStyle = '#8ae0d8';
    c.fillRect(2, 0, 1, 5); c.fillRect(0, 2, 5, 1); c.fillRect(1, 1, 3, 3);
    c.fillStyle = '#ffffff'; c.fillRect(2, 2, 1, 1);
  });
  canvasTexture(scene, 'slash', 26, 26, (c) => {
    c.lineCap = 'round';
    c.strokeStyle = 'rgba(255,250,235,0.95)'; c.lineWidth = 4;
    c.beginPath(); c.arc(5, 13, 16, -1.15, 1.15); c.stroke();
    c.strokeStyle = '#f7d774'; c.lineWidth = 1.5;
    c.beginPath(); c.arc(5, 13, 13, -1.0, 1.0); c.stroke();
  });

  drawTiles(scene);
  drawWall(scene);
  drawGate(scene);
  drawBackgrounds(scene);
}

function drawTiles(scene) {
  canvasTexture(scene, 'tiles', 16 * 5, 16, (ctx) => {
    const r = rng(7);
    const dirt = (ox) => {
      ctx.fillStyle = '#6b4a2e'; ctx.fillRect(ox, 0, 16, 16);
      for (let i = 0; i < 16; i++) {
        ctx.fillStyle = r() < 0.5 ? '#5a3c24' : '#7d5836';
        ctx.fillRect(ox + Math.floor(r() * 15), Math.floor(r() * 15), 2, 1);
      }
      ctx.fillStyle = '#8a6a4a'; ctx.fillRect(ox + 3, 10, 2, 2); ctx.fillRect(ox + 11, 4, 2, 1);
    };
    // 0: grass
    dirt(0);
    ctx.fillStyle = '#3f7a34'; ctx.fillRect(0, 0, 16, 5);
    ctx.fillStyle = '#5aa04a'; ctx.fillRect(0, 0, 16, 3);
    ctx.fillStyle = '#8ad06a'; ctx.fillRect(0, 0, 16, 1);
    for (let x = 0; x < 16; x += 2) { ctx.fillStyle = '#3f7a34'; ctx.fillRect(x, 5, 1, x % 4 === 0 ? 2 : 1); }
    ctx.fillStyle = '#e85a7a'; ctx.fillRect(4, 1, 1, 1);
    ctx.fillStyle = '#f0d060'; ctx.fillRect(11, 1, 1, 1);
    // 1: dirt
    dirt(16);
    // 2: one-way platform (wooden beam, gold trim)
    ctx.fillStyle = '#d4a845'; ctx.fillRect(32, 0, 16, 1);
    ctx.fillStyle = '#8a5a2a'; ctx.fillRect(32, 1, 16, 4);
    ctx.fillStyle = '#6a4420'; ctx.fillRect(32, 5, 16, 1);
    ctx.fillStyle = '#1b2a6b'; ctx.fillRect(34, 2, 2, 2); ctx.fillRect(44, 2, 2, 2);
    ctx.fillStyle = '#6a4420'; ctx.fillRect(35, 6, 2, 3); ctx.fillRect(43, 6, 2, 3);
    // 3: stone brick
    ctx.fillStyle = '#7a6448'; ctx.fillRect(48, 0, 16, 16);
    ctx.fillStyle = '#b89a70';
    ctx.fillRect(49, 1, 14, 6); ctx.fillRect(48, 9, 6, 6); ctx.fillRect(56, 9, 8, 6);
    ctx.fillStyle = '#d0b48a'; ctx.fillRect(49, 1, 14, 1); ctx.fillRect(48, 9, 6, 1); ctx.fillRect(56, 9, 8, 1);
    // 4: thorn bush (transparent background)
    for (let i = 0; i < 4; i++) {
      const bx = 64 + i * 4;
      ctx.fillStyle = '#5a2a2a'; ctx.fillRect(bx + 1, 6, 2, 10);
      ctx.fillStyle = '#c8c0b0'; ctx.fillRect(bx + 1, 3, 1, 3); ctx.fillRect(bx + 2, 1, 1, 3);
      ctx.fillStyle = '#7a3a3a'; ctx.fillRect(bx, 9, 1, 1); ctx.fillRect(bx + 3, 12, 1, 1);
    }
    ctx.fillStyle = '#2a5424'; ctx.fillRect(64, 13, 16, 3);
  });
}

function drawWall(scene) {
  canvasTexture(scene, 'wall', 16, 224, (ctx, w, h) => {
    ctx.fillStyle = '#5a4a38'; ctx.fillRect(0, 0, w, h);
    for (let y = 0; y < h; y += 8) {
      const off = (y / 8) % 2 ? 4 : 0;
      for (let x = -off; x < w; x += 8) {
        ctx.fillStyle = (y / 8) % 6 === 2 ? '#2a4a9a' : '#a88a60';
        ctx.fillRect(x + 1, y + 1, 7, 6);
        ctx.fillStyle = 'rgba(255,255,255,0.15)'; ctx.fillRect(x + 1, y + 1, 7, 1);
      }
    }
    ctx.fillStyle = '#d4a845'; ctx.fillRect(0, 0, w, 2);
  });
}

function drawGate(scene) {
  // Pointed arch gate
  canvasTexture(scene, 'gate', 40, 56, (ctx, w, h) => {
    ctx.fillStyle = '#d4a845'; ctx.fillRect(0, 0, w, h);
    ctx.fillStyle = '#1b2a6b'; ctx.fillRect(2, 2, w - 4, h - 2);
    ctx.fillStyle = '#2bb3a8';
    for (let y = 6; y < h; y += 8) for (let x = 5; x < w - 4; x += 8) ctx.fillRect(x, y, 2, 2);
    ctx.fillStyle = '#d4a845'; ctx.fillRect(2, 8, w - 4, 1);
    // arch opening
    ctx.fillStyle = '#d4a845';
    ctx.beginPath(); ctx.moveTo(8, h); ctx.lineTo(8, 26); ctx.quadraticCurveTo(8, 14, 20, 10); ctx.quadraticCurveTo(32, 14, 32, 26); ctx.lineTo(32, h); ctx.fill();
    ctx.fillStyle = '#120a1a';
    ctx.beginPath(); ctx.moveTo(10, h); ctx.lineTo(10, 27); ctx.quadraticCurveTo(10, 16, 20, 12.5); ctx.quadraticCurveTo(30, 16, 30, 27); ctx.lineTo(30, h); ctx.fill();
  });
  canvasTexture(scene, 'gate-glow', 20, 44, (ctx, w, h) => {
    const g = ctx.createLinearGradient(0, 0, 0, h);
    g.addColorStop(0, 'rgba(255,240,180,0.0)');
    g.addColorStop(0.5, 'rgba(255,230,150,0.8)');
    g.addColorStop(1, 'rgba(255,250,220,1)');
    ctx.fillStyle = g;
    ctx.beginPath(); ctx.moveTo(0, h); ctx.lineTo(0, 15); ctx.quadraticCurveTo(0, 4, 10, 0.5); ctx.quadraticCurveTo(20, 4, 20, 15); ctx.lineTo(20, h); ctx.fill();
  });
}

function drawBackgrounds(scene) {
  const W = 480;
  const H = 270;

  canvasTexture(scene, 'bg-sky', W, H, (ctx) => {
    const g = ctx.createLinearGradient(0, 0, 0, H);
    g.addColorStop(0, '#16225a');
    g.addColorStop(0.45, '#3a5aa8');
    g.addColorStop(0.8, '#e9c98f');
    g.addColorStop(1, '#f2e0b0');
    ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
    const r = rng(3);
    ctx.fillStyle = 'rgba(255,245,210,0.8)';
    for (let i = 0; i < 40; i++) ctx.fillRect(Math.floor(r() * W), Math.floor(r() * 90), 1, 1);
    // ornamental golden sun
    ctx.fillStyle = '#d4a845';
    for (let i = 0; i < 16; i++) {
      const a = (i / 16) * Math.PI * 2;
      ctx.beginPath();
      ctx.moveTo(360 + Math.cos(a - 0.12) * 24, 80 + Math.sin(a - 0.12) * 24);
      ctx.lineTo(360 + Math.cos(a) * 34, 80 + Math.sin(a) * 34);
      ctx.lineTo(360 + Math.cos(a + 0.12) * 24, 80 + Math.sin(a + 0.12) * 24);
      ctx.fill();
    }
    ctx.fillStyle = '#f7d774'; ctx.beginPath(); ctx.arc(360, 80, 22, 0, Math.PI * 2); ctx.fill();
    ctx.strokeStyle = '#d4a845'; ctx.lineWidth = 2; ctx.beginPath(); ctx.arc(360, 80, 17, 0, Math.PI * 2); ctx.stroke();
  });

  // Curly ribbon clouds
  canvasTexture(scene, 'bg-clouds', W, H, (ctx) => {
    const r = rng(11);
    const cloud = (x, y, s) => {
      for (const dx of [-W, 0, W]) {
        ctx.fillStyle = '#f2e6c9';
        ctx.strokeStyle = '#d4a845';
        ctx.lineWidth = 1;
        const blobs = [[0, 0, 8], [10, -4, 10], [22, 0, 8], [14, 4, 7], [-8, 3, 6]];
        for (const [bx, by, br] of blobs) {
          ctx.beginPath(); ctx.arc(x + dx + bx * s, y + by * s, br * s, 0, Math.PI * 2); ctx.fill(); ctx.stroke();
        }
        for (const [bx, by, br] of blobs) {
          ctx.beginPath(); ctx.arc(x + dx + bx * s, y + by * s, br * s - 1, 0, Math.PI * 2); ctx.fill();
        }
        ctx.beginPath(); ctx.arc(x + dx + 10 * s, y - 4 * s, 4 * s, 0, Math.PI * 1.5); ctx.stroke();
        ctx.beginPath(); ctx.moveTo(x + dx + 26 * s, y); ctx.quadraticCurveTo(x + dx + 36 * s, y + 6 * s, x + dx + 44 * s, y); ctx.stroke();
      }
    };
    for (let i = 0; i < 6; i++) cloud(i * 80 + r() * 30, 30 + r() * 70, 0.7 + r() * 0.5);
  });

  // Stylized violet mountains
  canvasTexture(scene, 'bg-mountains', W, H, (ctx) => {
    const r = rng(21);
    const pts = [];
    for (let x = 0; x <= W; x += 24) pts.push([x, 140 + r() * 60]);
    pts[pts.length - 1][1] = pts[0][1];
    ctx.fillStyle = '#5a4a8a';
    ctx.beginPath(); ctx.moveTo(0, H);
    for (const [x, y] of pts) ctx.lineTo(x, y);
    ctx.lineTo(W, H); ctx.fill();
    ctx.strokeStyle = '#9a8ac8'; ctx.lineWidth = 2;
    ctx.beginPath(); pts.forEach(([x, y], i) => (i ? ctx.lineTo(x, y) : ctx.moveTo(x, y))); ctx.stroke();
    ctx.fillStyle = '#7a6aa8';
    for (let i = 0; i < 30; i++) {
      const x = r() * W;
      const y = 190 + r() * 70;
      ctx.beginPath(); ctx.arc(x, y, 3 + r() * 5, 0, Math.PI * 2); ctx.fill();
    }
  });

  // Turquoise hills and cypress trees
  canvasTexture(scene, 'bg-hills', W, H, (ctx) => {
    const r = rng(33);
    const hill = (color, base, amp, freq, phase) => {
      ctx.fillStyle = color;
      ctx.beginPath(); ctx.moveTo(0, H);
      for (let x = 0; x <= W; x += 4) ctx.lineTo(x, base - Math.sin((x / W) * Math.PI * 2 * freq + phase) * amp);
      ctx.lineTo(W, H); ctx.fill();
    };
    hill('#2b8a78', 205, 14, 2, 0.5);
    const cypress = (x, y, hgt) => {
      for (const dx of [-W, 0, W]) {
        ctx.fillStyle = '#1a4a3a';
        ctx.beginPath(); ctx.ellipse(x + dx, y - hgt / 2, 4, hgt / 2, 0, 0, Math.PI * 2); ctx.fill();
        ctx.fillStyle = '#245e4a';
        ctx.beginPath(); ctx.ellipse(x + dx - 1, y - hgt / 2, 2, hgt / 2 - 2, 0, 0, Math.PI * 2); ctx.fill();
      }
    };
    for (let i = 0; i < 9; i++) {
      const x = i * 53 + r() * 20;
      cypress(x, 212 - Math.sin((x / W) * Math.PI * 4 + 0.5) * 14, 22 + r() * 16);
    }
    hill('#1f6a5c', 228, 8, 3, 1.7);
  });
}

export function createAnims(scene) {
  const f = (key, frames) => frames.map((frame) => ({ key, frame }));
  scene.anims.create({ key: 'hero-run', frames: f('hero', [1, 2]), frameRate: 10, repeat: -1 });
  scene.anims.create({ key: 'imp-walk', frames: f('imp', [0, 1]), frameRate: 6, repeat: -1 });
  scene.anims.create({ key: 'bat-fly', frames: f('bat', [0, 1]), frameRate: 8, repeat: -1 });
  scene.anims.create({ key: 'lion-walk', frames: f('lion', [0, 1]), frameRate: 6, repeat: -1 });
  scene.anims.create({ key: 'flame', frames: f('flame', [0, 1]), frameRate: 8, repeat: -1 });
}
