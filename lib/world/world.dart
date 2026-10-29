// The world of MeetRa: seven realms, each with twenty locations to reach and clear.
// Realms 1-6 open one after another (beat a realm's boss to open the next).
// The seventh, the Lightless Land, stays hidden until all six Dawn Sigils are found:
// one sigil waits in the secret location of every realm.

import 'dart:math' as math;

import '../config.dart';
import 'progress.dart';

enum LocKind { town, hearth, trail, cave, shrine, ruin, arena, boss, secret }

extension LocKindInfo on LocKind {
  String get label => switch (this) {
        LocKind.town => 'Town',
        LocKind.hearth => 'Hearth',
        LocKind.trail => 'Trail',
        LocKind.cave => 'Cave',
        LocKind.shrine => 'Shrine',
        LocKind.ruin => 'Ruin',
        LocKind.arena => 'Arena',
        LocKind.boss => 'Realm boss',
        LocKind.secret => 'Secret',
      };

  // Towns and hearths are visited, not played
  bool get playable => this != LocKind.town && this != LocKind.hearth;
}

enum RealmTheme { vale, city, desert, mountain, steppe, coast, dark }

class Location {
  Location(this.realm, this.index, this.kind, this.name, this.desc);

  final Realm realm;
  final int index;
  final LocKind kind;
  final String name;
  final String desc;
  final links = <Location>[];
  double x = 0, y = 0; // position on the realm map, 0..1

  String get id => '${realm.id}/$index';
  // Secret places need Saena's Feather to break the seal
  bool get needsFeather => kind == LocKind.secret;
}

class Realm {
  Realm({
    required this.index,
    required this.id,
    required this.name,
    required this.tagline,
    required this.lore,
    required this.theme,
    required this.color,
    required this.bossName,
    required this.bossTitle,
    required this.mapX,
    required this.mapY,
    this.hidden = false,
  });

  final int index;
  final String id;
  final String name;
  final String tagline;
  final String lore; // one or two sentences for the world map
  final RealmTheme theme;
  final int color; // ARGB, used for the map medallion and to tint the level sky
  final String bossName;
  final String bossTitle;
  final double mapX, mapY; // position on the world map, 0..1
  final bool hidden;
  final locations = <Location>[];

  Location get boss => locations[bossIndex];
  Location get secret => locations[secretIndex];
}

// Every realm uses the same layout: a winding main road of 14 stops (town → boss)
// with six side branches. Index: kind.
const _kinds = [
  LocKind.town, LocKind.trail, LocKind.trail, LocKind.hearth, LocKind.trail, LocKind.trail, LocKind.arena,
  LocKind.hearth, LocKind.trail, LocKind.trail, LocKind.trail, LocKind.hearth, LocKind.trail, LocKind.boss,
  LocKind.cave, LocKind.shrine, LocKind.ruin, LocKind.cave, LocKind.shrine, LocKind.secret,
];
const bossIndex = 13;
const secretIndex = 19;
// Side branches: (branch location, the main-road stop it hangs off)
const _branches = [(14, 2), (15, 4), (16, 6), (17, 9), (18, 11), (19, 12)];

// (name, description) for the 20 locations of each realm, in layout order
const _places = <String, List<(String, String)>>{
  'hearthvale': [
    ('Hearthvale Village', "Ra's home. Old Mehr keeps the village hearth burning."),
    ('The Reed Marsh', 'The First Trial. A lion stalks the reeds at the edge of the vale.'),
    ('Willow Ford', 'Shallow water and slippery stones. Horned demons lurk in the willows.'),
    ('Riverside Hearth', 'A fire on the riverbank. Rest and remember the way.'),
    ('The Salt Road', 'Caravans once carried salt here. Now horned demons wait in the hills.'),
    ('Sepand Watch', 'The fortress Ra once entered hidden in a salt caravan.'),
    ('Wild Horse Meadow', 'Where Ember was tamed. Something fierce guards the meadow now.'),
    ('Orchard Hearth', 'A hearth among pomegranate trees.'),
    ('Cypress Row', 'Tall cypresses line the road like a guard of honour.'),
    ("Shepherd's Climb", 'A steep path of ledges up to the high pastures.'),
    ('Kabulmere Bridge', 'The old bridge to Kabulmere, half fallen into the gorge.'),
    ('Tower Hearth', 'A fire at the foot of the tower where Rue once let down her braid.'),
    ('The Elephant Trail', 'Huge footprints and broken trees lead north.'),
    ('The Ivory Ruin', 'Lair of the White Elephant, who once terrorised the village.'),
    ('Badger Hollow', 'A burrow that goes much deeper than any badger needs.'),
    ('Shrine of the First Spark', 'Where fire was first struck from stone. Its warmth makes the heart stronger.'),
    ('Fallen Watchtower', 'A ruined tower. The old guards left their savings behind.'),
    ('Glowworm Cave', 'A cave lit by a thousand tiny lights.'),
    ('Shrine of Saena', 'A feather-shaped altar. Saena listens here.'),
    ("Saena's Hidden Nest", 'The great bird\'s secret nest. Only a feather can open the way.'),
  ],
  'crownhold': [
    ('Crownhold City', 'The heart of the realm, under the blinded king.'),
    ("Kings' Gate", 'The great gate of the capital, overrun by Hollows.'),
    ('Market Ward', 'Empty stalls, overturned carts and something moving in the shadows.'),
    ("Smiths' Hearth", 'The forge fire where Bram the Smith worked.'),
    ('Banner Square', 'Where the Leather Banner was first raised against the Serpent King.'),
    ('The Radiant Steps', "The stairs of Jarem's golden palace, now cracked."),
    ('The Polo Field', 'A field for games, now a field for duels.'),
    ('Palace Hearth', 'The royal fire, still burning low.'),
    ('Granary Row', 'The famine granaries. Rats and worse have moved in.'),
    ('The Fire Corridor', 'Where Prince Aven rode through two walls of flame.'),
    ('The Great Cypress', 'The tree the Fire Prophet planted, taller than the palace.'),
    ('Temple Hearth', 'The sacred fire of the temple.'),
    ('Throne Hall', 'The empty throne room. The darkness is thickest here.'),
    ('The Shadow Vault', 'Home of the Black Hollow, the first darkness.'),
    ('The Old Sewers', 'Tunnels under the city. Watch your step.'),
    ('Shrine of the Binder', 'Taro the Binder carved his glyphs here. Strength flows from them.'),
    ("Jarem's Fallen Throne", 'The flying throne, crashed in the gardens long ago.'),
    ('The Catacombs', 'The resting place of old kings. Not all of them rest.'),
    ('Shrine of the Fire Prophet', 'A quiet shrine with a fire that never smokes.'),
    ('The Sealed Library', 'Thirty kinds of writing, locked behind a seal of feathers.'),
  ],
  'sands': [
    ('Oasis of Wells', 'The last green place before the desert. Fill your waterskin.'),
    ('The Dune Sea', 'Endless dunes under a white sun.'),
    ('The Thirst Road', 'The Second Trial. No water, and no shade.'),
    ('Palm Hearth', 'A fire among palms at a dry well.'),
    ("The White Ram's Spring", 'Follow the white ram, and it leads to hidden water.'),
    ('The Kitchen Ruins', 'Where the Whispering Cook served the Serpent King.'),
    ('The Scorpion Pit', 'A fighting pit dug into the sand.'),
    ('Caravan Hearth', 'A caravan stop with a fire and friendly traders.'),
    ('The Glass Flats', 'Sand melted into glass by an old fire.'),
    ('Wormhold Docks', 'A port on the gulf, rich with silk.'),
    ('The Silkworm Gate', 'The gate of the fortress where a giant worm was fed.'),
    ('Mirage Hearth', 'A hearth that is really there. Probably.'),
    ('The Serpent Stair', 'Stairs carved in the shape of two snakes.'),
    ('The Twin-Serpent Court', 'Throne of Vexar, the Twin-Serpent King.'),
    ('The Buried Tomb', 'A tomb swallowed by the dunes.'),
    ('Shrine of the Rescued', 'Built by the people the kitchen servants saved.'),
    ('The Copper Wreck', 'A ship from the Copper Coast, stranded far from the sea.'),
    ('The Sandworm Burrow', 'The ground hums here.'),
    ('Shrine of Cool Water', 'A cold spring inside a shrine. It restores the spirit.'),
    ('The Mirage City', 'A city that is only seen in the heat. A feather shows its door.'),
  ],
  'skyspine': [
    ('Mountain Hamlet', 'A village of goatherds at the foot of the Sky Spine.'),
    ('The Goat Path', 'A narrow path only goats and heroes use.'),
    ('Eagle Ledge', 'Eagles circle overhead. One wrong step is a long fall.'),
    ('Pass Hearth', 'A fire in a stone hut on the pass.'),
    ('Chain Mountain Foot', 'Below the mountain where the Serpent King is chained.'),
    ("Kaedan's Hermitage", 'Where the heir lived quietly before Ra brought him home.'),
    ("Warden's Bridge", 'The Mountain Warden lets no one cross without a fight.'),
    ('Snowline Hearth', 'The last fire before the snow.'),
    ('Frostwood Edge', 'Pale trees, white with frost.'),
    ("The Witch's Garden", 'Flowers in the snow, and platforms that are not really there.'),
    ('Night Serpent Gorge', 'A dark gorge. Something huge moves in it.'),
    ('Ice Hearth', 'A fire that burns blue.'),
    ("The Warlord's Camp", "The Horned Warlord's war camp, full of the Giant's soldiers."),
    ('The Frozen Cave', 'Lair of the Pale Giant, who swallowed the Dawnfire.'),
    ('Echo Cave', 'Every sound comes back twice.'),
    ('Shrine of the Mountain King', 'The first king ruled from these heights.'),
    ("Corin's Last Camp", 'Where King Corin walked into the snow and was never seen again.'),
    ('The Ice Caverns', 'Caves of blue ice.'),
    ('Shrine of the Storm', 'Wind howls through this shrine day and night.'),
    ("Saena's Peak", 'The summit of the world, where Saena was born.'),
  ],
  'duskland': [
    ('Ashen River Camp', 'A camp on the bank of the Ashen River, the border of the Duskland.'),
    ('The Ashen Ford', 'The ford where Corin crossed without a boat.'),
    ('The Steppe Road', 'Open grassland as far as the eye can see.'),
    ('Nomad Hearth', 'A fire in a felt tent.'),
    ("Hunters' Field", 'Where the Seven Hunters held their feast.'),
    ('Silverhill', 'The town where Ember was once stolen.'),
    ('Field of the Twelve Duels', 'Champions meet here one on one.'),
    ('Garden Hearth', 'A fire in the ruined gardens of Aven.'),
    ("Aven's City", 'The beautiful city Prince Aven built, now silent.'),
    ('The Stone Pit', 'The pit where Bran was trapped under a great stone.'),
    ('Bright Fort', 'The hill fort of Prince Fen.'),
    ('Lake Hearth', 'A fire on the shore of a dark mountain lake.'),
    ('The Brazen Fortress', 'A fortress of bronze walls.'),
    ('The Lake of Hiding', 'Varak, the Dusk Khan, makes his last stand here.'),
    ('Shepherd Caves', 'Where young Corin grew up hidden among shepherds.'),
    ('Shrine of the Blood-Flower', 'A red flower grows here, and it heals.'),
    ('Hamavan Heights', 'The mountaintop where an army was once besieged.'),
    ('Whirlwind Hollow', 'A hollow where the Whirlwind Ogre sleeps.'),
    ('Shrine of the Seeker', 'Gale the Seeker rested here during his seven years of searching.'),
    ("The Hermit's Cave", 'Hume the Hermit\'s hidden home. Its door answers only to a feather.'),
  ],
  'marble': [
    ('The Marble Harbor', 'White ships in a white harbor.'),
    ('The Olive Coast', 'Olive groves above a blue sea.'),
    ('The Cliff Road', 'A road cut into the sea cliffs.'),
    ('Lighthouse Hearth', 'A fire at the top of the lighthouse.'),
    ('The Choosing Hall', 'Where Katya chose a nameless stranger.'),
    ('The Great Wolf Forest', 'Home of a wolf the size of a house.'),
    ('The Colosseum', 'The great arena of the West.'),
    ('Vineyard Hearth', 'A fire among the vines.'),
    ('The Marble Throne', 'The palace of the western kings.'),
    ('The Two Rivers Delta', 'Where two great rivers meet the sea.'),
    ("The River Child's Reeds", 'Where a baby in a chest was found among the reeds.'),
    ('Bridge Hearth', 'A fire on an old stone bridge.'),
    ('The Dragon Cliffs', 'Burnt rocks and old bones.'),
    ("The Dragon's Crown", 'The Cliff Dragon nests on the highest rock.'),
    ('The Sea Grotto', 'A grotto that floods with the tide.'),
    ('Shrine of the Waves', 'A shrine half under the sea.'),
    ('The Sunken Temple', 'A temple that slid into the bay.'),
    ("Smugglers' Cave", 'A cave full of forgotten cargo.'),
    ('Shrine of the Talking Tree', 'A sapling of the tree that speaks the future.'),
    ('The Lost Galley', 'A ghost ship that only appears to a feather-bearer.'),
  ],
  'lightless': [
    ('The Last Lantern', 'The last light before the dark. Beyond it, no sun.'),
    ('The Fog Road', 'Fog so thick you hear the path more than see it.'),
    ('The Whispering Stones', 'Stones that whisper the names of the lost.'),
    ('Glowstone Hearth', 'A hearth of stones that glow on their own.'),
    ('The Wall of Yag', 'The great wall built against the swarm.'),
    ('The Talking Tree', 'It knows how many days you have left. Will you ask?'),
    ('The Mirror Arena', 'An arena of black glass. Your reflection fights back.'),
    ('Ember Hearth', 'A hearth lit with a spark from the Dawnfire.'),
    ('The Lightless Forest', 'Trees without leaves, without color.'),
    ('The Sound Caves', 'Caves where you navigate by echoes.'),
    ('The Shore of Darkness', 'The edge of a black sea.'),
    ('Silent Hearth', 'A hearth that makes no sound.'),
    ('The Gate of Dawn', 'A gate that has never been opened.'),
    ('The Heart of Night', 'Your own shadow waits here, wearing your face.'),
    ('Cave of Lost Souls', 'Lost travellers still wander here.'),
    ('Shrine of Sound', 'A shrine of bells that ring by themselves.'),
    ('Ruins of the First City', 'Older than the first king.'),
    ('The Bottomless Cave', 'They say it has no floor. They are almost right.'),
    ('Shrine of the Dawnfire', 'The first flame was lit here, before time.'),
    ('The Water of Life', 'The spring at the end of the world. The true ending of the saga.'),
  ],
};

final List<Realm> realms = _buildRealms();

List<Realm> _buildRealms() {
  final list = [
    Realm(index: 0, id: 'hearthvale', name: 'Hearthvale', tagline: 'Home of Ra',
        lore: "Green hills and reed marshes around Ra's home. The hearth fires burn here first.", theme: RealmTheme.vale,
        color: 0xff4f9a5a, bossName: 'The White Elephant', bossTitle: 'Terror of the Vale', mapX: 0.82, mapY: 0.60),
    Realm(index: 1, id: 'crownhold', name: 'Crownhold', tagline: 'The heartland',
        lore: "The walled capital of the blinded king. Hollows creep through its streets and vaults.", theme: RealmTheme.city,
        color: 0xff2a4a9a, bossName: 'The Black Hollow', bossTitle: 'The First Darkness', mapX: 0.62, mapY: 0.50),
    Realm(index: 2, id: 'sands', name: 'The Serpent Sands', tagline: 'Land of the Twin-Serpent King',
        lore: "Dunes, dry wells and ghouls buried in the sand, below the court of a king with a serpent on each shoulder.", theme: RealmTheme.desert,
        color: 0xffc8913a, bossName: 'Vexar', bossTitle: 'The Twin-Serpent King', mapX: 0.44, mapY: 0.74),
    Realm(index: 3, id: 'skyspine', name: 'Sky Spine & Frostwood', tagline: 'Mountains of ice',
        lore: "Ice-capped peaks and frozen woods. The Pale Giant hides the stolen Dawnfire up here.", theme: RealmTheme.mountain,
        color: 0xff7fa9c8, bossName: 'The Pale Giant', bossTitle: 'Thief of the Dawnfire', mapX: 0.47, mapY: 0.26),
    Realm(index: 4, id: 'duskland', name: 'The Duskland', tagline: 'Realm of the Dusk Khan',
        lore: "Endless grass beyond the Ashen River, ruled by the Dusk Khan from his lake.", theme: RealmTheme.steppe,
        color: 0xff7a4a8e, bossName: 'Varak', bossTitle: 'The Dusk Khan', mapX: 0.25, mapY: 0.30),
    Realm(index: 5, id: 'marble', name: 'The Marble West', tagline: 'White cities by the sea',
        lore: "White harbors, olive groves and sea cliffs where the Cliff Dragon nests.", theme: RealmTheme.coast,
        color: 0xff2bb3a8, bossName: 'The Cliff Dragon', bossTitle: 'Lord of the Western Rocks', mapX: 0.08, mapY: 0.66),
    Realm(index: 6, id: 'lightless', name: 'The Lightless Land', tagline: 'Where the Water of Life is hidden',
        lore: "A land without sun at the edge of the world. The Water of Life waits in its dark.", theme: RealmTheme.dark,
        color: 0xff4a4658, bossName: 'The Mirror of Ra', bossTitle: 'Your own shadow', mapX: 0.80, mapY: 0.16, hidden: true),
  ];
  for (final r in list) {
    final places = _places[r.id]!;
    for (var i = 0; i < 20; i++) {
      r.locations.add(Location(r, i, _kinds[i], places[i].$1, places[i].$2));
    }
    void link(int a, int b) {
      r.locations[a].links.add(r.locations[b]);
      r.locations[b].links.add(r.locations[a]);
    }

    for (var i = 0; i < bossIndex; i++) {
      link(i, i + 1);
    }
    for (final (branch, parent) in _branches) {
      link(branch, parent);
    }
    _layout(r);
  }
  return list;
}

// Main road winds left to right; branches sit above or below their stop
void _layout(Realm r) {
  final phase = r.index * 1.3;
  for (var i = 0; i <= bossIndex; i++) {
    final l = r.locations[i];
    l.x = 0.05 + i * (0.90 / bossIndex);
    l.y = 0.5 + 0.22 * math.sin(i * 0.85 + phase);
  }
  for (final (branch, parent) in _branches) {
    final p = r.locations[parent];
    final up = p.y > 0.5;
    r.locations[branch]
      ..x = (p.x + 0.035).clamp(0.05, 0.95)
      ..y = up ? p.y - 0.36 : p.y + 0.36;
  }
}

// ---------- Rules ----------

int sigilCount(Progress p) => realms.take(6).where((r) => p.isCleared(r.secret)).length;

bool realmUnlocked(Realm r, Progress p) {
  if (r.index == 0) return true;
  if (r.hidden) return sigilCount(p) >= 6;
  return p.isCleared(realms[r.index - 1].boss);
}

// A location can be entered when its realm is open, any neighbour is cleared (or it is the town),
// and, for secret places, Ra carries Saena's Feather.
bool isOpen(Location l, Progress p, GameState s) {
  if (!realmUnlocked(l.realm, p)) return false;
  if (l.needsFeather && !s.hasFeather) return false;
  if (l.index == 0) return true;
  return l.links.any(p.isCleared);
}

int clearedIn(Realm r, Progress p) => r.locations.where(p.isCleared).length;
