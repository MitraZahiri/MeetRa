import Phaser from 'phaser';

// Live state of the on-screen buttons (written by UIScene, read by Controls)
export const touch = { left: false, right: false, down: false, jump: false, attack: false, spell: false };

export function clearTouch() {
  for (const k of Object.keys(touch)) touch[k] = false;
}

// Merges keyboard and touch input into one state
export class Controls {
  constructor(scene) {
    const K = Phaser.Input.Keyboard.KeyCodes;
    this.keys = scene.input.keyboard.addKeys({
      left: K.LEFT, right: K.RIGHT, up: K.UP, down: K.DOWN,
      a: K.A, d: K.D, w: K.W, s: K.S,
      space: K.SPACE, z: K.Z, j: K.J, x: K.X, k: K.K, c: K.C,
    });
    this.prev = { jump: false, attack: false, spell: false };
    this.state = {};
  }

  update() {
    const k = this.keys;
    const s = this.state;
    s.left = k.left.isDown || k.a.isDown || touch.left;
    s.right = k.right.isDown || k.d.isDown || touch.right;
    s.down = k.down.isDown || k.s.isDown || touch.down;
    const jump = k.space.isDown || k.up.isDown || k.w.isDown || k.z.isDown || touch.jump;
    const attack = k.j.isDown || k.x.isDown || touch.attack;
    const spell = k.k.isDown || k.c.isDown || touch.spell;
    s.jump = jump;
    s.jumpPressed = jump && !this.prev.jump;
    s.attackPressed = attack && !this.prev.attack;
    s.spellPressed = spell && !this.prev.spell;
    this.prev.jump = jump;
    this.prev.attack = attack;
    this.prev.spell = spell;
    return s;
  }
}
