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

## 3b. World Structure: 7 Realms × 20 Places

The game is played on a **world map** of seven realms (see the map in the Saga Bible). Each realm has its own **realm map** with **20 places** to reach, clear and unlock. That is 140 places in all.

| # | Realm | Theme | Realm boss | Opens when |
|---|---|---|---|---|
| 1 | **Hearthvale** | Green vale, home of Ra | The White Elephant | Start |
| 2 | **Crownhold** | The capital | The Black Hollow | Hearthvale's boss is beaten |
| 3 | **The Serpent Sands** | Desert | Vexar, the Twin-Serpent King | Crownhold's boss is beaten |
| 4 | **Sky Spine & Frostwood** | Snowy mountains | The Pale Giant | Serpent Sands' boss is beaten |
| 5 | **The Duskland** | Steppe | Varak, the Dusk Khan | Sky Spine's boss is beaten |
| 6 | **The Marble West** | Coast | The Cliff Dragon | Duskland's boss is beaten |
| 7 | **The Lightless Land** (hidden) | Darkness | The Mirror of Ra | All **6 Dawn Sigils** are found |

**Every realm has the same 20-place layout:** a winding main road of 14 stops from the town to the boss, plus six side branches.

| Kind | Count | What happens |
|---|---|---|
| Town | 1 | Start of the realm. Rest to restore health. |
| Hearth | 3 | Rest stops along the road. Visiting one opens the road beyond it. |
| Trail | 7 | Platforming levels with enemies, vases and chests. |
| Arena | 1 | A champion fight (mini-boss). |
| Realm boss | 1 | The realm's big fight. Beating it opens the next realm. |
| Cave | 2 | Low-ceiling levels with more treasure. |
| Shrine | 2 | Short levels that grant a permanent blessing (+1 heart, or +might and +aura). |
| Ruin | 1 | Treasure level: +50 gold the first time. |
| Secret | 1 | Hidden until Ra carries Saena's Feather and reaches it. Holds a **Dawn Sigil**. |

**Unlock rule:** a place opens when a neighbouring place is cleared. Secret places stay invisible until they open. Progress and Ra's stats are saved on the device.

Levels for every place are built from hand-made level chunks, seeded by the place's id, so each place always has the same layout. Difficulty rises with each realm (more enemies, tougher enemies, stronger bosses). The Reed Marsh (Hearthvale) is the hand-made tutorial level.

## 3c. The Saga in Play

The story is told in play, on parchment scrolls that pause the game. All text lives in `lib/world/saga.dart`.

| When | What is told |
|---|---|
| New game | The **prologue**: the Dawnfire, the Pale Giant, the blind king, Old Mehr's two roads |
| A realm's map opens for the first time | The realm's **chapter opening** |
| The first realm boss fight starts | The guardian's **words** |
| Back on the realm map after the boss falls | The **chapter's ending** (the Lightless Land's ending closes the saga) |
| Resting in a town | A word from someone there, a different person on each visit |
| Resting at a hearth | The traveller at that hearth |
| Touching a Verse Stone | One verse of the realm's legend |
| Breaking a cage in a cave or ruin | The freed captive's thanks |
| Back on the realm map after a shrine | Saena's vision |
| Back on the realm map after a secret place | Saena on the Dawn Sigil (the Water of Life in the Lightless Land) |

**The chapters** follow the realms: the vale gone cold (Hearthvale), the first darkness (Crownhold), the hungry king (Serpent Sands), the thief in the ice (Sky Spine, where the Dawnfire is won back), the khan beyond the river (Duskland), the edge of the map (Marble West) and the Water of Life (the Lightless Land, which heals the king's eyes).

**Verse Stones.** Seven trails in every realm (road stops 2, 4, 5, 8, 9, 10 and 12) hide a Verse Stone in the farthest room off the road. Each holds one verse of a legend in the breeze of the old epics, told with MeetRa's own people: the first spark, the smith's banner, the cooks who saved half, the first hero of the short road, the eleven duels, the king who tried to fly, and the spring at the end of the world. Seven verses complete a legend and give **+1 might**. The **Book of Verses** keeps them all, and replays every chapter told so far.

**Captives.** Both caves (road stops 14 and 17) and the ruin (16) of every realm hold a captive in a cage in the farthest room off the road. Three sword strikes free them: gold, a heart and a few words of thanks. The realm map marks the cages and counts the captives freed.

## 3d. Towns and Trade

**Towns** are walkable streets with no foes: houses in the realm's style, three townsfolk (the keeper, whose words change every visit, and two ordinary folk), a merchant's stall, an inn and a gate back to the map. Walking in visits the town and opens the roads beyond it. Stand at the stall or the inn's door and tap the Trade or Rest button that appears.

| Ware | Effect | Limit | Price (realm index t) |
|---|---|---|---|
| Healing Draught | Drink in a fight: mends three hearts | Satchel holds 3 | 12 + 4t |
| Heart Vessel | +1 heart | Once per realm, town only | 100 + 50t |
| Aura Tonic | +20 aura | Once per realm | 60 + 30t |
| Whetstone | +1 might | Once per realm, town only | 140 + 60t |

A **travelling merchant** stands by the hearth on road stops 5 and 10 of every realm, selling draughts and tonics. The **inn** is free: health, aura and bombs come back and the game is saved.

## 3e. The Seven Inn Arms

The saga's stories happen in its towns, so that is where Ra is armed. Every realm's inn keeps one weapon, given by the innkeeper on Ra's first night there with a few words about where it came from. Each arm adds more to every blow than the one before (+1 up to +7), and each changes how the attack button fights. Ra's own sword is always carried too; the arms button cycles through the sword and every arm carried, in the order they were won.

| Realm (inn) | Arm | Bonus | Attack button | Use in exploring and fights |
|---|---|---|---|---|
| Hearthvale | Reed Spear | +1 | A long, low thrust (42 px) | Hit foes before they reach Ra |
| Crownhold | Smith's Hammer | +2 | A slow, tall swing with heavy knockback | Smashes cracked rock walls in front of Ra; slabs still need a bomb |
| Serpent Sands | Tamarisk Bow | +3 | Fires an arrow | Strike flies and guardians from afar |
| Sky Spine | Ox-Head Mace | +4 | On the ground: a shockwave both ways; in the air: a heavy swing | Dazes every foe it touches and staggers a guardian on its feet |
| Duskland | Horsehair Lasso | +5 | Throws a loop a short way ahead | Drags a foe to Ra's feet, dazed; catches a guardian out of its charge |
| Marble West | Sea-Glass Shield | +6 | A rush forward behind the shield | Ra cannot be hurt during the rush |
| Lightless Land | Dawnfire Blade | +7 | The sword combo, burning | Every swing also sends a wave of fire that passes through foes |

The down-strike works with every arm. The weapons are a breeze of the old epics (a reed spear, a smith's hammer, a tamarisk bow, an ox-headed mace, a horsehair lasso), told with MeetRa's own people.

**The Mirror of Ra** at the Heart of Night is the battle that needs them all. Ra's own shadow fights like the beasts before it (prowl, charge, pounce, dazed against the wall), but its life is split into **seven wards**, raised in a random order. Each ward breaks only to one arm, shown by the colour of its glow, the diamond over its head and the boss bar; every other blow, feather or bomb is turned aside with a call of which arm gets through. When a ward breaks the Mirror leaps back and raises the next. The Heart of Night stays sealed on the realm map until Ra carries all seven arms.

## 4. Gameplay

### 4.1 Controls (phone)
Landscape. Left thumb moves; right thumb acts.

| Button | Action |
|---|---|
| ◀ ▶ | Walk |
| ▲ | Jump; tap again in mid-air to double jump; hold to jump higher |
| ⚔ | Attack with the arm in hand: the sword's **3-hit combo**, or the inn arm's own blow |
| Arms | Shows the weapon in hand; tap to change to the next one (appears with the first inn arm) |
| 💣 | Bomb: breaks cracked rock (the only way down or up through a cracked slab; set down under a slab, it sticks to it) and hurts foes |
| Bottle | Drink a healing draught (appears when the satchel holds one) |
| ✦ | Cast the selected spell (appears once a spell is earned) |
| (context) | Trade / Rest, shown only at a stall or the inn's door |

There is no down button: a swing while falling onto something strikes down on it.

Rule from Swordigo: **a button does not appear until its ability is earned.**
A keyboard works for development: arrows/WASD, Space, J (attack), K (spell), R or Tab (arms), B (bomb), H (draught), E (trade / rest).

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
