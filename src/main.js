import Phaser from 'phaser';
import { GAME_W, GAME_H, GRAVITY } from './config.js';
import { touch } from './input.js';
import { BootScene } from './scenes/BootScene.js';
import { BackgroundScene } from './scenes/BackgroundScene.js';
import { GameScene } from './scenes/GameScene.js';
import { UIScene } from './scenes/UIScene.js';

const game = new Phaser.Game({
  type: Phaser.AUTO,
  parent: 'game',
  width: GAME_W,
  height: GAME_H,
  backgroundColor: '#0d1233',
  pixelArt: true,
  roundPixels: true,
  physics: {
    default: 'arcade',
    arcade: { gravity: { x: 0, y: GRAVITY }, debug: false },
  },
  scale: {
    // EXPAND fills wide phone screens: height stays 540, width grows with the aspect ratio
    mode: Phaser.Scale.EXPAND,
    autoCenter: Phaser.Scale.CENTER_BOTH,
  },
  input: { activePointers: 4 },
  scene: [BootScene, BackgroundScene, GameScene, UIScene],
});

// Console access during development
if (import.meta.env.DEV) {
  window.__game = game;
  window.__touch = touch;
}
