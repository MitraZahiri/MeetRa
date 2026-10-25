# MeetRa: Game Design Document

**v0.2 · Mobile action-adventure platformer**

---

## 1. Pitch
A young guardian named **Ra** walks the old **Road of Seven Trials** to win back the stolen **Dawnfire** from the Pale Giant. Each trial has a guardian beast to beat and a new power to earn.

**Platform:** phones first (Android and iOS), played in landscape with touch controls.
**Feel:** Swordigo's tight, pick-up-and-play adventure, with better combat and a world people remember.

## 2. Inspiration: A Breeze, Not a Retelling
MeetRa takes only a light breeze from Persian epic poetry, especially the *Shahnameh*. It borrows themes and motifs, never the plot, characters or names:

- **Seven trials** on a dangerous road
- **Mythic beasts** as guardians: a lion, a serpent, a witch, a pale giant
- A **great guardian bird** who helps the hero (Saena)
- **Sacred hearth fires** that keep the dark away
- Visual motifs: cypress trees, pointed arches, curling ribbon clouds, lapis and gold

All characters, places and story beats are **original**. The game is in English.

## 3. Story

**The Hearthvale.** The vale has always been kept safe by the **Dawnfire**, a flame that never goes out. One night the **Pale Giant** comes down from the northern ice, swallows the flame and blinds the King's guard with frost. The vale starts to go dark.

Ra's teacher, **Old Mehr**, the keeper of the village hearth, tells Ra about two roads to the Giant's cave: the long, safe road and the old **Road of Seven Trials**. It is short, but no one has come back from it. Ra takes the short road.

**The Dawnblade.** Ra's family has guarded the Dawnblade for generations. The Giant breaks it into **four shards** and gives them to the trial guardians. *(Like Swordigo's Mageblade.)*

**Saena.** A great emerald bird who once raised a lost child in her nest on the mountain. When Ra burns one of her feathers at a hearth, she appears, guides Ra and gives new powers. *(Like Swordigo's ghostly master.)*

### The Seven Trials (regions)

| # | Trial | Region | Mechanical identity | Boss | Reward |
|---|---|---|---|---|---|
| 1 | **The Reed Lion** | Reed Marsh | Tutorial: move, jump, sword | **The Reed Lion** | Saena's Feather (found on the hill before the boss) |
| 2 | **The Thirsting Sands** | Desert | Water meter; follow a white ram to hidden springs | **Sand Wraith** | Dawnblade shard I |
| 3 | **The Night Serpent** | Dark Valley | Darkness; carry and light lanterns; the serpent hides in shadow | **Night Serpent** | Ember Burst |
| 4 | **The Veiled Witch** | Garden of Illusions | False platforms and false friends | **The Veiled Witch** | Truthlight · shard II |
| 5 | **The Mountain Warden** | High Passes | Lasso: swing across gaps, pull enemies | **The Warden** (becomes an ally) | Hunter's Lasso |
| 6 | **The Horned Warlord** | Giant's War Camp | Large fights against shielded brutes | **The Horned Warlord** | shard III |
| 7 | **The Pale Giant** | Frozen Cave | Every ability is tested | **The Pale Giant** | shard IV · the Dawnfire returns |

**Ending:** The Dawnfire melts the frost from the guards' eyes. In the last shot, something with two serpent heads watches from the shadows. *(Sequel hook.)*

### Hub
**Hearthvale village** (like Swordigo's Cairnwood): Old Mehr's hearth, a market (shops), a smith, the **Hearthkeeper** (free full heal) and a hill that looks toward Saena's mountain.

## 4. Gameplay

### 4.1 Controls (phone)
Landscape. Left thumb moves; right thumb acts.

| Button | Action |
|---|---|
| ◀ ▶ | Walk |
| ▼ | Hold in mid-air and swing to strike down; hold and jump to drop through platforms |
| ▲ | Jump; tap again in mid-air to double jump; hold to jump higher |
| ⚔ | Sword: **3-hit combo** |
| ✦ | Cast the selected spell (appears once a spell is earned) |

Rule from Swordigo: **a button does not appear until its ability is earned.**
A keyboard works for development: arrows/WASD, Space, J, K.

### 4.2 Combat (where we beat Swordigo)
- 3-hit combo; the third hit is stronger and knocks back
- **Hitstop** (60–80 ms freeze on hit), screen shake, spark particles
- Enemies flinch and get knocked back when hit
- Down-strike bounces off enemies (pogo)
- Sword reflects projectiles (planned)
- Coyote time and jump buffering for forgiving platforming

### 4.3 Spells (one for each of Swordigo's four)
| Spell | Swordigo equivalent | Combat | Exploration |
|---|---|---|---|
| **Saena's Feather** | Magic Bolt | Ranged feather projectile | Distant switches |
| **Ember Burst** | Magic Bomb | Area damage | Breaks cracked stone walls |
| **Hunter's Lasso** | Dragon's Grasp | Pulls enemies | Swing from hook rings |
| **Truthlight** | Dimension Rift | Breaks enchanted shields | Reveals illusions and hidden paths |

Resource: **Aura**, a gold bar that refills over time.

### 4.4 Progression
- **XP → level:** choose **Heart** (+1 heart), **Might** (+sword damage) or **Aura** (+spell power and a bigger bar).
- **Gold:** from enemies, bushes, vases and chests.
- **Gear:** swords, armor (e.g. the striped *Tiger Coat*), charms (regeneration, fire resistance, frost).
- **Checkpoints:** **Hearths** (sacred fire altars) save progress, heal and allow fast travel.
- **Collectibles:** hidden chests and **Lore Scrolls** that unlock a bestiary and short stories.

### 4.5 Death and falling
- Falling into a pit or thorns: back to the last safe ground, half a heart lost.
- Death: restart at the last hearth.

## 5. Enemies
Enemy families with element variants (Swordigo's method):
- **Hollow imps:** green (marsh), sand (desert), ash (war camp), pale (ice cave)
- **Bats:** normal, fire, frost
- **Scorpions** (desert), **serpentlings** (valley)
- **Giant's soldiers:** shield, spear, archer
- **Wisps:** create illusions (garden)

## 6. Mobile Design
- **Landscape only.** The app is locked to landscape.
- **Sessions:** a trial can be played in 10–15 minute chunks; hearths are never more than about 2 minutes apart.
- **Thumb zones:** no HUD in the bottom corners; the boss bar sits at the top.
- **Readable at small sizes:** the world camera shows 320×180 pixels at 3× zoom.
- **Performance target:** 60 fps on mid-range Android phones.
- **Distribution:** native Flutter apps (Google Play, App Store).
- **Monetization:** premium, no ads (like Swordigo). Open question.

## 7. Visual Style
- Flat, ornamental 2D with bold silhouettes
- Gold-leaf details, lapis skies, turquoise hills, vermilion accents
- Layered parallax: ribbon clouds, stylized mountains, cypress rows
- UI framed with thin gold borders
- Palette: `#1B2A6B` lapis · `#2BB3A8` turquoise · `#D4A845` gold · `#B83A2E` vermilion · `#F2E6C9` parchment

## 8. Audio
Original score. Plucked strings, reed flute and frame drum give the light Persian breeze; boss fights get heavier drums and horns.

## 9. Technology
- **Engine:** Flutter + Flame (Dart), with a small custom arcade physics layer
- **Mobile:** Android and iOS from one codebase (iOS builds need a Mac)
- **Editor:** Visual Studio Code
- **Levels:** ASCII maps in code for now, then **Tiled** (.tmj)
- **Resolution:** 540-high virtual screen, width follows the aspect ratio; world zoom 3×
- **Saves:** later, with shared_preferences

## 10. Roadmap
| Milestone | Content | Status |
|---|---|---|
| **M0: Prototype** | Movement, combos, Saena's Feather, XP and level choice, gold, breakables, hearths, Trial 1 map and Reed Lion boss, touch controls, Android project | ✅ done |
| M1: Vertical slice | Final sprites, music and sound, Hearthvale hub, shop, dialogue, saving | ⏳ |
| M2: Trials 2–3 | Desert (water meter), Night Serpent, Ember Burst | ⏳ |
| M3: Trials 4–5 | Illusions, Truthlight, Hunter's Lasso and swinging | ⏳ |
| M4: Trials 6–7 | War camp, Pale Giant, ending | ⏳ |
| M5: Launch | Polish, store pages, Google Play and App Store release | ⏳ |

## 11. Open Questions
- Art: pixel art or hand-painted?
- Premium price, or free demo plus a full-game unlock?
- Does Ra get a mount for chase sequences?
