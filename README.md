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
- Landscape lock and fullscreen on Android and iOS

All art and sound are generated placeholders. Final art arrives in M1.

## Getting started

Requires [Flutter](https://docs.flutter.dev/get-started/install) (3.29 or newer) and [Android Studio](https://developer.android.com/studio) with an emulator, or a phone with USB debugging.

```bash
flutter pub get
flutter emulators --launch Pixel_8_Pro_API_29   # or any AVD, or plug in a phone
flutter run
```

In VS Code, install the recommended extensions when prompted, pick **MeetRa (debug)** and press **F5**. Press `r` in the terminal (or save a file) to hot reload.

On a computer the keyboard works too (see Controls). iOS needs a Mac with Xcode: `flutter run` on an iOS simulator.

Run the tests with `flutter test`.

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
lib/
  main.dart            App, landscape fullscreen, UI layered over the game
  config.dart          Constants, player tuning, GameState
  input.dart           Merges keyboard and touch input
  sfx.dart             Sound effects synthesized to WAV at startup
  art/                 Pixel art generated from code (sprites, tiles, backgrounds)
  levels/              ASCII level builder and the First Trial map
  entities/            Player, Enemy (Imp, Bat), Lion
  game/                MeetRaGame (loop, camera, render), arcade physics, effects
  ui/                  HUD, sign box, banner, boss bar, menus, touch buttons
test/                  Unit tests (level builder, physics)
android/, ios/         Native platform projects
docs/                  Design documents
```

To add a level, write an ASCII map in `lib/levels/`. The character legend is in `build.dart`.

## Tech

[Flutter](https://flutter.dev) and [Flame](https://flame-engine.org), with [audioplayers](https://pub.dev/packages/audioplayers) for sound.
