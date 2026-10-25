// Game-wide constants

export const TILE = 16;
export const ZOOM = 3;
// Screen is 960x540; the world camera zooms 3x, so 320x180 world pixels are visible
export const GAME_W = 960;
export const GAME_H = 540;
export const GRAVITY = 900;

// Palette: lapis, turquoise, gold, vermilion, parchment
export const COLORS = {
  lapis: 0x1b2a6b,
  turquoise: 0x2bb3a8,
  gold: 0xd4a845,
  red: 0xb83a2e,
  parchment: 0xf2e6c9,
  ink: 0x1a1020,
};

// Tileset frame indices
export const T = {
  GRASS: 0,
  DIRT: 1,
  PLATFORM: 2,
  BRICK: 3,
  SPIKES: 4,
};

export const PLAYER = {
  speed: 110,
  accelGround: 1600,
  accelAir: 950,
  jump: 310,
  doubleJump: 270,
  coyote: 90, // ms you can still jump after walking off a ledge
  buffer: 120, // ms a jump pressed before landing is remembered
  invuln: 1000,
  featherCost: 20,
};

// XP needed to go from level N to N+1
export const xpForLevel = (lv) => Math.floor(20 + (lv - 1) * 15 + (lv - 1) ** 2 * 5);

// Health is counted in half hearts: 6 = 3 hearts
export const DEFAULT_STATE = {
  hp: 6,
  maxHp: 6,
  aura: 60,
  auraMax: 60,
  attack: 1,
  magic: 2,
  gold: 0,
  xp: 0,
  level: 1,
  xpNext: xpForLevel(1),
  hasFeather: false,
};

export function resetState(registry) {
  for (const [k, v] of Object.entries(DEFAULT_STATE)) registry.set(k, v);
}
