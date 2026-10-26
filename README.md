# MeetRa

A mobile action-adventure platformer in the spirit of **Swordigo**, with a light breeze of Persian epic poetry.

A young guardian named **Ra** walks the old **Road of Seven Trials** to win back the stolen Dawnfire from the Pale Giant.

## Status: M0 playable prototype

**The world:** 7 realms on a world map, each with its own map of **20 places** (140 in all): towns, hearths, trails, caves, shrines, ruins, an arena, a realm boss and a secret place. Clearing a place opens its neighbours; beating a realm's boss opens the next realm. The 7th realm, **the Lightless Land**, stays hidden until all six **Dawn Sigils** (one per secret place) are found. Progress is saved on the phone.

Every place has a playable level. The Reed Marsh is the hand-made tutorial; the others are built from level chunks and get harder realm by realm.

In every level:

- Walking, variable-height jumps, **double jump**, coyote time and jump buffering
- **3-hit sword combo**, down-strike (pogo), hitstop and screen shake
- **Saena's Feather** spell and the **Aura** bar
- XP, levelling and a **Heart / Might / Aura** choice
- Gold, breakable vases and bushes, a hidden chest, heart drops
- **Hearth** checkpoints that also heal you
- Pits and thorns send you back to the last safe ground
- Enemies: Hollow imps (they patrol, then chase you) and bats
- **Boss: the Reed Lion.** It charges, stuns itself on walls, pounces, and gets enraged at half health.
- Parallax backgrounds with sun rays, on-screen touch controls, generated sound effects
- A living world: grass that sways and parts around feet, weather for each realm (pollen and fireflies, dust, sand, snow, leaves, sea spray, embers), glowing hearths, coins and orbs, darkness and light in caves and the Lightless Land
- Juice: Ra's flowing scarf, breathing, landing squash and dust; hit sparks, shockwave rings, popping damage numbers, screen flashes; imps and bats that notice you, a lion that kicks up dust
- Procedural music in Persian modes: a santur and daf theme for exploring (Shur) and a tense boss theme (Chahargah), with a sound switch
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
- [Saga Bible (PDF)](docs/MeetRa-Saga-Bible.pdf): a game scenario for every story of the Shahnameh, plus the world map. Rebuild with `python docs/saga/build.py`.

## Project structure

```
lib/
  main.dart            App, landscape fullscreen, UI layered over the game
  config.dart          Constants, player tuning, GameState
  input.dart           Merges keyboard and touch input
  sfx.dart             Sound effects synthesized to WAV at startup
  music.dart           Procedural santur and daf music, rendered in a background isolate
  art/                 Pixel art generated from code (sprites, tiles, backgrounds)
  levels/              ASCII level builder, the hand-made tutorial and the level generator
  world/               The 7 realms × 20 places, unlock rules and the save file
  entities/            Player, Enemy (Imp, Bat), Lion
  game/                MeetRaGame (loop, camera, render), arcade physics, effects, ambience (grass, weather, lights)
  ui/                  HUD, menus, world and realm maps, touch buttons
test/                  Unit tests (level builder, physics, world and unlocks)
android/, ios/         Native platform projects
docs/                  Design documents
```

To add a level, write an ASCII map in `lib/levels/`. The character legend is in `build.dart`.

## Tech

[Flutter](https://flutter.dev) and [Flame](https://flame-engine.org), with [audioplayers](https://pub.dev/packages/audioplayers) for sound.
