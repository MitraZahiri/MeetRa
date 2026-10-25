import Phaser from 'phaser';
import { sfx } from '../sfx.js';

// The Reed Lion, boss of the First Trial.
// Loop: prowl, then (roar and) charge or pounce. A charge into a wall stuns it: that is your opening.
// Below half health it is enraged: faster, with double pounces.
export class Lion extends Phaser.Physics.Arcade.Sprite {
  constructor(scene, x, y) {
    super(scene, x, y, 'lion', 0);
    scene.add.existing(this);
    scene.physics.add.existing(this);
    this.setOrigin(0.5, 1).setScale(1.25).setDepth(9);
    this.body.setSize(32, 17).setOffset(4, 6);
    this.maxHp = 30;
    this.hp = this.maxHp;
    this.facing = -1;
    this.state = 'intro';
    this.timer = 1300;
    this.enraged = false;
    this.pounces = 0;
    this.contactDamage = 2;
  }

  get vulnerable() {
    return this.state !== 'dead';
  }

  setState(state, timer = 0) {
    this.state = state;
    this.timer = timer;
  }

  update(time, dt) {
    if (this.state === 'dead' || !this.body) return;
    const p = this.scene.player;
    const b = this.body;
    const onGround = b.blocked.down || b.touching.down;
    this.timer -= dt;
    const faceP = () => {
      this.facing = Math.sign(p.x - this.x) || this.facing;
    };

    switch (this.state) {
      case 'intro':
        b.velocity.x = 0;
        if (this.timer <= 0) this.setState('pace', 900);
        break;

      case 'pace':
        faceP();
        b.velocity.x = this.facing * (this.enraged ? 75 : 50);
        this.anims.play('lion-walk', true);
        this.anims.timeScale = 1;
        if (this.timer <= 0) {
          const pounce = Math.random() < (this.enraged ? 0.5 : 0.4);
          this.next = pounce ? 'pounce' : 'charge';
          this.pounces = this.enraged && pounce ? 2 : 1;
          this.setState('telegraph', this.enraged ? 380 : 550);
          if (!pounce) sfx.roar();
        }
        break;

      case 'telegraph':
        faceP();
        b.velocity.x = 0;
        this.anims.stop();
        this.setScale(1.3, 1.15); // crouch
        this.setTint(Math.floor(time / 70) % 2 ? 0xff8060 : 0xffffff);
        if (this.timer <= 0) {
          this.setScale(1.25).clearTint();
          if (this.next === 'charge') {
            this.setState('charge');
            this.scene.cameras.main.shake(200, 0.004);
          } else {
            this.doPounce(p);
          }
        }
        break;

      case 'charge': {
        b.velocity.x = this.facing * (this.enraged ? 290 : 240);
        this.anims.play('lion-walk', true);
        this.anims.timeScale = 2.5;
        const hitWall = (this.facing < 0 && (b.blocked.left || b.touching.left)) || (this.facing > 0 && (b.blocked.right || b.touching.right));
        if (hitWall) {
          this.anims.timeScale = 1;
          b.velocity.x = -this.facing * 60;
          b.velocity.y = -120;
          sfx.thud();
          this.scene.cameras.main.shake(300, 0.012);
          this.scene.burst(this.x + this.facing * 20, this.y - 10, [0xc8b8a0, 0x8a7a68], 12, 120);
          this.setState('stunned', 1500);
        }
        break;
      }

      case 'pounce':
        if (onGround && this.timer <= 0) {
          sfx.thud();
          this.scene.cameras.main.shake(120, 0.006);
          this.scene.burst(this.x, this.y, [0xc8b8a0], 8, 80);
          this.pounces--;
          if (this.pounces > 0) this.doPounce(p);
          else this.setState('pace', 900 + Math.random() * 900);
        }
        break;

      case 'stunned':
        if (onGround) b.velocity.x *= 0.9;
        this.anims.stop();
        this.setFrame(0);
        this.setAngle(Math.sin(time / 50) * 3);
        if (this.timer <= 0) {
          this.setAngle(0);
          this.setState('pace', 700);
        }
        break;
    }
    this.setFlipX(this.facing < 0);
  }

  doPounce(p) {
    this.facing = Math.sign(p.x - this.x) || this.facing;
    this.body.velocity.y = -340;
    this.body.velocity.x = Phaser.Math.Clamp((p.x - this.x) * 1.5, -220, 220);
    this.anims.stop();
    this.setFrame(1);
    this.setState('pounce', 150);
  }

  hurt(dmg) {
    if (this.state === 'dead') return;
    const real = this.state === 'stunned' ? Math.ceil(dmg * 1.5) : dmg;
    this.hp = Math.max(0, this.hp - real);
    this.setTintFill(0xffffff);
    this.scene.time.delayedCall(70, () => this.active && this.state !== 'dead' && this.clearTint());
    this.scene.floatText(this.x, this.y - 32, `${real}`, this.state === 'stunned' ? '#ff9a5a' : '#ffe28a');
    this.scene.events.emit('boss-hp', this.hp / this.maxHp);
    if (!this.enraged && this.hp <= this.maxHp / 2) {
      this.enraged = true;
      sfx.roar();
      this.scene.cameras.main.shake(400, 0.01);
    }
    if (this.hp <= 0) this.die();
  }

  die() {
    this.state = 'dead';
    this.body.enable = false;
    this.anims.stop();
    sfx.roar();
    const s = this.scene;
    s.cameras.main.shake(800, 0.01);
    s.tweens.add({
      targets: this,
      alpha: 0,
      angle: this.facing * -15,
      duration: 1400,
      onUpdate: () => {
        if (Math.random() < 0.3) s.burst(this.x + Phaser.Math.Between(-20, 20), this.y - Phaser.Math.Between(4, 28), [0xd9a441, 0xf0c870, 0x8a4a1a], 4, 90);
      },
      onComplete: () => {
        s.onBossDefeated(this.x, this.y);
        this.destroy();
      },
    });
  }
}
