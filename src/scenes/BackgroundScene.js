import Phaser from 'phaser';
import { ZOOM } from '../config.js';

// Parallax layers: follows the game camera and scrolls each layer at its own speed
export class BackgroundScene extends Phaser.Scene {
  constructor() {
    super('Background');
  }

  create() {
    const layers = [
      ['bg-sky', 0],
      ['bg-clouds', 0.06],
      ['bg-mountains', 0.15],
      ['bg-hills', 0.35],
    ];
    // Layer art is drawn at world scale (480x270); the camera shows GAME/ZOOM of it
    this.layers = layers.map(([key, factor]) => ({
      ts: this.add.tileSprite(0, 0, this.scale.width / ZOOM, this.scale.height / ZOOM, key).setOrigin(0).setScale(ZOOM),
      factor,
    }));
    this.drift = 0;
    const resize = (size) => this.layers.forEach((l) => l.ts.setSize(size.width / ZOOM, size.height / ZOOM));
    this.scale.on('resize', resize);
    this.events.once('shutdown', () => this.scale.off('resize', resize));
  }

  update(time, delta) {
    this.drift += delta * 0.004;
    const cam = this.scene.get('Game')?.cameras?.main;
    const view = cam ? cam.worldView : { x: 0, y: 0 };
    // Vertically the layers move with the world (art and map are both ~270px tall)
    const y = Phaser.Math.Clamp(view.y, 0, 270 - this.scale.height / ZOOM);
    for (const l of this.layers) {
      l.ts.tilePositionX = view.x * l.factor + (l.factor && l.factor < 0.1 ? this.drift : 0);
      l.ts.tilePositionY = y;
    }
  }
}
