import Phaser from 'phaser';

// Shared enemy behaviour: health, hit flash and knockback, loot on death
export class Enemy extends Phaser.Physics.Arcade.Sprite {
  constructor(scene, x, y, key, opts) {
    super(scene, x, y, key, 0);
    scene.add.existing(this);
    this.setOrigin(0.5, 1).setDepth(8);
    this.hp = opts.hp;
    this.contactDamage = opts.damage;
    this.xpValue = opts.xp;
    this.goldValue = opts.gold;
    this.colors = opts.colors;
    this.stun = 0;
    this.dying = false;
  }

  // Call AFTER adding to a physics group: group defaults overwrite body settings
  initBody() {}

  hurt(dmg, dir, knock = 1) {
    if (this.dying) return;
    this.hp -= dmg;
    this.setTintFill(0xffffff);
    this.scene.time.delayedCall(80, () => this.active && this.clearTint());
    this.scene.floatText(this.x, this.y - this.height, `${dmg}`, '#ffe28a');
    if (this.hp <= 0) {
      this.die();
      return;
    }
    this.stun = 300;
    this.body.velocity.x = dir * 140 * knock;
    if (this.body.allowGravity) this.body.velocity.y = -110 * knock;
  }

  die() {
    this.dying = true;
    const s = this.scene;
    s.burst(this.x, this.y - this.height / 2, this.colors, 14, 140);
    s.spawnGold(this.x, this.y - 8, this.goldValue);
    s.spawnXp(this.x, this.y - 8, this.xpValue);
    this.destroy();
  }
}

export class Imp extends Enemy {
  constructor(scene, x, y) {
    super(scene, x, y, 'imp', { hp: 3, damage: 1, xp: 6, gold: 3, colors: [0x4a8a3a, 0x2e5a26, 0xe8dcc0] });
    this.dir = -1;
  }

  initBody() {
    this.body.setSize(10, 14).setOffset(2, 1);
    this.play('imp-walk');
  }

  update(time, dt) {
    if (this.dying || !this.body) return;
    if (this.y > this.scene.level.height + 60) return this.destroy();
    if (this.stun > 0) {
      this.stun -= dt;
      return;
    }
    const p = this.scene.player;
    const dx = p.x - this.x;
    const aggro = !p.dead && Math.abs(dx) < 90 && Math.abs(p.y - this.y) < 24;
    if (aggro) this.dir = Math.sign(dx) || this.dir;

    const b = this.body;
    if ((this.dir < 0 && b.blocked.left) || (this.dir > 0 && b.blocked.right)) this.dir *= -1;
    // Turn around at ledges
    if (b.blocked.down) {
      const ahead = this.scene.layer.getTileAtWorldXY(this.x + this.dir * 8, this.y + 4);
      if (!ahead) this.dir *= -1;
    }
    b.velocity.x = this.dir * (aggro ? 70 : 30);
    this.setFlipX(this.dir > 0);
    this.anims.timeScale = aggro ? 2 : 1;
  }
}

export class Bat extends Enemy {
  constructor(scene, x, y) {
    super(scene, x, y, 'bat', { hp: 2, damage: 1, xp: 4, gold: 2, colors: [0x4b2a5e, 0x7a4a8e] });
    this.homeY = y;
    this.awake = false;
    this.t = Math.random() * 10;
  }

  initBody() {
    this.body.setAllowGravity(false);
    this.body.setSize(10, 6).setOffset(2, 1);
    this.play('bat-fly');
    this.anims.timeScale = 0.3;
  }

  update(time, dt) {
    if (this.dying || !this.body) return;
    this.t += dt / 1000;
    if (this.stun > 0) {
      this.stun -= dt;
      this.body.velocity.scale(0.9);
      return;
    }
    const p = this.scene.player;
    const dx = p.x - this.x;
    const dy = p.y - 10 - this.y;
    if (!this.awake && Math.hypot(dx, dy) < 110 && !p.dead) {
      this.awake = true;
      this.anims.timeScale = 1;
    }
    if (!this.awake) {
      this.body.velocity.set(0, Math.sin(this.t * 2) * 8);
      return;
    }
    const d = Math.hypot(dx, dy) || 1;
    this.body.velocity.set((dx / d) * 60, (dy / d) * 60 + Math.sin(this.t * 6) * 40);
    this.setFlipX(dx > 0);
  }
}
