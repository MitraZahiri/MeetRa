import Phaser from 'phaser';
import { PLAYER, T } from '../config.js';
import { sfx } from '../sfx.js';

const approach = (v, target, step) => (v < target ? Math.min(v + step, target) : Math.max(v - step, target));
const SOLID = new Set([T.GRASS, T.DIRT, T.BRICK, T.PLATFORM]);

export class Player extends Phaser.Physics.Arcade.Sprite {
  constructor(scene, x, y) {
    super(scene, x, y, 'hero', 0);
    scene.add.existing(this);
    scene.physics.add.existing(this);
    this.setOrigin(0.5, 1).setDepth(10);
    this.body.setSize(8, 16).setOffset(2, 2);
    this.body.setMaxVelocityY(520);
    this.setCollideWorldBounds(true);

    this.facing = 1;
    this.coyote = 0;
    this.jumpBuffer = 0;
    this.canDouble = true;
    this.jumpCut = false;
    this.attackTimer = 0;
    this.attackQueued = false;
    this.comboStep = 0;
    this.comboWindow = 0;
    this.spellCooldown = 0;
    this.invuln = 0;
    this.hurtLock = 0;
    this.dropTimer = 0;
    this.dead = false;
    this.frozen = false;
    this.safe = { x, y };
    this.safeTimer = 0;
  }

  get reg() {
    return this.scene.registry;
  }

  update(c, dt) {
    if (this.dead) return;
    if (this.frozen) {
      this.setVelocityX(0);
      return;
    }
    const body = this.body;
    const onGround = body.blocked.down || body.touching.down;

    this.coyote = onGround ? PLAYER.coyote : Math.max(0, this.coyote - dt);
    if (onGround) this.canDouble = true;
    this.jumpBuffer = c.jumpPressed ? PLAYER.buffer : Math.max(0, this.jumpBuffer - dt);
    this.invuln = Math.max(0, this.invuln - dt);
    this.hurtLock = Math.max(0, this.hurtLock - dt);
    this.dropTimer = Math.max(0, this.dropTimer - dt);
    this.attackTimer = Math.max(0, this.attackTimer - dt);
    this.comboWindow = Math.max(0, this.comboWindow - dt);
    this.spellCooldown = Math.max(0, this.spellCooldown - dt);

    // Horizontal movement
    let dir = (c.right ? 1 : 0) - (c.left ? 1 : 0);
    if (this.hurtLock > 0) dir = 0;
    if (dir && this.attackTimer <= 0) this.facing = dir;
    if (this.hurtLock <= 0) {
      const slow = this.attackTimer > 0 && onGround ? 0.35 : 1;
      const accel = (onGround ? PLAYER.accelGround : PLAYER.accelAir) * (dt / 1000);
      body.velocity.x = approach(body.velocity.x, dir * PLAYER.speed * slow, accel);
    }

    // Jumping (coyote time + buffer + double jump + drop through platforms)
    if (this.jumpBuffer > 0 && this.hurtLock <= 0) {
      if (c.down && onGround && this.tileUnderIs(T.PLATFORM)) {
        this.dropTimer = 250;
        this.jumpBuffer = 0;
      } else if (this.coyote > 0) {
        this.jump(PLAYER.jump);
        this.coyote = 0;
      } else if (this.canDouble) {
        this.jump(PLAYER.doubleJump);
        this.canDouble = false;
        this.scene.burst(this.x, this.y, [0xf2e6c9, 0x8ae0d8], 6, 60);
      }
    }
    if (!c.jump && body.velocity.y < -120 && !this.jumpCut) {
      body.velocity.y *= 0.45;
      this.jumpCut = true;
    }

    // Sword (presses during a swing are queued, so combos flow)
    if (c.attackPressed) this.attackQueued = true;
    if (this.attackQueued && this.attackTimer <= 0 && this.hurtLock <= 0) {
      this.attackQueued = false;
      this.attack(c, onGround);
    }
    if (c.spellPressed) this.castFeather();

    // Aura regeneration
    const aura = this.reg.get('aura');
    const auraMax = this.reg.get('auraMax');
    if (aura < auraMax) this.reg.set('aura', Math.min(auraMax, aura + 10 * (dt / 1000)));

    this.trackSafeGround(onGround, dt);
    this.animate(onGround);
  }

  jump(v) {
    this.body.velocity.y = -v;
    this.jumpCut = false;
    this.jumpBuffer = 0;
    sfx.jump();
    this.setScale(0.85, 1.15);
    this.scene.tweens.add({ targets: this, scaleX: 1, scaleY: 1, duration: 160 });
  }

  attack(c, onGround) {
    const down = !onGround && c.down;
    this.comboStep = this.comboWindow > 0 && !down ? (this.comboStep + 1) % 3 : 0;
    const step = down ? 'down' : this.comboStep;
    this.attackTimer = step === 2 ? 300 : 190;
    this.comboWindow = this.attackTimer + 260;
    sfx.swing();

    const b = this.body;
    const atk = this.reg.get('attack');
    let rect;
    let dmg = atk;
    let knock = 1;
    if (step === 'down') {
      rect = new Phaser.Geom.Rectangle(b.center.x - 11, b.bottom - 4, 22, 22);
    } else {
      const w = step === 2 ? 28 : 22;
      rect = new Phaser.Geom.Rectangle(this.facing > 0 ? b.right - 2 : b.left - w + 2, b.top - 5, w, 24);
      if (step === 2) {
        dmg = Math.ceil(atk * 1.6);
        knock = 1.8;
      }
    }

    // Slash trail
    const s = this.scene.add.image(rect.centerX, rect.centerY, 'slash').setDepth(11);
    s.setFlipX(this.facing < 0);
    if (step === 1) s.setFlipY(true);
    if (step === 2) s.setScale(1.3).setTint(0xffe28a);
    if (step === 'down') s.setAngle(90).setFlipX(false);
    this.scene.tweens.add({ targets: s, alpha: 0, duration: 160, onComplete: () => s.destroy() });

    const hits = this.scene.resolveMelee(rect, dmg, this.facing, knock);
    if (step === 'down' && hits > 0) {
      this.body.velocity.y = -270; // bounce off enemies with a down strike (pogo)
      this.canDouble = true;
    }
  }

  castFeather() {
    if (!this.reg.get('hasFeather') || this.spellCooldown > 0 || this.hurtLock > 0) return;
    if (this.reg.get('aura') < PLAYER.featherCost) {
      sfx.fizzle();
      this.spellCooldown = 200;
      return;
    }
    this.reg.set('aura', this.reg.get('aura') - PLAYER.featherCost);
    this.spellCooldown = 300;
    this.scene.spawnFeather(this.x + this.facing * 8, this.y - 10, this.facing, this.reg.get('magic'));
  }

  hurt(dmg, fromX) {
    if (this.invuln > 0 || this.dead || this.frozen) return;
    this.reg.set('hp', Math.max(0, this.reg.get('hp') - dmg));
    sfx.hurt();
    this.scene.cameras.main.shake(150, 0.006);
    this.invuln = PLAYER.invuln;
    this.hurtLock = 260;
    const away = Math.sign(this.x - fromX) || -this.facing;
    this.setVelocity(away * 160, -180);
    this.setTintFill(0xff4040);
    this.scene.time.delayedCall(90, () => this.clearTint());
    if (this.reg.get('hp') <= 0) this.scene.playerDied();
  }

  // Pits and thorns: half a heart of damage, then back to the last safe ground
  fallHurt() {
    if (this.dead) return;
    this.reg.set('hp', Math.max(0, this.reg.get('hp') - 1));
    sfx.hurt();
    if (this.reg.get('hp') <= 0) {
      this.scene.playerDied();
      return;
    }
    this.respawnAt(this.safe.x, this.safe.y);
    this.invuln = PLAYER.invuln;
  }

  respawnAt(x, y) {
    this.setPosition(x, y);
    this.setVelocity(0, 0);
    this.hurtLock = 0;
    this.attackTimer = 0;
  }

  tileUnderIs(index) {
    const t = this.scene.layer.getTileAtWorldXY(this.body.center.x, this.body.bottom + 2);
    return t && t.index === index;
  }

  trackSafeGround(onGround, dt) {
    if (!onGround || this.invuln > 0) {
      this.safeTimer = 0;
      return;
    }
    const layer = this.scene.layer;
    const l = layer.getTileAtWorldXY(this.body.left - 2, this.body.bottom + 2);
    const r = layer.getTileAtWorldXY(this.body.right + 2, this.body.bottom + 2);
    if (l && r && SOLID.has(l.index) && SOLID.has(r.index)) {
      this.safeTimer += dt;
      if (this.safeTimer > 150) this.safe = { x: this.x, y: this.y };
    }
  }

  animate(onGround) {
    this.setFlipX(this.facing < 0);
    this.setAlpha(this.invuln > 0 && Math.floor(this.scene.time.now / 60) % 2 ? 0.35 : 1);
    if (this.attackTimer > 0) {
      this.anims.stop();
      this.setFrame(4);
    } else if (!onGround) {
      this.anims.stop();
      this.setFrame(3);
    } else if (Math.abs(this.body.velocity.x) > 10) {
      this.anims.play('hero-run', true);
    } else {
      this.anims.stop();
      this.setFrame(0);
    }
  }
}
