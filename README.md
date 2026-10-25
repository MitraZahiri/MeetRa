# MeetRa

A mobile action-adventure platformer in the spirit of **Swordigo**, with a light breeze of Persian epic poetry.

A young guardian named **Ra** walks the old **Road of Seven Trials** to win back the stolen Dawnfire from the Pale Giant.

## Status: M0 playable prototype

The First Trial (The Reed Marsh) is playable from start to finish:

- Walking, variable-height jumps, **double jump**, coyote time and jump buffering
- **3-hit sword combo**, down-strike (pogo), hitstop and screen shake
- **Saena's Feather** spell and the **Aura** bar
- XP, levelling and a **Heart / Might / Aura** choice
- Gold, breakable vases and bushes, a hidden chest, heart drops
- **Hearth** checkpoints that also heal you
- Pits and thorns send you back to the last safe ground
- Enemies: Hollow imps (they patrol, then chase you) and bats
- **Boss: the Reed Lion.** It charges, stuns itself on walls, pounces, and gets enraged at half health.
- Parallax backgrounds, on-screen touch controls, generated sound effects
- Landscape lock, fullscreen, installable web app, Android project (Capacitor)

All art and sound are generated placeholders. Final art arrives in M1.

## Getting started (Visual Studio Code)

1. Open this folder in VS Code and install the recommended extensions when prompted.
2. Open a terminal (`` Ctrl+` ``) and run:

```bash
npm install
npm run dev
```

3. Open `http://localhost:5173` in a browser. Press **F5** in VS Code to launch Chrome with the debugger attached.

### Play on your phone (same Wi-Fi)
`npm run dev` prints a **Network** address such as `http://192.168.1.20:5173`. Open it on your phone and turn the phone sideways.

### Build the Android app
Requires [Android Studio](https://developer.android.com/studio).

```bash
npm run android
```

This builds the game, copies it into `android/` and opens Android Studio. Press ▶ Run to install it on a connected phone or an emulator.

iOS needs a Mac with Xcode: `npx cap add ios`, then `npm run ios`.

## Controls

| Action | Phone | Keyboard (dev) |
|---|---|---|
| Walk | ◀ ▶ | ← → / A D |
| Jump / double jump | ▲ | Space / ↑ / W |
| Sword combo | ⚔ | J / X |
| Down-strike | Hold ▼ in mid-air + ⚔ | ↓ + J |
| Drop through platform | Hold ▼ + ▲ | ↓ + Space |
| Saena's Feather | ✦ | K / C |
| Level-up choice | Tap a card | 1 / 2 / 3 |

## Documents

- [Swordigo analysis](docs/01-swordigo-analysis.md): a detailed breakdown of the reference game
- [Game design document](docs/02-game-design.md): story, the seven trials, mechanics, mobile design, roadmap

## Project structure

```
src/
  main.js              Phaser configuration
  config.js            Constants, player tuning, starting state
  input.js             Merges keyboard and touch input
  sfx.js               WebAudio sound effects
  art/                 Pixel art generated from code (sprites, tiles, backgrounds)
  levels/              ASCII level builder and the First Trial map
  entities/            Player, Enemy (Imp, Bat), Lion
  scenes/              Boot, Background (parallax), Game, UI
public/                Web app manifest and icon
android/               Native Android project (Capacitor)
docs/                  Design documents
```

To add a level, write an ASCII map in `src/levels/`. The character legend is in `build.js`.

## Tech

[Phaser 3](https://phaser.io), [Vite](https://vitejs.dev), [Capacitor](https://capacitorjs.com).
