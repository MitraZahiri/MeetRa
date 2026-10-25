import Phaser from 'phaser';
import { resetState } from '../config.js';
import { touch, clearTouch } from '../input.js';
import { sfx } from '../sfx.js';

const FONT = 'Georgia, "Times New Roman", serif';
const GOLD = '#f7d774';
const PARCH = '#f2e6c9';
const INK = '#1a1020';

// HUD, menus and on-screen controls. The game is phone-first: touch buttons are always shown.
// Keyboard still works for development (arrows/WASD, Space, J, K, 1-3, R).
export class UIScene extends Phaser.Scene {
  constructor() {
    super('UI');
  }

  // The canvas expands to the phone's aspect ratio, so width is not fixed (height stays 540)
  get W() {
    return this.scale.width;
  }

  get H() {
    return this.scale.height;
  }

  text(x, y, str, size, color = PARCH, extra = {}) {
    const t = this.add.text(x, y, str, {
      fontFamily: FONT,
      fontSize: `${size}px`,
      color,
      stroke: INK,
      strokeThickness: Math.max(3, size / 5),
      align: 'center',
      ...extra,
    });
    t.setResolution(2);
    t.texture.setFilter(Phaser.Textures.FilterMode.LINEAR);
    return t;
  }

  create() {
    this.game_ = this.scene.get('Game');

    // HUD
    this.heartImgs = [];
    this.hud = this.add.graphics();
    this.goldIcon = this.add.image(this.W - 28, 28, 'coin').setScale(4);
    this.goldText = this.text(this.W - 48, 28, '0', 24, GOLD).setOrigin(1, 0.5);
    this.levelText = this.text(this.W - 24, 58, 'Lv 1', 18).setOrigin(1, 0.5);
    this.auraLabel = this.text(24, 62, 'AURA', 13, GOLD).setOrigin(0, 0.5);

    // Signpost box
    this.signBox = this.add.container(this.W / 2, 110).setVisible(false);
    const sb = this.add.graphics();
    sb.fillStyle(0xf2e6c9, 0.95).fillRoundedRect(-320, -48, 640, 96, 10);
    sb.lineStyle(3, 0xd4a845).strokeRoundedRect(-320, -48, 640, 96, 10);
    sb.lineStyle(1, 0x1b2a6b).strokeRoundedRect(-313, -41, 626, 82, 8);
    this.signText = this.text(0, 0, '', 21, INK, { stroke: INK, strokeThickness: 0, wordWrap: { width: 600 } }).setOrigin(0.5);
    this.signBox.add([sb, this.signText]);

    // Banner
    this.banner = this.text(this.W / 2, 200, '', 40, GOLD).setOrigin(0.5).setAlpha(0);
    this.bannerSub = this.text(this.W / 2, 242, '', 20).setOrigin(0.5).setAlpha(0);

    // Boss bar (top, so thumbs never cover it)
    this.bossBox = this.add.container(this.W / 2, 96).setVisible(false);
    this.bossBar = this.add.graphics();
    this.bossName = this.text(0, -24, '', 20, GOLD).setOrigin(0.5);
    this.bossBox.add([this.bossBar, this.bossName]);
    this.bossFrac = 1;

    this.createTouchControls();
    this.layout();
    this.scale.on('resize', this.layout, this);
    this.events.once('shutdown', () => this.scale.off('resize', this.layout, this));

    // Events from the game scene
    const ge = this.game_.events;
    const on = (ev, fn) => {
      ge.on(ev, fn, this);
      this.events.once('shutdown', () => ge.off(ev, fn, this));
    };
    on('banner', this.showBanner);
    on('sign', this.showSign);
    on('boss-start', (boss) => {
      this.bossName.setText(`${boss.name} · ${boss.title}`);
      this.bossFrac = 1;
      this.bossBox.setVisible(true);
      this.signBox.setVisible(false);
      this.drawBossBar();
    });
    on('boss-hp', (f) => {
      this.bossFrac = f;
      this.drawBossBar();
    });
    on('boss-end', () => this.bossBox.setVisible(false));
    on('victory', this.showVictory);

    this.showTitle();
  }

  // Re-anchor HUD and buttons to the right edge and centre when the screen size changes
  layout() {
    const W = this.W;
    this.goldIcon.x = W - 28;
    this.goldText.x = W - 48;
    this.levelText.x = W - 24;
    for (const o of [this.signBox, this.banner, this.bannerSub, this.bossBox]) o.x = W / 2;
    for (const [btn, fromRight] of this.rightButtons) btn.x = W - fromRight;
  }

  // ---------- Title screen ----------

  showTitle() {
    // The game scene ignores pause while it is still being created, so pause it one frame later
    this.game_.events.once('postupdate', () => this.titleOpen && this.scene.pause('Game'));
    this.titleOpen = true;
    const c = this.add.container(0, 0).setDepth(100);
    const bg = this.add.rectangle(0, 0, this.W, this.H, 0x0d1233, 0.82).setOrigin(0);
    const frame = this.add.graphics();
    frame.lineStyle(3, 0xd4a845).strokeRect(40, 40, this.W - 80, this.H - 80);
    frame.lineStyle(1, 0x2bb3a8).strokeRect(50, 50, this.W - 100, this.H - 100);
    const title = this.text(this.W / 2, 190, 'MeetRa', 96, GOLD).setOrigin(0.5);
    const sub = this.text(this.W / 2, 270, 'The First Trial · The Reed Marsh', 24).setOrigin(0.5);
    const hint = this.text(this.W / 2, 400, 'Tap to begin', 30, GOLD).setOrigin(0.5);
    this.tweens.add({ targets: hint, alpha: 0.3, yoyo: true, repeat: -1, duration: 700 });
    c.add([bg, frame, title, sub, hint]);

    const start = () => {
      if (!this.titleOpen) return;
      this.titleOpen = false;
      sfx.unlock();
      this.goFullscreen();
      this.input.keyboard.off('keydown', start);
      this.input.off('pointerup', start);
      this.tweens.add({ targets: c, alpha: 0, duration: 400, onComplete: () => c.destroy() });
      this.scene.resume('Game');
      this.time.delayedCall(500, () => this.showBanner('The First Trial', 'The Reed Marsh'));
    };
    this.time.delayedCall(300, () => {
      this.input.keyboard.on('keydown', start);
      // pointerup (not pointerdown) so the browser accepts the fullscreen request
      this.input.on('pointerup', start);
    });
  }

  // On phones: go fullscreen and lock to landscape. Inside the native (Capacitor) app this is a no-op.
  goFullscreen() {
    const os = this.sys.game.device.os;
    if (!(os.android || os.iOS || os.iPad || os.iPhone)) return;
    if (!this.scale.isFullscreen && this.scale.fullscreen.available) this.scale.startFullscreen();
    screen.orientation?.lock?.('landscape').catch(() => {});
  }

  // ---------- HUD ----------

  update() {
    const reg = this.registry;
    const hp = reg.get('hp');
    const maxHp = reg.get('maxHp');
    const nHearts = Math.ceil(maxHp / 2);
    while (this.heartImgs.length < nHearts) {
      this.heartImgs.push(this.add.image(30 + this.heartImgs.length * 32, 30, 'heart', 0).setScale(3));
    }
    this.heartImgs.forEach((h, i) => {
      const v = hp - i * 2;
      h.setFrame(v >= 2 ? 0 : v === 1 ? 1 : 2);
    });

    this.goldText.setText(`${reg.get('gold')}`);
    this.levelText.setText(`Lv ${reg.get('level')}`);

    const g = this.hud;
    g.clear();
    // XP bar
    const xpW = 140;
    g.fillStyle(0x1a1020, 0.8).fillRect(this.W - 24 - xpW, 74, xpW, 7);
    g.fillStyle(0x8ae0d8).fillRect(this.W - 24 - xpW, 74, xpW * (reg.get('xp') / reg.get('xpNext')), 7);
    // Aura bar: only shown once a spell is earned
    const hasFeather = reg.get('hasFeather');
    this.auraLabel.setVisible(hasFeather);
    if (hasFeather) {
      const w = reg.get('auraMax') * 2;
      g.fillStyle(0x1a1020, 0.8).fillRect(70, 56, w + 4, 12);
      g.fillStyle(0xd4a845).fillRect(72, 58, w * (reg.get('aura') / reg.get('auraMax')), 8);
      g.lineStyle(1, 0xf7d774).strokeRect(70, 56, w + 4, 12);
    }
    this.spellBtn.setVisible(hasFeather);
  }

  drawBossBar() {
    const g = this.bossBar;
    const w = 380;
    g.clear();
    g.fillStyle(0x1a1020, 0.85).fillRect(-w / 2 - 3, -7, w + 6, 16);
    g.fillStyle(0xb83a2e).fillRect(-w / 2, -4, w * this.bossFrac, 10);
    g.lineStyle(2, 0xd4a845).strokeRect(-w / 2 - 3, -7, w + 6, 16);
  }

  showBanner(title, sub = '') {
    this.tweens.killTweensOf([this.banner, this.bannerSub]);
    this.banner.setText(title).setAlpha(0).setScale(0.8);
    this.bannerSub.setText(sub).setAlpha(0);
    this.tweens.add({ targets: this.banner, alpha: 1, scale: 1, duration: 300, ease: 'Back.out' });
    this.tweens.add({ targets: this.bannerSub, alpha: 1, duration: 300, delay: 120 });
    this.tweens.add({ targets: [this.banner, this.bannerSub], alpha: 0, duration: 500, delay: 2600 });
  }

  showSign(text) {
    if (!text) {
      this.signBox.setVisible(false);
      return;
    }
    this.signText.setText(text);
    this.signBox.setVisible(true).setScale(0.9).setAlpha(0);
    this.tweens.add({ targets: this.signBox, scale: 1, alpha: 1, duration: 160 });
  }

  // ---------- Level up ----------

  openLevelUp(count) {
    this.pendingUps = (this.pendingUps || 0) + count;
    clearTouch();
    if (this.levelPanel) return;
    const reg = this.registry;
    const c = this.add.container(0, 0).setDepth(90);
    this.levelPanel = c;
    c.add(this.add.rectangle(0, 0, this.W, this.H, 0x0d1233, 0.75).setOrigin(0));
    c.add(this.text(this.W / 2, 90, `LEVEL ${reg.get('level')}!`, 48, GOLD).setOrigin(0.5));
    c.add(this.text(this.W / 2, 140, 'Choose your strength', 22).setOrigin(0.5));

    const choices = [
      { icon: '♥', name: 'Heart', desc: '+1 heart', apply: () => { reg.inc('maxHp', 2); reg.inc('hp', 2); } },
      { icon: '⚔', name: 'Might', desc: '+1 sword damage', apply: () => reg.inc('attack', 1) },
      { icon: '✦', name: 'Aura', desc: '+20 Aura\n+1 spell power', apply: () => { reg.inc('auraMax', 20); reg.inc('magic', 1); } },
    ];
    const pick = (ch) => {
      ch.apply();
      sfx.pickup();
      this.pendingUps--;
      this.input.keyboard.off('keydown', onKey);
      c.destroy();
      this.levelPanel = null;
      if (this.pendingUps > 0) this.openLevelUp(0);
      else this.scene.resume('Game');
    };
    choices.forEach((ch, i) => {
      const x = this.W / 2 + (i - 1) * 260;
      const y = 320;
      const card = this.add.graphics();
      const draw = (hover) => {
        card.clear();
        card.fillStyle(hover ? 0x2a3a8b : 0x1b2a6b, 1).fillRoundedRect(x - 115, y - 120, 230, 250, 12);
        card.lineStyle(3, hover ? 0xf7d774 : 0xd4a845).strokeRoundedRect(x - 115, y - 120, 230, 250, 12);
      };
      draw(false);
      const zone = this.add.zone(x, y + 5, 230, 250).setInteractive();
      zone.on('pointerover', () => draw(true));
      zone.on('pointerout', () => draw(false));
      // Short delay so the tap that triggered the level-up can't pick a card by accident
      zone.on('pointerup', () => this.time.now - opened > 300 && pick(ch));
      c.add([
        card,
        zone,
        this.text(x, y - 60, ch.icon, 56, GOLD).setOrigin(0.5),
        this.text(x, y + 10, ch.name, 32).setOrigin(0.5),
        this.text(x, y + 66, ch.desc, 19, '#c8bca0').setOrigin(0.5),
      ]);
    });
    const opened = this.time.now;
    const onKey = (e) => {
      const i = ['1', '2', '3'].indexOf(e.key);
      if (i >= 0) pick(choices[i]);
    };
    this.time.delayedCall(250, () => this.levelPanel === c && this.input.keyboard.on('keydown', onKey));
  }

  // ---------- Victory ----------

  showVictory() {
    const reg = this.registry;
    this.tweens.killTweensOf([this.banner, this.bannerSub]);
    this.banner.setAlpha(0);
    this.bannerSub.setAlpha(0);
    this.signBox.setVisible(false);
    this.levelPanel?.destroy();
    this.levelPanel = null;
    const c = this.add.container(0, 0).setDepth(100).setAlpha(0);
    c.add(this.add.rectangle(0, 0, this.W, this.H, 0x0d1233, 0.88).setOrigin(0));
    const frame = this.add.graphics();
    frame.lineStyle(3, 0xd4a845).strokeRect(40, 40, this.W - 80, this.H - 80);
    c.add(frame);
    c.add(this.text(this.W / 2, 130, 'FIRST TRIAL COMPLETE', 52, GOLD).setOrigin(0.5));
    c.add(this.text(this.W / 2, 200, 'Ra has defeated the Reed Lion.\nThe road east lies open.', 22).setOrigin(0.5));
    c.add(this.text(this.W / 2, 280, `Level ${reg.get('level')}   ·   ${reg.get('gold')} gold`, 26, '#8ae0d8').setOrigin(0.5));
    c.add(this.text(this.W / 2, 335, 'Next: The Second Trial · The Thirsting Sands (coming soon)', 20, '#c8bca0').setOrigin(0.5));
    const again = this.text(this.W / 2, 425, '[ Play again ]', 30, GOLD).setOrigin(0.5);
    again.setInteractive().on('pointerup', () => this.restart());
    c.add(again);
    this.tweens.add({ targets: c, alpha: 1, duration: 800 });
    this.input.keyboard.once('keydown-R', () => this.restart());
  }

  restart() {
    resetState(this.registry);
    clearTouch();
    this.scene.get('Game').scene.restart();
    this.scene.restart();
  }

  // ---------- On-screen controls ----------

  createTouchControls() {
    this.input.addPointer(3);
    const btn = (x, y, r, label, key) => {
      const c = this.add.container(x, y).setDepth(50);
      const circle = this.add.circle(0, 0, r, 0xf2e6c9, 0.14).setStrokeStyle(3, 0xd4a845, 0.6);
      const t = this.text(0, 0, label, r * 0.7, PARCH).setOrigin(0.5).setAlpha(0.85);
      c.add([circle, t]);
      circle.setInteractive();
      const set = (v) => {
        touch[key] = v;
        circle.setFillStyle(0xf2e6c9, v ? 0.4 : 0.14);
      };
      circle.on('pointerdown', () => set(true));
      circle.on('pointerup', () => set(false));
      circle.on('pointerout', () => set(false));
      return c;
    };
    // Left thumb: movement. Right thumb: actions.
    btn(85, this.H - 90, 62, '◀', 'left');
    btn(230, this.H - 90, 62, '▶', 'right');
    btn(158, this.H - 205, 42, '▼', 'down');
    this.spellBtn = btn(0, this.H - 235, 46, '✦', 'spell').setVisible(false);
    this.rightButtons = [
      [btn(0, this.H - 90, 66, '▲', 'jump'), 90],
      [btn(0, this.H - 80, 56, '⚔', 'attack'), 240],
      [this.spellBtn, 130],
    ];
  }
}
