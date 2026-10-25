# Swordigo: Reference Analysis

> MeetRa takes its core feel from **Swordigo**. This document breaks Swordigo down so we can understand why it works. The goal is to learn from it, not to copy it.

## 1. Overview

| Field | Value |
|---|---|
| Developer / Publisher | Touch Foo (independent studio, Finland) |
| Release | March 22, 2012, iOS and Android |
| Genre | 2.5D side-scrolling action-adventure platformer, action RPG, light Metroidvania |
| Influences | *Zelda II: The Adventure of Link*, *Metroid*, *Castlevania: Symphony of the Night* |
| Scores | Metacritic 86/100 · TouchArcade 4.5/5 · AppSpy 5/5 · Pocket Gamer 8/10 · Gamezebo 4/5 |
| Length | ~8 hours main story, 10+ hours for every chest |
| Downloads | ~10 million, with a loyal fan base |
| Business model | Premium; no in-app purchases |

## 2. Story Summary

1. A nameless young hero lives in **Cairnwood** village. He finds his master dead in the forest.
2. He learns the world is overrun by dark creatures called **Corruptors**.
3. The only weapon that can destroy them is the **Mageblade**.
4. When he reaches the keep where it was hidden, he learns it was **broken into four pieces**.
5. His master's **ghost** guides him. Each major region ends with a boss that guards a shard.
6. The shards are reforged in the **Chambers of Power**, and the hero enters **World's End Keep**.
7. The final boss, the **Master of Chaos**, is a dark double of the hero.

**Takeaway:** The story is deliberately minimal and never gets in the way, but its characters are forgettable. Reviewers raised this often. *This is where MeetRa can do better.*

## 3. Controls

Swordigo's most praised feature is its touch controls. TouchArcade called them flawless.

| Input | Behaviour |
|---|---|
| Left / Right | Hold to walk; double-tap to run |
| Jump | Tap to jump; tap again in mid-air to **double jump**; hold to jump higher (variable height) |
| Sword | Appears after the first weapon is found; swings **reflect projectiles** |
| Spell | Appears above Jump after the first spell; spell selection sits under the mana bar |
| Hand (lift/throw) | Lift, throw and place pots and boxes |
| Menu | Top-left: character, inventory, world map, quests, options |

**Lesson:** Keep the screen clean. Few buttons, and new buttons appear only when an ability is earned. This teaches the player and keeps the layout simple.

## 4. Core Loop

```
Explore → break enemies, grass and pots → collect XP and Soul Shards (currency)
   → level up (choose Health / Damage / Magic) → buy swords, armor, trinkets
   → earn a new spell → blocked paths open in old areas → boss → blade shard
```

### 4.1 Progression
- **Levels:** Each level-up lets the player raise **one of three stats**: Health, Damage or Magic. Simple, but it is a real choice.
- **Health:** Hearts; start with 3.
- **Currency:** Soul Shards, dropped by enemies, grass, pots and boxes.
- **Mana:** Blue bar that refills over time; spells cost mana.
- **Gear:** Swords (damage), armor (damage taken), **trinkets** (passives such as ice, energy, regeneration).
- **Healers:** Every major town has one, and they restore full health for free.

### 4.2 Spells (four in total, each a combat tool and a puzzle tool)

| Spell | Combat | Exploration | Given by |
|---|---|---|---|
| **Magic Bolt** | Ranged projectile | Hits distant switches | Master (early) |
| **Magic Bomb** | Area damage | Breaks cracked walls and rocks; hidden chests | Master's ghost (Forgotten Keep Cellar) |
| **Dragon's Grasp** | Pulls enemies in | Grapples up to ledges | A spirit (Fiery Depths) |
| **Dimension Rift** | Breaks some bosses' shields | Reveals hidden paths in another dimension | A spirit (Hall of Trials) |

**Lesson:** Each new ability adds a new puzzle language and a reason to revisit old areas (Metroidvania gating).

## 5. World Structure

The quest chain is linear, but the regions are connected, and **portals** (checkpoint plus fast travel) make backtracking easy.

**Part 1:** Cairnwood Village & Forest → Plains, Marblemist Cave → Forgotten Keep (+ Cellar) → Chamber of the Mageblade → Sinister Cave → Evernight Forest → Wellcliff Graveyard, Corrupted Crypt → King's Road → Walls of Florennum, Sewers → City of Florennum → Florennum Dungeon → Overseer's Lair

**Part 2:** Wastelands & Thieves' Hideout → Greyhedge Village → Great Caves, Purplemoor → Chambers of the Flame & Fiery Depths → Icy Cave, Snowy Slopes, Infested Gold Mine, Snowy Summit → Frozen Temple & Hall of Trials → Hall of the Dwarven Kings → Chambers of Power → Corrupted Grove → World's End Keep → Lair of Death

**Every region has its own identity:** new enemy types, a new palette and a small mechanical twist (sliding on ice, lava, darkness).

## 6. Enemies and Bosses

**Enemy families** are reused with color and element variants. This keeps production cheap.
- Beetles: Bush, Spike, Fel, Fire, Frost
- Bats: normal, angry, fire, ice
- Others: Grasswalker, Snapper, Bandits, Charger, Tainted Knight, Skeletons, Bone Eater, Fireblob, Snow Bug, Ice Dwarves, Frost Mage, Dark Knight, Corruptors

**Boss design pattern:** each boss tests the spell earned in that region.

| Boss | Mechanic |
|---|---|
| Overseer | Teleports around the arena when hit; shoot Bolts from a platform |
| Fire boss (Chambers of the Flame) | Pull it down with **Dragon's Grasp**; rolling lava after 50% |
| Dwarven Kings boss | Shielded; destroy two beam sources with **Dimension Rift** |
| Skeleton Lord | Optional; rewards the Magic Sword |
| Master of Chaos | Summoned by striking the chaos stone; the hero's dark double |

Optional named mini-bosses (Szan, Boulder, Zak, Jack, Zudara, Slick...) give each one a personality and reward exploration.

## 7. Level Design Principles

1. **Short rooms, frequent checkpoints.** Falling into a pit returns you to the last ledge with a little damage. Other deaths return you to the last portal.
2. **Hidden chests everywhere:** bombable walls, pushable blocks, high ledges. Completionists get their own goal.
3. **Box physics puzzles:** push, stack, climb, press switches.
4. **Ability gates:** bomb walls, grapple points, rift doors. These give reasons to return to old areas.
5. **Pacing:** new enemies and gear arrive often. Reviewers describe it as fresh from start to finish.

## 8. Visuals and Audio

- **2.5D:** 3D models on a 2D plane, simple low-poly characters.
- Criticism: very simple character models and repetitive environments. Visuals are the most divisive part of the game.
- *Opportunity for MeetRa: a strong, distinctive 2D style.*

## 9. Strengths and Weaknesses

### Why players love it
- Clean, reliable touch controls
- "Pick up and play" design with a console feel on mobile
- Each new spell adds both a combat layer and an exploration layer
- Varied regions and memorable bosses
- Manageable length and fair checkpoints
- Premium, ad-free, with nostalgic Zelda II spirit

### Weaknesses (what MeetRa should fix)
- **Stiff sword combat:** no combos, a fixed swing pattern, enemies attacking from just out of reach
- Simple, repetitive visuals
- Forgettable characters and a derivative story
- A handful of small bugs

## 10. Lessons for MeetRa

| **Keep** from Swordigo | **Improve** on Swordigo |
|---|---|
| Minimal touch controls; buttons appear when abilities are earned | 3-hit combos, air attacks, down-strike (pogo) |
| Choose one of three stats on level-up | Better hit feel: hitstop, screen shake, knockback |
| Four spells = four puzzle languages | Memorable characters and a richer world |
| Region boss guards a shard | A distinctive, hand-drawn 2D style |
| Portals as checkpoint plus fast travel | Original music and sound design |
| Forgiving fall penalty | |

## Sources
- [Wikipedia: Swordigo](https://en.wikipedia.org/wiki/Swordigo)
- [TouchArcade review](https://toucharcade.com/?p=94672)
- [JayIsGames review and walkthrough](https://jayisgames.com/review/swordigo.php)
- [Swordigo Fandom Wiki: Spells](https://swordigo.fandom.com/wiki/Category:Spells)
- [AppSpy review](https://www.appspy.com/swordigo-review)
- [Pocket Gamer review](https://www.pocketgamer.com/swordigo/review/)
- [Pixelneet: "Swordigo: a forgotten classic"](https://pixelneet.substack.com/p/swordigo-a-forgotten-classic)
- [App Store page](https://games.apple.com/game/499125840)
