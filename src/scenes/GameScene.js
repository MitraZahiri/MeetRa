import Phaser from 'phaser';
import { TILE, T, ZOOM, xpForLevel } from '../config.js';
import { Controls } from '../input.js';
import { sfx } from '../sfx.js';
import { buildLevel } from '../levels/build.js';
import { LEVEL1 } from '../levels/level1.js';
import { Player } from '../entities/Player.js';
import { Imp, Bat } from '../entities/Enemy.js';
import { Lion } from '../entities/Lion.js';

const rectOf = (body) => new Phaser.Geom.Rectangle(body.x, body.y, body.width, body.height);
const overlaps = (a, b) => Phaser.Geom.Intersects.RectangleToRectangle(a, b);

export class GameScene extends Phaser.Scene {
  constructor() {
    super('Game');
  }

  create() {
    this.def = LEVEL1;
    this.level = buildLevel(this.def);
    const L = this.level;

    // Tilemap
    const map = this.make.tilemap({ data: L.data, tileWidth: TILE, tileHeight: TILE });
    const tiles = map.addTilesetImage('tiles');
    this.layer = map.createLayer(0, tiles, 0, 0).setDepth(5);
    this.layer.setCollision([T.GRASS, T.DIRT, T.BRICK, T.SPIKES]);
    this.layer.forEachTile((t) => {
      if (t.index === T.PLATFORM) t.setCollision(false, false, true, false);
    });

    this.physics.world.setBounds(0, 0, L.width, L.height + 64);
    this.physics.world.setBoundsCollision(true, true, false, false);

    // Groups
    this.enemies = this.physics.add.group({ runChildUpdate: true });
    this.coins = this.physics.add.group({ bounceY: 0.45, dragX: 90 });
    this.hearts = this.physics.add.group({ bounceY: 0.3, dragX: 90 });
    this.feathers = this.physics.add.group({ allowGravity: false });
    this.walls = this.physics.add.staticGroup();
    this.breakables = [];
    this.chests = [];
    this.altars = [];
    this.signs = [];
    this.orbs = [];

    this.checkpoint = null;
    this.bossStarted = false;
    this.bossDefeated = false;
    this.lion = null;
    this.victory = false;
    this.controls = new Controls(this);

    this.spawnObjects();

    // Collisions
    const P = this.player;
    this.physics.add.collider(P, this.layer, this.onPlayerTile, this.processPlayerTile, this);
    this.physics.add.collider(P, this.walls);
    this.physics.add.collider(this.enemies, this.layer);
    this.physics.add.collider(this.enemies, this.walls);
    this.physics.add.collider(this.coins, this.layer);
    this.physics.add.collider(this.hearts, this.layer);
    this.physics.add.collider(this.feathers, this.layer, (f) => this.killFeather(f));
    this.physics.add.overlap(P, this.enemies, (p, e) => !e.dying && p.hurt(e.contactDamage, e.x));
    this.physics.add.overlap(P, this.coins, (p, c) => this.collectCoin(c));
    this.physics.add.overlap(P, this.hearts, (p, h) => this.collectHeart(h));
    this.physics.add.overlap(this.feathers, this.enemies, (f, e) => {
      if (e.dying || !f.active) return;
      e.hurt(f.dmg, Math.sign(f.body.velocity.x), 0.6);
      this.killFeather(f);
    });

    // Camera
    const cam = this.cameras.main;
    cam.setZoom(ZOOM);
    cam.setBounds(0, 0, L.width, L.height);
    cam.startFollow(P, true, 0.12, 0.12, 0, 20);
    cam.setRoundPixels(true);

    this.events.once('shutdown', () => this.tweens.killAll());
  }

  spawnObjects() {
    let signIndex = 0;
    for (const o of this.level.objects) {
      switch (o.type) {
        case 'P':
          this.player = new Player(this, o.x, o.y);
          break;
        case 'A': {
          const base = this.add.image(o.x, o.y, 'altar').setOrigin(0.5, 1).setDepth(4);
          const flame = this.add.sprite(o.x, o.y - 13, 'flame').setOrigin(0.5, 1).setDepth(4).setVisible(false);
          const ember = this.add.image(o.x, o.y - 13, 'px').setTint(0x803020).setDepth(4);
          this.altars.push({ x: o.x, y: o.y, base, flame, ember, lit: false });
          break;
        }
        case 'S': {
          const img = this.add.image(o.x, o.y, 'sign').setOrigin(0.5, 1).setDepth(3);
          this.signs.push({ x: o.x, y: o.y, img, text: this.def.signs[signIndex++] });
          break;
        }
        case 'D':
        case 'V': {
          const e = o.type === 'D' ? new Imp(this, o.x, o.y) : new Bat(this, o.x, o.y - 40);
          this.enemies.add(e);
          e.initBody();
          break;
        }
        case 'v':
        case '*': {
          const img = this.add.image(o.x, o.y, o.type === 'v' ? 'vase' : 'bush').setOrigin(0.5, 1).setDepth(4);
          img.kind = o.type === 'v' ? 'vase' : 'bush';
          this.breakables.push(img);
          break;
        }
        case 'C': {
          const img = this.add.sprite(o.x, o.y, 'chest', 0).setOrigin(0.5, 1).setDepth(4);
          this.chests.push({ img, opened: false });
          break;
        }
        case 'F': {
          const glow = this.add.circle(o.x, o.y - 10, 10, 0x8ae0d8, 0.25).setDepth(6);
          const img = this.add.image(o.x, o.y - 10, 'feather').setScale(1.5).setAngle(-30).setDepth(7);
          this.tweens.add({ targets: [img, glow], y: o.y - 16, yoyo: true, repeat: -1, duration: 900, ease: 'Sine.inOut' });
          this.tweens.add({ targets: glow, scale: 1.4, alpha: 0.1, yoyo: true, repeat: -1, duration: 700 });
          this.featherPickup = { img, glow, x: o.x, y: o.y - 10 };
          break;
        }
        case 'L':
          this.lionSpawn = { x: o.x, y: o.y };
          break;
        case '[':
          this.arenaLeft = o.x - TILE / 2;
          break;
        case ']':
          this.arenaRight = o.x + TILE / 2;
          this.rightWall = this.walls.create(o.x, o.y / 2, 'wall'); // duvar zeminden tavana kadar
          break;
        case 'G': {
          const gate = this.add.image(o.x, o.y, 'gate').setOrigin(0.5, 1).setDepth(3);
          const glow = this.add.image(o.x, o.y, 'gate-glow').setOrigin(0.5, 1).setDepth(3).setAlpha(0);
          this.gate = { x: o.x, y: o.y, img: gate, glow };
          break;
        }
      }
    }
    this.checkpoint = { x: this.player.x, y: this.player.y };
  }

  // ---------- Collision callbacks ----------

  processPlayerTile(player, tile) {
    return !(tile.index === T.PLATFORM && player.dropTimer > 0);
  }

  onPlayerTile(player, tile) {
    if (tile.index === T.SPIKES) player.fallHurt();
  }

  // ---------- Loop ----------

  update(time, delta) {
    const dt = Math.min(delta, 50);
    const c = this.controls.update();
    const P = this.player;
    P.update(c, dt);
    if (this.lion) this.lion.update(time, dt);

    if (!P.dead && P.y > this.level.height + 16) P.fallHurt();

    const pr = rectOf(P.body);
    this.updateAltars(pr);
    this.updateSigns();
    this.updatePickups(pr, dt);
    this.updateOrbs(dt);
    this.updateChests(pr);

    if (this.lion && this.lion.active && this.lion.state !== 'dead' && this.lion.state !== 'stunned' && !P.dead) {
      if (overlaps(pr, rectOf(this.lion.body))) P.hurt(this.lion.contactDamage, this.lion.x);
    }
    if (this.lion && this.lion.active) {
      this.feathers.getChildren().slice().forEach((f) => {
        if (f.active && this.lion.state !== 'dead' && overlaps(rectOf(f.body), rectOf(this.lion.body))) {
          this.lion.hurt(f.dmg);
          this.killFeather(f);
        }
      });
    }

    // Boss arena trigger
    if (!this.bossStarted && !this.bossDefeated && this.arenaLeft !== undefined && P.x > this.arenaLeft + TILE * 3) {
      this.startBoss();
    }

    // Exit gate
    if (this.gate && this.bossDefeated && !this.victory && Math.abs(P.x - this.gate.x) < 10 && P.body.blocked.down) {
      this.win();
    }
  }

  updateAltars(pr) {
    for (const a of this.altars) {
      if (!overlaps(pr, new Phaser.Geom.Rectangle(a.x - 10, a.y - 24, 20, 24))) continue;
      const reg = this.registry;
      if (reg.get('hp') < reg.get('maxHp')) reg.set('hp', reg.get('maxHp'));
      if (!a.lit) {
        this.altars.forEach((o) => { o.current = false; });
        a.lit = true;
        a.flame.setVisible(true).play('flame');
        a.ember.setVisible(false);
        sfx.altar();
        this.burst(a.x, a.y - 16, [0xffe066, 0xff9a2a], 16, 90);
        this.events.emit('banner', 'Hearth lit', 'Checkpoint reached · health restored');
      }
      if (!this.checkpoint || this.checkpoint.x !== a.x) this.checkpoint = { x: a.x, y: a.y };
    }
  }

  updateSigns() {
    const P = this.player;
    let near = null;
    for (const s of this.signs) if (Math.abs(P.x - s.x) < 22 && Math.abs(P.y - s.y) < 30) near = s;
    if (near !== this.activeSign) {
      this.activeSign = near;
      this.events.emit('sign', near ? near.text : null);
    }
  }

  updatePickups(pr, dt) {
    const P = this.player;
    // Saena's feather
    const f = this.featherPickup;
    if (f && Phaser.Math.Distance.Between(P.x, P.y - 9, f.img.x, f.img.y) < 14) {
      this.featherPickup = null;
      this.tweens.killTweensOf([f.img, f.glow]);
      f.img.destroy();
      f.glow.destroy();
      this.registry.set('hasFeather', true);
      this.registry.set('aura', this.registry.get('auraMax'));
      sfx.pickup();
      this.burst(P.x, P.y - 10, [0x2bb3a8, 0x8ae0d8, 0xd4a845], 24, 130);
      this.events.emit('banner', 'Saena\'s Feather', 'Tap ✦ to throw it · costs Aura');
    }
    // Coin magnet
    for (const c of this.coins.getChildren()) {
      c.age += dt;
      if (c.age > 350 && Phaser.Math.Distance.Between(c.x, c.y, P.x, P.y - 8) < 40) {
        this.physics.moveTo(c, P.x, P.y - 8, 220);
      }
    }
  }

  updateOrbs(dt) {
    const P = this.player;
    for (let i = this.orbs.length - 1; i >= 0; i--) {
      const o = this.orbs[i];
      o.t += dt;
      if (o.t < 300) {
        o.img.x += o.vx * (dt / 1000);
        o.img.y += o.vy * (dt / 1000);
        o.vx *= 0.92;
        o.vy *= 0.92;
      } else {
        const dx = P.x - o.img.x;
        const dy = P.y - 9 - o.img.y;
        const d = Math.hypot(dx, dy);
        const sp = Math.min(400, 120 + o.t * 0.4) * (dt / 1000);
        if (d < 8 || P.dead) {
          o.img.destroy();
          this.orbs.splice(i, 1);
          if (!P.dead) this.gainXp(o.value);
          continue;
        }
        o.img.x += (dx / d) * sp;
        o.img.y += (dy / d) * sp;
      }
    }
  }

  updateChests(pr) {
    for (const ch of this.chests) {
      if (ch.opened || !overlaps(pr, ch.img.getBounds())) continue;
      ch.opened = true;
      ch.img.setFrame(1);
      sfx.pickup();
      this.spawnGold(ch.img.x, ch.img.y - 10, 12);
      this.spawnXp(ch.img.x, ch.img.y - 10, 8);
      this.events.emit('banner', 'Treasure!', 'Hidden chests reward the curious');
    }
  }

  // ---------- Combat ----------

  resolveMelee(rect, dmg, dir, knock) {
    let hits = 0;
    for (const e of this.enemies.getChildren().slice()) {
      if (e.active && !e.dying && overlaps(rect, rectOf(e.body))) {
        e.hurt(dmg, dir, knock);
        hits++;
      }
    }
    if (this.lion && this.lion.active && this.lion.state !== 'dead' && overlaps(rect, rectOf(this.lion.body))) {
      this.lion.hurt(dmg);
      hits++;
    }
    for (const b of this.breakables.slice()) {
      if (overlaps(rect, b.getBounds())) {
        this.breakObject(b);
        hits++;
      }
    }
    if (hits) {
      sfx.hit();
      this.hitstop(65);
      this.cameras.main.shake(70, 0.003);
    }
    return hits;
  }

  hitstop(ms) {
    if (this.physics.world.isPaused) return;
    this.physics.world.pause();
    this.time.delayedCall(ms, () => this.physics.world.resume());
  }

  breakObject(b) {
    this.breakables.splice(this.breakables.indexOf(b), 1);
    sfx.break();
    const colors = b.kind === 'vase' ? [0xb8683a, 0xd8905a, 0x1b2a6b] : [0x3f7a34, 0x5aa04a, 0xe85a7a];
    this.burst(b.x, b.y - 6, colors, 12, 110);
    const r = Math.random();
    if (r < 0.15) this.spawnHeart(b.x, b.y - 8);
    else if (r < 0.75) this.spawnGold(b.x, b.y - 8, Phaser.Math.Between(1, b.kind === 'vase' ? 3 : 1));
    if (b.kind === 'bush') this.spawnXp(b.x, b.y - 8, 1);
    b.destroy();
  }

  spawnFeather(x, y, dir, dmg) {
    sfx.feather();
    const f = this.feathers.create(x, y, 'feather');
    f.setFlipX(dir < 0).setDepth(9);
    f.body.setAllowGravity(false);
    f.body.setSize(10, 4);
    f.setVelocityX(dir * 270);
    f.dmg = dmg;
    f.trail = this.add.particles(0, 0, 'px', {
      follow: f,
      lifespan: 220,
      frequency: 25,
      speed: 10,
      scale: { start: 1, end: 0 },
      tint: [0x8ae0d8, 0xd4a845],
    }).setDepth(8);
    this.time.delayedCall(1100, () => this.killFeather(f));
  }

  killFeather(f) {
    if (!f.active) return;
    this.burst(f.x, f.y, [0x8ae0d8, 0xffffff], 6, 60);
    f.trail?.destroy();
    f.destroy();
  }

  // ---------- Loot ----------

  spawnGold(x, y, n) {
    for (let i = 0; i < n; i++) {
      const c = this.coins.create(x, y, 'coin').setDepth(7);
      c.setVelocity(Phaser.Math.Between(-70, 70), Phaser.Math.Between(-220, -130));
      c.age = 0;
      this.time.delayedCall(9000, () => c.active && c.destroy());
    }
  }

  spawnHeart(x, y) {
    const h = this.hearts.create(x, y, 'heart', 0).setDepth(7);
    h.setVelocity(Phaser.Math.Between(-40, 40), -180);
    this.time.delayedCall(10000, () => h.active && h.destroy());
  }

  spawnXp(x, y, total) {
    const n = Math.min(total, 8);
    const base = Math.floor(total / n);
    let rest = total - base * n;
    for (let i = 0; i < n; i++) {
      const value = base + (rest-- > 0 ? 1 : 0);
      const img = this.add.image(x, y, 'xp').setDepth(9);
      const a = Math.random() * Math.PI * 2;
      this.orbs.push({ img, value, t: 0, vx: Math.cos(a) * 120, vy: Math.sin(a) * 120 - 40 });
    }
  }

  collectCoin(c) {
    if (c.age < 150) return;
    c.destroy();
    this.registry.inc('gold', 1);
    sfx.coin();
  }

  collectHeart(h) {
    h.destroy();
    const reg = this.registry;
    reg.set('hp', Math.min(reg.get('maxHp'), reg.get('hp') + 2));
    sfx.pickup();
  }

  gainXp(n) {
    const reg = this.registry;
    let xp = reg.get('xp') + n;
    let level = reg.get('level');
    let next = reg.get('xpNext');
    let ups = 0;
    while (xp >= next) {
      xp -= next;
      level++;
      next = xpForLevel(level);
      ups++;
    }
    reg.set('xp', xp);
    reg.set('xpNext', next);
    reg.set('level', level);
    if (ups) {
      sfx.levelup();
      this.burst(this.player.x, this.player.y - 10, [0xffe28a, 0xffffff, 0x8ae0d8], 30, 160);
      this.pendingLevelUps = (this.pendingLevelUps || 0) + ups;
      this.time.delayedCall(350, () => this.openLevelUp());
    }
  }

  openLevelUp() {
    if (!this.pendingLevelUps || this.player.dead || this.victory) return;
    this.scene.pause();
    this.scene.get('UI').openLevelUp(this.pendingLevelUps);
    this.pendingLevelUps = 0;
  }

  // ---------- Boss ----------

  startBoss() {
    this.bossStarted = true;
    this.leftWall = this.walls.create(this.arenaLeft + TILE / 2, this.rightWall.y, 'wall');
    this.burst(this.leftWall.x, this.level.height - 3 * TILE, [0xa88a60, 0x5a4a38], 16, 120);
    const cam = this.cameras.main;
    cam.setBounds(this.arenaLeft, 0, this.arenaRight - this.arenaLeft, this.level.height);
    cam.shake(400, 0.008);
    sfx.roar();
    this.lion = new Lion(this, this.lionSpawn.x, this.lionSpawn.y);
    this.lionColliders = [
      this.physics.add.collider(this.lion, this.layer),
      this.physics.add.collider(this.lion, this.walls),
    ];
    this.events.emit('boss-start', this.def.boss);
  }

  onBossDefeated(x, y) {
    this.bossDefeated = true;
    this.lionColliders.forEach((c) => c.destroy());
    this.lion = null;
    this.spawnGold(x, y - 16, 25);
    this.spawnXp(x, y - 16, 60);
    this.spawnHeart(x, y - 16);
    [this.leftWall, this.rightWall].forEach((w) => {
      this.burst(w.x, w.y, [0xa88a60, 0x2a4a9a], 24, 160);
      w.destroy();
    });
    this.cameras.main.setBounds(0, 0, this.level.width, this.level.height);
    this.events.emit('boss-end');
    this.events.emit('banner', 'The Reed Lion falls!', 'The gate to the east is open');
    this.tweens.add({ targets: this.gate.glow, alpha: 1, duration: 1200 });
  }

  resetBoss() {
    if (!this.bossStarted || this.bossDefeated) return;
    this.lionColliders.forEach((c) => c.destroy());
    this.lion?.destroy();
    this.lion = null;
    this.leftWall?.destroy();
    this.bossStarted = false;
    this.cameras.main.setBounds(0, 0, this.level.width, this.level.height);
    this.events.emit('boss-end');
  }

  // ---------- Death / victory ----------

  playerDied() {
    const P = this.player;
    if (P.dead) return;
    P.dead = true;
    P.setTint(0x802020).setVelocity(0, -150);
    P.body.checkCollision.none = true;
    this.cameras.main.shake(300, 0.01);
    this.time.delayedCall(900, () => {
      this.cameras.main.fadeOut(400, 10, 6, 20);
      this.cameras.main.once('camerafadeoutcomplete', () => {
        this.resetBoss();
        const cp = this.checkpoint;
        P.dead = false;
        P.body.checkCollision.none = false;
        P.clearTint();
        P.respawnAt(cp.x, cp.y);
        P.safe = { x: cp.x, y: cp.y };
        this.registry.set('hp', this.registry.get('maxHp'));
        this.cameras.main.fadeIn(400);
        this.events.emit('banner', 'Ra rises again', 'Back at the last hearth');
      });
    });
  }

  win() {
    this.victory = true;
    this.player.frozen = true;
    sfx.victory();
    this.tweens.add({ targets: this.player, alpha: 0, duration: 900, delay: 300 });
    this.time.delayedCall(1100, () => this.events.emit('victory'));
  }

  // ---------- Effects ----------

  burst(x, y, colors, count = 10, speed = 100) {
    const p = this.add.particles(x, y, 'px', {
      speed: { min: speed * 0.3, max: speed },
      angle: { min: 0, max: 360 },
      lifespan: { min: 250, max: 550 },
      scale: { start: 1, end: 0 },
      gravityY: 300,
      tint: colors,
      emitting: false,
    }).setDepth(12);
    p.explode(count);
    this.time.delayedCall(700, () => p.destroy());
  }

  floatText(x, y, text, color) {
    const t = this.add.text(x, y, text, {
      fontFamily: 'monospace',
      fontSize: '8px',
      color,
      stroke: '#1a1020',
      strokeThickness: 2,
    }).setOrigin(0.5).setDepth(20);
    this.tweens.add({ targets: t, y: y - 14, alpha: 0, duration: 600, onComplete: () => t.destroy() });
  }
}
