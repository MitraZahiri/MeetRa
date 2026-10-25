import Phaser from 'phaser';
import { generateTextures, createAnims } from '../art/sprites.js';
import { resetState } from '../config.js';

export class BootScene extends Phaser.Scene {
  constructor() {
    super('Boot');
  }

  create() {
    generateTextures(this);
    createAnims(this);
    resetState(this.registry);
    this.scene.launch('Background');
    this.scene.launch('Game');
    this.scene.launch('UI');
    this.scene.stop();
  }
}
