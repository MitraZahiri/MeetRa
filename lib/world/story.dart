// The tale of MeetRa, told in short pages: a prologue, an opening for every realm, and the words
// of every realm boss when Ra first faces it and when it falls. Each part is told only once.

// The prologue, before the first look at the world map
const prologue = [
  'Long ago the sun had an eye, and the Eye of Ra watched over the seven realms. '
      'Its light was kept on earth in a single flame: the Dawnfire, burning in the hearth of Hearthvale.',
  'One winter night the Pale Giant came down from the Sky Spine, crushed the hearth and carried the Dawnfire away into the ice. '
      "Since then every day is shorter, and the sun's eye grows dim.",
  'Creatures that fear the light crept out of their holes: horned demons, carrion flies, the scorpions of the dark spirit. '
      'Kings fell silent. Roads went dark.',
  'Old Mehr, keeper of the village fire, put a sword in the hands of a young guardian. '
      '"Walk the Road of Seven Trials, Ra. Bring the dawn home."',
];

// Told the first time Ra enters each realm
const realmTales = [
  [
    'The reeds whisper of a lion in the marsh, and the White Elephant tramples the orchards. '
        'Before the road can leave the vale, the vale itself must be made safe.',
    'Saena, the great bird, has dropped a feather somewhere near. Find it, and sealed doors will open for you.',
  ],
  [
    'The capital is dark at noon. The king was blinded the night the Dawnfire fell, '
        'and a shadow sits on his throne: the Black Hollow, the first darkness, which feeds on fear.',
    'Divs have come down from the hills to the walls. They hurl boulders at anything that moves. '
        'Cut the stones out of the air, or keep moving.',
  ],
  [
    'South lie the Serpent Sands, ruled by Vexar the Twin-Serpent King. '
        'Two snakes grow from his shoulders, and every day they must be fed.',
    "His serpents spit venom from the dunes, and ghouls sleep under the sand. Watch where you step. "
        "The Pale Giant bought Vexar's loyalty with a spark of the stolen fire.",
  ],
  [
    'At last, the mountains. Somewhere in the ice the Pale Giant guards the Dawnfire, and the cold here bites through armour.',
    'Al, the hag-spirit, haunts the frozen woods. She melts into the air and returns behind you. '
        'When she flickers, turn and strike.',
  ],
  [
    "The Dawnfire burns again, yet the sun's eye stays dim. Before he fell, the Pale Giant gave a shard of the flame "
        'to Varak, the Dusk Khan, who longs for a world of endless evening.',
    "Cross the Ashen River and ride into the steppe. The Khan's riders have never lost a battle.",
  ],
  [
    "Varak's shard was not the last. The Cliff Dragon swallowed one ember and nests with it on the western rocks, "
        'and the white cities by the sea have shut their gates in fear.',
    'Climb the sea cliffs. Beyond the dragon, at the edge of the map, the old charts end in darkness.',
  ],
  [
    'Six Dawn Sigils shine together, and a road opens where there was none: into the Lightless Land, where no sun has ever risen.',
    'Only the Water of Life can wake the Eye of Ra again. But something waits at the spring with your face, '
        'your sword, and all your strength.',
  ],
];

// What each realm boss says when Ra first steps into its arena
const bossTaunts = [
  '"Little guardian. Go home to your hearth while you still have one."',
  '"I am the dark behind your eyes. The king feared me first. You will be next."',
  '"My serpents are hungry, child of the dawn. Today they feed on a hero."',
  '"The Dawnfire is mine! Its warmth is the only warmth in all this ice. Come and take it, if your hands do not freeze."',
  '"Why fight the dusk? Evening is gentle. Lay down your sword and rest forever."',
  '"The ember in my belly is older than your kings. Climb down from my rock, or burn."',
  '"I know every move you make, Ra. I am every move you make."',
];

// Told when each realm boss falls; the last one is the ending of the saga
const bossFalls = [
  ['The beast falls. The vale breathes again, and the old road north to Crownhold is open.'],
  [
    'Light spills into the throne hall. The blind king weeps: he can feel the sun on his face.',
    'Far to the south, the sands are stirring.',
  ],
  [
    'The serpents fall silent and Vexar crumbles to dust.',
    'In his treasury lies a map of the frozen mountains, with an X drawn in red ink.',
  ],
  [
    'The Dawnfire! Ra lifts it out of the ice, and its warmth floods the mountains.',
    "Yet high above, the sun's eye stays dim. A shard of the flame is missing.",
  ],
  [
    "The Dusk Khan's shard returns to the flame, and the steppe turns gold in a long sunset.",
    'But one ember is still missing, somewhere in the west.',
  ],
  [
    "The dragon's ember joins the flame. The Dawnfire burns whole at last.",
    "But the sun's eye has slept too long. Only the Water of Life can wake it now.",
  ],
  [
    "The shadow bows and fades into Ra's own. Beyond it, the Water of Life glitters in the dark.",
    'Ra lets a single drop fall into the Dawnfire. High above, for the first time in a hundred days, the Eye of Ra opens wide.',
    'The seven realms wake to a long, golden dawn. The road home is short, and the hearth of Hearthvale is warm again.\n\nThe End',
  ],
];
